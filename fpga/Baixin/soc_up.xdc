#set_property SEVERITY {Warning} [get_drc_checks RTSTAT-2]
#时钟信号连接
#create_clock -period 10.000 [get_ports clk]
set_property PACKAGE_PIN AC19 [get_ports clk]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

#reset
set_property PACKAGE_PIN AA15 [get_ports resetn]

#LED
set_property PACKAGE_PIN L8 [get_ports {led[0]}]
set_property PACKAGE_PIN H9 [get_ports {led[1]}]
set_property PACKAGE_PIN G9 [get_ports {led[2]}]
set_property PACKAGE_PIN K8 [get_ports {led[3]}]
set_property PACKAGE_PIN H8 [get_ports {led[4]}]
set_property PACKAGE_PIN F8 [get_ports {led[5]}]
set_property PACKAGE_PIN G8 [get_ports {led[6]}]
set_property PACKAGE_PIN F7 [get_ports {led[7]}]
set_property PACKAGE_PIN A5 [get_ports {led[8]}]
set_property PACKAGE_PIN G7 [get_ports {led[9]}]
set_property PACKAGE_PIN A4 [get_ports {led[10]}]
set_property PACKAGE_PIN D6 [get_ports {led[11]}]
set_property PACKAGE_PIN J19 [get_ports {led[12]}]
set_property PACKAGE_PIN J20 [get_ports {led[13]}]
set_property PACKAGE_PIN J15 [get_ports {led[14]}]
set_property PACKAGE_PIN J14 [get_ports {led[15]}]

#led_rg 0/1
set_property PACKAGE_PIN L18 [get_ports {led_rg0[0]}]
set_property PACKAGE_PIN L17 [get_ports {led_rg0[1]}]
set_property PACKAGE_PIN K17 [get_ports {led_rg1[0]}]
set_property PACKAGE_PIN K16 [get_ports {led_rg1[1]}]

#NUM
set_property PACKAGE_PIN E25 [get_ports {num_csn[7]}]
set_property PACKAGE_PIN E23 [get_ports {num_csn[6]}]
set_property PACKAGE_PIN G20 [get_ports {num_csn[5]}]
set_property PACKAGE_PIN F22 [get_ports {num_csn[4]}]
set_property PACKAGE_PIN F23 [get_ports {num_csn[3]}]
set_property PACKAGE_PIN F24 [get_ports {num_csn[2]}]
set_property PACKAGE_PIN F25 [get_ports {num_csn[1]}]
set_property PACKAGE_PIN E26 [get_ports {num_csn[0]}]

set_property PACKAGE_PIN D26 [get_ports {num_a_g[0]}]
set_property PACKAGE_PIN G24 [get_ports {num_a_g[1]}]
set_property PACKAGE_PIN H24 [get_ports {num_a_g[2]}]
set_property PACKAGE_PIN G25 [get_ports {num_a_g[3]}]
set_property PACKAGE_PIN H22 [get_ports {num_a_g[4]}]
set_property PACKAGE_PIN H21 [get_ports {num_a_g[5]}]
set_property PACKAGE_PIN G22 [get_ports {num_a_g[6]}]
#set_property PACKAGE_PIN G21 :DP

#switch
set_property PACKAGE_PIN Y16 [get_ports {switch[7]}]
set_property PACKAGE_PIN Y15 [get_ports {switch[6]}]
set_property PACKAGE_PIN AC18 [get_ports {switch[5]}]
set_property PACKAGE_PIN AD18 [get_ports {switch[4]}]
set_property PACKAGE_PIN AB16 [get_ports {switch[3]}]
set_property PACKAGE_PIN AD17 [get_ports {switch[2]}]
set_property PACKAGE_PIN AC17 [get_ports {switch[1]}]
set_property PACKAGE_PIN AC16 [get_ports {switch[0]}]

#btn_key
set_property PACKAGE_PIN AC23 [get_ports {btn_key_col[0]}]
set_property PACKAGE_PIN W14 [get_ports {btn_key_col[1]}]
set_property PACKAGE_PIN AC22 [get_ports {btn_key_col[2]}]
set_property PACKAGE_PIN AB21 [get_ports {btn_key_col[3]}]
set_property PACKAGE_PIN AE18 [get_ports {btn_key_row[0]}]
set_property PACKAGE_PIN W15 [get_ports {btn_key_row[1]}]
set_property PACKAGE_PIN AF18 [get_ports {btn_key_row[2]}]
set_property PACKAGE_PIN AE17 [get_ports {btn_key_row[3]}]

#btn_step
set_property PACKAGE_PIN AC21 [get_ports {btn_step[0]}]
set_property PACKAGE_PIN AA20 [get_ports {btn_step[1]}]

#SPI flash
set_property PACKAGE_PIN M25 [get_ports SPI_CLK]
set_property PACKAGE_PIN L24 [get_ports SPI_CS]
set_property PACKAGE_PIN K26 [get_ports SPI_MISO]
set_property PACKAGE_PIN K25 [get_ports SPI_MOSI]

#mac phy connect
set_property PACKAGE_PIN AA3 [get_ports mtxclk_0]
set_property PACKAGE_PIN AB2 [get_ports mrxclk_0]
set_property PACKAGE_PIN W5 [get_ports mtxen_0]
set_property PACKAGE_PIN AC1 [get_ports {mtxd_0[0]}]
set_property PACKAGE_PIN AD1 [get_ports {mtxd_0[1]}]
set_property PACKAGE_PIN AF2 [get_ports {mtxd_0[2]}]
set_property PACKAGE_PIN AE1 [get_ports {mtxd_0[3]}]
set_property PACKAGE_PIN AE2 [get_ports mtxerr_0]
set_property PACKAGE_PIN V2 [get_ports mrxdv_0]
set_property PACKAGE_PIN W3 [get_ports {mrxd_0[0]}]
set_property PACKAGE_PIN U7 [get_ports {mrxd_0[1]}]
set_property PACKAGE_PIN Y3 [get_ports {mrxd_0[2]}]
set_property PACKAGE_PIN AC2 [get_ports {mrxd_0[3]}]
set_property PACKAGE_PIN V1 [get_ports mrxerr_0]
set_property PACKAGE_PIN V3 [get_ports mcoll_0]
set_property PACKAGE_PIN W4 [get_ports mcrs_0]
set_property PACKAGE_PIN V7 [get_ports mdc_0]
set_property PACKAGE_PIN V6 [get_ports mdio_0]
set_property PACKAGE_PIN Y1 [get_ports phy_rstn]

#uart
set_property PACKAGE_PIN D5 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property PACKAGE_PIN E6 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

#debug uart
set_property PACKAGE_PIN Y21 [get_ports UART_RX2]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX2]
set_property PACKAGE_PIN W21 [get_ports UART_TX2]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX2]

#ejtag
set_property PACKAGE_PIN K15 [get_ports EJTAG_TRST]
set_property PACKAGE_PIN M15 [get_ports EJTAG_TCK]
set_property PACKAGE_PIN M17 [get_ports EJTAG_TDI]
set_property PACKAGE_PIN M16 [get_ports EJTAG_TMS]
set_property PACKAGE_PIN L15 [get_ports EJTAG_TDO]


set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_a_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_csn[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_col[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_row[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_step[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports SPI_MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_MISO]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_CS]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_CLK]

set_property IOSTANDARD LVCMOS33 [get_ports {mrxd_0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mtxd_0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports mtxerr_0]
set_property IOSTANDARD LVCMOS33 [get_ports mtxen_0]
set_property IOSTANDARD LVCMOS33 [get_ports mtxclk_0]
set_property IOSTANDARD LVCMOS33 [get_ports mrxerr_0]
set_property IOSTANDARD LVCMOS33 [get_ports mcoll_0]
set_property IOSTANDARD LVCMOS33 [get_ports mcrs_0]
set_property IOSTANDARD LVCMOS33 [get_ports mdc_0]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_0]
set_property IOSTANDARD LVCMOS33 [get_ports mrxclk_0]
set_property IOSTANDARD LVCMOS33 [get_ports mrxdv_0]

set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TRST]
set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TCK]
set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TDI]
set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TMS]
set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TDO]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets EJTAG_TCK_IBUF]

create_clock -period 40.000 -name mrxclk_0 -waveform {0.000 20.000} [get_ports mrxclk_0]
create_clock -period 40.000 -name mtxclk_0 -waveform {0.000 20.000} [get_ports mtxclk_0]

set_false_path -from [get_clocks clk_pll_i] -to [get_clocks clk_out2_clk_pll_33]
set_false_path -from [get_clocks mrxclk_0] -to [get_clocks clk_out2_clk_pll_33]
set_false_path -from [get_clocks mtxclk_0] -to [get_clocks clk_out2_clk_pll_33]
set_false_path -from [get_clocks clk_out2_clk_pll_33] -to [get_clocks clk_out1_clk_pll_33]
set_false_path -from [get_clocks clk_out1_clk_pll_33] -to [get_clocks clk_out2_clk_pll_33]
set_false_path -from [get_clocks clk_out2_clk_pll_33] -to [get_clocks mrxclk_0]
set_false_path -from [get_clocks clk_out2_clk_pll_33] -to [get_clocks mrxclk_0]
set_false_path -from [get_clocks clk_out2_clk_pll_33] -to [get_clocks mtxclk_0]
set_false_path -from [get_clocks clk_out2_clk_pll_33] -to [get_clocks mtxclk_0]
