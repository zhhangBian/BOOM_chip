`ifndef a_alu_definition
`define a_alu_definition

`define _ALU_NOP      (3'b000)

`define _GRAND_OP_BW  (3'b001)
`define _GRAND_OP_LI  (3'b010)
`define _GRAND_OP_INT (3'b011)
`define _GRAND_OP_SFT (3'b100)

`define _BW_AND       (3'b001)
`define _BW_OR        (3'b010)
`define _BW_NOR       (3'b011)
`define _BW_XOR       (3'b100)
`define _BW_ANDN      (3'b101)
`define _BW_ORN       (3'b110)

`define _LI_LUI       (3'b001)
`define _LI_PCADDUI   (3'b010)

`define _INT_ADD      (3'b001)
`define _INT_SUB      (3'b010)
`define _INT_SLT      (3'b011)
`define _INT_SLTU     (3'b100)

`define _SFT_SLL      (3'b001)
`define _SFT_SRL      (3'b010)
`define _SFT_SLA      (3'b011)
`define _SFT_SRA      (3'b100)

`endif