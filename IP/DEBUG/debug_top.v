module debug_top(
     input           sys_clk,            
     input           sys_rst_n,          
     input           uart_rxd,
     input[31:0]     debug_wb_pc,
     input[ 4:0]     debug_wb_rf_wnum,
     input[31:0]     debug_wb_rf_wdata,
     input           ws_valid,
     output          break_point,
     output          infor_flag,
     output[ 4:0]    reg_num,
     input [31:0]    rf_rdata,
     output          infom_flag,
     output[31:0]    start_addr,
     input           mem_flag,
     input[ 7:0]     mem_rdata,   
     output          uart_txd          
     );
 
  //parameter define
parameter  CLK_FREQ = 50000000;         
parameter  UART_BPS = 9600;          
    
//wire define   
wire       uart_recv_done;              
wire [7:0] uart_recv_data;              
wire       uart_send_en;                
wire [7:0] uart_send_data;             
wire       uart_tx_busy;                


uart_recv u_uart_recv(                 
    .sys_clk        (sys_clk), 
    .sys_rst_n      (sys_rst_n),
    
    .uart_rxd       (uart_rxd),
    .uart_done      (uart_recv_done),
    .uart_data      (uart_recv_data)
    );

  
uart_send  u_uart_send(                 
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    
    .uart_en        (uart_send_en),
    .uart_din       (uart_send_data),
    .uart_tx_busy   (uart_tx_busy),
    .uart_txd       (uart_txd)
    );
    
  
trace_debug u_trace_debug(
    .sys_clk        (sys_clk),             
    .sys_rst_n      (sys_rst_n),           

    .recv_done      (uart_recv_done),   
    .recv_data      (uart_recv_data),

    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .ws_valid         (ws_valid         ),
    .break_point      (break_point      ),
    .infor_flag       (infor_flag       ),
    .reg_num          (reg_num          ),
    .rf_rdata         (rf_rdata         ),
    .infom_flag       (infom_flag       ),
    .start_addr       (start_addr       ),
    .mem_flag         (mem_flag         ),
    .mem_rdata        (mem_rdata        ),
  
    .tx_busy        (uart_tx_busy),           
    .send_en        (uart_send_en),     
    .send_data      (uart_send_data)    
    );
    
endmodule 

module uart_recv(
    input             sys_clk,                  
    input             sys_rst_n,               
     
    input             uart_rxd,                 
    output  reg       uart_done,               
    output  reg [7:0] uart_data               
    );
    
//parameter define
parameter  CLK_FREQ = 50000000;               
parameter  UART_BPS = 9600;                    
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;       
                                                
//reg define
reg        uart_rxd_d0;
reg        uart_rxd_d1;
reg        rx_flag; 
reg [15:0] clk_cnt;                
reg [ 3:0] rx_cnt;                  
reg [ 7:0] rxdata;                             

//wire define
wire       start_flag;

assign  start_flag = uart_rxd_d1 & (~uart_rxd_d0);    

always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        uart_rxd_d0 <= 1'b0;
        uart_rxd_d1 <= 1'b0;          
    end
    else begin
        uart_rxd_d0  <= uart_rxd;                   
        uart_rxd_d1  <= uart_rxd_d0;
    end   
end

  
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                                  
        rx_flag <= 1'b0;
    else begin
        if(start_flag)                          
            rx_flag <= 1'b1;                    
                                               
        else if((rx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2))
            rx_flag <= 1'b0;                   
            else
               rx_flag <= rx_flag;
    end
end


always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if ( rx_flag ) begin                   
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
      else
            clk_cnt <= 16'd0;                   
    end
    else                                            
        clk_cnt <= 16'd0;                       
end


always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        rx_cnt  <= 4'd0;
    else if ( rx_flag ) begin                   
        if (clk_cnt == BPS_CNT - 1)             
            rx_cnt <= rx_cnt + 1'b1;           
        else
            rx_cnt <= rx_cnt;       
    end
    else
        rx_cnt  <= 4'd0;                        
end


always @(posedge sys_clk or negedge sys_rst_n) begin 
    if ( !sys_rst_n)  
        rxdata <= 8'd0;                                     
    else if(rx_flag)                            
        if (clk_cnt == BPS_CNT/2) begin         
            case ( rx_cnt )
            4'd1 : rxdata[0] <= uart_rxd_d1;   
            4'd2 : rxdata[1] <= uart_rxd_d1;
            4'd3 : rxdata[2] <= uart_rxd_d1;
            4'd4 : rxdata[3] <= uart_rxd_d1;
            4'd5 : rxdata[4] <= uart_rxd_d1;
            4'd6 : rxdata[5] <= uart_rxd_d1;
            4'd7 : rxdata[6] <= uart_rxd_d1;
            4'd8 : rxdata[7] <= uart_rxd_d1;   
           default:;                                    
           endcase
       end
       else 
           rxdata <= rxdata;
    else
        rxdata <= 8'd0;
end


always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n) begin
        uart_data <= 8'd0;                               
        uart_done <= 1'b0;
    end
    else if(rx_cnt == 4'd9) begin                         
        uart_data <= rxdata;                    
        uart_done <= 1'b1;                    
    end
    else begin
        uart_data <= 8'd0;                                   
        uart_done <= 1'b0; 
    end    
end

endmodule    

module uart_send(
    input              sys_clk,             
    input              sys_rst_n,           
    input              uart_en,             
    input       [ 7:0] uart_din,            
    output             uart_tx_busy,                   
    output  reg        uart_txd                  
    );
    
//parameter define
parameter  CLK_FREQ = 50000000;             
parameter  UART_BPS = 9600;                 
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;   

//reg define
reg        uart_en_d0; 
reg        uart_en_d1;  
reg        tx_flag;
reg [15:0] clk_cnt;             
reg [ 7:0] tx_data;             
reg [ 3:0] tx_cnt; 

wire       en_flag;                            

assign uart_tx_busy = tx_flag;

assign en_flag = (~uart_en_d1) & uart_en_d0;

always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        uart_en_d0 <= 1'b0;                                  
        uart_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        uart_en_d0 <= uart_en;                               
        uart_en_d1 <= uart_en_d0;                            
    end
end


always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end 
    else if (en_flag) begin                             
            tx_flag <= 1'b1;               
            tx_data <= uart_din;           
        end
                                            
        else if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16))) begin                                       
            tx_flag <= 1'b0;                
            tx_data <= 8'd0;
        end
        else begin
            tx_flag <= tx_flag;
            tx_data <= tx_data;
        end 
end


always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if (tx_flag) begin                
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;               
    end
    else                             
        clk_cnt <= 16'd0;                   
end


always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        tx_cnt <= 4'd0;
    else if (tx_flag) begin                 
        if (clk_cnt == BPS_CNT - 1)         
            tx_cnt <= tx_cnt + 1'b1;        
        else
            tx_cnt <= tx_cnt;       
    end
    else                              
        tx_cnt  <= 4'd0;                    
end


always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n)  
        uart_txd <= 1'b1;        
    else if (tx_flag)
       case(tx_cnt)
           4'd0: uart_txd <= 1'b0;        
           4'd1: uart_txd <= tx_data[0];   
           4'd2: uart_txd <= tx_data[1];
           4'd3: uart_txd <= tx_data[2];
           4'd4: uart_txd <= tx_data[3];
           4'd5: uart_txd <= tx_data[4];
           4'd6: uart_txd <= tx_data[5];
           4'd7: uart_txd <= tx_data[6];
           4'd8: uart_txd <= tx_data[7];   
           4'd9: uart_txd <= 1'b1;         
           default: ;
     endcase
    else 
        uart_txd <= 1'b1;                   
end

endmodule             


/*...........................................................Debug module........................................*/
module trace_debug(
     input            sys_clk,                   
     input            sys_rst_n,                
     
     input            recv_done,                 
     input[7:0]       recv_data,

     input[31:0]      debug_wb_pc,
     input[ 4:0]      debug_wb_rf_wnum,
     input[31:0]      debug_wb_rf_wdata,
     input            ws_valid,
     output           break_point,
     output           infor_flag,
     output[ 4:0]     reg_num, 
     input [31:0]     rf_rdata,

     output           infom_flag,
     output[31:0]     start_addr,
     input            mem_flag,
     input[ 7:0]      mem_rdata,

     input            tx_busy,                      
     output reg       send_en,                   
     output reg [7:0] send_data                  
    );

//reg define
reg recv_done_d0;
reg recv_done_d1;

//wire define
wire recv_done_flag;

assign recv_done_flag = (~recv_done_d1) & recv_done_d0;
                                                
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        recv_done_d0 <= 1'b0;                                  
        recv_done_d1 <= 1'b0;
    end                                                      
    else begin                                               
        recv_done_d0 <= recv_done;                               
        recv_done_d1 <= recv_done_d0;                            
    end
end


//receive
reg[31:0] break_pc;
reg[ 4:0] recv_state;
reg       break_flag;
reg       infor_flag_r;
reg[ 7:0] reg_num_r;
reg       infom_flag_r;
reg[31:0] start_addr_r;
reg       step_flag;
reg[31:0] step_pc;
reg[31:0] trace_pc;
reg       trace_flag;
reg       list_flag;
always@(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin  
        recv_state  <=5'd0;
        break_flag  <=1'b0;
        break_pc    <=32'd0;
        infor_flag_r<=1'b0;
        reg_num_r   <=8'd0;
        infom_flag_r<=1'b0;
        start_addr_r<=32'd0;
        step_flag   <=1'b0;
        step_pc     <=32'd0;
        trace_pc    <=32'd0;
        trace_flag  <=1'b0;
        list_flag   <=1'b0;
    end
    else begin
        case(recv_state)
        5'd00:begin
            if(recv_done_flag && recv_data==8'd01)begin          //trace
                recv_state<=5'd22;
                trace_flag<=1'b1;  
            end
            if(recv_done_flag && recv_data==8'd02)begin          //break_point
                recv_state<=recv_state+1'b1;
                break_flag<=1'b1;
                step_flag <=1'b0;
                trace_flag<=1'b0;   
            end
            else if(recv_done_flag && recv_data==8'd03)begin    //continue
                recv_state  <=5'd09;
                break_flag  <=1'b0;
                step_flag   <=1'b0;
            end
            else if(recv_done_flag && recv_data==8'd04)begin    //infor
                recv_state<=5'd10;
            end
            else if(recv_done_flag && recv_data==8'd05)begin    //infom
                recv_state<=5'd13;
            end
            else if(recv_done_flag && recv_data==8'd06)begin    //step
                recv_state<=5'd09;
                step_flag <=1'b1;
                break_flag<=1'b0;
                step_pc   <=debug_wb_pc;
            end
            else if(recv_done_flag && recv_data==8'd07)begin   //list
                recv_state<=5'd30;
                list_flag <=1'b1;
            end
        end
        //receive break_point
        5'd01:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd02:begin
            if(recv_done_flag)begin
                break_pc[31:24]<=recv_data;
                recv_state     <=recv_state+1'b1;
            end
        end
        5'd03:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd04:begin
            if(recv_done_flag)begin
                break_pc[23:16]<=recv_data;
                recv_state     <=recv_state+1'b1;
            end
        end
        5'd05:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd06:begin
            if(recv_done_flag)begin
                break_pc[15:8]<=recv_data;
                recv_state    <=recv_state+1'b1;
            end
        end
        5'd07:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd08:begin
            if(recv_done_flag)begin
                break_pc[7:0]<=recv_data;
                recv_state   <=recv_state+1'b1;
            end
        end
        5'd09:if(!recv_done_flag)
                recv_state  <=5'd0;

        //receive reg_num 
        5'd10:if(!recv_done_flag)
                recv_state  <=recv_state+1'b1;
        5'd11:begin
            if(recv_done_flag)begin
                infor_flag_r<=1'b1;
                reg_num_r   <=recv_data;
                recv_state  <=recv_state+1'b1;
            end
        end
        5'd12:begin
            infor_flag_r<=1'b0;
            recv_state  <=5'd09;
        end

        //receive mem_addr
        5'd13:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd14:begin
            if(recv_done_flag)begin
                start_addr_r[31:24]<=recv_data;
                recv_state         <=recv_state+1'b1;
            end
        end
        5'd15:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd16:begin
            if(recv_done_flag)begin
                start_addr_r[23:16]<=recv_data;
                recv_state         <=recv_state+1'b1;
            end 
        end
        5'd17:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd18:begin
            if(recv_done_flag)begin
                start_addr_r[15:8]<=recv_data;
                recv_state        <=recv_state+1'b1;
            end
        end
        5'd19:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd20:begin
            if(recv_done_flag)begin
                infom_flag_r   <=1'b1;
                start_addr_r[7:0]<=recv_data;
                recv_state       <=recv_state+1'b1;
            end
        end
        5'd21:begin
            if(mem_flag)begin
                infom_flag_r<=1'b0;
                recv_state  <=5'd09;
            end
        end
        
        5'd22:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd23:begin
            if(recv_done_flag)begin
                trace_pc[31:24]<=recv_data;
                recv_state    <=recv_state+1'b1;
            end
        end
        5'd24:if(!recv_done_flag)
                recv_state    <=recv_state+1'b1;
        5'd25:begin
            if(recv_done_flag)begin
                trace_pc[23:16]<=recv_data;
                recv_state    <=recv_state+1'b1;
            end
        end
        5'd26:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd27:begin
            if(recv_done_flag)begin
                trace_pc[15:8]<=recv_data;
                recv_state   <=recv_state+1'b1;
            end
        end
        5'd28:if(!recv_done_flag)
                recv_state   <=recv_state+1'b1;
        5'd29:begin
            if(recv_done_flag)begin
                trace_pc[7:0]<=recv_data;
                recv_state  <=5'd09;
            end
        end
        5'd30:begin
            list_flag <=1'b0;
            recv_state<=5'd0;
        end
        default:;
        endcase
    end
end


//break_point and step processing
assign break_point=((break_pc==debug_wb_pc && ws_valid && break_flag) || (step_pc!=debug_wb_pc && step_flag))? 1'b1:1'b0; 
//infor processing
assign infor_flag=infor_flag_r;
assign reg_num=reg_num_r[4:0];
//infom processing
assign infom_flag=infom_flag_r;
assign start_addr=start_addr_r;


//send
reg a_flag;
reg send_flag;
reg[ 5:0] send_state;
reg[31:0] rf_rdata_r;
reg[ 7:0] mem_rdata_r;
reg[ 4:0] wnum_r;
reg[31:0] wdata_r;
reg[31:0] list_pc_r;

always@(posedge sys_clk or negedge sys_rst_n) begin         
      if (!sys_rst_n) begin
          send_en   <= 1'b0;
          send_data <= 8'd0;
          send_flag <= 1'b0;
          a_flag    <= 1'b0;
          send_state<= 6'd0;
      end                                                      
      else if(infor_flag)begin 
               send_flag <= 1'b1;
               send_state<= 6'd0;
               rf_rdata_r<= rf_rdata;                                                        
          end
      else if(infom_flag && mem_flag)begin
               send_flag  <=1'b1;
               send_state <=6'd20;
               mem_rdata_r<=mem_rdata;
      end
      else if(trace_pc==debug_wb_pc && trace_flag && !a_flag)begin 
               send_flag <= 1'b1;
               a_flag    <= 1'b1;
               send_state<= 6'd25;
               wnum_r    <= debug_wb_rf_wnum;
               wdata_r   <= debug_wb_rf_wdata;                                                          
          end
      else if(list_flag)begin
               send_flag<=1'b1;
               send_state<=6'd50;
               list_pc_r<=debug_wb_pc;
      end
      else if(send_flag)begin
        case(send_state)
        6'd00:begin
            if(~tx_busy)begin
              send_en   <= 1'b1;
              send_data <= rf_rdata_r[31:24];
              send_state<=send_state+1'b1;
            end
      end
        6'd04:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd05:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=rf_rdata_r[23:16];
                send_state<=send_state+1'b1;   
            end
        end
        6'd09:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd10:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=rf_rdata_r[15:8];
                send_state<=send_state+1'b1;   
            end
        end
        6'd14:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end 
        6'd15:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=rf_rdata_r[7:0];
                send_state<=send_state+1'b1;   
            end
        end
        6'd19:begin
                send_en   <= 1'b0;
                send_flag <= 1'b0;
                send_state<= 6'd0;
        end


        6'd20:begin
            if(~tx_busy)begin
              send_en   <= 1'b1;
              send_data <= mem_rdata_r;
              send_state<=send_state+1'b1;
            end
      end
        6'd24:begin
                send_en   <= 1'b0;
                send_flag <= 1'b0;
                send_state<= 5'd0;
        end
        

        6'd25:begin
            if(~tx_busy)begin
              send_en   <= 1'b1;
              send_data <={3'd0,wnum_r};
              send_state<=send_state+1'b1;
            end
      end
        6'd29:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd30:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=wdata_r[31:24];
                send_state<=send_state+1'b1;   
            end
        end
        6'd34:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd35:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=wdata_r[23:16];
                send_state<=send_state+1'b1;   
            end
        end
        6'd39:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end 
        6'd40:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=wdata_r[15:8];
                send_state<=send_state+1'b1;   
            end
        end
        6'd44:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end 
        6'd45:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=wdata_r[7:0];
                send_state<=send_state+1'b1;   
            end
        end
        6'd49:begin
            if(recv_state==5'd10 || recv_state==5'd13 || recv_state==5'd29)begin
                send_en   <= 1'b0;
                send_flag <= 1'b0;
                a_flag    <= 1'b0;
                send_state<= 6'd0;
            end
        end


        6'd50:begin
            if(~tx_busy)begin
              send_en   <= 1'b1;
              send_data <= list_pc_r[31:24];
              send_state<=send_state+1'b1;
            end
      end
        6'd52:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd53:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=list_pc_r[23:16];
                send_state<=send_state+1'b1;   
            end
        end
        6'd55:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end
        6'd56:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=list_pc_r[15:8];
                send_state<=send_state+1'b1;   
            end
        end
        6'd58:begin
                send_en   <= 1'b0;
                send_state<= send_state+1'b1;
        end 
        6'd59:begin
            if(~tx_busy)begin
                send_en   <= 1'b1;
                send_data <=list_pc_r[7:0];
                send_state<=send_state+1'b1;   
            end
        end
        6'd61:begin
                send_en   <= 1'b0;
                send_flag <= 1'b0;
                send_state<= 6'd0;
        end   
        default:send_state <= send_state+1'b1;
        endcase
      end
end

endmodule  
