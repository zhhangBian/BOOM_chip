`include "a_defines.svh"

module e_alu(
    input   logic [31:0]  r0_i,
    input   logic [31:0]  r1_i,
    input   logic [31:0]  pc_i,

    input   logic [2:0]   grand_op_i,
    input   logic [2:0]   op_i,

    output  logic [31:0]  result_o
);

logic [31:0] bw_result;     // 逻辑运算
logic [31:0] li_result;     // 移位相关操作
logic [31:0] int_result;    // 常规运算
logic [31:0] sft_result;    // SFT移位
logic [31:0] com_result;    // 比较结果

logic [31:0] sub_result = r0_i - r1_i;

// GRAND_OP
always_comb begin
    case (grand_op_i)
    `_GRAND_OP_BW: begin
        result_o = bw_result;
    end

    `_GRAND_OP_LI: begin
        result_o = li_result;
    end

    `_GRAND_OP_INT: begin
        result_o = int_result;
    end

    `_GRAND_OP_SFT: begin
        result_o = sft_result;
    end

    `_GRAND_OP_COM: begin
        result_o = com_result;
    end

    default: begin
        result_o = 32'b0;
    end
    endcase
end

// BW
always_comb begin
    case (op)
    `_BW_AND: begin
        bw_result = r0_i & r1_i;
    end

    `_BW_OR: begin
        bw_result = r1 | r1_i;
    end

    `_BW_NOR: begin
        bw_result = ~(r0_i | r1_i);
    end

    `_BW_XOR: begin
        bw_result = r0_i ^ r1_i;
    end

    `_BW_ANDN: begin
        bw_result = r0_i & (~r1_i);
    end

    `_BW_ORN: begin
        bw_result = r0_i | (~r1_i);
    end

    default: begin
        bw_result = 32'b0;
    end
    endcase
end

// LI
always_comb begin
    case (op)
    `_LI_LUI: begin
        li_result = {r1_i[19:0], 12'b0};
    end

    `_LI_PCADDUI: begin
        li_result = {r1_i[19:0], 12'b0} + pc_i;
    end

    default: begin
        li_result = 32'b0;
    end
    endcase
end

// INT
always_comb begin
    case (op)
    `_INT_ADD: begin
        int_result = r0_i + r1_i;
    end

    `_INT_SUB: begin
        int_result = sub_result;
    end

    `_INT_SLT: begin
        int_result = ($signed(r0_i) < $signed(r1_i)) ? 1: 0;
    end

    `_INT_SLTU: begin
        int_result = r0_i < r1_i ? 1 : 0;
    end

    default: begin
        int_result = 32'b0;
    end
    endcase
end

// SFT
always_comb begin
    case (op)
    `_SFT_SLL: begin
        sft_result = r0_i >> r1_i[4:0];
    end

    `_SFT_SRL: begin
        sft_result = r0_i << r1_i[4:0];
    end

    `_SFT_SLA: begin
        sft_result = $signed($signed(r0_i) <<< $signed(r1_i[4:0]));
    end

    `_SFT_SRA: begin
        sft_result = $signed($signed(r0_i) >>> $signed(r1_i[4:0]));
    end

    default: begin
        sft_result = 32'b0;
    end
    endcase
end

// COM
always_comb begin
    case (op)
        `_COM_EQ: begin
            com_result = (sub_result == 0);
        end 

        `_COM_NE: begin
            com_result = (sub_result != 0);
        end

        `_COM_LT: begin
            com_result = ($signed(r0_i) < $signed(r1_i));
        end

        `_COM_GE: begin
            com_result = ($signed(r0_i) >= $signed(r1_i));
        end

        `_COM_LTU: begin
            com_result = (r0_i < r1_i);
        end

        `_COM_GEU: begin
            com_result = (r0_i >= r1_i);
        end

        default: begin
            com_result = '0;
        end
    endcase
end

endmodule
