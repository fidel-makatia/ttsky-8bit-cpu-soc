# ============================================================================
# Vivado Non-Project Mode Build Script for Zybo Z7-010
# ============================================================================
# Usage: vivado -mode batch -source build.tcl
#
# Produces: build/top_zybo.bit
# ============================================================================

set script_dir [file dirname [info script]]
set src_dir    [file join $script_dir .. src]
set build_dir  [file join $script_dir build]

# Create build directory
file mkdir $build_dir

# ---- Read source files ----
read_verilog [file join $script_dir top_zybo.v]
read_verilog [file join $src_dir soc_top.v]
read_verilog [file join $src_dir control.v]
read_verilog [file join $src_dir alu.v]
read_verilog [file join $src_dir program_rom.v]
read_verilog [file join $src_dir regfile.v]
read_verilog [file join $src_dir gpio.v]
read_verilog [file join $src_dir uart_tx.v]
read_verilog [file join $src_dir timer.v]

# ---- Read constraints ----
read_xdc [file join $script_dir zybo_z7010.xdc]

# ---- Synthesis ----
synth_design -top top_zybo -part xc7z010clg400-1
report_utilization -file [file join $build_dir utilization_synth.rpt]

# ---- Optimization ----
opt_design

# ---- Place ----
place_design
report_utilization -file [file join $build_dir utilization_place.rpt]

# ---- Route ----
route_design
report_timing_summary -file [file join $build_dir timing.rpt]
report_utilization -file [file join $build_dir utilization_route.rpt]

# ---- Write bitstream ----
write_bitstream -force [file join $build_dir top_zybo.bit]

puts ""
puts "============================================"
puts " Build complete!"
puts " Bitstream: build/top_zybo.bit"
puts "============================================"
