# system
# 50 MHz clock
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports i_clk]
# set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS33} [get_ports i_Rst_n]

#
# ov5640-1

set_property -dict {PACKAGE_PIN F9 IOSTANDARD LVCMOS33} [get_ports o_cmos_scl1]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports io_cmos_sda1]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports o_cmos_reset1]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports i_cmos_vsync1]
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33} [get_ports i_cmos_href1]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports i_cmos_pclk1]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[7]}]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[6]}]
set_property -dict {PACKAGE_PIN G12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[5]}]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[4]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[3]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[2]}]
set_property -dict {PACKAGE_PIN F8 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data1[0]}]
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_cmos_pclk1_IBUF]
# ov5640-2
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports o_cmos_scl2]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports io_cmos_sda2]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports o_cmos_reset2]
set_property -dict {PACKAGE_PIN E10 IOSTANDARD LVCMOS33} [get_ports i_cmos_vsync2]
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports i_cmos_href2]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports i_cmos_pclk2]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[7]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[6]}]
set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[5]}]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[4]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[3]}]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[2]}]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[1]}]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports {i_cmos_data2[0]}]
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_cmos_pclk2_IBUF]

# hdmi-1
set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVCMOS33} [get_ports o_TMDS1_en]
set_property -dict {PACKAGE_PIN Y22 IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_P]
set_property -dict {PACKAGE_PIN AA22 IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_N]
set_property -dict {PACKAGE_PIN AF24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[0]}]
set_property -dict {PACKAGE_PIN AE23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[1]}]
set_property -dict {PACKAGE_PIN AC23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[2]}]
set_property -dict {PACKAGE_PIN AF25 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[0]}]
set_property -dict {PACKAGE_PIN AF23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[1]}]
set_property -dict {PACKAGE_PIN AC24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[2]}]
#------------------- led ----------------------
set_property -dict {PACKAGE_PIN E25 IOSTANDARD LVCMOS33} [get_ports {o_led[7]}]
set_property -dict {PACKAGE_PIN D25 IOSTANDARD LVCMOS33} [get_ports {o_led[6]}]
set_property -dict {PACKAGE_PIN D24 IOSTANDARD LVCMOS33} [get_ports {o_led[5]}]
set_property -dict {PACKAGE_PIN C26 IOSTANDARD LVCMOS33} [get_ports {o_led[4]}]
set_property -dict {PACKAGE_PIN C24 IOSTANDARD LVCMOS33} [get_ports {o_led[3]}]
set_property -dict {PACKAGE_PIN D23 IOSTANDARD LVCMOS33} [get_ports {o_led[2]}]
set_property -dict {PACKAGE_PIN A24 IOSTANDARD LVCMOS33} [get_ports {o_led[1]}]
set_property -dict {PACKAGE_PIN A23 IOSTANDARD LVCMOS33} [get_ports {o_led[0]}]
#------------------- key ----------------------
# set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS33} [get_ports {i_key[0]}]
# set_property -dict {PACKAGE_PIN G25 IOSTANDARD LVCMOS33} [get_ports {i_key[1]}]
# set_property -dict {PACKAGE_PIN E26 IOSTANDARD LVCMOS33} [get_ports {i_key[2]}]
# set_property -dict {PACKAGE_PIN G26 IOSTANDARD LVCMOS33} [get_ports {i_key[3]}]
# set_property -dict {PACKAGE_PIN H26 IOSTANDARD LVCMOS33} [get_ports {i_key[4]}]
#------------------- UART ----------------------
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports system_uart_debug_rxd]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports system_uart_debug_txd]

#------------------- Ethernet MII PHY1 ----------------------
set_property -dict {PACKAGE_PIN AE2 IOSTANDARD LVCMOS18} [get_ports {eth_rgmii_rd[0]}]
set_property -dict {PACKAGE_PIN AE1 IOSTANDARD LVCMOS18} [get_ports {eth_rgmii_rd[1]}]
set_property -dict {PACKAGE_PIN AC1 IOSTANDARD LVCMOS18} [get_ports {eth_rgmii_rd[2]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS18} [get_ports {eth_rgmii_rd[3]}]
set_property -dict {PACKAGE_PIN AF3 IOSTANDARD LVCMOS18} [get_ports eth_rgmii_rx_ctl]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS18} [get_ports eth_rgmii_rxc]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS18} [get_ports eth_reset]
set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVCMOS18} [get_ports eth_mdio_mdc]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS18} [get_ports eth_mdio_mdio_io]
set_property -dict {PACKAGE_PIN AB4 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports {eth_rgmii_td[0]}]
set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports {eth_rgmii_td[1]}]
set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports {eth_rgmii_td[2]}]
set_property -dict {PACKAGE_PIN AA2 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports {eth_rgmii_td[3]}]
set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports eth_rgmii_tx_ctl]
set_property -dict {PACKAGE_PIN AC2 IOSTANDARD LVCMOS18 SLEW FAST} [get_ports eth_rgmii_txc]

#------------------- Ethernet MII PHY2 ----------------------
# set_property -dict {PACKAGE_PIN V22     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[0]}]
# set_property -dict {PACKAGE_PIN W26     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[1]}]
# set_property -dict {PACKAGE_PIN W25     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[2]}]
# set_property -dict {PACKAGE_PIN W21     IOSTANDARD LVCMOS33} [get_ports {phy2_rxd[3]}]
# set_property -dict {PACKAGE_PIN AA23    IOSTANDARD LVCMOS33} [get_ports phy2_rx_clk]
# set_property -dict {PACKAGE_PIN U26     IOSTANDARD LVCMOS33} [get_ports phy2_rx_ctl]
# set_property -dict {PACKAGE_PIN V26     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[0]}]
# set_property -dict {PACKAGE_PIN V21     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[1]}]
# set_property -dict {PACKAGE_PIN U24     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[2]}]
# set_property -dict {PACKAGE_PIN U25     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy2_txd[3]}]
# set_property -dict {PACKAGE_PIN AB24    IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy2_tx_clk]
# set_property -dict {PACKAGE_PIN W23     IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy2_tx_ctl]
# create_clock -period 8.000 -name phy1_rx_clk [get_ports phy2_rx_clk]


#------------------- FLASH SPI ----------------------
#--------- S25FL256SAGNFI00 --- 256Mbit -------------
# set_property -dict {PACKAGE_PIN C8 IOSTANDARD LVCMOS33} [get_ports system_spi_0_clk_io]
set_property -dict {PACKAGE_PIN C23 IOSTANDARD LVCMOS33} [get_ports system_spi_0_ss_io]
set_property -dict {PACKAGE_PIN B24 IOSTANDARD LVCMOS33} [get_ports system_spi_0_io0_io]
set_property -dict {PACKAGE_PIN A25 IOSTANDARD LVCMOS33} [get_ports system_spi_0_io1_io]
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS33} [get_ports system_spi_0_io2_io]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS33} [get_ports system_spi_0_io3_io]
# I2C Pins (EEPROM - Page 16)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports iic_sensor_sda]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports iic_sensor_scl]
#------------------- EEPROM,AT24C04 ----------------------
set_property -dict {PACKAGE_PIN C21 IOSTANDARD LVCMOS33} [get_ports iic_temp_sda]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33} [get_ports iic_temp_scl]


#------------------- hdmi ----------------------
# set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVCMOS33} [get_ports o_TMDS1_en]
# set_property -dict {PACKAGE_PIN Y22  IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_P]
# set_property -dict {PACKAGE_PIN AA22 IOSTANDARD TMDS_33} [get_ports o_TMDS1_CLK_N]
# set_property -dict {PACKAGE_PIN AF24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[0]}]
# set_property -dict {PACKAGE_PIN AE23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[1]}]
# set_property -dict {PACKAGE_PIN AC23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_P[2]}]
# set_property -dict {PACKAGE_PIN AF25 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[0]}]
# set_property -dict {PACKAGE_PIN AF23 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[1]}]
# set_property -dict {PACKAGE_PIN AC24 IOSTANDARD TMDS_33} [get_ports {o_TMDS1_N[2]}]




