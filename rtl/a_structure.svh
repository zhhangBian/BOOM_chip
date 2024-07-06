`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

typedef logic [4 :0] arf_id;
typedef logic [5 :0] rob_id;

typedef struct packed {
    arf_id [3 :0][31:0] r_arfid;
    arf_id [1 :0][31:0] w_arfid;
} arf_table_t;

`endif