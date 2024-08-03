`include "a_defines.svh" 

module axi_convert #(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Input ID field width (from AXI masters)
    parameter S_ID_WIDTH = 8,
    // Output ID field width (towards AXI slaves)
    // Additional bits required for response routing
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    // Propagate awuser signal
    parameter AWUSER_ENABLE = 0,
    // Width of awuser signal
    parameter AWUSER_WIDTH = 1,
    // Propagate wuser signal
    parameter WUSER_ENABLE = 0,
    // Width of wuser signal
    parameter WUSER_WIDTH = 1,
    // Propagate buser signal
    parameter BUSER_ENABLE = 0,
    // Width of buser signal
    parameter BUSER_WIDTH = 1,
    // Propagate aruser signal
    parameter ARUSER_ENABLE = 0,
    // Width of aruser signal
    parameter ARUSER_WIDTH = 1,
    // Propagate ruser signal
    parameter RUSER_ENABLE = 0,
    // Width of ruser signal
    parameter RUSER_WIDTH = 1,
    // Number of concurrent unique IDs for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_THREADS = {S_COUNT{32'd2}},
    // Number of concurrent operations for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_ACCEPT = {S_COUNT{32'd16}},
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    parameter M_BASE_ADDR = 0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Read connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_READ = {M_COUNT{{S_COUNT{1'b1}}}},
    // Write connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_WRITE = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd4}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AW channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AW_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface W channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_W_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface B channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_B_REG_TYPE = {S_COUNT{2'd1}},
    // Slave interface AR channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AR_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface R channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_R_REG_TYPE = {S_COUNT{2'd2}},
    // Master interface AW channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AW_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface W channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_W_REG_TYPE = {M_COUNT{2'd2}},
    // Master interface B channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_B_REG_TYPE = {M_COUNT{2'd0}},
    // Master interface AR channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AR_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface R channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_R_REG_TYPE = {M_COUNT{2'd0}}
) (
    input  wire                             clk,
    input  wire                             rst_n,

    /*
     * AXI slave interfaces
     */
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axi_awid,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [S_COUNT*8-1:0]             s_axi_awlen,
    input  wire [S_COUNT*3-1:0]             s_axi_awsize,
    input  wire [S_COUNT*2-1:0]             s_axi_awburst,
    input  wire [S_COUNT-1:0]               s_axi_awlock,
    input  wire [S_COUNT*4-1:0]             s_axi_awcache,
    input  wire [S_COUNT*3-1:0]             s_axi_awprot,
    input  wire [S_COUNT*4-1:0]             s_axi_awqos,
    input  wire [S_COUNT*AWUSER_WIDTH-1:0]  s_axi_awuser,
    input  wire [S_COUNT-1:0]               s_axi_awvalid,
    output wire [S_COUNT-1:0]               s_axi_awready,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [S_COUNT*STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire [S_COUNT-1:0]               s_axi_wlast,
    input  wire [S_COUNT*WUSER_WIDTH-1:0]   s_axi_wuser,
    input  wire [S_COUNT-1:0]               s_axi_wvalid,
    output wire [S_COUNT-1:0]               s_axi_wready,
    output wire [S_COUNT*S_ID_WIDTH-1:0]    s_axi_bid,
    output wire [S_COUNT*2-1:0]             s_axi_bresp,
    output wire [S_COUNT*BUSER_WIDTH-1:0]   s_axi_buser,
    output wire [S_COUNT-1:0]               s_axi_bvalid,
    input  wire [S_COUNT-1:0]               s_axi_bready,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axi_arid,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [S_COUNT*8-1:0]             s_axi_arlen,
    input  wire [S_COUNT*3-1:0]             s_axi_arsize,
    input  wire [S_COUNT*2-1:0]             s_axi_arburst,
    input  wire [S_COUNT-1:0]               s_axi_arlock,
    input  wire [S_COUNT*4-1:0]             s_axi_arcache,
    input  wire [S_COUNT*3-1:0]             s_axi_arprot,
    input  wire [S_COUNT*4-1:0]             s_axi_arqos,
    input  wire [S_COUNT*ARUSER_WIDTH-1:0]  s_axi_aruser,
    input  wire [S_COUNT-1:0]               s_axi_arvalid,
    output wire [S_COUNT-1:0]               s_axi_arready,
    output wire [S_COUNT*S_ID_WIDTH-1:0]    s_axi_rid,
    output wire [S_COUNT*DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [S_COUNT*2-1:0]             s_axi_rresp,
    output wire [S_COUNT-1:0]               s_axi_rlast,
    output wire [S_COUNT*RUSER_WIDTH-1:0]   s_axi_ruser,
    output wire [S_COUNT-1:0]               s_axi_rvalid,
    input  wire [S_COUNT-1:0]               s_axi_rready,

    /*
     * AXI master interfaces
     */
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axi_awid,
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axi_awaddr,
    output wire [M_COUNT*8-1:0]             m_axi_awlen,
    output wire [M_COUNT*3-1:0]             m_axi_awsize,
    output wire [M_COUNT*2-1:0]             m_axi_awburst,
    output wire [M_COUNT-1:0]               m_axi_awlock,
    output wire [M_COUNT*4-1:0]             m_axi_awcache,
    output wire [M_COUNT*3-1:0]             m_axi_awprot,
    output wire [M_COUNT*4-1:0]             m_axi_awqos,
    output wire [M_COUNT*4-1:0]             m_axi_awregion,
    output wire [M_COUNT*AWUSER_WIDTH-1:0]  m_axi_awuser,
    output wire [M_COUNT-1:0]               m_axi_awvalid,
    input  wire [M_COUNT-1:0]               m_axi_awready,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [M_COUNT*STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire [M_COUNT-1:0]               m_axi_wlast,
    output wire [M_COUNT*WUSER_WIDTH-1:0]   m_axi_wuser,
    output wire [M_COUNT-1:0]               m_axi_wvalid,
    input  wire [M_COUNT-1:0]               m_axi_wready,
    input  wire [M_COUNT*M_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [M_COUNT*2-1:0]             m_axi_bresp,
    input  wire [M_COUNT*BUSER_WIDTH-1:0]   m_axi_buser,
    input  wire [M_COUNT-1:0]               m_axi_bvalid,
    output wire [M_COUNT-1:0]               m_axi_bready,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axi_arid,
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axi_araddr,
    output wire [M_COUNT*8-1:0]             m_axi_arlen,
    output wire [M_COUNT*3-1:0]             m_axi_arsize,
    output wire [M_COUNT*2-1:0]             m_axi_arburst,
    output wire [M_COUNT-1:0]               m_axi_arlock,
    output wire [M_COUNT*4-1:0]             m_axi_arcache,
    output wire [M_COUNT*3-1:0]             m_axi_arprot,
    output wire [M_COUNT*4-1:0]             m_axi_arqos,
    output wire [M_COUNT*4-1:0]             m_axi_arregion,
    output wire [M_COUNT*ARUSER_WIDTH-1:0]  m_axi_aruser,
    output wire [M_COUNT-1:0]               m_axi_arvalid,
    input  wire [M_COUNT-1:0]               m_axi_arready,
    input  wire [M_COUNT*M_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [M_COUNT*DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [M_COUNT*2-1:0]             m_axi_rresp,
    input  wire [M_COUNT-1:0]               m_axi_rlast,
    input  wire [M_COUNT*RUSER_WIDTH-1:0]   m_axi_ruser,
    input  wire [M_COUNT-1:0]               m_axi_rvalid,
    output wire [M_COUNT-1:0]               m_axi_rready
);

assign m_axi_awid      =  s_axi_awid[S_ID_WIDTH - 1:0];
assign m_axi_awaddr    =  s_axi_awaddr[31:0];  
assign m_axi_awlen     =  s_axi_awlen[7:0];  
assign m_axi_awsize    =  s_axi_awsize[2:0];
assign m_axi_awburst   =  s_axi_awburst[1:0];
assign m_axi_awlock    =  s_axi_awlock[1:0];
assign m_axi_awcache   =  s_axi_awcache[3:0];
assign m_axi_awprot    =  s_axi_awprot[2:0];
assign m_axi_awvalid   =  s_axi_awvalid[0];
assign s_axi_awready   =  {1'b0,m_axi_awready}; 
assign m_axi_wdata     =  s_axi_wdata[31:0];
assign m_axi_wstrb     =  s_axi_wstrb[3:0];
assign m_axi_wlast     =  s_axi_wlast[0];
assign m_axi_wvalid    =  s_axi_wvalid[0];
assign s_axi_wready    =  {1'b0,m_axi_wready};
assign m_axi_bready    =  1'b1;


logic choose, choose_q;
wire  i = choose;

assign m_axi_araddr    =  s_axi_araddr[32*i+:32];          
assign m_axi_arlen     =  s_axi_arlen[i*8+:8];          
assign m_axi_arsize    =  s_axi_arsize[i*3+:3];
assign m_axi_arburst   =  s_axi_arburst[i*2+:2];
assign m_axi_arlock    =  s_axi_arlock[i*2+:2];
assign m_axi_arcache   =  s_axi_arcache[i*4+:4];
assign m_axi_arprot    =  s_axi_arprot[i*3+:3];
assign m_axi_arvalid   =  s_axi_arvalid[i];
assign s_axi_arready   =  (i) ? {m_axi_arready,1'b0} : {1'b0,m_axi_arready};
assign s_axi_rdata     =  {m_axi_rdata, m_axi_rdata};
assign s_axi_rresp     =  2'b11;
assign s_axi_rlast     =  {m_axi_rlast, m_axi_rlast};
assign s_axi_rvalid    =  (i) ? {m_axi_rvalid,1'b0} : {1'b0,m_axi_rvalid};
assign m_axi_rready    =  s_axi_rready[i];

assign m_axi_arid      = '0;
assign m_axi_awid      = '0;


typedef enum logic [3:0] {
    IDLE,
    DCACHE_RD,
    ICACHE
} fsm_state ;

fsm_state fsm_cur, fsm_next;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        fsm_cur <= IDLE;
        choose_q <= '0;
    end else begin
        fsm_cur <= fsm_next;
        choose_q <= choose;
    end
end
// if (s_axi_awvalid[0]) begin
//                 fsm_next = DCACHE_WB;
//             end else 
// DCACHE_WB: begin
//             if (s_axi_wvalid[0] & s_axi_wlast[0] & m_axi_wready) begin
//                 fsm_next = IDLE;
//             end else begin
//                 fsm_next = DCACHE_WB;
//             end
//         end

always_comb begin
    fsm_next = fsm_cur;
    choose   = '0;
    case(fsm_cur) 
        IDLE:begin
            if (s_axi_arvalid[0]) begin
                choose = '0;
                fsm_next = DCACHE_RD;
            end else if (s_axi_arvalid[1]) begin
                choose = '1;
                fsm_next = ICACHE;
            end else begin
                fsm_next = IDLE;
            end
        end 
        DCACHE_RD: begin
            if (s_axi_rready[0] & m_axi_rvalid & m_axi_rlast) begin
                fsm_next = IDLE;
            end else begin
                fsm_next = DCACHE_RD;
            end
        end
        ICACHE: begin
            if (s_axi_rready[1] & m_axi_rvalid & m_axi_rlast) begin
                choose   = '1;
                fsm_next = IDLE;
            end else begin
                choose   = '1;
                fsm_next = ICACHE;
            end
        end
    endcase
end
    
endmodule