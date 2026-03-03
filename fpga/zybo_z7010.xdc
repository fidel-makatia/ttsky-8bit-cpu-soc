## ============================================================================
## Zybo Z7-010 Constraints for 8-bit CPU SoC
## ============================================================================
## Reference: Digilent Zybo-Z7-Master.xdc
## https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc
## ============================================================================

## ---- System Clock (125 MHz) ----
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sys_clk }];
create_clock -period 8.000 -name sys_clk -waveform {0.000 4.000} [get_ports { sys_clk }];

## ---- Reset Button (BTN0, active-high) ----
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];

## ---- LEDs (gpio_out[3:0]) ----
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## ---- Slide Switches (gpio_in[3:0]) ----
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## ---- PMOD JA: gpio_out[7:4] on pins 1-4 ----
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { ja_upper[0] }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { ja_upper[1] }];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { ja_upper[2] }];
set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { ja_upper[3] }];

## ---- PMOD JA: UART TX on pin 7, Halted on pin 8 ----
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { ja_uart_tx }];
set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { ja_halted }];

## ---- Timing: tell Vivado about the derived 5 MHz clock ----
create_generated_clock -name clk_5mhz -source [get_ports sys_clk] -divide_by 25 [get_pins {clk_cnt_reg[4]/Q}]
