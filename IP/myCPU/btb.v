module btb
#(
    parameter BTBNUM = 32
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

reg [29:0] pc      [BTBNUM-1:0];
reg [29:0] target  [BTBNUM-1:0];
reg [ 2:0] counter [BTBNUM-1:0];

reg [31:0] fetch_pc_r;
reg fetch_en_r;

reg [BTBNUM-1:0] jirl_flag;
reg [BTBNUM-1:0] valid    ;

reg [29:0] ras [7:0];
reg [ 3:0] ras_ptr;

wire [29:0] ras_top;

wire ras_full;
wire ras_empty;

wire [31:0] match_rd;

wire [29:0] match_target;
wire [ 2:0] match_counter;
wire [ 4:0] match_index;
wire        match_jirl_flag;

wire all_entry_valid;
wire [4:0] select_one_invalid_entry;

wire [4:0] add_entry_index;

reg [5:0] fcsr;

always @(posedge clk) begin
    if (reset)
        fetch_en_r <= 1'b0;
    else 
	fetch_en_r <= fetch_en;

    if (fetch_en) 
        fetch_pc_r <= fetch_pc;
end

assign add_entry_index = all_entry_valid ? fcsr[4:0] : select_one_invalid_entry;

assign all_entry_valid = &valid;

one_valid_32 sel_on_entry (.in(~valid), .out_en(select_one_invalid_entry));

always @(posedge clk) begin
    if (reset) begin
        valid <= 8'b0;
    end
    else if (operate_en) begin
        if (add_entry) begin
            valid[add_entry_index]     <= 1'b1;
            pc[add_entry_index]        <= operate_pc[31:2];
            target[add_entry_index]    <= right_target[31:2];
            counter[add_entry_index]   <= 3'b100;
            jirl_flag[add_entry_index] <= pop_ras;
        end
        else if (delete_entry) begin
            valid[operate_index]     <= 1'b0;
            jirl_flag[operate_index] <= 1'b0;
        end
        else if (target_error && !pop_ras) begin
            target[operate_index]    <= right_target[31:2];
            counter[operate_index]   <= 3'b100;
            jirl_flag[operate_index] <= 1'b0;
        end
        else if (pre_error || pre_right) begin
            if (right_orien) begin
                if (counter[operate_index] != 3'b111) begin
                    counter[operate_index] <= counter[operate_index] + 3'b1;
                end
            end
            else begin
                if (counter[operate_index] != 3'b000) begin
                    counter[operate_index] <= counter[operate_index] - 3'b1;
                end
            end
        end
    end
    
end

genvar i;
generate 
    for (i = 0; i < BTBNUM; i = i + 1)
        begin: match
            assign match_rd[i] = fetch_en_r && ((fetch_pc_r[31:2] == pc[i]) && valid[i] && !(jirl_flag[i] && ras_empty)); 
        end
endgenerate

assign ras_top = ras[ras_ptr - 4'b1]; //ras modify may before inst fetch

encoder_32_5 encode_match (.in(match_rd), .out(match_index));

assign match_target = target[match_index];
assign match_counter = counter[match_index];
assign match_jirl_flag = jirl_flag[match_index];

assign ret_pc = match_jirl_flag ? {ras_top, 2'b0} : {match_target, 2'b0};
assign ret_en = |match_rd;
assign taken  = match_counter[2];
assign ret_index = match_index;

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
