# Robust FPGA programming script for Zybo Z7-010
set script_dir [file dirname [info script]]
set bitstream  [file join $script_dir build top_zybo.bit]

if {![file exists $bitstream]} {
    puts "ERROR: Bitstream not found at $bitstream"
    exit 1
}

open_hw_manager

# Connect to hw_server, launching a fresh one
connect_hw_server -allow_non_jtag

# Retry refresh up to 5 times (intermittent USB/JTAG detection)
set found 0
for {set attempt 1} {$attempt <= 5} {incr attempt} {
    puts "Attempt $attempt: Refreshing hardware targets..."
    refresh_hw_server
    if {[catch {set targets [get_hw_targets]} err]} {
        puts "  No targets yet, retrying in 2 seconds..."
        after 2000
        continue
    }
    if {[llength $targets] > 0} {
        set found 1
        break
    }
    puts "  Empty target list, retrying in 2 seconds..."
    after 2000
}

if {!$found} {
    puts "ERROR: No hardware targets found after 5 attempts."
    puts "Check USB connection and drivers."
    close_hw_manager
    exit 1
}

puts "Available targets: $targets"

# Open the first available target
foreach target $targets {
    puts "Trying target: $target"
    if {[catch {open_hw_target $target} err]} {
        puts "  Failed: $err"
        continue
    }
    puts "  Opened successfully!"

    # Find devices on this target
    set devices [get_hw_devices]
    puts "  Devices: $devices"

    if {[llength $devices] > 0} {
        # Find the xc7z010 device (skip arm_dap which is not programmable)
        set device ""
        foreach d $devices {
            if {[string match "xc7z*" $d]} {
                set device $d
                break
            }
        }
        if {$device eq ""} {
            set device [lindex $devices end]
        }
        puts "Programming device: $device"
        current_hw_device $device
        set_property PROGRAM.FILE $bitstream $device

        program_hw_devices $device

        puts ""
        puts "============================================"
        puts " Programming complete!"
        puts " The CPU is now running on the FPGA."
        puts "============================================"

        catch {close_hw_target}
        catch {disconnect_hw_server}
        close_hw_manager
        exit 0
    }
    close_hw_target
}

puts "ERROR: No programmable devices found on any target."
catch {disconnect_hw_server}
close_hw_manager
exit 1
