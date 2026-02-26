## Timing Constraints
create_clock -period 10.000 -name gclk [get_ports clk]

## IO Standards and Drive Strength
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports UART_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports UART_txd]
set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Display IO Standards (Regexp matches all Segment/Anode pins)
set_property IOSTANDARD LVCMOS33 [get_ports -regexp {^(D0_AN|D1_AN|D0_SEG|D1_SEG)\[[0-9]+\]$}]
set_property SLEW SLOW [get_ports -regexp {^(D0_AN|D1_AN|D0_SEG|D1_SEG)\[[0-9]+\]$}]
set_property DRIVE 4   [get_ports -regexp {^(D0_AN|D1_AN|D0_SEG|D1_SEG)\[[0-9]+\]$}]

## Physical Pin Assignments

# Clock
set_property PACKAGE_PIN F14 [get_ports clk]

# NEW: Hardware Reset (Button J2)
set_property PACKAGE_PIN J2 [get_ports rst]

# UART (Serial)
set_property PACKAGE_PIN V12 [get_ports UART_rxd]
set_property PACKAGE_PIN U11 [get_ports UART_txd]

# LED
set_property PACKAGE_PIN G1 [get_ports led]

# --- 7-Segment Display 0 (Address) ---
set_property PACKAGE_PIN D5 [get_ports {D0_AN[0]}]
set_property PACKAGE_PIN C4 [get_ports {D0_AN[1]}]
set_property PACKAGE_PIN C7 [get_ports {D0_AN[2]}]
set_property PACKAGE_PIN A8 [get_ports {D0_AN[3]}]

set_property PACKAGE_PIN D7 [get_ports {D0_SEG[0]}]
set_property PACKAGE_PIN C5 [get_ports {D0_SEG[1]}]
set_property PACKAGE_PIN A5 [get_ports {D0_SEG[2]}]
set_property PACKAGE_PIN B7 [get_ports {D0_SEG[3]}]
set_property PACKAGE_PIN A7 [get_ports {D0_SEG[4]}]
set_property PACKAGE_PIN D6 [get_ports {D0_SEG[5]}]
set_property PACKAGE_PIN B5 [get_ports {D0_SEG[6]}]
set_property PACKAGE_PIN A6 [get_ports {D0_SEG[7]}]

# --- 7-Segment Display 1 (Data) ---
set_property PACKAGE_PIN H3 [get_ports {D1_AN[0]}]
set_property PACKAGE_PIN J4 [get_ports {D1_AN[1]}]
set_property PACKAGE_PIN F3 [get_ports {D1_AN[2]}]
set_property PACKAGE_PIN E4 [get_ports {D1_AN[3]}]

set_property PACKAGE_PIN F4 [get_ports {D1_SEG[0]}]
set_property PACKAGE_PIN J3 [get_ports {D1_SEG[1]}]
set_property PACKAGE_PIN D2 [get_ports {D1_SEG[2]}]
set_property PACKAGE_PIN C2 [get_ports {D1_SEG[3]}]
set_property PACKAGE_PIN B1 [get_ports {D1_SEG[4]}]
set_property PACKAGE_PIN H4 [get_ports {D1_SEG[5]}]
set_property PACKAGE_PIN D1 [get_ports {D1_SEG[6]}]
set_property PACKAGE_PIN C1 [get_ports {D1_SEG[7]}]