#!/bin/bash
# ============================================================================
# FPGA Programming Script (No Vivado Required)
# ============================================================================
# Uses openFPGALoader to program the Zybo Z7-010 board.
#
# Install openFPGALoader:
#   Windows (MSYS2): pacman -S mingw-w64-ucrt-x86_64-openfpgaloader
#   macOS:           brew install openfpgaloader
#   Linux (Ubuntu):  sudo apt install openfpgaloader
#   Linux (Fedora):  sudo dnf install openFPGALoader
#   From source:     https://github.com/trabucayre/openFPGALoader
#
# Usage: ./program.sh [bitstream_file]
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_BIT="${SCRIPT_DIR}/build/top_zybo.bit"
BITSTREAM="${1:-$DEFAULT_BIT}"
BOARD="zybo_z7_10"

# ---- Check bitstream exists ----
if [ ! -f "$BITSTREAM" ]; then
    echo "ERROR: Bitstream not found: $BITSTREAM"
    echo ""
    echo "Build it first with one of:"
    echo "  Option A (open-source): ./build_openxc7.sh"
    echo "  Option B (Vivado):      vivado -mode batch -source build.tcl"
    exit 1
fi

# ---- Check openFPGALoader is installed ----
if ! command -v openFPGALoader &> /dev/null; then
    echo "ERROR: openFPGALoader not found!"
    echo ""
    echo "Install it:"
    echo "  Windows (MSYS2): pacman -S mingw-w64-ucrt-x86_64-openfpgaloader"
    echo "  macOS:           brew install openfpgaloader"
    echo "  Linux (Ubuntu):  sudo apt install openfpgaloader"
    echo "  Linux (Fedora):  sudo dnf install openFPGALoader"
    echo "  From source:     https://github.com/trabucayre/openFPGALoader"
    exit 1
fi

echo "============================================"
echo " Programming Zybo Z7-010"
echo " Bitstream: $BITSTREAM"
echo "============================================"
echo ""

# ---- Program the FPGA (volatile - SRAM) ----
openFPGALoader -b "$BOARD" "$BITSTREAM"

echo ""
echo "============================================"
echo " Programming complete!"
echo " The CPU test is now running."
echo " Watch LEDs count: 0001 -> 0010 -> ... -> 1111"
echo " Press BTN0 to reset and re-run."
echo "============================================"
