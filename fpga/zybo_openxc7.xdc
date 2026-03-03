# ============================================================================
# Zybo Z7-010 Constraints for openXC7 / nextpnr-xilinx
# ============================================================================
# Simplified from zybo_z7010.xdc (no -dict style, no timing constraints)
# ============================================================================

# ---- System Clock (125 MHz) ----
set_property PACKAGE_PIN K17 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]

# ---- Reset Button (BTN0, active-high) ----
set_property PACKAGE_PIN K18 [get_ports btn0]
set_property IOSTANDARD LVCMOS33 [get_ports btn0]

# ---- LEDs (gpio_out[3:0]) ----
set_property PACKAGE_PIN M14 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN M15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN G14 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN D18 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

# ---- Slide Switches (gpio_in[3:0]) ----
set_property PACKAGE_PIN G15 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN P15 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W13 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN T16 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]

# ---- PMOD JA: gpio_out[7:4] on pins 1-4 ----
set_property PACKAGE_PIN N15 [get_ports {ja_upper[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_upper[0]}]
set_property PACKAGE_PIN L14 [get_ports {ja_upper[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_upper[1]}]
set_property PACKAGE_PIN K16 [get_ports {ja_upper[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_upper[2]}]
set_property PACKAGE_PIN K14 [get_ports {ja_upper[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_upper[3]}]

# ---- PMOD JA: UART TX on pin 7, Halted on pin 8 ----
set_property PACKAGE_PIN N16 [get_ports ja_uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports ja_uart_tx]
set_property PACKAGE_PIN L15 [get_ports ja_halted]
set_property IOSTANDARD LVCMOS33 [get_ports ja_halted]
