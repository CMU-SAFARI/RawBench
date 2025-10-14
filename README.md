# RawBench

## Overview

RawBench provides a standardized evaluation framework for comparing nanopore signal analysis tools. This repository contains job scripts, configuration templates, and setup tools for benchmarking:

1. **RSA Evaluation framework** - RSA techniques, datasets, downstream tasks and metrics
2. **Basecalling and read mapping tools** - Dorado and minimap2

## Quick Start

### 1. Initial Setup

Clone the repository and set up the base environment:

```bash
git clone https://github.com/Furkan9015/rawbench.git
cd rawbench
chmod +x scripts/setup_env.sh setup.sh
```

### 2. Install Dependencies

#### Core Tools Installation

The benchmarking framework requires several external tools. Install them according to your system:

**Dorado (ONT Basecaller):**
```bash
# Download from: https://github.com/nanoporetech/dorado
# Install to /usr/local/bin/dorado or update DORADO_PATH in environment
```

**RawHash2 (Optional):**
```bash 
# Download from: https://github.com/CMU-SAFARI/RawHash2
# Install to /usr/local/bin/rawhash2 or update RAWHASH2_PATH
```

#### Python Environment Setup

```bash
# Create conda environment for Sigmoni
conda create --name sigmoni python=3.8
conda activate sigmoni
conda install h5py numpy scipy
pip install uncalled4

# Create environment for BAM processing
conda create --name bamtofastq
conda activate bamtofastq
conda install bamtofastq

# Create environment for minimap2
conda create --name mm2
conda activate mm2
conda install minimap2
```

### 3. Install Analysis Tools

#### Install Sigmoni
```bash
# Follow instructions in sigmoni_submodule/README.md
# Option 1: Add as git submodule (if public repository available)
# Option 2: Manual installation - download Sigmoni source code

# Required files in sigmoni_submodule/:
#   - index.py (index building script)
#   - main.py (classification script) 
#   - example/ directory with sample data
```

#### Install SPUMONI  
```bash
# Follow instructions in spumoni_submodule/README.md
# Option 1: Add as git submodule (if public repository available)  
# Option 2: Manual installation and compilation

# Required: compiled spumoni executable in spumoni_submodule/build/spumoni
cd spumoni_submodule
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### 4. Environment Configuration

Configure paths for your installation:

```bash
# Load the environment setup (do this before running any job scripts)
source scripts/setup_env.sh

# Check environment is configured correctly  
print_environment
validate_environment
```

#### Customize Environment Variables

Edit your shell profile (`.bashrc`, `.zshrc`) or create a local config:

```bash
# External tool paths - customize for your installation
export DORADO_PATH="/path/to/dorado"
export RAWHASH2_PATH="/path/to/rawhash2"

# Data directories - customize for your setup
export BASECALLING_MODELS_DIR="/path/to/basecalling_models"  
export POD5_DATA_DIR="/path/to/pod5_data"

# Then reload environment
source scripts/setup_env.sh
```

### 5. Data Setup

#### Download Required Data

```bash
# Create data directories
mkdir -p ../basecalling_models ../pod5

# Download Dorado models (example)
# wget -P ../basecalling_models/ https://cdn.oxfordnanoportal.com/software/analysis/dorado/dna_r10.4.1_e8.2_400bps_sup@v5.0.0.tar.gz
# tar -xzf ../basecalling_models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0.tar.gz -C ../basecalling_models/

# Place your POD5 signal data in ../pod5/
# Expected files: hsapiens.pod5, ecoli.pod5, dmelanogaster.pod5
```

#### Reference Genomes

Place reference genomes in the `refs/` directory:
- `hsapiens.fa` - Human reference (dataset d8)
- `ecoli.fa` - E. coli reference (dataset d9)  
- `dmelanogaster.fa` - D. melanogaster reference (dataset d10)

## Usage

### Environment Loading

**IMPORTANT:** Always load the environment before running any scripts:

```bash
cd rawbench/
source scripts/setup_env.sh
```

### Running Benchmarks

#### Basecalling Benchmarks

```bash
# Load environment first
source scripts/setup_env.sh

cd job_scripts/basecalling

# Human dataset (d8)
sbatch d8_basecall_sup.sh

# E. coli dataset (d9)  
sbatch d9_basecall_sup.sh

# D. melanogaster dataset (d10)
sbatch d10_basecall_sup.sh
```

#### Read Classification Benchmarks

```bash
# Load environment first
source scripts/setup_env.sh

cd job_scripts/read_classification

# Sigmoni-based classification
sbatch zymo_ont_rindex_ttest.sh
sbatch zymo_uncalled4_rindex_ttest.sh
```

#### Read Mapping Benchmarks  

```bash
# Load environment first
source scripts/setup_env.sh

cd job_scripts/read_mapping

# minimap2 mapping
sbatch d8_2chunksmax_mm2.sh
sbatch d9_1chunkmax_mm2.sh
```

### Manual Tool Usage

#### Sigmoni Classification

```bash
# Activate environment
source scripts/setup_env.sh
conda activate sigmoni

cd sigmoni_submodule/example/zymo

# Build index
python ../../index.py -p ref_fastas/pos_class/*.fasta -n ref_fastas/neg_class/*.fasta \
  -b 6 --shred 100000 -o ./ --ref-prefix zymo_ont

# Run classification  
python ../../main.py -i fast5/ -r refs/zymo_ont -b 6 -t 64 -o ./ \
  --complexity --thresh 1.6666666666333334
```

#### SPUMONI Operations

```bash
# Activate environment
source scripts/setup_env.sh

cd spumoni_submodule

# Build index
./build/spumoni build -r ../refs/reference.fa -M -P -m -o ./index_dir

# Run classification
./build/spumoni run -r ./index_dir -p ../basecalled_reads/reads.fa -P -c
```

## Repository Structure

```
rawbench/
├── README.md                 # This file
├── DEPENDENCIES.md           # Detailed dependency information
├── setup.sh                  # Legacy setup script
├── scripts/
│   └── setup_env.sh          # Environment configuration script
├── sigmoni_submodule/        # Sigmoni tool installation directory
│   └── README.md             # Installation instructions
├── spumoni_submodule/        # SPUMONI tool installation directory
│   └── README.md             # Installation instructions  
├── job_scripts/              # SLURM job scripts for benchmarking
│   ├── basecalling/          # Basecalling benchmark scripts
│   ├── read_mapping/         # Read mapping evaluation scripts
│   └── read_classification/  # Classification benchmark scripts
├── refs/                     # Reference genomes (FASTA format)
├── outputs/                  # Generated results and logs
├── basecalled_reads/         # Generated basecalled FASTQ files
├── kmer_models/             # K-mer models for nanopore chemistries
├── fast5/                   # Fast5 signal data download scripts
├── pod5/                    # POD5 signal data download scripts
└── .gitignore               # Excludes build artifacts and data files
```

## Expected Directory Structure (Full Installation)

```
parent_directory/
├── basecalling_models/       # Dorado neural network models
├── pod5/                     # POD5 signal files by organism
├── bin/                      # External tool binaries (optional)
│   ├── dorado
│   └── rawhash2
└── rawbench/                 # This repository
    ├── sigmoni_submodule/    # Sigmoni source code
    ├── spumoni_submodule/    # SPUMONI source code & build/
    └── [rest of repository]
```

## Troubleshooting

### Environment Validation

Check if all required tools are installed:

```bash
source scripts/setup_env.sh
validate_environment
```

### Common Issues

1. **"Dorado not found"** - Update `DORADO_PATH` environment variable
2. **"SPUMONI executable not found"** - Compile SPUMONI in `spumoni_submodule/build/`
3. **"Sigmoni not found"** - Install Sigmoni source files according to `sigmoni_submodule/README.md`
4. **Missing conda environments** - Create required environments (sigmoni, bamtofastq, mm2)
5. **Path issues** - Always run `source scripts/setup_env.sh` before job scripts

### Job Script Debugging

Job scripts include validation and will report missing dependencies. Check SLURM output files in `outputs/` for detailed error messages.

## Output Formats

- `*.out` / `*.err` files: SLURM job outputs and errors
- `*.report` files: Classification results for each read  
- `*.paf` files: Alignment results in PAF format
- `*_timing.log` files: Performance timing measurements
- `*.throughput` files: Performance and accuracy metrics

## Contributing

When modifying job scripts:
1. Maintain environment variable usage instead of hardcoded paths
2. Include validation checks for required files/tools
3. Update documentation if changing expected directory structure
4. Test with `validate_environment` before committing

## Citation

If you use RawBench in your research, please cite:

```bibtex
@software{rawbench2025,
  title = {RawBench: A comprehensive benchmarking framework for raw nanopore signal analysis},
  author = {Eris, Furkan and McConnell, Ulysse and Firtina, Can and Mutlu, Onur},
  year = {2025},
  url = {https://github.com/Furkan9015/rawbench}
}
```

## License

This project is licensed under the MIT License - see the repository for details.
