//x/y   //执行需要34个周期
module div(
    input div_clk, reset,
    input div,
    input div_signed,
    input [31:0] x, y,
    output [31:0] s, r,
    output complete
    );

reg [32:0] UnsignS;
reg [32:0] UnsignR;
reg [32:0] tmp_r;
reg [7:0] count;
wire [32:0] tmp_d;
wire [32:0] result_r;
wire [32:0] UnsignX, UnsignY;

reg  div_signed_buffer; 
reg  x_31_buffer;
reg  y_31_buffer;
wire real_div_signed;
wire real_x_31;
wire real_y_31;
wire complete_delay;
wire real_complete;

assign complete_delay = (count == 8'hf0);
assign real_complete = complete_delay || complete;

always @(posedge div_clk) begin 
    if (reset) begin 
        div_signed_buffer <= 1'b0;
        x_31_buffer <= 1'b0;
        y_31_buffer <= 1'b0;
    end 
    else if (div) begin 
        div_signed_buffer <= div_signed;   //when div inst go to ms, div_signed will be changed. so buffer it.
        x_31_buffer <= x[31];
        y_31_buffer <= y[31];
    end
end

assign real_div_signed = real_complete ? div_signed_buffer : div_signed;
assign real_x_31 = real_complete ? x_31_buffer : x[31];
assign real_y_31 = real_complete ? y_31_buffer : y[31];

assign UnsignX = {1'b0, (real_div_signed ? (x[31] ? (~x + 32'b1) : x) : x)}; //取绝对值并扩展至33位
assign UnsignY = {1'b0, (real_div_signed ? (y[31] ? (~y + 32'b1) : y) : y)};

always @(posedge div_clk) begin  //33位除法计算
    if (reset || ~div || complete_delay) begin
        count <= 8'd32;     //计算33次
        tmp_r <= 33'b0;
    end
    else if (~(count[7])) begin
        if (tmp_d[32]) begin    //tmp_d为负数
            UnsignS <= {UnsignS[31:0], 1'b0};
            tmp_r <= result_r;
        end 
        else begin
            UnsignS <= {UnsignS[31:0], 1'b1};
            tmp_r <= tmp_d;
        end
        count <= count - 8'd1;
    end
    else begin
        UnsignR <= tmp_r;
        count   <= 8'hf0; //complete signal only maintain one clock
    end

end

assign complete = (count == 8'hff);//chenji

assign result_r = {tmp_r[31:0], UnsignX[count]};
assign tmp_d = result_r - UnsignY;

wire [32:0] TmpS, TmpR;
assign TmpS = (real_div_signed ? ((real_x_31 == real_y_31) ? UnsignS : ~(UnsignS - 1)) : UnsignS); //去绝对值并截位
assign TmpR = (real_div_signed ? (real_x_31 ? ~(UnsignR - 1) : UnsignR) : UnsignR);

assign s = TmpS[31:0];
assign r = TmpR[31:0];

endmodule

//表达式的符号关系
//x[31]  y[31]  s[31]  r[31]
//  0      0      0      0
//  0      1      1      0
//  1      0      1      1
//  1      1      0      1
