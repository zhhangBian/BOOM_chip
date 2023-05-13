module debug_sram(
    input         clk,
    input         aresetn,

     //read req
    output  [3:0]   arid,
    output  [31:0]  araddr,
    output  [7:0]   arlen,  //0
    output  [2:0]   arsize,
    output  [1:0]   arburst,//2b'01
    output  [1:0]   arlock, //0
    output  [3:0]   arcache,//0
    output  [2:0]   arprot, //0
    output  reg     arvalid,
    input           arready,
    
    //read ack
    input   [3:0]    rid,
    input   [63:0]   rdata,
    input   [1:0]    rresp,
    input            rlast,
    input            rvalid,
    output  reg      rready,

    //解决查询内存功能和cpu核访存的冲突
    input            break_point,
    input            cpu_rready,
    output  reg      rvalid_r,
    output  reg      rid_r,
    output  reg[63:0]rdata_r,
    output  reg      rlast_r,
    output  reg      flag,        

    //uart slave
    input           infom_flag,
    input   [31:0]  start_addr,
    output          mem_flag,
    output  [ 7:0]  mem_rdata 
    
    );
assign arid       =4'd2;
assign araddr     =start_addr;
assign arlen      =1'b0;
assign arsize     =3'd0;
assign arburst    =2'b01;
assign arlock     = 1'b0;
assign arcache    = 1'b0;
assign arprot     = 1'b0;


reg       mem_flag_r;
reg[63:0] mem_rdata_r;
reg       delay;

always@(posedge clk or negedge aresetn)begin
  if(!aresetn)
    delay<=1'b1;
  else if(infom_flag)
    delay<=1'b0;
  else 
    delay<=1'b1;
end

always@(posedge clk or negedge aresetn)begin
    if(!aresetn)
      arvalid<=1'b0;
    else if(arvalid && arready)
      arvalid<=1'b0;
    else if(infom_flag && delay)
      arvalid<=1'b1;
end

always@(posedge clk or negedge aresetn)begin
    if(!aresetn)begin
      rready     <=1'b0;
      mem_flag_r <=1'b0;
      mem_rdata_r<=64'd0;
    end
    else if(arvalid && arready)
      rready<=1'b1;
    else if(rvalid && rready && rid==4'd2)begin
      rready     <=1'b0;
      mem_flag_r <=1'b1;
      mem_rdata_r<=rdata[63:0];
    end
    else begin 
      mem_flag_r <=1'b0;
      mem_rdata_r<=64'd0;
    end
end


always@(posedge clk or negedge aresetn)begin
  if(!aresetn)begin
    rvalid_r<=1'b0;
    rid_r   <=1'b0;
    rdata_r <=64'd0;
    rlast_r <=1'b0;
    flag    <=1'b0;
  end
  else if(rvalid && rid!=4'd2)begin
    rvalid_r<=rvalid;
    rid_r   <=rid;
    rdata_r <=rdata;
    rlast_r <=rlast;
    flag    <=1'b1;
    end
  else if(!break_point && cpu_rready)begin
    rvalid_r<=1'b0;
    rid_r   <=1'b0;
    rdata_r <=64'd0;
    rlast_r <=1'b0;
    flag    <=1'b0;
  end
end

assign mem_rdata=(start_addr[2:0]==3'b000)? mem_rdata_r[ 7:0] :
                 (start_addr[2:0]==3'b001)? mem_rdata_r[15:8] :
                 (start_addr[2:0]==3'b010)? mem_rdata_r[23:16]:
                 (start_addr[2:0]==3'b011)? mem_rdata_r[31:24]:
                 (start_addr[2:0]==3'b100)? mem_rdata_r[39:32]:
                 (start_addr[2:0]==3'b101)? mem_rdata_r[47:40]:
                 (start_addr[2:0]==3'b110)? mem_rdata_r[55:48]:
                                            mem_rdata_r[63:56];
assign mem_flag=mem_flag_r;

endmodule
