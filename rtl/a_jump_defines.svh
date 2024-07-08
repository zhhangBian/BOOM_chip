`ifndef a_jump_defines
`define a_jump_defines

// | tar | sign | 空余 | 3位比较类型 |

// 跳转的目的地
`define _TAR_REG    1'b0
`define _TAR_PC     1'b1

// 符合扩展类型（未来可舍去）
`define _UNSIGNED   1'b0
`define _SIGNED     1'b1

// 比较类型
`define _CMP_GT     3'b001 
`define _CMP_EQ     3'b010
`define _CMP_LT     3'b100

`endif