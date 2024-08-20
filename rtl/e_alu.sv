`include "a_defines.svh"

module e_alu(
    input   logic [31:0]  r0_i,
    input   logic [31:0]  r1_i,
    input   logic [31:0]  pc_i,
    input   logic [31:0]  imm_i,

    input   logic [2:0]   grand_op_i,
    input   logic [2:0]   op_i,

    output  logic [31:0]  result_o
);

logic [31:0] bw_result;     // 逻辑运算
logic [31:0] li_result;     // 移位相关操作
logic [31:0] int_result;    // 常规运算
logic [31:0] sft_result;    // SFT移位
logic [31:0] com_result;    // 比较结果

logic [31:0] sub_result;
assign sub_result = r0_i - r1_i;

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
    case (op_i)
    `_BW_AND: begin
        bw_result = r0_i & r1_i;
    end

    `_BW_OR: begin
        bw_result = r0_i | r1_i;
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
    case (op_i)
    `_LI_LUI: begin
        li_result = {r0_i[19:0], 12'b0};
    end

    `_LI_PCADDUI: begin
        li_result = {r0_i[19:0], 12'b0} + pc_i;
    end

    default: begin
        li_result = 32'b0;
    end
    endcase
end

// INT
always_comb begin
    case (op_i)
    `_INT_ADD: begin
        int_result = r0_i + r1_i;
    end

    `_INT_SUB: begin
        int_result = sub_result;
    end

    `_INT_SLT: begin
        int_result = ($signed(r0_i) < $signed(r1_i)) ? 32'h1: 32'h0;
    end

    `_INT_SLTU: begin
        int_result = (r0_i < r1_i ? 32'h1 : 32'h0);
    end

    default: begin
        int_result = 32'h0;
    end
    endcase
end

logic [15:0] data1, data2, data3, data4;
logic [4:0] num1, num2, num3, num4;
logic [4:0] shift_num, shift_num1, shift_num2;
logic [31:0] data_li;

always_comb begin
    data1 = r0_i[31:16];
    data2 = r0_i[15:0];
    data3 = r1_i[31:16];
    data4 = r1_i[15:0];

    num1 = '0;
    num2 = '0;
    num3 = '0;
    num4 = '0;
    for(integer i = 15; i >= 0; i -= 1) begin
        if(data1[i] == 1'b1) begin
            break;
        end
        num1 += 5'b1;
    end

    for(integer i = 15; i >= 0; i -= 1) begin
        if(data2[i] == 1'b1) begin
            break;
        end
        num2 += 5'b1;
    end

    for(integer i = 15; i >= 0; i -= 1) begin
        if(data3[i] == 1'b1) begin
            break;
        end
        num3 += 5'b1;
    end

    for(integer i = 15; i >= 0; i -= 1) begin
        if(data4[i] == 1'b1) begin
            break;
        end
        num4 += 5'b1;
    end

    shift_num1 = (num1 > num2) ? num1 : num2;
    shift_num2 = (num3 > num4) ? num3 : num4;
    shift_num = (shift_num1 > shift_num2) ? shift_num1 : shift_num2;
end

logic [31:0] sft1, sft2;

// SFT
always_comb begin
    case (op_i)
    `_SFT_SLL: begin
        sft_result = ((r0_i) << (r1_i[4:0]));
    end

    `_SFT_SRL: begin
        sft_result = ((r0_i) >> (r1_i[4:0]));
    end

    `_SFT_SLA: begin
        sft_result = $signed($signed(r0_i) <<< $signed(r1_i[4:0]));
    end

    `_SFT_SRA: begin
        sft_result = $signed($signed(r0_i) >>> $signed(r1_i[4:0]));
    end

    `_SFT_WIN: begin
        if(shift_num == 5'b0) begin
            sft_result = imm_i;
        end
        else begin
            sft1 = imm_i << (5'd32 - shift_num);
            sft2 = imm_i >> (shift_num);
            sft_result = sft1 | sft2;
        end
    end

    default: begin
        sft_result = 32'b0;
    end
    endcase
end

// COM
always_comb begin
    case (op_i)
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
            com_result = ($signed(r0_i) >= $signed(r1_i)) ? 32'h1 : 32'h0;
        end

        `_COM_LTU: begin
            com_result = (r0_i < r1_i ? 32'h1 : 32'h0);
        end

        `_COM_GEU: begin
            com_result = (r0_i >= r1_i ? 32'h1 : 32'h0);
        end

        `_COM_PCADD4: begin
            com_result = pc_i + 32'h4;
        end

        default: begin
            com_result = 32'b0;
        end
    endcase
end

endmodule
