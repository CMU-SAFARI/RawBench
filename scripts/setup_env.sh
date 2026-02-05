#!/bin/bash
# Environment setup script for RawBench
# Source this file before running job scripts: source scripts/setup_env.sh

# Find repository root (works from anywhere in the repo)
export RAWBENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# External tool paths - customize these for your installation
export DORADO_PATH="${DORADO_PATH:-/usr/local/bin/dorado}"
export RAWHASH2_PATH="${RAWHASH2_PATH:-/usr/local/bin/rawhash2}"

# Model and data paths - customize these for your installation  
export BASECALLING_MODELS_DIR="${BASECALLING_MODELS_DIR:-${RAWBENCH_ROOT}/../basecalling_models}"
export POD5_DATA_DIR="${POD5_DATA_DIR:-${RAWBENCH_ROOT}/../pod5}"
export REFS_DIR="${REFS_DIR:-${RAWBENCH_ROOT}/refs}"

# Output directories
export OUTPUTS_DIR="${RAWBENCH_ROOT}/outputs"
export BASECALLED_READS_DIR="${RAWBENCH_ROOT}/basecalled_reads"

# Tool-specific paths
export SIGMONI_DIR="${RAWBENCH_ROOT}/sigmoni_submodule"
export SPUMONI_BUILD_DIR="${RAWBENCH_ROOT}/spumoni_submodule/build"

# Add SPUMONI and its helper programs to PATH
export PATH="${SPUMONI_BUILD_DIR}:${SPUMONI_BUILD_DIR}/src:${SPUMONI_BUILD_DIR}/bin:${PATH}"

# Create output directories if they don't exist
mkdir -p "${OUTPUTS_DIR}" "${BASECALLED_READS_DIR}"

# Validation function to check if required tools exist
validate_environment() {
    local missing_tools=()
    
    # Check external tools
    [[ -x "${DORADO_PATH}" ]] || missing_tools+=("dorado at ${DORADO_PATH}")
    [[ -d "${BASECALLING_MODELS_DIR}" ]] || missing_tools+=("basecalling models directory at ${BASECALLING_MODELS_DIR}")
    [[ -d "${POD5_DATA_DIR}" ]] || missing_tools+=("POD5 data directory at ${POD5_DATA_DIR}")
    
    # Check SPUMONI
    [[ -x "${SPUMONI_BUILD_DIR}/spumoni" ]] || missing_tools+=("compiled SPUMONI at ${SPUMONI_BUILD_DIR}/spumoni")
    
    # Check Sigmoni (if index.py and main.py exist)
    [[ -f "${SIGMONI_DIR}/index.py" ]] || missing_tools+=("Sigmoni index.py at ${SIGMONI_DIR}/index.py")
    [[ -f "${SIGMONI_DIR}/main.py" ]] || missing_tools+=("Sigmoni main.py at ${SIGMONI_DIR}/main.py")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "WARNING: Missing required tools/directories:" >&2
        printf "  - %s\n" "${missing_tools[@]}" >&2
        echo "Please check installation and update environment variables as needed." >&2
        return 1
    fi
    
    echo "Environment validation passed. All required tools found."
    return 0
}

# Print environment info
print_environment() {
    echo "RawBench Environment Configuration:"
    echo "  Repository root: ${RAWBENCH_ROOT}"
    echo "  Dorado path: ${DORADO_PATH}"
    echo "  Models directory: ${BASECALLING_MODELS_DIR}"
    echo "  POD5 data directory: ${POD5_DATA_DIR}"
    echo "  References directory: ${REFS_DIR}"
    echo "  Outputs directory: ${OUTPUTS_DIR}"
    echo "  Sigmoni directory: ${SIGMONI_DIR}"
    echo "  SPUMONI build directory: ${SPUMONI_BUILD_DIR}"
}

# Optional: validate on source (comment out if too noisy)
# validate_environment
