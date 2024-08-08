// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Thu Aug  8 20:09:13 2024
// Host        : device running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               h:/LoogArch/Reference/NOP_SoC/IP/xilinx_ip/clk_wiz_0_loongson/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_out1, clk_in1)
/* synthesis syn_force_seq_prim="clk_out1" */
/* synthesis syn_force_seq_prim="clk_in1" */;
  output clk_out1 /* synthesis syn_isclock = 1 */;
  input clk_in1 /* synthesis syn_isclock = 1 */;
endmodule
