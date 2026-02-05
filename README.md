# RawBench

Benchmarking framework for raw signal analysis (RSA) of nanopore sequencing data. RSA methods skip basecalling and work directly on the electrical signal, which is faster but involves different tradeoffs in accuracy and resource usage.

RawBench decomposes RSA into three stages and benchmarks different methods at each:

| Stage | Methods compared |
|---|---|
| Reference encoding | ONT pore model, uncalled4 pore model |
| Signal segmentation | t-test event detection |
| Representation matching | hash-based (RawHash2), FM-index (uncalled), r-index (Sigmoni), DTW, vector distances |

The baseline is the traditional basecall-then-map approach (Dorado + minimap2).

Associated paper: [Eris et al., 2025](https://arxiv.org/pdf/2510.03629)

## Datasets

Three organisms at different genome sizes, plus a mock community for classification:

| ID | Organism | Reference | Chemistry |
|---|---|---|---|
| d8 | H. sapiens | CHM13v2 | R10.4.1 |
| d9 | E. coli | CFT073 | R10.4.1 |
| d10 | D. melanogaster | BDGP6.32 | R10.4.1 |
| zymo | Zymo mock community | combined refs | R9.4.1 |

Signal data: https://huggingface.co/collections/nappenstance/rawbench-datasets

## Methods benchmarked

### Read mapping (signal → genomic coordinates)

Each method indexes a reference genome, then maps raw signal reads against it:

| Script pattern | Method | Stages |
|---|---|---|
| `d*_mm2.sh` | minimap2 | basecall → map (baseline) |
| `d*_uncalled4_hash_ttest.sh` | RawHash2 hash | t-test segmentation → hash matching |
| `d*_uncalled4_fmindex_ttest.sh` | uncalled FM-index | t-test segmentation → FM-index matching |
| `d*_uncalled4_dtw.sh` | uncalled4 DTW | signal storage → DTW alignment |
| `d*_uncalled4_vectordistances_ttest.sh` | uncalled4 vector | t-test segmentation → vector distance matching |
| `d*_ont_hash_ttest.sh` | ONT hash | t-test segmentation → hash matching (ONT model) |

Chunk-limited variants (`d*_Nchunksmax_mm2.sh`) test how quickly each method reaches a mapping decision using only the first N signal chunks.

### Read classification (signal → species label)

Binary classification on the Zymo mock community (positive vs negative reference set):

| Script | Method |
|---|---|
| `zymo_ont_rindex_ttest.sh` | Sigmoni with ONT pore model + r-index |
| `zymo_uncalled4_rindex_ttest.sh` | Sigmoni with uncalled4 pore model + r-index |
| `zymo_uncalled4_fmindex_ttest.sh` | uncalled FM-index |
| `zymo_uncalled4_hashbased_ttest.sh` | RawHash2 hash-based |
| `zymo_uncalled4_dtw_ttest.sh` | uncalled4 DTW |
| `zymo_uncalled4_vectordistances_ttest.sh` | uncalled4 vector distances |

### Evaluation

All methods produce PAF files. Evaluate with `uncalled pafstats`:

```bash
uncalled pafstats -r ground_truth.paf --annotate tool_output.paf \
  > annotated.paf 2> metrics.throughput
```

## Setup

### 1. Clone with submodules

```bash
git clone --recursive https://github.com/CMU-SAFARI/RawBench.git
cd RawBench
```

If you already cloned without `--recursive`:
```bash
git submodule update --init --recursive
```

### 2. Install tools

**Conda environments:**

```bash
# Sigmoni (r-index classification) -- needs ont-fast5-api to read fast5
conda create --name sigmoni python=3.8 -y
conda activate sigmoni
conda install h5py numpy scipy ont-fast5-api -y
pip install uncalled4

# minimap2 (basecall-then-map baseline)
conda create --name mm2 -y && conda activate mm2 && conda install minimap2 -y

# BAM conversion (basecalling benchmarks only)
conda create --name bamtofastq -y && conda activate bamtofastq && conda install -c bioconda bamtofastq -y
```

**Build SPUMONI** (r-index backend for Sigmoni):

```bash
cd spumoni_submodule
mkdir -p build && cd build
cmake ..
make -j$(nproc)
make install          # required -- copies helper programs to build/bin/
cd ../..
```

**External tools** (not included, install separately):
- [Dorado](https://github.com/nanoporetech/dorado) -- ONT basecaller. Set `DORADO_PATH`.
- [RawHash2](https://github.com/CMU-SAFARI/RawHash2) -- hash-based signal mapper. Install to `../bin/rawhash2` or set `RAWHASH2_PATH`.

### 3. Download data

```bash
# Reference genomes
cd refs && bash download_refs.sh && cd ..

# Signal data (fast5)
cd fast5 && bash download.sh && cd ..
```

Or download individual organisms: `bash download_refs.sh ecoli`, `bash download.sh ecoli`.

### 4. Load environment

```bash
source scripts/setup_env.sh
validate_environment
```

This sets `SPUMONI_BUILD_DIR`, adds SPUMONI and its helpers to `PATH`, and checks that tools exist. Override paths before sourcing if needed:

```bash
export DORADO_PATH="/your/path/to/dorado"
export RAWHASH2_PATH="/your/path/to/rawhash2"
source scripts/setup_env.sh
```

### 5. Smoke test

```bash
source scripts/setup_env.sh
conda activate sigmoni
mkdir -p /tmp/rawbench_test/output

# Build Sigmoni index (ecoli positive, dmelanogaster negative)
python sigmoni_submodule/index.py \
  -p refs/ecoli.fa -n refs/dmelanogaster.fa \
  -b 6 --shred 100000 \
  -o /tmp/rawbench_test --ref-prefix ecoli_test

# Classify ecoli fast5 reads
python sigmoni_submodule/main.py \
  -i fast5/ecoli/ \
  -r /tmp/rawbench_test/refs/ecoli_test \
  -b 6 -t $(nproc) \
  -o /tmp/rawbench_test/output \
  --complexity --sp

# Should print read_id / class columns
head /tmp/rawbench_test/output/reads_binary.report
```

## Running benchmarks

Edit `#SBATCH` headers in the job scripts for your cluster (partition names, node exclusions are site-specific).

```bash
source scripts/setup_env.sh

# Basecalling (Dorado)
sbatch job_scripts/basecalling/d9_basecall_sup.sh

# Read mapping -- different methods on same dataset
sbatch job_scripts/read_mapping/d9_mm2.sh                          # baseline
sbatch job_scripts/read_mapping/d9_uncalled4_fmindex_ttest.sh      # FM-index
sbatch job_scripts/read_mapping/d9_uncalled4_vectordistances_ttest.sh  # vector distances

# Read classification -- different methods on Zymo
sbatch job_scripts/read_classification/zymo_ont_rindex_ttest.sh            # r-index
sbatch job_scripts/read_classification/zymo_uncalled4_hashbased_ttest.sh   # hash-based
sbatch job_scripts/read_classification/zymo_uncalled4_fmindex_ttest.sh     # FM-index
```

## Nextflow pipeline

The `nextflow-pipeline/` directory contains a Nextflow workflow that decomposes RawHash2 into its three stages (reference encoding, signal segmentation, representation matching) as separate processes. See [its README](nextflow-pipeline/README.md) for details. Currently only implements RawHash2's methods.

## Repository layout

```
RawBench/
├── scripts/setup_env.sh           # environment config
├── sigmoni_submodule/              # Sigmoni r-index classifier (submodule)
├── spumoni_submodule/              # SPUMONI r-index backend (submodule)
├── job_scripts/
│   ├── basecalling/                # Dorado basecalling (d8, d9, d10)
│   ├── read_mapping/               # mm2, hash, FM-index, DTW, vector dist.
│   └── read_classification/        # Sigmoni, hash, FM-index, DTW, vector dist.
├── nextflow-pipeline/              # modular Nextflow decomposition of RawHash2
├── refs/
│   ├── download_refs.sh            # downloads ecoli, hsapiens, dmelanogaster
│   └── download_references.md
├── fast5/
│   ├── download.sh                 # downloads signal data
│   └── ecoli_filenames.txt
├── kmer_models/                    # pore chemistry models (included)
│   ├── ont_r10.4.1.txt
│   └── uncalled4_r10.4.1.txt
├── outputs/                        # benchmark results
├── basecalled_reads/               # generated FASTQs
└── DEPENDENCIES.md
```

## Troubleshooting

Run `validate_environment` to check what's missing.

- SPUMONI crashes with "helper program paths are invalid" -- run `make install` in `spumoni_submodule/build/`.
- `sigmoni_submodule/` is empty -- run `git submodule update --init --recursive`.
- Sigmoni `main.py` crashes with `FileNotFoundError` -- create the output directory first (`mkdir -p`).
- SLURM jobs fail -- edit `#SBATCH` headers. Partition names (`gpu_part`, `cpu_part`) and node exclusions (`--exclude=kratos...`) are site-specific.
- `uncalled` / `rawhash2` not found -- install them and set paths, or put binaries in `../bin/`.

## Output files

- `*.report` -- per-read classification (TSV: read_id, class)
- `*.paf` -- alignments in PAF format
- `*_ann.paf` -- PAF annotated with evaluation metrics
- `*.throughput` -- accuracy, speed, and throughput metrics
- `*.pseudo_lengths` -- PML profiles (Sigmoni)
- `*_timing.log` -- resource usage from `/usr/bin/time -v`
- `*.out` / `*.err` -- SLURM logs

## Citation

```bibtex
@software{rawbench2025,
  title = {RawBench: A comprehensive benchmarking framework for raw nanopore signal analysis},
  author = {Eris, Furkan and McConnell, Ulysse and Firtina, Can and Mutlu, Onur},
  year = {2025},
  url = {https://github.com/CMU-SAFARI/RawBench}
}
```

## License

MIT
