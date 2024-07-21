`ifndef _a_iq_defines
`define _a_iq_defines

typedef logic [31:0] word_t;

typedef struct packed {
    word_t  pc;
    word_t  imm;
    logic   if_jump;

    logic   [2:0]   grand_op;
    logic   [2:0]   op;
    
    rob_id_t        wreg_id;
    logic   wreg;
    logic   wmem;
    logic   [3:0]   rmask;
    logic   [3:0]   strb;
    logic   cacop;
    logic   dbar;
    logic   llsc;
    logic   msigned;
    logic   msize;

    logic   inst_valid; 
} decode_info_t;

`endif