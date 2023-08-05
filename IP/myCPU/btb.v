module btb
#(
    parameter BTBNUM = 32,
	parameter RASNUM = 16
)
(
    input             clk           ,
    input             reset         ,
    //from/to if
    input  [31:0]     fetch_pc      ,
    input             fetch_en      ,
    output [31:0]     ret_pc        ,
    output            taken         ,
    output            ret_en        ,
    output [ 4:0]     ret_index     ,
    //from id
    input             operate_en    ,
    input  [31:0]     operate_pc    ,
    input  [ 4:0]     operate_index ,
    input             pop_ras       ,
    input             push_ras      ,
    input             add_entry     ,
    input             delete_entry  ,
    input             pre_error     ,
    input             pre_right     ,
    input             target_error  ,
    input             right_orien   ,
    input  [31:0]     right_target  
);

/*
* btb_pc record all branch inst pc except jirl
* ras_pc only record jirl pc
*/
reg [29:0] btb_pc      [BTBNUM-1:0];
reg [29:0] btb_target  [BTBNUM-1:0];
reg [ 1:0] btb_counter [BTBNUM-1:0];

reg [BTBNUM-1:0] btb_valid;

reg [29:0] ras_pc [RASNUM-1:0];

reg [RASNUM-1:0] ras_valid;

reg [31:0] fetch_pc_r;
reg fetch_en_r;

//reg [BTBNUM-1:0] jirl_flag;

reg [29:0] ras [7:0];
reg [ 3:0] ras_ptr;

wire [29:0] ras_top;

wire ras_full;
wire ras_empty;

wire [31:0] btb_match_rd;
wire [15:0] ras_match_rd;

wire btb_match;
wire ras_match;

wire [29:0] btb_match_target;
wire [ 1:0] btb_match_counter;
wire [ 4:0] btb_match_index;
wire [ 4:0] btb_random_index;

wire [ 3:0] ras_match_index;
wire [ 3:0] ras_random_index;

wire btb_all_entry_valid;
wire [4:0] btb_select_one_invalid_entry;
wire [4:0] btb_add_entry_index;
reg  [4:0] btb_add_entry_index_r;
wire [31:0] btb_add_entry_dec;

wire ras_all_entry_valid;
wire [3:0] ras_select_one_invalid_entry;
wire [3:0] ras_add_entry_index;

wire [31:0] btb_untaken_entry;
reg  [31:0] btb_untaken_entry_r;
wire [31:0] btb_untaken_entry_t;
reg         btb_add_entry_r;
wire [4:0]  btb_sel_one_untaken_entry;
wire        btb_has_one_untaken_entry;

reg [5:0] fcsr;

always @(posedge clk) begin
    if (reset)
        fetch_en_r <= 1'b0;
    else 
	fetch_en_r <= fetch_en;

    if (fetch_en) 
        fetch_pc_r <= fetch_pc;
end

always @(posedge clk) begin
	btb_untaken_entry_r   <= btb_untaken_entry;
	btb_add_entry_r       <= operate_en && !pop_ras && add_entry;
	btb_add_entry_index_r <= btb_add_entry_index;
end

//untaken entry list cal at previous clock
assign btb_untaken_entry_t = btb_untaken_entry_r & ({32{!btb_add_entry_r}} | ~btb_add_entry_dec); 
assign btb_has_one_untaken_entry = |btb_untaken_entry_t;

decoder_5_32 dec_btb_add_entry (.in(btb_add_entry_index_r), .out(btb_add_entry_dec));
one_valid_32 sel_one_untaken_entry (.in(btb_untaken_entry_t), .out_en(btb_sel_one_untaken_entry));

//assign btb_random_index = (btb_match && (fcsr[4:0] == btb_match_index)) ? (fcsr[4:0]+1'b1) : fcsr[4:0];
//untaken entry can exit first, make no difference, except lose history infor. 
assign btb_add_entry_index = !btb_all_entry_valid ?      btb_select_one_invalid_entry :
							 btb_has_one_untaken_entry ? btb_sel_one_untaken_entry : 
							 							 fcsr[4:0] ; 

assign btb_all_entry_valid = &btb_valid;
one_valid_32 sel_one_btb_entry (.in(~btb_valid), .out_en(btb_select_one_invalid_entry));

//assign ras_random_index = (ras_match && (fcsr[3:0] == ras_match_index)) ? (fcsr[3:0]+1'b1) : fcsr[3:0];
assign ras_add_entry_index = ras_all_entry_valid ? fcsr[3:0] : ras_select_one_invalid_entry;
assign ras_all_entry_valid = &ras_valid;
one_valid_16 sel_one_ras_entry (.in(~ras_valid), .out_en(ras_select_one_invalid_entry));

always @(posedge clk) begin
    if (reset) begin
        btb_valid <= 32'b0;
		ras_valid <= 16'b0;
    end
    else if (operate_en && !pop_ras) begin
        if (add_entry) begin
            btb_valid[btb_add_entry_index]   <= 1'b1;
            btb_pc[btb_add_entry_index]      <= operate_pc[31:2];
            btb_target[btb_add_entry_index]  <= right_target[31:2];
            btb_counter[btb_add_entry_index] <= 2'b10;
        end
        else if (target_error) begin
            btb_target[operate_index]    <= right_target[31:2];
            btb_counter[operate_index]   <= 2'b10;
        end
        else if (pre_error || pre_right) begin
            if (right_orien) begin
                if (btb_counter[operate_index] != 2'b11) begin
                    btb_counter[operate_index] <= btb_counter[operate_index] + 2'b1;
                end
            end
            else begin
                if (btb_counter[operate_index] != 2'b00) begin
                    btb_counter[operate_index] <= btb_counter[operate_index] - 2'b1;
                end
            end
        end
    end
	else if (operate_en && pop_ras) begin
		if (add_entry) begin
			ras_valid[ras_add_entry_index] <= 1'b1;
            ras_pc[ras_add_entry_index]    <= operate_pc[31:2];
		end
	end
    
end

genvar i;
generate 
    for (i = 0; i < BTBNUM; i = i + 1)
        begin: btb_match_com
            assign btb_match_rd[i] = fetch_en_r && ((fetch_pc_r[31:2] == btb_pc[i]) && btb_valid[i]); 
        end
endgenerate

generate 
    for (i = 0; i < RASNUM; i = i + 1)
        begin: ras_match_com
            assign ras_match_rd[i] = fetch_en_r && ((fetch_pc_r[31:2] == ras_pc[i]) && ras_valid[i]); 
        end
endgenerate

generate 
	for (i = 0; i < BTBNUM; i = i + 1)
		begin: sel_untaken_entry
			assign btb_untaken_entry[i] = btb_valid[i] && ~|btb_counter[i];
		end
endgenerate

assign btb_match = |btb_match_rd;
assign ras_match = |ras_match_rd;

assign ras_top = ras[ras_ptr - 4'b1]; //ras modify may before inst fetch

encoder_32_5 encode_btb_match (.in(btb_match_rd), .out(btb_match_index));
encoder_16_4 encode_ras_match (.in(ras_match_rd), .out(ras_match_index));

assign btb_match_target = btb_target[btb_match_index];
assign btb_match_counter = btb_counter[btb_match_index];

assign ret_pc = {32{ras_match}} & {ras_top, 2'b0} |
				{32{btb_match}} & {btb_match_target, 2'b0};
assign ret_en = btb_match || ras_match;
assign taken  = btb_match && btb_match_counter[1] || ras_match;
assign ret_index = {5{btb_match}} & {btb_match_index} | 
				   {5{ras_match}} & {1'b0,ras_match_index};

assign ras_full  = ras_ptr[3];
assign ras_empty = (ras_ptr == 4'd0);

always @(posedge clk) begin
    if (reset) begin
        ras_ptr <= 4'b0;
    end
    else if (operate_en) begin
        if (push_ras && !ras_full) begin
            ras[ras_ptr] <= operate_pc[31:2] + 30'b1;
            ras_ptr <= ras_ptr + 4'b1;
        end
        else if (pop_ras && !ras_empty) begin
            ras_ptr <= ras_ptr - 4'b1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        fcsr <= 6'b100010;
    end
    else begin
        fcsr[0] <= fcsr[5];
        fcsr[1] <= fcsr[0];
        fcsr[2] <= fcsr[1];
        fcsr[3] <= fcsr[2] ^ fcsr[5];
        fcsr[4] <= fcsr[3] ^ fcsr[5];
        fcsr[5] <= fcsr[4];
    end
end

endmodule
