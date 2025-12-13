# system
# 50 MHz clock
set_property -dict {LOC G22 IOSTANDARD LVCMOS33} [get_ports i_Sys_clk[0]]
create_clock -period 20.000 -name i_Sys_clk[0] [get_ports i_Sys_clk[0]]
# set_property -dict {LOC D26 IOSTANDARD LVCMOS33} [get_ports i_Rst_n]

# led
set_property -dict {LOC E25 IOSTANDARD LVCMOS33} [get_ports {o_led[7]}]
set_property -dict {LOC D25 IOSTANDARD LVCMOS33} [get_ports {o_led[6]}]
set_property -dict {LOC D24 IOSTANDARD LVCMOS33} [get_ports {o_led[5]}]
set_property -dict {LOC C26 IOSTANDARD LVCMOS33} [get_ports {o_led[4]}]
set_property -dict {LOC C24 IOSTANDARD LVCMOS33} [get_ports {o_led[3]}]
set_property -dict {LOC D23 IOSTANDARD LVCMOS33} [get_ports {o_led[2]}]
set_property -dict {LOC A24 IOSTANDARD LVCMOS33} [get_ports {o_led[1]}]
set_property -dict {LOC A23 IOSTANDARD LVCMOS33} [get_ports {o_led[0]}]

set_false_path -to [get_ports {o_led[*]}]
set_output_delay 0 [get_ports {o_led[*]}]

# key
set_property -dict {LOC D26 IOSTANDARD LVCMOS33} [get_ports {i_key[0]}]
set_property -dict {LOC G25 IOSTANDARD LVCMOS33} [get_ports {i_key[1]}]
set_property -dict {LOC E26 IOSTANDARD LVCMOS33} [get_ports {i_key[2]}]
set_property -dict {LOC G26 IOSTANDARD LVCMOS33} [get_ports {i_key[3]}]
set_property -dict {LOC H26 IOSTANDARD LVCMOS33} [get_ports {i_key[4]}]

set_false_path -from [get_ports {i_key[*]}]
set_input_delay 0 [get_ports {i_key[*]}]

# UART
set_property -dict {LOC A17 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports o_uart_txd]
set_property -dict {LOC B17 IOSTANDARD LVCMOS33} [get_ports i_uart_rxd]
set_false_path -to [get_ports {o_uart_txd}]
set_output_delay 0 [get_ports {o_uart_txd}]
set_false_path -from [get_ports {i_uart_rxd}]
set_input_delay 0 [get_ports {i_uart_rxd}]

# Ethernet MII PHY
set_property -dict {LOC AE2     IOSTANDARD LVCMOS33} [get_ports {phy1_rxd[0]}]
set_property -dict {LOC AE1     IOSTANDARD LVCMOS33} [get_ports {phy1_rxd[1]}]
set_property -dict {LOC AC1     IOSTANDARD LVCMOS33} [get_ports {phy1_rxd[2]}]
set_property -dict {LOC AB1     IOSTANDARD LVCMOS33} [get_ports {phy1_rxd[3]}]
set_property -dict {LOC AA2     IOSTANDARD LVCMOS33} [get_ports phy1_rx_clk]
set_property -dict {LOC AF3     IOSTANDARD LVCMOS33} [get_ports phy1_rx_ctl]
set_property -dict {LOC AA4     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy1_txd[0]}]
set_property -dict {LOC AB4     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy1_txd[1]}]
set_property -dict {LOC AA3     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy1_txd[2]}]
set_property -dict {LOC AA2     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy1_txd[3]}]
set_property -dict {LOC AC2    IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy1_tx_clk]
set_property -dict {LOC Y3     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy1_tx_ctl]
create_clock -period 8.000 -name phy1_rx_clk [get_ports phy1_rx_clk]

set_property -dict {LOC V22     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[0]}]
set_property -dict {LOC W26     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[1]}]
set_property -dict {LOC W25     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[2]}]
set_property -dict {LOC W21     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[3]}]
set_property -dict {LOC AA23    IOSTANDARD LVCMOS33} [get_ports phy2_rx_clk]
set_property -dict {LOC U26     IOSTANDARD LVCMOS33} [get_ports phy2_rx_ctl]
set_property -dict {LOC V26     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[0]}]
set_property -dict {LOC V21     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[1]}]
set_property -dict {LOC U24     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[2]}]
set_property -dict {LOC U25     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[3]}]
set_property -dict {LOC AB24    IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy2_tx_clk]
set_property -dict {LOC W23     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy2_tx_ctl]
create_clock -period 8.000 -name phy1_rx_clk [get_ports phy2_rx_clk]

# ov5640-1
set_property -dict {LOC F9 IOSTANDARD LVCMOS33} [get_ports o_cmos_scl1]
set_property -dict {LOC C9 IOSTANDARD LVCMOS33} [get_ports io_cmos_sda1]
set_property -dict {LOC H14 IOSTANDARD LVCMOS33} [get_ports o_cmos_reset1]
set_property -dict {LOC F14 IOSTANDARD LVCMOS33} [get_ports i_cmos_vsync1]
set_property -dict {LOC H11 IOSTANDARD LVCMOS33} [get_ports i_cmos_href1]
set_property -dict {LOC F13 IOSTANDARD LVCMOS33} [get_ports i_cmos_pclk1]
set_property -dict {LOC D8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[7]}]
set_property -dict {LOC A9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[6]}]
set_property -dict {LOC G12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[5]}]
set_property -dict {LOC G11 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[4]}]
set_property -dict {LOC B9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[3]}]
set_property -dict {LOC A8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[2]}]
set_property -dict {LOC F8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[1]}]
set_property -dict {LOC G14 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[0]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {i_cmos_pclk1_IBUF[0]}]
# ov5640-2
set_property -dict {LOC C14 IOSTANDARD LVCMOS33} [get_ports o_cmos_scl2]
set_property -dict {LOC B14 IOSTANDARD LVCMOS33} [get_ports io_cmos_sda2]
set_property -dict {LOC A14 IOSTANDARD LVCMOS33} [get_ports o_cmos_reset2]
set_property -dict {LOC E10 IOSTANDARD LVCMOS33} [get_ports i_cmos_vsync2]
set_property -dict {LOC D11 IOSTANDARD LVCMOS33} [get_ports i_cmos_href2]
set_property -dict {LOC B11 IOSTANDARD LVCMOS33} [get_ports i_cmos_pclk2]
set_property -dict {LOC B12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[7]}]
set_property -dict {LOC D9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[6]}]
set_property -dict {LOC D10 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[5]}]
set_property -dict {LOC C13 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[4]}]
set_property -dict {LOC C12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[3]}]
set_property -dict {LOC E12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[2]}]
set_property -dict {LOC D14 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[1]}]
set_property -dict {LOC D13 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[0]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {i_cmos_pclk2_IBUF[0]}]

#
# hdmi
set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVCMOS33} [get_ports o_TMDS1_en]


set_property -dict {PACKAGE_PIN Y22  IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_P]
set_property -dict {PACKAGE_PIN AA22 IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_N]
set_property -dict {PACKAGE_PIN AF24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[0]}]
set_property -dict {PACKAGE_PIN AE23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[1]}]
set_property -dict {PACKAGE_PIN AC23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[2]}]
set_property -dict {PACKAGE_PIN AF25 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[0]}]
set_property -dict {PACKAGE_PIN AF23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[1]}]
set_property -dict {PACKAGE_PIN AC24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[2]}]



