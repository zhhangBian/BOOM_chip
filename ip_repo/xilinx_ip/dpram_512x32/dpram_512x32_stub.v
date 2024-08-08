// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Thu Aug  8 20:09:31 2024
// Host        : device running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               h:/LoogArch/Reference/NOP_SoC/IP/xilinx_ip/dpram_512x32/dpram_512x32_stub.v
// Design      : dpram_512x32
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_7,Vivado 2023.2" *)
module dpram_512x32(clka, ena, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="ena,wea[0:0],addra[8:0],dina[31:0],addrb[8:0],doutb[31:0]" */
/* synthesis syn_force_seq_prim="clka" */
/* synthesis syn_force_seq_prim="clkb" */;
  input clka /* synthesis syn_isclock = 1 */;
  input ena;
  input [0:0]wea;
  input [8:0]addra;
  input [31:0]dina;
  input clkb /* synthesis syn_isclock = 1 */;
  input [8:0]addrb;
  output [31:0]doutb;
endmodule
