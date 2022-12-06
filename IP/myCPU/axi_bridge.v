module axi_bridge(
    input   clk,
    input   reset,

    output   reg[ 3:0] arid,
    output   reg[31:0] araddr,
    output   reg[ 7:0] arlen,
    output   reg[ 2:0] arsize,
    output      [ 1:0] arburst,
    output      [ 1:0] arlock,
    output      [ 3:0] arcache,
    output      [ 2:0] arprot,
    output   reg       arvalid,
    input              arready,

    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output   reg    rready,

    output      [ 3:0] awid,
    output   reg[31:0] awaddr,
    output   reg[ 7:0] awlen,
    output   reg[ 2:0] awsize,
    output      [ 1:0] awburst,
    output      [ 1:0] awlock,
    output      [ 3:0] awcache,
    output      [ 2:0] awprot,
    output   reg       awvalid,
    input              awready,

    output      [ 3:0] wid,
    output   reg[31:0] wdata,
    output   reg[ 3:0] wstrb,
    output   reg       wlast,
    output   reg       wvalid,
    input              wready,

    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output   reg    bready,
    //cache sign
    input            inst_rd_req     ,
    input  [ 2:0]    inst_rd_type    ,
    input  [31:0]    inst_rd_addr    ,
    output           inst_rd_rdy     ,
    output           inst_ret_valid  ,
    output           inst_ret_last   ,
    output [31:0]    inst_ret_data   ,
    input            inst_wr_req     ,
    input  [ 2:0]    inst_wr_type    ,
    input  [31:0]    inst_wr_addr    ,
    input  [ 3:0]    inst_wr_wstrb   ,
    input  [127:0]   inst_wr_data    ,
    output           inst_wr_rdy     ,

    input            data_rd_req     ,
    input  [ 2:0]    data_rd_type    ,
    input  [31:0]    data_rd_addr    ,
    output           data_rd_rdy     ,
    output           data_ret_valid  ,
    output           data_ret_last   ,
    output [31:0]    data_ret_data   ,
    input            data_wr_req     ,
    input  [ 2:0]    data_wr_type    ,
    input  [31:0]    data_wr_addr    ,
    input  [ 3:0]    data_wr_wstrb   ,
    input  [127:0]   data_wr_data    ,
    output           data_wr_rdy     ,
    output           write_buffer_empty
);

//fixed signal
assign  arburst = 2'b1;
assign  arlock  = 2'b0;
assign  arcache = 4'b0;
assign  arprot  = 3'b0;
assign  awid    = 4'b1;
assign  awburst = 2'b1;
assign  awlock  = 2'b0;
assign  awcache = 4'b0;
assign  awprot  = 3'b0;
assign  wid     = 4'b1;

assign  inst_wr_rdy = 1'b1;

localparam read_requst_empty = 1'b0;
localparam read_requst_ready = 1'b1;
localparam read_respond_empty = 1'b0;
localparam read_respond_transfer = 1'b1;
localparam write_request_empty = 3'b000;
localparam write_addr_ready = 3'b001;
localparam write_data_ready = 3'b010;
localparam write_all_ready = 3'b011;
localparam write_data_transform = 3'b100;
localparam write_data_wait = 3'b101;
localparam write_wait_b = 3'b110;

reg       read_requst_state;
reg       read_respond_state;
reg [2:0] write_requst_state;

wire      write_wait_enable;

wire         rd_requst_state_is_empty;
wire         rd_requst_can_receive;

assign rd_requst_state_is_empty = read_requst_state == read_requst_empty;

wire        data_rd_cache_line;
wire        inst_rd_cache_line;
wire [ 2:0] data_real_rd_size;
wire [ 7:0] data_real_rd_len ;
wire [ 2:0] inst_real_rd_size;
wire [ 7:0] inst_real_rd_len ;
wire        data_wr_cache_line;
wire [ 2:0] data_real_wr_size;
wire [ 7:0] data_real_wr_len ;

reg [127:0] write_buffer_data;
reg [ 2:0]  write_buffer_num;

wire        write_buffer_last;

assign write_buffer_empty = (write_buffer_num == 3'b0) && !write_wait_enable;

assign rd_requst_can_receive = rd_requst_state_is_empty && !(write_wait_enable && !(bvalid && bready));

assign data_rd_rdy = rd_requst_can_receive;
assign inst_rd_rdy = !data_rd_req && rd_requst_can_receive;

//read type must be cache line
assign data_rd_cache_line = data_rd_type == 3'b100                   ;
assign data_real_rd_size  = data_rd_cache_line ? 3'b10 : data_rd_type;
assign data_real_rd_len   = data_rd_cache_line ? 8'b11 : 8'b0        ;

assign inst_rd_cache_line = inst_rd_type == 3'b100                   ;
assign inst_real_rd_size  = inst_rd_cache_line ? 3'b10 : inst_rd_type;
assign inst_real_rd_len   = inst_rd_cache_line ? 8'b11 : 8'b0        ;

//write size can be special
assign data_wr_cache_line = data_wr_type == 3'b100;
assign data_real_wr_size  = data_wr_cache_line ? 3'b10 : data_wr_type;
assign data_real_wr_len   = data_wr_cache_line ? 8'b11 : 8'b0             ;

assign inst_ret_valid = !rid[0] && rvalid;
assign inst_ret_last  = !rid[0] && rlast;
assign inst_ret_data  = rdata;    //this signal needed buffer???
assign data_ret_valid =  rid[0] && rvalid;
assign data_ret_last  =  rid[0] && rlast;
assign data_ret_data  = rdata;

assign data_wr_rdy = (write_requst_state == write_request_empty);

assign write_buffer_last = write_buffer_num == 3'b1;

always @(posedge clk) begin
    if (reset) begin
        read_requst_state <= read_requst_empty;
        arvalid <= 1'b0;
    end
    else case (read_requst_state)
        read_requst_empty: begin
            if (data_rd_req) begin
                if (write_wait_enable) begin
                    if (bvalid && bready) begin   //when wait write back, stop send read request. easiest way.
                        read_requst_state <= read_requst_ready;
                        arid <= 4'b1;
                        araddr <= data_rd_addr;
                        arsize <= data_real_rd_size;
                        arlen  <= data_real_rd_len;
                        arvalid <= 1'b1;
                    end
                end
                else begin
                    read_requst_state <= read_requst_ready;
                    arid <= 4'b1;
                    araddr <= data_rd_addr;
                    arsize <= data_real_rd_size;
                    arlen  <= data_real_rd_len;
                    arvalid <= 1'b1;
                end
            end
            else if (inst_rd_req) begin
                if (write_wait_enable) begin
                    if (bvalid && bready) begin
                        read_requst_state <= read_requst_ready;
                        arid <= 4'b0;
                        araddr <= inst_rd_addr;
                        arsize <= inst_real_rd_size;
                        arlen  <= inst_real_rd_len;
                        arvalid <= 1'b1;
                    end
                end
                else begin
                    read_requst_state <= read_requst_ready;
                    arid <= 4'b0;
                    araddr <= inst_rd_addr;
                    arsize <= inst_real_rd_size;
                    arlen  <= inst_real_rd_len;
                    arvalid <= 1'b1;
                end
            end
        end
        read_requst_ready: begin
            if (arready && arid[0]) begin
                read_requst_state <= read_requst_empty;
                arvalid <= 1'b0;
            end
            else if (arready && !arid[0]) begin 
                read_requst_state <= read_requst_empty;
                arvalid <= 1'b0;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        read_respond_state <= read_respond_empty;
        rready <= 1'b1;
    end
    else case (read_respond_state)
        read_respond_empty: begin
            if (rvalid && rready) begin 
                read_respond_state <= read_respond_transfer;
            end
        end
        read_respond_transfer: begin
            if (rlast && rvalid) begin
                read_respond_state <= read_respond_empty;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        write_requst_state <= write_request_empty;
        awvalid <= 1'b0;
        wvalid  <= 1'b0;
        wlast   <= 1'b0;
        bready  <= 1'b0;
        
        write_buffer_num   <= 3'b0;
        write_buffer_data  <= 128'b0;
    end
    else case (write_requst_state)
        write_request_empty: begin
            if (data_wr_req) begin
                write_requst_state <= write_data_wait;
                //end
                awaddr  <= data_wr_addr;
                awsize  <= data_real_wr_size;
                awlen   <= data_real_wr_len;
                awvalid <= 1'b1;
                wdata   <= data_wr_data[31:0];  //from write 128 bit buffer
                wstrb   <= data_wr_wstrb;

                write_buffer_data <= {32'b0, data_wr_data[127:32]};

                if (data_wr_type == 3'b100) begin
                    write_buffer_num <= 3'b011;
                end
                else begin
                    write_buffer_num <= 3'b0;
                    wlast <= 1'b1;
                end
            end
        end
        write_data_wait: begin
            if (awready) begin
                write_requst_state <= write_data_transform;
                awvalid <= 1'b0;
		wvalid  <= 1'b1;
            end
        end 
        write_data_transform: begin
            if (wready) begin
                if (wlast) begin
                    write_requst_state <= write_wait_b;
                    wvalid <= 1'b0;
                    wlast <= 1'b0;
        	    bready <= 1'b1;
                end
                else begin
                    if (write_buffer_last) begin
                        wlast <= 1'b1;
                    end
                
                    write_requst_state <= write_data_transform;
    
                    wdata   <= write_buffer_data[31:0];
                    wvalid  <= 1'b1;
                    write_buffer_data <= {32'b0, write_buffer_data[127:32]};
                    write_buffer_num  <= write_buffer_num - 3'b1;
                end
            end
        end
	write_wait_b: begin
		if (bvalid && bready) begin
                    write_requst_state <= write_request_empty;
		    bready <= 1'b0;
		end
	end
        default: begin
            write_requst_state <= write_request_empty;
        end
    endcase
end

assign write_wait_enable = ~(write_requst_state == write_request_empty);

endmodule
