module decoder_2_4(
    input  [ 1:0] in,
    output [ 3:0] out
);

genvar i;
generate for (i=0; i<4; i=i+1) begin : gen_for_dec_2_4
    assign out[i] = (in == i);
end endgenerate

endmodule


module encoder_4_2(
    input  [3:0] in,
    output [1:0] out
);

assign out = {2{in[0]}} & 2'd0 |
	     {2{in[1]}} & 2'd1 |
	     {2{in[2]}} & 2'd2 |
	     {2{in[3]}} & 2'd3 ;

endmodule

module decoder_4_16(
    input  [ 3:0] in,
    output [15:0] out
);

genvar i;
generate for (i=0; i<16; i=i+1) begin : gen_for_dec_4_16
    assign out[i] = (in == i);
end endgenerate

endmodule

module encoder_16_4(
    input  [15:0] in,
    output [ 3:0] out
);

wire [1:0] out_0, out_1, out_2, out_3;

encoder_4_2 one (.in(in[ 3: 0]), .out(out_0));
encoder_4_2 two (.in(in[ 7: 4]), .out(out_1));
encoder_4_2 thr (.in(in[11: 8]), .out(out_2));
encoder_4_2 fou (.in(in[15:12]), .out(out_3));

assign out = {4{|in[ 3: 0]}} & {2'd0, out_0} |
	     {4{|in[ 7: 4]}} & {2'd1, out_1} |		
	     {4{|in[11: 8]}} & {2'd2, out_2} |		
	     {4{|in[15:12]}} & {2'd3, out_3} ;		

endmodule

module decoder_5_32(
    input  [ 4:0] in,
    output [31:0] out
);

genvar i;
generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
    assign out[i] = (in == i);
end endgenerate

endmodule

module encoder_32_5(
    input  [31:0] in,
    output [ 4:0] out
);

wire [3:0] out_0, out_1;

encoder_16_4 one (.in(in[15: 0]), .out(out_0));
encoder_16_4 two (.in(in[31:16]), .out(out_1));

assign out = {5{|in[15: 0]}} & {1'd0, out_0} |
	     {5{|in[31:16]}} & {1'd1, out_1} ;

endmodule


module decoder_6_64(
    input  [ 5:0] in,
    output [63:0] out
);

genvar i;
generate 
	for (i=0; i<64; i=i+1) 
	begin : gen_for_dec_6_64  //bug7
    	assign out[i] = (in == i);
	end
endgenerate

endmodule

module one_valid_16 (
    input  [15:0] in,
    output [ 3:0] out_en
);

wire [15:0] one_in;

assign one_in[0] = in[0];

genvar i;
generate 
	for (i=1; i<16; i=i+1)
	begin: sel_one
		assign one_in[i] = in[i] && ~|in[i-1:0];
	end
endgenerate

encoder_16_4 coder (.in(one_in), .out(out_en));

endmodule

module one_valid_32 (
    input  [31:0] in,
    output [ 4:0] out_en
);

wire [31:0] one_in;

assign one_in[0] = in[0];

genvar i;
generate 
	for (i=1; i<32; i=i+1)
	begin: sel_one
		assign one_in[i] = in[i] && ~|in[i-1:0];
	end
endgenerate

encoder_32_5 coder (.in(one_in), .out(out_en));

endmodule

