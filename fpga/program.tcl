# ============================================================================
# Vivado Hardware Programming Script for Zybo Z7-010
# ============================================================================
# Usage: vivado -mode batch -source program.tcl
#
# Make sure the Zybo is connected via USB and powered on.
# ============================================================================

set script_dir [file dirname [info script]]
set bitstream  [file join $script_dir build top_zybo.bit]

if {![file exists $bitstream]} {
    puts "ERROR: Bitstream not found at $bitstream"
    puts "Run build.tcl first: vivado -mode batch -source build.tcl"
    exit 1
}

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

set device [get_hw_devices xc7z010_1]
current_hw_device $device
set_property PROGRAM.FILE $bitstream $device

program_hw_devices $device

puts ""
puts "============================================"
puts " Programming complete!"
puts " The CPU is now running on the Zybo Z7-010."
puts "============================================"

close_hw_manager
