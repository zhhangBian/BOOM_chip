module dcache
(
    input               clk          ,
    input               reset        ,
    //to from cpu
    input               valid        ,
    input               op           , //cache inst treat as load, op is zero
    input  [ 2:0]       size         ,
    input  [ 7:0]       index        ,
    input  [19:0]       tag          ,
    input  [ 3:0]       offset       ,
    input  [ 3:0]       wstrb        ,
    input  [31:0]       wdata        ,
    output              addr_ok      ,
    output              data_ok      ,
    output [31:0]       rdata        ,
    input               uncache_en   ,
    input               dcacop_op_en ,
    input  [ 1:0]       cacop_op_mode,
    input  [ 4:0]       preld_hint   ,
    input               preld_en     ,
    input               tlb_excp_cancel_req,
	output              dcache_empty ,
    //to from axi
    output              rd_req       ,
    output [ 2:0]       rd_type      ,
    output [31:0]       rd_addr      ,
    input               rd_rdy       ,
    input               ret_valid    ,
    input               ret_last     ,
    input  [31:0]       ret_data     ,
    output reg          wr_req       ,
    output [ 2:0]       wr_type      ,
    output [31:0]       wr_addr      ,
    output [ 3:0]       wr_wstrb     ,
    output [127:0]      wr_data      ,
    input               wr_rdy       ,
    //to perf_counter
    output              cache_miss   
);

reg [255:0] way0_d_reg;
reg [255:0] way1_d_reg;

wire        request_uncache_en        ;
reg         request_buffer_op         ;
reg         request_buffer_preld      ;
reg [ 2:0]  request_buffer_size       ;
reg [ 7:0]  request_buffer_index      ;
reg [19:0]  request_buffer_tag        ;
reg [ 3:0]  request_buffer_offset     ;
reg [ 3:0]  request_buffer_wstrb      ;
reg [31:0]  request_buffer_wdata      ;
reg         request_buffer_uncache_en ;
reg         request_buffer_dcacop     ;
reg [ 1:0]  request_buffer_cacop_op_mode;

reg          miss_buffer_replace_way ;
reg  [ 1:0]  miss_buffer_ret_num     ;
wire [ 1:0]  ret_num_add_one         ;

reg [ 7:0]  write_buffer_index      ;
reg [ 3:0]  write_buffer_wstrb      ;
reg [31:0]  write_buffer_wdata      ;
reg         write_buffer_way        ;
reg [ 3:0]  write_buffer_offset     ;
 
wire [ 7:0] way0_bank0_addra    ;
wire [31:0] way0_bank0_dina     ;
wire [31:0] way0_bank0_douta    ;
wire        way0_bank0_ena      ;
wire [ 3:0] way0_bank0_wea      ;
wire [ 7:0] way0_bank1_addra    ;
wire [31:0] way0_bank1_dina     ;
wire [31:0] way0_bank1_douta    ;
wire        way0_bank1_ena      ;
wire [ 3:0] way0_bank1_wea      ;
wire [ 7:0] way0_bank2_addra    ;
wire [31:0] way0_bank2_dina     ;
wire [31:0] way0_bank2_douta    ;
wire        way0_bank2_ena      ;
wire [ 3:0] way0_bank2_wea      ;
wire [ 7:0] way0_bank3_addra    ;
wire [31:0] way0_bank3_dina     ;
wire [31:0] way0_bank3_douta    ;
wire        way0_bank3_ena      ;
wire [ 3:0] way0_bank3_wea      ;
wire [ 7:0] way1_bank0_addra    ;
wire [31:0] way1_bank0_dina     ;
wire [31:0] way1_bank0_douta    ;
wire        way1_bank0_ena      ;
wire [ 3:0] way1_bank0_wea      ;
wire [ 7:0] way1_bank1_addra    ;
wire [31:0] way1_bank1_dina     ;
wire [31:0] way1_bank1_douta    ;
wire        way1_bank1_ena      ;
wire [ 3:0] way1_bank1_wea      ;
wire [ 7:0] way1_bank2_addra    ;
wire [31:0] way1_bank2_dina     ;
wire [31:0] way1_bank2_douta    ;
wire        way1_bank2_ena      ;
wire [ 3:0] way1_bank2_wea      ;
wire [ 7:0] way1_bank3_addra    ;
wire [31:0] way1_bank3_dina     ;
wire [31:0] way1_bank3_douta    ;
wire        way1_bank3_ena      ;
wire [ 3:0] way1_bank3_wea      ;

wire [ 7:0] way0_tagv_addra     ;
wire [20:0] way0_tagv_dina      ;
wire [20:0] way0_tagv_douta     ;
wire        way0_tagv_ena       ;
wire        way0_tagv_wea       ;
wire [ 7:0] way1_tagv_addra     ;
wire [20:0] way1_tagv_dina      ;
wire [20:0] way1_tagv_douta     ;
wire        way1_tagv_ena       ;
wire        way1_tagv_wea       ;

wire        wr_match_way0_bank0 ;
wire        wr_match_way0_bank1 ;
wire        wr_match_way0_bank2 ;
wire        wr_match_way0_bank3 ;
wire        wr_match_way1_bank0 ;
wire        wr_match_way1_bank1 ;
wire        wr_match_way1_bank2 ;
wire        wr_match_way1_bank3 ;

wire [ 7:0] main_state_index;

wire        way0_d      ;
wire        way1_d      ;

wire        way0_hit    ;
wire        way1_hit    ;
wire        cache_hit   ;

wire [31:0]  way0_load_word  ;
wire [31:0]  way1_load_word  ;
wire [31:0]  load_res        ;
wire [127:0] way0_data       ;
wire [127:0] way1_data       ;
 
wire [127:0] replace_data    ;
wire         replace_d       ;
wire         replace_v       ;
wire [20:0]  replace_tag     ;
wire         chosen_way      ;
wire         replace_way     ;

wire         main_idle2lookup  ;
wire         main_lookup2lookup;

wire [ 7:0]  tagv_addra;
wire [31:0]  bank_dina ;
wire [20:0]  tagv_dina ;
wire         bank_ena  ;
wire         tagv_ena  ;
wire         tagv_wea_en    ;

wire         main_state_is_idle   ;
wire         main_state_is_lookup ;
wire         main_state_is_miss   ;
wire         main_state_is_replace;
wire         main_state_is_refill ;

wire         write_state_is_idle;
wire         write_state_is_full;

wire         uncache_wr     ;
reg          uncache_wr_buffer;
wire [ 2:0]  uncache_wr_type;

wire         way0_wr_en;
wire         way1_wr_en;

wire [31:0]  refill_data;
wire [31:0]  write_in;

wire         cacop_op_mode0;
wire         cacop_op_mode1;
wire         cacop_op_mode2;

wire         cacop_op_mode2_hit_wr;
reg          cacop_op_mode2_hit_wr_buffer;

wire         preld_st_en;
wire         preld_ld_en;
wire         preld_ld_st_en;

wire         req_or_inst_valid;

reg          lookup_way0_hit_buffer;
reg          lookup_way1_hit_buffer;

localparam main_idle    = 5'b00001;
localparam main_lookup  = 5'b00010;
localparam main_miss    = 5'b00100;
localparam main_replace = 5'b01000;
localparam main_refill  = 5'b10000;
localparam write_buffer_idle  = 1'b0;
localparam write_buffer_write = 1'b1; 

reg [4:0] main_state;
reg       write_buffer_state;

reg       rd_req_buffer;

wire      invalid_way;

//state machine
//main loop
always @(posedge clk) begin
    if (reset) begin
        main_state <= main_idle;

        request_buffer_op         <=  1'b0;
        request_buffer_preld      <=  1'b0;
        request_buffer_size       <=  3'b0;
        request_buffer_index      <=  8'b0;
        request_buffer_tag        <= 20'b0;
        request_buffer_offset     <=  4'b0;
        request_buffer_wstrb      <=  4'b0;
        request_buffer_wdata      <= 32'b0;
        request_buffer_uncache_en <=  1'b0;

        request_buffer_cacop_op_mode <= 2'b0;
        request_buffer_dcacop        <= 1'b0;

        miss_buffer_replace_way <= 1'b0;

		wr_req <= 1'b0;
    end
    else case (main_state)
        main_idle: begin
            if (req_or_inst_valid && main_idle2lookup) begin
                main_state <= main_lookup;

                request_buffer_op         <= op        ;
                request_buffer_preld      <= preld_en     ;
                request_buffer_size       <= size      ;
                request_buffer_index      <= index     ;
                request_buffer_offset     <= offset    ;
                request_buffer_wstrb      <= wstrb     ;
                request_buffer_wdata      <= wdata     ;

                request_buffer_cacop_op_mode <= cacop_op_mode ;
                request_buffer_dcacop        <= dcacop_op_en  ;
            end
        end
        main_lookup: begin
            if (req_or_inst_valid && main_lookup2lookup) begin
                main_state <= main_lookup;

                request_buffer_op         <= op        ;
                request_buffer_preld      <= preld_en  ;
                request_buffer_size       <= size      ;
                request_buffer_index      <= index     ;
                request_buffer_offset     <= offset    ;
                request_buffer_wstrb      <= wstrb     ;
                request_buffer_wdata      <= wdata     ;

                request_buffer_cacop_op_mode <= cacop_op_mode ;
                request_buffer_dcacop        <= dcacop_op_en  ;
            end
            else if (tlb_excp_cancel_req) begin
                main_state <= main_idle;
            end
            else if (!cache_hit) begin
				//uncache wr --> wr_req 1
				//uncache rd, cacop(code==0) --> wr_req 0
				//cacop(code==1, 2), cache st, cache ld --> wr_req (dirty && valid)
				if (uncache_wr || ((replace_d && replace_v) && (!request_uncache_en || cacop_op_mode2_hit_wr) && !cacop_op_mode0))
                	main_state <= main_miss;
				else 
					main_state <= main_replace;

                request_buffer_tag        <= tag;
                request_buffer_uncache_en <= request_uncache_en;
				uncache_wr_buffer         <= uncache_wr;
                miss_buffer_replace_way   <= replace_way;
				cacop_op_mode2_hit_wr_buffer <= cacop_op_mode2_hit_wr;
            end
            else begin
                main_state <= main_idle;
            end
        end
        main_miss: begin
            if (wr_rdy) begin
                main_state <= main_replace;
				wr_req <= 1'b1;
            end
        end
        main_replace: begin
            if (rd_rdy) begin
                main_state <= main_refill;
                miss_buffer_ret_num <= 2'b0;   //when get ret data, it will be sent to cpu directly.
            end
			wr_req <= 1'b0;
        end
        main_refill: begin
            if ((ret_valid && ret_last) || !rd_req_buffer) begin   //when rd_req is not set, go to next state directly
                main_state <= main_idle;
            end
            else begin
                if (ret_valid) begin
                    miss_buffer_ret_num <= ret_num_add_one;
                end
            end
        end
        default: begin
            main_state <= main_idle;
        end
    endcase
end

//hit write state 
always @(posedge clk) begin
    if (reset) begin
        write_buffer_state  <= write_buffer_idle;

        write_buffer_index  <= 8'b0;
        write_buffer_wstrb  <= 4'b0;
        write_buffer_wdata  <= 32'b0;
        write_buffer_offset <= 4'b0;
        write_buffer_way    <= 1'b0;
    end
    else case (write_buffer_state)
        write_buffer_idle: begin
            if (main_state_is_lookup && cache_hit && request_buffer_op && !tlb_excp_cancel_req) begin
                write_buffer_state  <= write_buffer_write;

                write_buffer_index  <= request_buffer_index;
                write_buffer_wstrb  <= request_buffer_wstrb;
                write_buffer_wdata  <= request_buffer_wdata;
                write_buffer_offset <= request_buffer_offset;
                write_buffer_way    <= way1_hit;
            end
        end
        write_buffer_write: begin
            if (main_state_is_lookup && cache_hit && request_buffer_op && !tlb_excp_cancel_req) begin
                write_buffer_state  <= write_buffer_write;

                write_buffer_index  <= request_buffer_index;
                write_buffer_wstrb  <= request_buffer_wstrb;
                write_buffer_wdata  <= request_buffer_wdata;
                write_buffer_offset <= request_buffer_offset;
                write_buffer_way    <= way1_hit;
            end
            else begin
                write_buffer_state <= write_buffer_idle;
            end
        end
    endcase
end

/*====================================main state idle=======================================*/

assign req_or_inst_valid = valid || dcacop_op_en || preld_en;

//state change condition, write hit cache block write do not conflict with lookup read and cacop
assign main_idle2lookup   = !(write_state_is_full && ((write_buffer_offset[3:2] == offset[3:2]) || dcacop_op_en));

assign dcache_empty = main_state_is_idle;
//addr_ok logic

/*===================================main state lookup======================================*/

//tag compare
assign way0_hit  = way0_tagv_douta[0] && (tag == way0_tagv_douta[20:1]);   //this signal will not maintain
assign way1_hit  = way1_tagv_douta[0] && (tag == way1_tagv_douta[20:1]);
assign cache_hit = (way0_hit || way1_hit) && !(uncache_en || cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2);  //uncache road reuse
//when cache inst op mode2 no hit, main state machine will still go a round. implement easy.

assign main_lookup2lookup = !(write_state_is_full && ((write_buffer_offset[3:2] == offset[3:2]) || dcacop_op_en)) && 
                            !(request_buffer_op  && !op && ((request_buffer_offset[3:2] == offset[3:2]) || dcacop_op_en)) &&
                            cache_hit;
 
assign addr_ok = (main_state_is_idle && main_idle2lookup) || (main_state_is_lookup && main_lookup2lookup); //request can be get

//data select
assign way0_data = {way0_bank3_douta, way0_bank2_douta, way0_bank1_douta, way0_bank0_douta};
assign way1_data = {way1_bank3_douta, way1_bank2_douta, way1_bank1_douta, way1_bank0_douta};
assign way0_load_word = way0_data[request_buffer_offset[3:2]*32 +: 32];
assign way1_load_word = way1_data[request_buffer_offset[3:2]*32 +: 32];
assign load_res  = {32{way0_hit}} & way0_load_word |
                   {32{way1_hit}} & way1_load_word ;

assign request_uncache_en = (uncache_en && !request_buffer_dcacop);

assign uncache_wr = request_uncache_en && request_buffer_op && !cacop_op_mode1 && !cacop_op_mode2_hit_wr;
//data_ok logic

assign invalid_way = (!way1_tagv_douta[0] || chosen_way) && way0_tagv_douta[0];  //chose invalid way first. 

assign replace_way = ((cacop_op_mode0 || cacop_op_mode1) && request_buffer_offset[0]) ||
                     (cacop_op_mode2 && way1_hit)                                     ||
                     (!request_buffer_dcacop) && invalid_way   ;

assign way0_d = way0_d_reg[request_buffer_index] ||
				((write_buffer_index==request_buffer_index)&&write_state_is_full&&!write_buffer_way);
assign way1_d = way1_d_reg[request_buffer_index] ||
				((write_buffer_index==request_buffer_index)&&write_state_is_full&& write_buffer_way);

assign replace_d    = replace_way ? way1_d : way0_d;
assign replace_v    = replace_way ? way1_tagv_douta[0] : way0_tagv_douta[0];

/*====================================main state miss=======================================*/

assign replace_tag  = miss_buffer_replace_way ? way1_tagv_douta[20:1] : way0_tagv_douta[20:1];
assign replace_data = miss_buffer_replace_way ? way1_data : way0_data;

assign wr_type  = uncache_wr_buffer ? uncache_wr_type : 3'b100;     //replace cache line
assign wr_addr  = uncache_wr_buffer ? {request_buffer_tag, request_buffer_index, request_buffer_offset} :
 	                                  {replace_tag, request_buffer_index, 4'b0};
assign wr_data  = uncache_wr_buffer ? {96'b0, request_buffer_wdata} : replace_data;
assign wr_wstrb = uncache_wr_buffer ? request_buffer_wstrb : 4'hf;

//assign wr_req = main_state_is_miss;

/*==================================main state replace======================================*/

assign uncache_wr_type = request_buffer_size;

assign rd_req  = main_state_is_replace && !(uncache_wr_buffer || cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2);

assign rd_type = request_buffer_uncache_en ? request_buffer_size : 3'b100;
assign rd_addr = request_buffer_uncache_en ? {request_buffer_tag, request_buffer_index, request_buffer_offset} : {request_buffer_tag, request_buffer_index, 4'b0};
/*===================================main state refill======================================*/

//write process will not block pipeline
//preld ins will not block pipeline      ps:preld is not real mem inst, this operation is controled in pipeline
assign data_ok = ((main_state_is_lookup && (cache_hit || request_buffer_op || tlb_excp_cancel_req)) || 
                  (main_state_is_refill && (!request_buffer_op && (ret_valid && ((miss_buffer_ret_num == request_buffer_offset[3:2]) || request_buffer_uncache_en))))) && 
                  !(request_buffer_preld || request_buffer_dcacop);  //when rd_req is not set, set data_ok directly.
//rdate connect with ret_data dirctly. maintain one clock only

assign write_in = {(request_buffer_wstrb[3] ? request_buffer_wdata[31:24] : ret_data[31:24]), 
                   (request_buffer_wstrb[2] ? request_buffer_wdata[23:16] : ret_data[23:16]),
                   (request_buffer_wstrb[1] ? request_buffer_wdata[15: 8] : ret_data[15: 8]),
                   (request_buffer_wstrb[0] ? request_buffer_wdata[ 7: 0] : ret_data[ 7: 0])};

assign refill_data = (request_buffer_op && (request_buffer_offset[3:2] == miss_buffer_ret_num)) ? write_in : ret_data; 

assign way0_wr_en = !miss_buffer_replace_way && ret_valid;  //when rd_req is not set, ret_valid and ret_last will not be set. block will not be wr also.
assign way1_wr_en =  miss_buffer_replace_way && ret_valid;

assign cache_miss = main_state_is_refill && ret_last && !(request_buffer_uncache_en || request_buffer_dcacop || request_buffer_preld);  

//add one 
assign ret_num_add_one[0] = miss_buffer_ret_num[0] ^ 1'b1;
assign ret_num_add_one[1] = miss_buffer_ret_num[1] ^ miss_buffer_ret_num[0];

always @(posedge clk) begin
    if (reset) begin
        rd_req_buffer <= 1'b0;
    end
    else if (rd_req) begin
        rd_req_buffer <= 1'b1;
    end
    else if (main_state_is_refill && (ret_valid && ret_last)) begin
        rd_req_buffer <= 1'b0;
    end
end

/*==========================================================================================*/

//refill or write state update dirty reg
always @(posedge clk) begin
    if (main_state_is_refill && ((ret_valid && ret_last) || !rd_req_buffer) && (!(request_buffer_uncache_en || cacop_op_mode0))) begin
        if (miss_buffer_replace_way) begin  //clear dirty flags
            way1_d_reg[request_buffer_index] <= request_buffer_op;
        end
        else begin
            way0_d_reg[request_buffer_index] <= request_buffer_op;
        end
    end
    else if (write_state_is_full) begin
        if (write_buffer_way) begin
            way1_d_reg[write_buffer_index] <= 1'b1;
        end
        else begin
            way0_d_reg[write_buffer_index] <= 1'b1;
        end
    end
end

//cache ins control signal
assign cacop_op_mode0 = request_buffer_dcacop && (request_buffer_cacop_op_mode == 2'b00);
assign cacop_op_mode1 = request_buffer_dcacop && ((request_buffer_cacop_op_mode == 2'b01) || (request_buffer_cacop_op_mode == 2'b11));
assign cacop_op_mode2 = request_buffer_dcacop && (request_buffer_cacop_op_mode == 2'b10);

assign cacop_op_mode2_hit_wr = cacop_op_mode2 && (way0_hit || way1_hit);

//output
assign rdata = {32{main_state_is_lookup}} & load_res |
               {32{main_state_is_refill}} & ret_data ;

/*===============================bank addra logic==============================*/

assign wr_match_way0_bank0 = write_state_is_full && (!write_buffer_way && (write_buffer_offset[3:2] == 2'b00));
assign wr_match_way0_bank1 = write_state_is_full && (!write_buffer_way && (write_buffer_offset[3:2] == 2'b01));
assign wr_match_way0_bank2 = write_state_is_full && (!write_buffer_way && (write_buffer_offset[3:2] == 2'b10));
assign wr_match_way0_bank3 = write_state_is_full && (!write_buffer_way && (write_buffer_offset[3:2] == 2'b11));
assign wr_match_way1_bank0 = write_state_is_full && ( write_buffer_way && (write_buffer_offset[3:2] == 2'b00));
assign wr_match_way1_bank1 = write_state_is_full && ( write_buffer_way && (write_buffer_offset[3:2] == 2'b01));
assign wr_match_way1_bank2 = write_state_is_full && ( write_buffer_way && (write_buffer_offset[3:2] == 2'b10));
assign wr_match_way1_bank3 = write_state_is_full && ( write_buffer_way && (write_buffer_offset[3:2] == 2'b11));

assign main_state_index = {8{addr_ok}}                             & index                  |             /*lookup*/
						  {8{!addr_ok}}                            & request_buffer_index   ;

assign way0_bank0_addra = wr_match_way0_bank0 ? write_buffer_index : main_state_index;
assign way0_bank1_addra = wr_match_way0_bank1 ? write_buffer_index : main_state_index;
assign way0_bank2_addra = wr_match_way0_bank2 ? write_buffer_index : main_state_index;
assign way0_bank3_addra = wr_match_way0_bank3 ? write_buffer_index : main_state_index;
assign way1_bank0_addra = wr_match_way1_bank0 ? write_buffer_index : main_state_index;
assign way1_bank1_addra = wr_match_way1_bank1 ? write_buffer_index : main_state_index;
assign way1_bank2_addra = wr_match_way1_bank2 ? write_buffer_index : main_state_index;
assign way1_bank3_addra = wr_match_way1_bank3 ? write_buffer_index : main_state_index;

/*===============================bank we logic=================================*/

assign way0_bank0_wea = {4{wr_match_way0_bank0}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way0_wr_en && (miss_buffer_ret_num == 2'b00))}} & 4'hf;

assign way0_bank1_wea = {4{wr_match_way0_bank1}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way0_wr_en && (miss_buffer_ret_num == 2'b01))}} & 4'hf;

assign way0_bank2_wea = {4{wr_match_way0_bank2}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way0_wr_en && (miss_buffer_ret_num == 2'b10))}} & 4'hf;

assign way0_bank3_wea = {4{wr_match_way0_bank3}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way0_wr_en && (miss_buffer_ret_num == 2'b11))}} & 4'hf;

assign way1_bank0_wea = {4{wr_match_way1_bank0}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way1_wr_en && (miss_buffer_ret_num == 2'b00))}} & 4'hf;

assign way1_bank1_wea = {4{wr_match_way1_bank1}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way1_wr_en && (miss_buffer_ret_num == 2'b01))}} & 4'hf;

assign way1_bank2_wea = {4{wr_match_way1_bank2}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way1_wr_en && (miss_buffer_ret_num == 2'b10))}} & 4'hf;

assign way1_bank3_wea = {4{wr_match_way1_bank3}} & write_buffer_wstrb |
                        {4{main_state_is_refill && (way1_wr_en && (miss_buffer_ret_num == 2'b11))}} & 4'hf;

/*===============================bank dina logic=================================*/

assign bank_dina = {32{write_state_is_full}}   & write_buffer_wdata |
                   {32{main_state_is_refill}} & refill_data         ;

assign way0_bank0_dina = bank_dina;
assign way0_bank1_dina = bank_dina;
assign way0_bank2_dina = bank_dina;
assign way0_bank3_dina = bank_dina;
assign way1_bank0_dina = bank_dina;
assign way1_bank1_dina = bank_dina;
assign way1_bank2_dina = bank_dina;
assign way1_bank3_dina = bank_dina;

/*===============================bank ena logic=================================*/

assign bank_ena = (!(request_buffer_uncache_en || cacop_op_mode0)) || main_state_is_idle || main_state_is_lookup;

assign way0_bank0_ena = bank_ena;
assign way0_bank1_ena = bank_ena;
assign way0_bank2_ena = bank_ena;
assign way0_bank3_ena = bank_ena;
assign way1_bank0_ena = bank_ena;
assign way1_bank1_ena = bank_ena;
assign way1_bank2_ena = bank_ena;
assign way1_bank3_ena = bank_ena;

/*===============================tagv addra logic=================================*/

assign tagv_addra = {8{addr_ok }}                                   & index                |
                    {8{!addr_ok}}                                   & request_buffer_index ; 

assign way0_tagv_addra = tagv_addra;
assign way1_tagv_addra = tagv_addra;

/*===============================tagv ena logic=================================*/

assign tagv_ena = (!request_buffer_uncache_en) || main_state_is_idle || main_state_is_lookup;

assign way0_tagv_ena  = tagv_ena;
assign way1_tagv_ena  = tagv_ena;

/*===============================tagv wea logic=================================*/

assign tagv_wea_en = main_state_is_refill && ((ret_valid && ret_last) || cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2_hit_wr_buffer);

assign way0_tagv_wea = !miss_buffer_replace_way && tagv_wea_en; //wirte at last 4B
assign way1_tagv_wea =  miss_buffer_replace_way && tagv_wea_en;

/*===============================tagv dina logic=================================*/

assign tagv_dina = (cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2_hit_wr_buffer) ? 21'b0 : {request_buffer_tag, 1'b1};

assign way0_tagv_dina = tagv_dina;
assign way1_tagv_dina = tagv_dina;

/*==============================================================================*/

data_bank_sram way0_bank0(
    .addra      (way0_bank0_addra)  ,
    .clka       (clk             )  ,
    .dina       (way0_bank0_dina )  ,
    .douta      (way0_bank0_douta)  ,
    .ena        (way0_bank0_ena  )  ,
    .wea        (way0_bank0_wea  )  
);

data_bank_sram way0_bank1(
    .addra      (way0_bank1_addra)  ,
    .clka       (clk             )  ,
    .dina       (way0_bank1_dina )  ,
    .douta      (way0_bank1_douta)  ,
    .ena        (way0_bank1_ena  )  ,
    .wea        (way0_bank1_wea  )  
);

data_bank_sram way0_bank2(
    .addra      (way0_bank2_addra)  ,
    .clka       (clk             )  ,
    .dina       (way0_bank2_dina )  ,
    .douta      (way0_bank2_douta)  ,
    .ena        (way0_bank2_ena  )  ,
    .wea        (way0_bank2_wea  )  
);

data_bank_sram way0_bank3(
    .addra      (way0_bank3_addra)  ,
    .clka       (clk             )  ,
    .dina       (way0_bank3_dina )  ,
    .douta      (way0_bank3_douta)  ,
    .ena        (way0_bank3_ena  )  ,
    .wea        (way0_bank3_wea  )  
);

data_bank_sram way1_bank0(
    .addra      (way1_bank0_addra)  ,
    .clka       (clk             )  ,
    .dina       (way1_bank0_dina )  ,
    .douta      (way1_bank0_douta)  ,
    .ena        (way1_bank0_ena  )  ,
    .wea        (way1_bank0_wea  )  
);

data_bank_sram way1_bank1(
    .addra      (way1_bank1_addra)  ,
    .clka       (clk             )  ,
    .dina       (way1_bank1_dina )  ,
    .douta      (way1_bank1_douta)  ,
    .ena        (way1_bank1_ena  )  ,
    .wea        (way1_bank1_wea  )  
);

data_bank_sram way1_bank2(
    .addra      (way1_bank2_addra)  ,
    .clka       (clk             )  ,
    .dina       (way1_bank2_dina )  ,
    .douta      (way1_bank2_douta)  ,
    .ena        (way1_bank2_ena  )  ,
    .wea        (way1_bank2_wea  )  
);

data_bank_sram way1_bank3(
    .addra      (way1_bank3_addra)  ,
    .clka       (clk             )  ,
    .dina       (way1_bank3_dina )  ,
    .douta      (way1_bank3_douta)  ,
    .ena        (way1_bank3_ena  )  ,
    .wea        (way1_bank3_wea  )  
);

//[20:1] tag     [0:0] v
tagv_sram way0_tagv( 
    .addra      (way0_tagv_addra)  ,
    .clka       (clk            )  ,
    .dina       (way0_tagv_dina )  ,
    .douta      (way0_tagv_douta)  ,
    .ena        (way0_tagv_ena  )  ,
    .wea        (way0_tagv_wea  )
);

tagv_sram way1_tagv( 
    .addra      (way1_tagv_addra)  ,
    .clka       (clk            )  ,
    .dina       (way1_tagv_dina )  ,
    .douta      (way1_tagv_douta)  ,
    .ena        (way1_tagv_ena  )  ,
    .wea        (way1_tagv_wea  )
);

lfsr lfsr(
    .clk        (clk        )   ,
    .reset      (reset      )   ,
    .random_val (chosen_way )
);

assign main_state_is_idle    = main_state == main_idle   ;
assign main_state_is_lookup  = main_state == main_lookup ;
assign main_state_is_miss    = main_state == main_miss   ;
assign main_state_is_replace = main_state == main_replace;
assign main_state_is_refill  = main_state == main_refill ;

assign write_state_is_idle  = (write_buffer_state == write_buffer_idle) ;
assign write_state_is_full = (write_buffer_state == write_buffer_write);

endmodule

`ifdef SIMU
module data_bank_sram
#(
    parameter WIDTH = 32    ,
    parameter DEPTH = 256
)
(
    input  [ 7:0]          addra   ,
    input                  clka    ,
    input  [31:0]          dina    ,
    output [31:0]          douta   ,
    input                  ena     ,
    input  [ 3:0]          wea      
);

reg [31:0] mem_reg [255:0];
reg [31:0] output_buffer;

always @(posedge clka) begin
    if (ena) begin
        if (wea) begin
            if (wea[0]) begin
                mem_reg[addra][ 7: 0] <= dina[ 7: 0]; 
            end 

            if (wea[1]) begin
                mem_reg[addra][15: 8] <= dina[15: 8];
            end

            if (wea[2]) begin
                mem_reg[addra][23:16] <= dina[23:16];
            end

            if (wea[3]) begin
                mem_reg[addra][31:24] <= dina[31:24];
            end
        end
        else begin
            output_buffer <= mem_reg[addra];
        end
    end
end

assign douta = output_buffer;

endmodule 

module tagv_sram
#( 
    parameter WIDTH = 21    ,
    parameter DEPTH = 256
)
( 
    input  [ 7:0]          addra   ,
    input                  clka    ,
    input  [20:0]          dina    ,
    output [20:0]          douta   ,
    input                  ena     ,
    input                  wea 
);

reg [20:0] mem_reg [255:0];
reg [20:0] output_buffer;

always @(posedge clka) begin
    if (ena) begin
        if (wea) begin
            mem_reg[addra] <= dina;
        end
        else begin
            output_buffer <= mem_reg[addra];
        end
    end
end

assign douta = output_buffer;

endmodule
`endif

module lfsr
( 
    input           clk         ,
    input           reset       ,

    output          random_val  
);

reg [7:0] r_lfsr;

always @(posedge clk) begin
    if (reset) begin
        r_lfsr <= 8'b1;
    end
    else begin
        r_lfsr[0] <= r_lfsr[7];
        r_lfsr[1] <= r_lfsr[0];
        r_lfsr[2] <= r_lfsr[1];
        r_lfsr[3] <= r_lfsr[2];
        r_lfsr[4] <= r_lfsr[3] ^ r_lfsr[7];
        r_lfsr[5] <= r_lfsr[4] ^ r_lfsr[7];
        r_lfsr[6] <= r_lfsr[5] ^ r_lfsr[7];
        r_lfsr[7] <= r_lfsr[6];
    end
end

assign random_val = r_lfsr[7];

endmodule
