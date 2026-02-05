# RawBench Nextflow pipeline

Nextflow pipeline that breaks RawHash2's signal analysis into swappable stages: reference encoding, signal segmentation, and representation matching. The idea is to let you mix and match components for evaluation, though right now only RawHash2's own methods are implemented.

## Prerequisites

- Nextflow >= 22.04.0
- Java 8+
- GCC/G++ (to compile the C/C++ binaries)
- RawHash2 built and available at `../rawhash2/`

## Installation

```bash
cd rawbench/nextflow-pipeline

# Build RawHash2 first (the pipeline links against it)
cd ../rawhash2
make
cd ../nextflow-pipeline

# Build the pipeline's C binaries
cd bin
make all
cd ..

# Check it works
nextflow run main.nf --help
```

Or step by step:

```bash
# 1. Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# 2. Build RawHash2
cd rawbench/rawhash2 && make

# 3. Build pipeline binaries (links against RawHash2)
cd ../nextflow-pipeline/bin && make all
```

## Running

```bash
# Replicate RawHash2 exactly
nextflow run main.nf \
  --reference_fasta refs/ecoli.fa \
  --signal_files "../pod5/ecoli.pod5" \
  --preset rawhash2

# Pick components yourself
nextflow run main.nf \
  --reference_fasta refs/hsapiens.fa \
  --signal_files "../pod5/hsapiens.pod5" \
  --pore_model uncalled4_r1041 \
  --segmentation_method ttest \
  --matching_method hash
```

### Profiles

- `standard` -- runs locally, 4 CPUs, 8 GB RAM
- `cluster` -- submits to SLURM (partition names are hardcoded to our cluster, edit `nextflow.config` for yours)
- `rawhash2` -- loads RawHash2-specific settings from `conf/rawhash2.config`

```bash
nextflow run main.nf -profile cluster,rawhash2 \
  --reference_fasta refs/ecoli.fa \
  --signal_files "../pod5/ecoli.pod5"
```

## What the pipeline does

Four stages, each in its own Nextflow module:

1. `REFERENCE_ENCODING` -- converts FASTA to expected signal levels using a pore model. Extracted from RawHash2's `ri_seq_to_sig()`.
2. `SIGNAL_SEGMENTATION` -- detects events in raw signal (t-test segmentation). From RawHash2's `detect_events()`.
3. `REPRESENTATION_MATCHING` -- hashes segmented events and chains matches against the encoded reference. From RawHash2's sketching + chaining code.
4. `EVALUATE_RESULTS` -- runs evaluation metrics on the output PAF.

The binary sources map to RawHash2 files:
- `reference_encoder.c` from `rawhash2/src/rsig.c`
- `signal_segmenter.c` from `rawhash2/src/revent.c`
- `hash_matcher.cpp` from `rawhash2/src/rsketch.c`, `rseed.c`, `rmap.cpp`

### What's actually swappable (and what isn't yet)

The `--pore_model` flag has two options (`uncalled4_r1041` and `ont_r1041`), both from RawHash2's bundled models. Segmentation is t-test only. Matching is hash only. Adding more methods is the point of the modular design, but it hasn't happened yet.

## Output

```
results/
├── reference_encoding/      # encoded reference signals
├── signal_segmentation/     # segmented event streams
├── representation_matching/ # PAF mapping results
├── evaluation/              # metrics
├── timeline.html            # Nextflow execution timeline
├── report.html              # Nextflow report
└── trace.txt                # resource usage per task
```

## Adding new components

1. Write a new module in `modules/`
2. Put the binary in `bin/`
3. Wire it into `main.nf`
4. Add any config in `conf/`

## Citation

If you use this, cite RawHash2 (the signal analysis components come from there):

```bibtex
@article{firtina2023rawhash2,
  title = {{RawHash2}: {Mapping DNA Sequences Directly From Raw Nanopore Signals Using Hash-based Seeding and Adaptive Quantization}},
  author = {Firtina, Can and Mansouri Ghiasi, Arian and Lindegger, Joel and Singh, Gagandeep and Cavlak, Melina Bastas and Mao, Haiyu and Alser, Mohammed},
  journal = {Bioinformatics},
  volume = {39},
  number = {22},
  pages = {4153--4162},
  year = {2023},
  doi = {10.1093/bioinformatics/btad272}
}
```
