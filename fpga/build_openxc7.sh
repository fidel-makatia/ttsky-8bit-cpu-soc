#!/bin/bash
# ============================================================================
# Open-Source FPGA Build Script (runs inside regymm/openxc7 Docker container)
# ============================================================================
# Produces: /build/top_zybo.bit
#
# Flow: yosys (synthesis) → nextpnr-xilinx (P&R) → prjxray (bitstream)
# ============================================================================

set -e

DEVICE="xc7z010clg400-1"
FAMILY="zynq7"
TOP="top_zybo"

PROJ_DIR="/project"
SRC_DIR="/project/src"
FPGA_DIR="/project/fpga"
BUILD_DIR="/project/fpga/build"
CHIPDB_DIR="/chipdb"

DB_ROOT="/nextpnr-xilinx/xilinx/external/prjxray-db"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "============================================"
echo " openXC7 FPGA Build for Zybo Z7-010"
echo "============================================"
echo ""

# ---- Step 1: Generate chipdb (if not cached) ----
CHIPDB_BIN="xc7z010.bin"
CHIPDB_FILE="${CHIPDB_DIR}/${CHIPDB_BIN}"
if [ ! -f "$CHIPDB_FILE" ]; then
    echo "[1/4] Generating chipdb for ${DEVICE}..."
    echo "      (This takes a few minutes on first build, cached for later)"
    cd /nextpnr-xilinx
    pypy3 xilinx/python/bbaexport.py --device "$DEVICE" --bba "${CHIPDB_DIR}/xc7z010.bba"
    bbasm --l "${CHIPDB_DIR}/xc7z010.bba" "$CHIPDB_FILE"
    rm -f "${CHIPDB_DIR}/xc7z010.bba"
    echo "      Done! chipdb cached at ${CHIPDB_FILE}"
    cd "$BUILD_DIR"
else
    echo "[1/4] Using cached chipdb for ${DEVICE}"
fi

echo ""

# ---- Step 2: Synthesis with yosys ----
echo "[2/4] Synthesizing with yosys..."
VERILOG_FILES=(
    "${FPGA_DIR}/top_zybo.v"
    "${SRC_DIR}/soc_top.v"
    "${SRC_DIR}/control.v"
    "${SRC_DIR}/alu.v"
    "${FPGA_DIR}/program_rom_fpga.v"
    "${SRC_DIR}/regfile.v"
    "${SRC_DIR}/gpio.v"
    "${SRC_DIR}/uart_tx.v"
    "${SRC_DIR}/timer.v"
)

yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top ${TOP}; write_json ${BUILD_DIR}/${TOP}.json" \
    "${VERILOG_FILES[@]}" 2>&1 | tee "${BUILD_DIR}/synth.log"

echo "      Synthesis complete → ${TOP}.json"
echo ""

# ---- Step 3: Place & Route with nextpnr-xilinx ----
echo "[3/4] Place & Route with nextpnr-xilinx..."
nextpnr-xilinx \
    --chipdb "$CHIPDB_FILE" \
    --xdc "${FPGA_DIR}/zybo_openxc7.xdc" \
    --json "${BUILD_DIR}/${TOP}.json" \
    --write "${BUILD_DIR}/${TOP}_routed.json" \
    --fasm "${BUILD_DIR}/${TOP}.fasm" \
    --router router2 \
    2>&1 | tee "${BUILD_DIR}/pnr.log"

echo "      Place & Route complete → ${TOP}.fasm"
echo ""

# ---- Step 4: Generate bitstream ----
echo "[4/4] Generating bitstream..."

# FASM → frames
DBROOT="${DB_ROOT}/${FAMILY}"
source /prjxray/env/bin/activate 2>/dev/null || true
export PATH="/prjxray/build/tools:$PATH"

fasm2frames \
    --part "$DEVICE" \
    --db-root "$DBROOT" \
    "${BUILD_DIR}/${TOP}.fasm" > "${BUILD_DIR}/${TOP}.frames"

# frames → bitstream
PART_YAML="${DBROOT}/${DEVICE}/part.yaml"
xc7frames2bit \
    --part_file "$PART_YAML" \
    --part_name "$DEVICE" \
    --frm_file "${BUILD_DIR}/${TOP}.frames" \
    --output_file "${BUILD_DIR}/${TOP}.bit"

echo ""
echo "============================================"
echo " Build complete!"
echo " Bitstream: fpga/build/${TOP}.bit"
echo "============================================"
echo ""
ls -la "${BUILD_DIR}/${TOP}.bit"
