module simu_top
#(
    `ifdef AXI128
        parameter   DATA_WIDTH = 128, 
    `elsif AXI64
        parameter   DATA_WIDTH = 64, 
    `else
        parameter   DATA_WIDTH = 32, 
    `endif


    `ifdef ADDR64
        parameter   BUS_WIDTH  = 64,
        parameter   CPU_WIDTH  = 64
    `else
        parameter   BUS_WIDTH  = 32,
        parameter   CPU_WIDTH  = 32
    `endif


)(
    input                       aclk,
    input                       aresetn, 

    //input  [  7             :0] intrpt,
    input                       enable_delay,
    input  [  22            :0] random_seed,
    // ram 
    output                      ram_ren  ,
    output [BUS_WIDTH-1     :0] ram_raddr,
    input  [DATA_WIDTH-1    :0] ram_rdata,
    output [DATA_WIDTH/8-1  :0] ram_wen  ,
    output [BUS_WIDTH-1     :0] ram_waddr,
    output [DATA_WIDTH-1    :0] ram_wdata
    // debug
    
    ,
    output [CPU_WIDTH-1     :0] debug0_wb_pc      ,
    output                      debug0_wb_rf_wen  ,
    output [  4             :0] debug0_wb_rf_wnum ,
    output [CPU_WIDTH-1     :0] debug0_wb_rf_wdata
    
    `ifdef CPU_2CMT
    ,
    output [CPU_WIDTH-1     :0] debug1_wb_pc      ,
    output                      debug1_wb_rf_wen  ,
    output [  4             :0] debug1_wb_rf_wnum ,
    output [CPU_WIDTH-1     :0] debug1_wb_rf_wdata
    `endif
    
    ,

    output [31:0] num_data,
    output        open_trace,
    output        num_monitor,       
    output [ 7:0] confreg_uart_data,
    output        write_uart_valid,

	output	   [127:0] uart_ctr_bus,

    inout             uart_rx,
    inout             uart_tx,

    output     [15:0] led,          
    output     [1 :0] led_rg0,      
    output     [1 :0] led_rg1,      
    output reg [7 :0] num_csn,      
    output reg [6 :0] num_a_g,      
    input      [7 :0] switch,       
    output     [3 :0] btn_key_col,  
    input      [3 :0] btn_key_row,  
    input      [1 :0] btn_step      


);

`ifndef RAND_TEST
assign num_data          = soc.confreg.num_data         ; 
assign open_trace        = soc.confreg.open_trace       ; 
assign num_monitor       = soc.confreg.num_monitor      ;
assign confreg_uart_data = soc.confreg.confreg_uart_data;
assign write_uart_valid  = soc.confreg.write_uart_valid ;
`endif

soc_top #(
    .BUS_WIDTH(BUS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH), 
    .CPU_WIDTH(CPU_WIDTH)
)
    soc(
    .aclk        (aclk        ),
    .aresetn     (aresetn     ), 

    //.intrpt      (intrpt      ),
    .enable_delay(enable_delay),
    .random_seed (random_seed ),
    
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
    .UART_RX             (uart_rx         ),
    .UART_TX             (uart_tx         ),

    // For confreg
    .led                 (led           ),
    .led_rg0             (led_rg0       ),
    .led_rg1             (led_rg1       ),
    .num_csn             (num_csn       ),
    .num_a_g             (num_a_g       ),
    .switch              (switch        ),
    .btn_key_col         (btn_key_col   ),
    .btn_key_row         (btn_key_row   ),
    .btn_step            (btn_step      )

);

//use for simulation
assign uart_ctr_bus = {
					   	simu_top.soc.APB_DEV.uart0.PWDATA			  ,
					   	{28'b0, simu_top.soc.APB_DEV.uart0.PADDR[3:0]},
					   	{31'b0, simu_top.soc.APB_DEV.uart0.PWRITE 	 },
						{31'b0, simu_top.soc.APB_DEV.uart0.PENABLE	 }
					   };

endmodule
