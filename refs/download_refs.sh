#!/bin/bash
# Download reference genomes for RawBench benchmarks
# Run from the refs/ directory: cd refs && bash download_refs.sh
#
# Primary references (used in rawhash2 benchmarks):
#   d9:  E. coli CFT073
#   d8:  Human CHM13v2 (hs1)
#   d10: D. melanogaster BDGP6.32

set -euo pipefail

download_ecoli() {
    echo "=== Downloading E. coli CFT073 ==="
    wget -O ecoli.fa.gz \
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/007/445/GCA_000007445.1_ASM744v1/GCA_000007445.1_ASM744v1_genomic.fna.gz"
    gunzip ecoli.fa.gz
    echo "Saved: ecoli.fa ($(du -h ecoli.fa | cut -f1))"
}

download_hsapiens() {
    echo "=== Downloading Human CHM13v2 ==="
    wget -O hsapiens.fa.gz \
        "https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz"
    gunzip hsapiens.fa.gz
    echo "Saved: hsapiens.fa ($(du -h hsapiens.fa | cut -f1))"
}

download_dmelanogaster() {
    echo "=== Downloading D. melanogaster BDGP6.32 ==="
    wget -O dmelanogaster.fa.gz \
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/215/GCF_000001215.4_Release_6_plus_ISO1_MT/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.gz"
    gunzip dmelanogaster.fa.gz
    echo "Saved: dmelanogaster.fa ($(du -h dmelanogaster.fa | cut -f1))"
}

case "${1:-all}" in
    ecoli)          download_ecoli ;;
    hsapiens)       download_hsapiens ;;
    dmelanogaster)  download_dmelanogaster ;;
    all)
        download_ecoli
        download_hsapiens
        download_dmelanogaster
        ;;
    *)
        echo "Usage: $0 [ecoli|hsapiens|dmelanogaster|all]"
        exit 1
        ;;
esac
