// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Thu Aug  8 20:09:31 2024
// Host        : device running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               h:/LoogArch/Reference/NOP_SoC/IP/xilinx_ip/dpram_512x32/dpram_512x32_sim_netlist.v
// Design      : dpram_512x32
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "dpram_512x32,blk_mem_gen_v8_4_7,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_7,Vivado 2023.2" *) 
(* NotValidForBitStream *)
module dpram_512x32
   (clka,
    ena,
    wea,
    addra,
    dina,
    clkb,
    addrb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [8:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [8:0]addra;
  wire [8:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]doutb;
  wire ena;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_douta_UNCONNECTED;
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "9" *) 
  (* C_ADDRB_WIDTH = "9" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     3.68295 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "dpram_512x32.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "1" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "512" *) 
  (* C_READ_DEPTH_B = "512" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "512" *) 
  (* C_WRITE_DEPTH_B = "512" *) 
  (* C_WRITE_MODE_A = "NO_CHANGE" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  dpram_512x32_blk_mem_gen_v8_4_7 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(NLW_U0_douta_UNCONNECTED[31:0]),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[8:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[8:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2023.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
jLV29U0rrfMIZhYJzdoUrPoqB9eHQ5NXmWyCdqnN3Wgm+GU4C3zthrN1m4QGiaj0thPCIynZbX+0
7yjtkv+T5ByJ6NhiofAwWseGLvPXlYu6ERAPvi4SAYpF2VUqQHtPAbPmnPubGdDRgIEpeobF7hsz
rEcpEru1pyiScUriyuo=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
vsoizVrOONWw/DhjRLEYrtRmtji+Ok63CbpSg/l9VnoKAi8tAzqRbQ57atGB2N6IGGbKHkbK2Uzh
EHgWvYZeyt4hE+bpQX91vc9PNxfjQMGzPoFD3jCWk30EmEk+AND39eWx+DhJ8xhFuucoOQ2GwyAk
B+Mjs15naPE7DvlHel8hnD4dfSdYhGKp96oozu8JeBto8aHG6poOuYkxSwaut7NCI+mabCkMxtMp
RrydgmRuTvhRTbJMyx5CxFSZTRDrS5aU1vaRlnMiqKCI7g2KY9pemYaJsFeVodBuo6IyKGynyEhs
wr+VtUhQDtaVhMkwB95WwmMoDk9F2L5Au1I+TQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
W081dPMCWhKs5YlQD7n3zvf7+PTcnb8eFWxoVs8+zHLkxDMA1klITbsfztGYvJFce8Yao5XQLLqZ
oUE5Pq2arq+zwICFUcLjdMsmP1WmL82znHOPHm83zNwrxWMloHkySAqzFbgJeHa973uZqj0M8ydc
sYmzCYVlGVjt0QX0xqA=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Zpc3MmdLWaVOv+S4z2POuoyslYoAbWc+Npxq2UyQRtDwf566IId3uwAetolMAgfLo/G3ezuSOXMn
8NznS37h9XvmVrxA50SAux68P87WgkLtiUYqM3CMBKkxNlZ/TR8WzTuQyFdvzkOE9lp8HC7LXnk5
RDsnOM+su46FW7ysY01COslo9Xc7rhs6WFqx29+Xcqk8+ZMLSzaJfuwZdNmJFS3Q1vhlq3ZeYqMl
wMieB731KsPxjxp7VKNHpTbgFryC2isqc4ohBDOt52M/Bz4B/rIpFeHfZ7X3jWSiKtSuBsDN2NXf
EMjfAT248dlK7NxJ+NBNPhS5sLxTiGyQhta57A==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rPMYqnkKhJKV1wltOfDrKos9ZbucaoX3WGTuqsdLkGpcKObzslHBwlGrKtWV7bZYmS2SM+QuEMfa
CE+tCUdsSiprp+n5BuSQlJa6BJ8mlqccjoo/JLw2QEmUhyMXQ3TLGomGGoZdeTmMPXhUBAOyLPea
Ddc8mgtTN8Kpy117GOTXDKP+IKJqW01fLrPJpgEhFiJCbyElLgtCRWmI94gX+y4XNVS0Cd1YwNw6
4nHgnEdC7fXARDKcYO3VsWC/pdzPQgursXloNLrVYa6i2xr+8E1V0+nSWwNYQZP7XUIVqXKMU8Ea
bT4acXrRCF/5tJJ5B9JparYI0zxXSbaakn1dIw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2022_10", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mfroTgL8g2pyIXQ/mGO9YHm19cd5mOlJ++qpusOYeVxGmkIhvF4aKx+AyIUz2yGGAeCtOzIasHty
pyqKgZhibSqxcpHgR0m6GOxXXOXJiHaK8NzxUzXeRJovcBI/WjtDhXeb1LRMI1J97jVBtJPJQH0Y
fGOD7jWvkvQwxnrZdyLp6kPWgSIcavHHDbO7iJv4gnyGp6W3/FCDo2RKWNLoW+SNjSdLZ6YRP8a+
ldaGU8TYvJ03KWlmik7repuN6AwxCjg2KeQ+x1sBAEXzROXomuSbvX3ZAo8UiIKAQY1SJumHLG3L
QI/S4Wbl1Hz6LDTsttMwP480gq6+tb6s1E4oWw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QJIabgm8dx/gVHbOQFwt8maOKVHFgkpZTPR6dzD8fqoGo9M9oGPTqBqchtPZWgv2UYFF2KEUSlV4
L3SDXBKrLs+NsAVTcICaEMiEi6j82zj/C1LsPkQfS8RLrg0ab8lbDMb5YqJ7lkHs3iM65x2iN1Mf
66cTgCbkAdl3rDpab75btpTQt5ZKiq5CSY3RZfyIW0uWbTGTELm6liuRKM9+K8BQwTU7A+FFFQBA
/9eJwQYzNNA/iwoYJ2WTPd6pBlzXriNLu9M+/2bYicNBSuH1PBR9v2ESrTB6k7EiV1zvBXV9NuG/
sFt4MumWMuSNwP2W38bQATxxW/l0IrmaXGOC/w==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
lhKf/Vgj6pHpme1ji4HVe36BU8pMkam/2I9lFeyOiBnIbzgdEGfLJBcEvkL33A7s0hxa6LFbHnkT
upgMpPjmIghBz3xUQ13vpiY152thFec6qvlcdg1r+GTmnBOSFl6g/OfZ3eFUhfsve6ZjQHpXnKFo
a55hN2+eP1EG9+VxGeM7XkHaeFhEIry52qtnmg072KEFIwRiGs2d/TJ4AqupuIdIiP1kTN9k+oqa
2ta1vdtqPY0dDHqrf+5YSd0CejkhQeCqg/bauLP3755SwdOPRgooG5ANT8hUpTiFMFXtU+GC9NSp
evJtMHUy1NbgMmhFHO+w3URLEdjSaBxZPD7YLdWkF65jY526tJzoek+BzEKoBaGfCaY7O1nHKXm+
89k3rPUy0Xo4/0nHpno+N/Db09heJPbnGsCwN/l+KnR6Lz8kvWziBjZe0ijOkKI+T12y3T1VeOtY
H/aqtNlQt1mhFwrbw6ezaAiDPVbCQXnly6b4tbb8+nFsxWOGIGAfLozB

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PNsQ8uEcQYrl+GaDuBaq1tQ5br5aAdaqHnyrc0NVu/JnQUk53jaiLx8Oz5fNACvWelUUk2/C+P5I
b2rbU1bb/dC6TqC5J1N0yoMYRYw58u4Lrl8Kgqgt9Rlph5Qgzzfxp+oblXF/pO4mRyAXpZhpNkFT
0Ar9BUtPOTOtJ9/g53SRnZ6GjxzfeD+25J4fcXBNo2gCTgUkwiLSsJRwTB/cJmn+dZPwPdIOHEP9
TkfDK+OrbLYO3T+DFBTCMRNH2NB1J9sc5s+nPU8iYnjgPTo6HoGW+LIlCz6yNJMZzJzoeW708utc
0fJXkT7vLDVh7olvy3V9AAY8Do0YR1kiZlhVhQ==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
zAz8RnGHFebkJFAS+gjC+mXHW7m7We+JgSmIz15mS01u/4+9Ng0sJfkeXOClmVPTQ2Mp2Yuv6/6f
ehzUTcANilWsqLM6Q1FToCPNX/NTqodlcHirGM7b5R9yevouNT/aqH12nmbunBQmBHmehNutdCjG
r6Z7kZgeZ2ZE7MMOF0rTy1XHEPkqgMNTRoS8R/pPWPTW4/j+bn3aJj0Q/fTz4Gi3mbSUKWs2fREQ
UKiuolNJkN6DiDvhlVYHUyytXNJG44ikmBXehoQQRLapkYaxnQmMRT1ok9uY6pKoy71CtvJ3Mt2x
EQv1GU2i4qQyAOwa0mkEohWXduicU6tDz3zQwQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
TK3eE9V+v1z2P1KjG4GrjhA1n3qDOpNzLGXdtjnjhF0QBFPSuhC+nmNqTPOb3p2a9r5KD0miY3Cd
+KpjH6Ao09E2/LD2Go4aLQh6vP+9BldlSKEwCGfx2NjBQrXWVH21lQR7IRjOvyTOclpd7SgtUJLw
dvebETyLiKr9C6RfnIBeptuCA3iJlXfwkh6I0JfzD5WBizQkotioZmmrXv5105pCXQ4Ta1WThFsA
2ll9dZeSjEDHUxxhfyfjryv9m4VL89ZDU/rGITsdptwB1BC1jLqmPDymY05lyECnjA6NIR5GGfI4
K2y2f4GfikKoN5r9IOvFzw963Wm82ZZPtXOKGg==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20480)
`pragma protect data_block
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
/6yhXzhLsdzbQ7Uz27FhYEI=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
