`timescale 1ns/100ps

`define CLK_PERIOD          2

`define  DATA_WIDTH 32 
`define  BUS_WIDTH  32
`define  CPU_WIDTH  32

`define CPU soc.cpu

module tb();
  reg clk;
  reg rst_b;
  reg cmt;
  reg time_count;

  initial
  begin
    clk =0;
    forever begin
      #(`CLK_PERIOD/2) clk = ~clk;
    end
  end

  reg [31:0] mem_inst_temp [262143:0];

  initial
  begin
    rst_b = 1;
    #100;
    rst_b = 0;
    #100;
    rst_b = 1;
  end
  initial
  begin
      $display("********* Read program *********");
      $readmemb("obj/inst_ram.mif", mem_inst_temp);
  end

  `ifndef NO_DUMP
  initial
  begin
      $dumpfile("test.vcd");
      $display("********* Start Dump *********");
      $dumpvars;  
  end
  `endif
  
wire [31:0] debug0_wb_pc      ;
wire        debug0_wb_rf_wen  ;
wire [ 4:0] debug0_wb_rf_wnum ;
wire [31:0] debug0_wb_rf_wdata;

wire [31:0] ram_wl;
wire [31:0] ram_rl;

wire        uart_rx;
wire        uart_tx;

wire        ram_ren  ;
wire [31:0] ram_raddr;
reg  [31:0] ram_rdata;
wire [ 3:0] ram_wen  ;
wire [31:0] ram_waddr;
wire [31:0] ram_wdata;
 
assign ram_wl = ram_waddr[19:2];
assign ram_rl = ram_raddr[19:2];

always @(posedge clk) begin
    if(ram_ren) begin
        ram_rdata <= mem_inst_temp[ram_rl];
    end
end

always @(posedge clk) begin
    if(ram_wen[0]) begin
        mem_inst_temp[ram_wl][7:0] <= ram_waddr[7:0];
    end
end

always @(posedge clk) begin
    if(ram_wen[1]) begin
        mem_inst_temp[ram_wl][15:8] <= ram_waddr[15:8];
    end
end

always @(posedge clk) begin
    if(ram_wen[2]) begin
        mem_inst_temp[ram_wl][23:16] <= ram_waddr[23:16];
    end
end

always @(posedge clk) begin
    if(ram_wen[3]) begin
        mem_inst_temp[ram_wl][31:24] <= ram_waddr[31:24];
    end
end

soc_top #(
    .BUS_WIDTH(`BUS_WIDTH),
    .DATA_WIDTH(`DATA_WIDTH), 
    .CPU_WIDTH(`CPU_WIDTH)
)
    soc(
    .aclk        (clk        ),
    .aresetn     (rst_b     ), 

    .enable_delay(1'b0),
    .random_seed (23'b0),
    
    // ram
    .sram_ren  (ram_ren  ),
    .sram_raddr(ram_raddr),
    .sram_rdata(ram_rdata),
    .sram_wen  (ram_wen  ),
    .sram_waddr(ram_waddr),
    .sram_wdata(ram_wdata)

    ,
    .debug0_wb_pc      (debug0_wb_pc      ),// O, 64 
    .debug0_wb_rf_wen  (debug0_wb_rf_wen  ),// O, 4  
    .debug0_wb_rf_wnum (debug0_wb_rf_wnum ),// O, 5  
    .debug0_wb_rf_wdata(debug0_wb_rf_wdata) // O, 64 

    `ifdef CPU_2CMT
    ,
    .debug1_wb_pc      (debug1_wb_pc      ),// O, 64 
    .debug1_wb_rf_wen  (debug1_wb_rf_wen  ),// O, 4  
    .debug1_wb_rf_wnum (debug1_wb_rf_wnum ),// O, 5  
    .debug1_wb_rf_wdata(debug1_wb_rf_wdata) // O, 64 
    `endif
    ,
    .UART_RX             (uart_rx       ),
    .UART_TX             (uart_tx       ),
    .led                 (              ),
    .led_rg0             (              ),
    .led_rg1             (              ),
    .num_csn             (              ),
    .num_a_g             (              ),
    .switch              (8'b0          ),
    .btn_key_col         (              ),
    .btn_key_row         (4'b0          ),
    .btn_step            (2'b0          )
  );

initial 
begin
forever begin
  #(`CLK_PERIOD * 10000)
  $display("running at pc %x",debug0_wb_pc);
  if(`CPU.wb_stage.ws_excp && `CPU.wb_stage.ws_excp_num[5]) begin
  	$display("************ Test Success ***************");
	$finish;
  end
end
end

endmodule
