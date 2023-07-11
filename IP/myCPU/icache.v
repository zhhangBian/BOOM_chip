module icache
(
    input               clk            ,
    input               reset          ,
    //to from cpu
    input               valid          ,
    input               op             ,
    input  [ 7:0]       index          ,
    input  [19:0]       tag            ,
    input  [ 3:0]       offset         ,
    input  [ 3:0]       wstrb          ,
    input  [31:0]       wdata          ,
    output              addr_ok        ,
    output              data_ok        ,
    output [31:0]       rdata          ,
    input               uncache_en     ,
    input               icacop_op_en   ,
    input  [ 1:0]       cacop_op_mode  ,  
    input  [ 7:0]       cacop_op_addr_index , //this signal from mem stage's va
    input  [19:0]       cacop_op_addr_tag   , 
    input  [ 3:0]       cacop_op_addr_offset,
    output              icache_unbusy,
    input               tlb_excp_cancel_req,
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

reg         request_buffer_op         ;
reg [ 7:0]  request_buffer_index      ;
reg [19:0]  request_buffer_tag        ;
reg [ 3:0]  request_buffer_offset     ;
reg [ 3:0]  request_buffer_wstrb      ;
reg [31:0]  request_buffer_wdata      ;
reg         request_buffer_uncache_en ;
reg         request_buffer_icacop     ;
reg [ 1:0]  request_buffer_cacop_op_mode;

reg          miss_buffer_replace_way ;
reg  [ 1:0]  miss_buffer_ret_num     ;
wire [ 1:0]  ret_num_add_one         ;
 
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

wire        way0_hit    ;
wire        way1_hit    ;
wire        cache_hit   ;

wire [31:0]  way0_load_word  ;
wire [31:0]  way1_load_word  ;
wire [31:0]  load_res        ;
wire [127:0] way0_data       ;
wire [127:0] way1_data       ;

wire         main_idle2lookup  ;
wire         main_lookup2lookup;

wire [ 7:0]  bank_addra;
wire [ 7:0]  tagv_addra;
wire [31:0]  bank_dina ;
wire [20:0]  tagv_dina ;
wire         bank_ena  ;
wire         tagv_ena  ;
wire         tagv_wea_en    ;

wire         main_state_is_idle   ;
wire         main_state_is_lookup ;
wire         main_state_is_replace;
wire         main_state_is_refill ;

wire         way0_wr_en;
wire         way1_wr_en;

wire [31:0]  refill_data;

wire         cacop_op_mode0;
wire         cacop_op_mode1;
wire         cacop_op_mode2;

wire         chosen_way;
wire         replace_way;
wire         cacop_op_mode2_hit_wr;
wire         cacop_op_mode2_no_hit;

reg          lookup_way0_hit_buffer;
reg          lookup_way1_hit_buffer;

wire [ 3:0]  real_offset;
wire [19:0]  real_tag   ;
wire [ 7:0]  real_index ;

wire         req_or_inst_valid ;   

localparam main_idle    = 5'b00001;
localparam main_lookup  = 5'b00010;
localparam main_replace = 5'b01000;
localparam main_refill  = 5'b10000;
localparam write_buffer_idle  = 1'b0;
localparam write_buffer_write = 1'b1; 

reg [4:0] main_state;

reg       rd_req_buffer;

wire      invalid_way;

//state machine
//main loop
always @(posedge clk) begin
    if (reset) begin
        main_state <= main_idle;

        request_buffer_op         <=  1'b0;
        request_buffer_index      <=  8'b0;
        request_buffer_tag        <= 20'b0;
        request_buffer_offset     <=  4'b0;
        request_buffer_wstrb      <=  4'b0;
        request_buffer_wdata      <= 32'b0;
        request_buffer_uncache_en <=  1'b0;

        request_buffer_cacop_op_mode <= 2'b0;
        request_buffer_icacop        <= 1'b0;

        miss_buffer_replace_way <= 1'b0;

        wr_req <= 1'b0;
    end
    else case (main_state)
        main_idle: begin
            if (req_or_inst_valid && main_idle2lookup) begin
                main_state <= main_lookup;

                request_buffer_op         <= op   ;
                request_buffer_index      <= real_index ;
                request_buffer_offset     <= real_offset;
                request_buffer_wstrb      <= wstrb;
                request_buffer_wdata      <= wdata;

                request_buffer_cacop_op_mode <= cacop_op_mode;
                request_buffer_icacop        <= icacop_op_en ;
            end
        end
        main_lookup: begin
            if (req_or_inst_valid && main_lookup2lookup) begin
                main_state <= main_lookup;

                request_buffer_op         <= op   ;
                request_buffer_index      <= real_index ;
                request_buffer_offset     <= real_offset;
                request_buffer_wstrb      <= wstrb;
                request_buffer_wdata      <= wdata;

                request_buffer_cacop_op_mode <= cacop_op_mode;
                request_buffer_icacop        <= icacop_op_en  ;
            end
            else if (tlb_excp_cancel_req) begin
                main_state <= main_idle;
            end
            else if (!cache_hit) begin
                main_state <= main_replace;

                request_buffer_tag <= real_tag;
                request_buffer_uncache_en <= (uncache_en && !request_buffer_icacop);
                miss_buffer_replace_way <= replace_way;
            end
            else begin
                main_state <= main_idle;
            end
        end
        main_replace: begin
            if (rd_rdy) begin
                main_state <= main_refill;
                miss_buffer_ret_num <= 2'b0;   //when get ret data, it will be sent to cpu directly.
            end
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

assign real_offset = icacop_op_en ? cacop_op_addr_offset : offset;
assign real_index  = icacop_op_en ? cacop_op_addr_index  : index ;

assign real_tag    = request_buffer_icacop ? cacop_op_addr_tag    : tag   ;

/*====================================main state idle=======================================*/

assign req_or_inst_valid = valid || icacop_op_en;

assign main_idle2lookup   = 1'b1;

assign icache_unbusy = main_state_is_idle;

//addr_ok logic

/*===================================main state lookup======================================*/

//tag compare
assign way0_hit  = way0_tagv_douta[0] && (real_tag == way0_tagv_douta[20:1]);   //this signal will not maintain
assign way1_hit  = way1_tagv_douta[0] && (real_tag == way1_tagv_douta[20:1]);
assign cache_hit = (way0_hit || way1_hit) && !(uncache_en || cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2);  //uncache road reuse
//when cache inst op mode2 no hit, main state machine will still go a round. implement easy.

assign main_lookup2lookup = cache_hit;

assign addr_ok = ((main_state_is_idle && main_idle2lookup) || (main_state_is_lookup && main_lookup2lookup)) && !icacop_op_en; //request can be get

//data select
assign way0_data = {way0_bank3_douta, way0_bank2_douta, way0_bank1_douta, way0_bank0_douta};
assign way1_data = {way1_bank3_douta, way1_bank2_douta, way1_bank1_douta, way1_bank0_douta};
assign way0_load_word = way0_data[request_buffer_offset[3:2]*32 +: 32];
assign way1_load_word = way1_data[request_buffer_offset[3:2]*32 +: 32];
assign load_res  = {32{way0_hit}} & way0_load_word |
                   {32{way1_hit}} & way1_load_word ;

//data_ok logic

/*====================================main state miss=======================================*/

assign invalid_way = (!way1_tagv_douta[0] || chosen_way) && way0_tagv_douta[0];  //chose invalid way first. 

assign replace_way = ((cacop_op_mode0 || cacop_op_mode1) && request_buffer_offset[0]) ||
                     (cacop_op_mode2 && way1_hit)                                     ||
                     (!request_buffer_icacop) && invalid_way;

/*==================================main state replace======================================*/

assign rd_req  = main_state_is_replace && !(cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2);

/*===================================main state refill======================================*/

assign rd_type = request_buffer_uncache_en ? 3'b10 : 3'b100;
assign rd_addr = request_buffer_uncache_en ? {request_buffer_tag, request_buffer_index, request_buffer_offset} : {request_buffer_tag, request_buffer_index, 4'b0};

//write process will not block pipeline 
assign data_ok = (main_state_is_lookup && (cache_hit || tlb_excp_cancel_req)) || 
                 (main_state_is_refill && ((ret_valid && ((miss_buffer_ret_num == request_buffer_offset[3:2]) || request_buffer_uncache_en))/* || !rd_req_buffer*/)) &&
                 !request_buffer_icacop;  //when rd_req is not set, set data_ok directly.
//rdate connect with ret_data dirctly. maintain one clock only

assign refill_data = ret_data;

assign way0_wr_en = !miss_buffer_replace_way && ret_valid;  //when rd_req is not set, ret_valid and ret_last will not be set. block will not be wr also.
assign way1_wr_en =  miss_buffer_replace_way && ret_valid;

assign cache_miss = main_state_is_refill && ret_last && !(request_buffer_uncache_en || request_buffer_icacop);

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

//cache ins control signal
assign cacop_op_mode0 = request_buffer_icacop && (request_buffer_cacop_op_mode == 2'b00);
assign cacop_op_mode1 = request_buffer_icacop && ((request_buffer_cacop_op_mode == 2'b01) || (request_buffer_cacop_op_mode == 2'b11));
assign cacop_op_mode2 = request_buffer_icacop && (request_buffer_cacop_op_mode == 2'b10);

assign cacop_op_mode2_hit_wr = cacop_op_mode2 && (lookup_way0_hit_buffer || lookup_way1_hit_buffer);
assign cacop_op_mode2_no_hit = cacop_op_mode2 && !lookup_way0_hit_buffer && !lookup_way1_hit_buffer;

always @(posedge clk) begin
    if (reset) begin
        lookup_way0_hit_buffer <= 1'b0;
        lookup_way1_hit_buffer <= 1'b0;
    end
    else if (cacop_op_mode2 && main_state_is_lookup) begin
        lookup_way0_hit_buffer <= way0_hit;
        lookup_way1_hit_buffer <= way1_hit;         //buffer way hit info
    end
end

//output
assign rdata = {32{main_state_is_lookup}} & load_res |
               {32{main_state_is_refill}} & ret_data ;

/*===============================bank addra logic==============================*/

assign bank_addra = {8{addr_ok}}                                  & real_index           |          /*lookup*/
					{8{!addr_ok}} 								  & request_buffer_index ;
                                 
assign way0_bank0_addra = bank_addra; 
assign way0_bank1_addra = bank_addra; 
assign way0_bank2_addra = bank_addra; 
assign way0_bank3_addra = bank_addra; 
assign way1_bank0_addra = bank_addra; 
assign way1_bank1_addra = bank_addra; 
assign way1_bank2_addra = bank_addra; 
assign way1_bank3_addra = bank_addra; 

/*===============================bank we logic=================================*/

assign way0_bank0_wea = {4{main_state_is_refill && 
                        (way0_wr_en && (miss_buffer_ret_num == 2'b00))}} & 4'hf;

assign way0_bank1_wea = {4{main_state_is_refill && 
                        (way0_wr_en && (miss_buffer_ret_num == 2'b01))}} & 4'hf;                    

assign way0_bank2_wea = {4{main_state_is_refill && 
                        (way0_wr_en && (miss_buffer_ret_num == 2'b10))}} & 4'hf;                      

assign way0_bank3_wea = {4{main_state_is_refill && 
                        (way0_wr_en && (miss_buffer_ret_num == 2'b11))}} & 4'hf;                       

assign way1_bank0_wea = {4{main_state_is_refill && 
                        (way1_wr_en && (miss_buffer_ret_num == 2'b00))}} & 4'hf;

assign way1_bank1_wea = {4{main_state_is_refill && 
                        (way1_wr_en && (miss_buffer_ret_num == 2'b01))}} & 4'hf;

assign way1_bank2_wea = {4{main_state_is_refill &&
                        (way1_wr_en && (miss_buffer_ret_num == 2'b10))}} & 4'hf;                   

assign way1_bank3_wea = {4{main_state_is_refill &&
                        (way1_wr_en && (miss_buffer_ret_num == 2'b11))}} & 4'hf;

/*===============================bank dina logic=================================*/

assign bank_dina = {32{main_state_is_refill}} & refill_data;             

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

assign tagv_addra = {8{addr_ok || (icacop_op_en && 
                    (main_state_is_idle || main_state_is_lookup))}} & real_index              | 
                    {8{main_state_is_replace || main_state_is_refill}} & request_buffer_index ;
                    //{8{(main_state_is_miss && wr_rdy) ||

assign way0_tagv_addra = tagv_addra;
assign way1_tagv_addra = tagv_addra;

/*===============================tagv ena logic=================================*/

assign tagv_ena = (!request_buffer_uncache_en) || main_state_is_idle || main_state_is_lookup;

assign way0_tagv_ena  = tagv_ena;
assign way1_tagv_ena  = tagv_ena;

/*===============================tagv wea logic=================================*/

assign tagv_wea_en = main_state_is_refill && ((ret_valid && ret_last) || cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2_hit_wr);

assign way0_tagv_wea = !miss_buffer_replace_way && tagv_wea_en; //wirte at last 4B
assign way1_tagv_wea =  miss_buffer_replace_way && tagv_wea_en;

/*===============================tagv dina logic=================================*/

assign tagv_dina = (cacop_op_mode0 || cacop_op_mode1 || cacop_op_mode2_hit_wr) ? 21'b0 : {request_buffer_tag, 1'b1};

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
assign main_state_is_replace = main_state == main_replace;
assign main_state_is_refill  = main_state == main_refill ;

endmodule
