# ============================================================================
# Program the Zybo Z7-010 FPGA
# ============================================================================
# Usage: vivado -mode batch -source fpga/program.tcl
#
# Connect the Zybo via USB and power it on before running.
# ============================================================================

set script_dir [file dirname [info script]]
set bitstream  [file join $script_dir build top_zybo.bit]

if {![file exists $bitstream]} {
    puts ""
    puts "ERROR: Bitstream not found!"
    puts "Build it first:  vivado -mode batch -source fpga/build.tcl"
    puts ""
    exit 1
}

open_hw_manager
connect_hw_server -allow_non_jtag

# Retry up to 5 times (USB/JTAG detection can be flaky)
set found 0
for {set attempt 1} {$attempt <= 5} {incr attempt} {
    puts "Attempt $attempt: Looking for hardware..."
    refresh_hw_server
    if {[catch {set targets [get_hw_targets]} err]} {
        puts "  Not found yet, retrying in 2s..."
        after 2000
        continue
    }
    if {[llength $targets] > 0} {
        set found 1
        break
    }
    puts "  No targets, retrying in 2s..."
    after 2000
}

if {!$found} {
    puts ""
    puts "ERROR: No board found. Check:"
    puts "  1. USB cable is connected"
    puts "  2. Board is powered on (green LED)"
    puts "  3. No other Vivado instance is running"
    puts ""
    close_hw_manager
    exit 1
}

# Open target and find the FPGA
foreach target $targets {
    if {[catch {open_hw_target $target} err]} { continue }

    set devices [get_hw_devices]
    set device ""
    foreach d $devices {
        if {[string match "xc7z*" $d]} {
            set device $d
            break
        }
    }
    if {$device eq ""} { close_hw_target; continue }

    current_hw_device $device
    set_property PROGRAM.FILE $bitstream $device
    program_hw_devices $device

    puts ""
    puts "============================================"
    puts " Done! CPU is running on the FPGA."
    puts " Watch the LEDs count up."
    puts " Press BTN0 to restart."
    puts "============================================"

    catch {close_hw_target}
    catch {disconnect_hw_server}
    close_hw_manager
    exit 0
}

puts "ERROR: No FPGA device found."
close_hw_manager
exit 1
