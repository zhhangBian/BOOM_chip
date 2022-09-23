#clock
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];


#reset
set_property PACKAGE_PIN C12 [get_ports resetn]


#LED
set_property PACKAGE_PIN H17 [get_ports {led[0]}]
set_property PACKAGE_PIN K15 [get_ports {led[1]}]
set_property PACKAGE_PIN J13 [get_ports {led[2]}]
set_property PACKAGE_PIN N14 [get_ports {led[3]}]
set_property PACKAGE_PIN R18 [get_ports {led[4]}]
set_property PACKAGE_PIN V17 [get_ports {led[5]}]
set_property PACKAGE_PIN U17 [get_ports {led[6]}]
set_property PACKAGE_PIN U16 [get_ports {led[7]}]
set_property PACKAGE_PIN V16 [get_ports {led[8]}]
set_property PACKAGE_PIN T15 [get_ports {led[9]}]
set_property PACKAGE_PIN U14 [get_ports {led[10]}]
set_property PACKAGE_PIN T16 [get_ports {led[11]}]
set_property PACKAGE_PIN V15 [get_ports {led[12]}]
set_property PACKAGE_PIN V14 [get_ports {led[13]}]
set_property PACKAGE_PIN V12 [get_ports {led[14]}]
set_property PACKAGE_PIN V11 [get_ports {led[15]}]

#led_rg 0/1
set_property PACKAGE_PIN N15 [get_ports {led_rg0[1]}]
set_property PACKAGE_PIN M16 [get_ports {led_rg0[0]}]
set_property PACKAGE_PIN N16 [get_ports {led_rg1[1]}]
set_property PACKAGE_PIN R11 [get_ports {led_rg1[0]}]

#NUM
set_property PACKAGE_PIN U13  [get_ports {num_csn[7]}]
set_property PACKAGE_PIN K2 [get_ports {num_csn[6]}]
set_property PACKAGE_PIN T14 [get_ports {num_csn[5]}]
set_property PACKAGE_PIN P14 [get_ports {num_csn[4]}]
set_property PACKAGE_PIN J14 [get_ports {num_csn[3]}]
set_property PACKAGE_PIN T9 [get_ports {num_csn[2]}]
set_property PACKAGE_PIN J18 [get_ports {num_csn[1]}]
set_property PACKAGE_PIN J17 [get_ports {num_csn[0]}]

set_property PACKAGE_PIN L18 [get_ports {num_a_g[0]}]
set_property PACKAGE_PIN T11 [get_ports {num_a_g[1]}]
set_property PACKAGE_PIN P15 [get_ports {num_a_g[2]}]
set_property PACKAGE_PIN K13 [get_ports {num_a_g[3]}]
set_property PACKAGE_PIN K16 [get_ports {num_a_g[4]}]
set_property PACKAGE_PIN R10 [get_ports {num_a_g[5]}]
set_property PACKAGE_PIN T10 [get_ports {num_a_g[6]}]
#set_property PACKAGE_PIN C4 :DP

#switch
set_property PACKAGE_PIN R13 [get_ports {switch[7]}]
set_property PACKAGE_PIN U18 [get_ports {switch[6]}]
set_property PACKAGE_PIN T18 [get_ports {switch[5]}]
set_property PACKAGE_PIN R17 [get_ports {switch[4]}]
set_property PACKAGE_PIN R15 [get_ports {switch[3]}]
set_property PACKAGE_PIN M13 [get_ports {switch[2]}]
set_property PACKAGE_PIN L16 [get_ports {switch[1]}]
set_property PACKAGE_PIN J15 [get_ports {switch[0]}]

#uart
set_property PACKAGE_PIN C4 [get_ports UART_RX]
set_property PACKAGE_PIN D4 [get_ports UART_TX]

#spi flash
set_property PACKAGE_PIN L13 [get_ports SPI_CS ]
set_property PACKAGE_PIN K17 [get_ports SPI_MOSI ]
set_property PACKAGE_PIN K18 [get_ports SPI_MISO ]

#mac phy connect
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports ETH_MDC]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports ETH_MDIO]
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS33} [get_ports ETH_RST_N]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports ETH_CRS_DV]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports ETH_RXERR]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports ETH_RXD[0]]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports ETH_RXD[1]]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports ETH_TXEN]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports ETH_TXD[0]]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports ETH_TXD[1]]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports ETH_CLK]
#set_property -dict { PACKAGE_PIN B8 IOSTANDARD LVCMOS33 } [get_ports { ETH_INTN }];



set_property IOSTANDARD LVCMOS33 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_a_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_csn[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_CS ]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_MOSI ]
set_property IOSTANDARD LVCMOS33 [get_ports SPI_MISO ]
