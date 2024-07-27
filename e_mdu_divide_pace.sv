// 固定32周期出结果
// 频率较高

module divide_high_pace (
    input   wire    clk,
    input   wire    rst_n,

    input   [31:0]  num0,
    input   [31:0]  num1,

    output  [31:0]  div_res,
    output  [31:0]  mod_res,

    input   start,
    input   sign,
    output  logic   busy
);

wire [31:0] num0_abs = (sign && num0[31]) ? -num0 : num0;
wire [31:0] num1_abs = (sign && num1[31]) ? -num1 : num1;

logic[5:0] timer;
logic[31:0] dividend_q, mod_res_q;
logic[62:0] divisor_q;

logic neg_div_res_q, neg_mod_res_q;

logic[63:0] sub_result;

assign mod_res = neg_div_res_q ? -dividend_q[31:0] : dividend_q[31:0];
assign div_res = neg_mod_res_q ? -mod_res_q : mod_res_q;
assign sub_result = {31'd0, dividend_q} - divisor_q[62:0];

always_ff @(posedge clk) begin
    if(!rst_n) begin
        timer <= 6'd0;
        busy <= '0;
    end

    else if(start) begin
        timer <= 6'd32;
        busy <= '1;
    end

    else begin
        if(timer != 0) begin
            if(timer == 6'd1) begin
                busy <= '0;
            end

        timer <= timer - 6'd1;
        end
    end
end

always_ff @(posedge clk) begin
    if(start) begin
        dividend_q <= num0_abs;
        divisor_q <= {num1_abs, 31'd0};

        neg_div_res_q <= num0[31] && sign;
        neg_mod_res_q <= (num0[31] != num1[31]) && sign;
    end

    else begin
        if(timer != 0) begin
        if(!sub_result[63]) begin
            mod_res_q <= {mod_res_q[30:0], 1'b1};
            dividend_q <= sub_result[31:0];
        end

        else begin
            mod_res_q <= {mod_res_q[30:0], 1'b0};
        end

        divisor_q <= {'0, divisor_q[62:1]};
        end
    end
end

endmodule
