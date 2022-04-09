 `ifdef RAND_TEST
     `define RAND_TEST_BUS_WD 32*CPU_WIDTH + 5*32 + 2*CPU_WIDTH

     //Below is a sample for 2 commit

     `define CORE0           simu_top.soc.cpu
     `define FIX             `CORE0.cpu.cpu
     `define EXBUS           `CORE0.wb_stage
     `define EXBUS_EX        `EXBUS.excp_flush
     `define EXBUS_ERET      `EXBUS.ertn_flush     // (1bit) Please notify rand_tester when ERET is excuted
     `define EXBUS_EXCODE    `EXBUS.csr_ecode
     `define EXBUS_EPC       `EXBUS.csr_era
     `define GR_RTL          `CORE0.id_stage.u_regfile.rf
     `define CSR             `CORE0.u_csr
     `define CR_BADVADDR     `CSR.csr_badv
     `define ROQ             `CORE0.wb_stage
     `define CMTBUS_VALID0   `ROQ.real_valid 
     `define CMTBUS_CMTNUM0  {3'b0, !(`EXBUS.ws_excp || `EXBUS.ertn_flush)&&`CMTBUS_VALID0}              // (2bit) the number (range from 0 to 3) which ref result counter would increase by, for ordinary instruction (neither splitted nor merged), this value is 1
     `ifdef CPU_2CMT
     `define CMTBUS_VALID1   `ROQ.port1_submit
     `define CMTBUS_CMTNUM1  {2'b0,`ROQ.port1_submit_num}
     `endif
    

 //   `ifdef RAND_TEST
 //   `define RAND_TEST_BUS_WD 32*CPU_WIDTH + 5*32 + 2*CPU_WIDTH
 
 //   //Below is a sample for 2 commit
      
 //   `define CORE0           simu_top.soc.cpu
 //   `define FIX             `CORE0.cpu.cpu
 //   `define EXBUS           `CORE0.cpu.cpu.wb_stage
 //   `define EXBUS_EX        `EXBUS.wb_exception
 //   `define EXBUS_ERET      `EXBUS.wb_eret     // (1bit) Please notify rand_tester when ERET is excuted
 //   `define EXBUS_EXCODE    `EXBUS.wb_exccode
 //   `define EXBUS_EPC       `EXBUS.wb_epc
 //   `define GR_RTL          `FIX.registers.regs
 //   `define CSR             `CORE0.cpu.cpu.csr
 //   `define CR_BADVADDR     `CSR.badv
 //   `define ROQ             `CORE0.cpu.cpu.wb_stage
 //   `define CMTBUS_VALID0   `ROQ.port0_submit 
 //   `define CMTBUS_CMTNUM0  {2'b0,`ROQ.port0_submit_num}    // (2bit) the number (range from 0 to 3) which ref result counter would increase by, for ordinary instruction (neither splitted nor merged), this value is 1
 //   `ifdef CPU_2CMT
 //   `define CMTBUS_VALID1   `ROQ.port1_submit
 //   `define CMTBUS_CMTNUM1  {2'b0,`ROQ.port1_submit_num}
 //   `endif

   
`endif
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
    
    `ifdef RAND_TEST
    ,
    output [`RAND_TEST_BUS_WD-1:0] rand_test_bus
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

`ifdef RAND_TEST
wire        cmtbus_valid0;
wire [3:0]  cmtbus_cmtnum0;

wire [3:0] commit_num;
wire       cmt_last_split;

assign cmtbus_valid0 = `CMTBUS_VALID0;
assign cmtbus_cmtnum0 = `CMTBUS_CMTNUM0;

`ifdef CPU_2CMT
wire        cmtbus_valid1;
wire [3:0]  cmtbus_cmtnum1;
assign cmtbus_valid1 = `CMTBUS_VALID1;
assign cmtbus_cmtnum1 = `CMTBUS_CMTNUM1;
assign commit_num = cmtbus_cmtnum0 + cmtbus_cmtnum1;
assign cmt_last_split = cmtbus_valid1 ? (cmtbus_cmtnum1 == 0) :
                        cmtbus_valid0 ? (cmtbus_cmtnum0 == 0) :
                        1'b0;

`else
assign commit_num = cmtbus_cmtnum0;
assign cmt_last_split = cmtbus_valid0 ? (cmtbus_cmtnum0 == 0) :
                        1'b0;

`endif
assign rand_test_bus ={
                        {28'b0,commit_num},
                        {31'b0,cmt_last_split},
                        {`CR_BADVADDR},
                        {`EXBUS_EPC},
                        {26'b0,`EXBUS_EXCODE},
                        {31'b0,`EXBUS_ERET},
                        {31'b0,`EXBUS_EX},
                        `GR_RTL[31],`GR_RTL[30],`GR_RTL[29],`GR_RTL[28],
                        `GR_RTL[27],`GR_RTL[26],`GR_RTL[25],`GR_RTL[24],
                        `GR_RTL[23],`GR_RTL[22],`GR_RTL[21],`GR_RTL[20],
                        `GR_RTL[19],`GR_RTL[18],`GR_RTL[17],`GR_RTL[16],
                        `GR_RTL[15],`GR_RTL[14],`GR_RTL[13],`GR_RTL[12],
                        `GR_RTL[11],`GR_RTL[10],`GR_RTL[ 9],`GR_RTL[ 8],
                        `GR_RTL[ 7],`GR_RTL[ 6],`GR_RTL[ 5],`GR_RTL[ 4],
                        `GR_RTL[ 3],`GR_RTL[ 2],`GR_RTL[ 1],`GR_RTL[ 0]
                         };



`endif
endmodule
