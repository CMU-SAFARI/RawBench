#!/bin/bash
# Download fast5 signal data for RawBench benchmarks
# Run from the fast5/ directory: cd fast5 && bash download.sh
#
# Requires: wget, tar, pod5 (pip install pod5)
#
# Signal data sources:
#   E. coli:         GIAB R1041 duplex control (42basepairs)
#   D. melanogaster: ONT open data (42basepairs)
#   H. sapiens:      converted from POD5 (requires pod5 files in ../pod5/hsapiens/)

set -euo pipefail

download_ecoli() {
    echo "=== Downloading E. coli fast5 files ==="
    local URL="https://42basepairs.com/download/s3/human-pangenomics/submissions/5b73fa0e-658a-4248-b2b8-cd16155bc157--UCSC_GIAB_R1041_nanopore/Ecoli_R1041_Duplex_Control/1_3_23_R1041_Duplex_Ecoli_Control.fast5.tar"
    local ARCHIVE="1_3_23_R1041_Duplex_Ecoli_Control.fast5.tar"
    local EXTRACT_DIR="1_3_23_R1041_Duplex_Ecoli_Control"

    mkdir -p ecoli
    echo "Downloading archive (~large, use -c for resume)..."
    wget -c "$URL" -O "$ARCHIVE"

    if [[ -f ecoli_filenames.txt ]]; then
        echo "Extracting selected fast5 files from filelist..."
        tar -xvf "$ARCHIVE" -T ecoli_filenames.txt
    else
        echo "No ecoli_filenames.txt found, extracting all..."
        tar -xvf "$ARCHIVE"
    fi

    find "$EXTRACT_DIR" -name "*.fast5" -exec mv {} ecoli/ \;
    rm -rf "$EXTRACT_DIR"
    echo "E. coli fast5 files saved to ecoli/"
}

download_dmelanogaster() {
    echo "=== Downloading D. melanogaster fast5 files ==="
    local BASE_URL="https://42basepairs.com/download/s3/ont-open-data/contrib/melanogaster_bkim_2023.01/flowcells/D.melanogaster.R1041.400bps/D_melanogaster_1/20221217_1251_MN20261_FAV70669_117da01a/fast5"
    local FILENAME_LIST="dmelanogaster_filenames.txt"

    if [[ ! -f "$FILENAME_LIST" ]]; then
        echo "Error: $FILENAME_LIST not found. Cannot download without filename list." >&2
        return 1
    fi

    mkdir -p dmelanogaster
    while read -r fname; do
        [[ -z "$fname" ]] && continue
        echo "Downloading $fname"
        wget -q --show-progress -O "dmelanogaster/${fname}" "${BASE_URL}/${fname}"
    done < "$FILENAME_LIST"
    echo "D. melanogaster fast5 files saved to dmelanogaster/"
}

convert_hsapiens() {
    echo "=== Converting H. sapiens POD5 to fast5 ==="
    local POD5_DIR="../pod5/hsapiens"

    if [[ ! -d "$POD5_DIR" ]]; then
        echo "Error: $POD5_DIR not found. Download POD5 files first." >&2
        return 1
    fi

    if ! command -v pod5 &>/dev/null; then
        echo "Error: pod5 not found. Install with: pip install pod5" >&2
        return 1
    fi

    mkdir -p hsapiens
    for f in "$POD5_DIR"/*.pod5; do
        echo "Converting $(basename "$f")"
        pod5 convert to_fast5 "$f" --output hsapiens/
    done
    echo "H. sapiens fast5 files saved to hsapiens/"
}

case "${1:-all}" in
    ecoli)          download_ecoli ;;
    dmelanogaster)  download_dmelanogaster ;;
    hsapiens)       convert_hsapiens ;;
    all)
        download_ecoli
        download_dmelanogaster
        convert_hsapiens
        ;;
    *)
        echo "Usage: $0 [ecoli|dmelanogaster|hsapiens|all]"
        exit 1
        ;;
esac
