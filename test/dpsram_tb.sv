`timescale 1ns/1ps

module tb_dpsram;

    // Parameters
    localparam DATA_WIDTH = 32;
    localparam DATA_DEPTH = 1024;
    localparam BYTE_SIZE  = 32;

    // Signals
    reg clk0, rst_n0, en0_i;
    reg [$clog2(DATA_DEPTH)-1:0] addr0_i;
    reg [(DATA_WIDTH/BYTE_SIZE)-1:0] we0_i;
    reg [DATA_WIDTH-1:0] wdata0_i;
    wire [DATA_WIDTH-1:0] rdata0_o;

    reg clk1, rst_n1, en1_i;
    reg [$clog2(DATA_DEPTH)-1:0] addr1_i;
    reg [(DATA_WIDTH/BYTE_SIZE)-1:0] we1_i;
    reg [DATA_WIDTH-1:0] wdata1_i;
    wire [DATA_WIDTH-1:0] rdata1_o;

    // Instantiate the DUT (Device Under Test)
    dpsram #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH),
        .BYTE_SIZE(BYTE_SIZE)
    ) dut (
        .clk0(clk0),
        .rst_n0(rst_n0),
        .addr0_i(addr0_i),
        .en0_i(en0_i),
        .we0_i(we0_i),
        .wdata0_i(wdata0_i),
        .rdata0_o(rdata0_o),
        .clk1(clk1),
        .rst_n1(rst_n1),
        .addr1_i(addr1_i),
        .en1_i(en1_i),
        .we1_i(we1_i),
        .wdata1_i(wdata1_i),
        .rdata1_o(rdata1_o)
    );

    // Clock generation
    always #5 clk0 = ~clk0;
    always #5 clk1 = ~clk1;

    // Initial block for the testbench
    initial begin
        // Initialize signals
        clk0 = 0;
        rst_n0 = 0;
        en0_i = 0;
        addr0_i = 0;
        we0_i = 0;
        wdata0_i = 0;

        clk1 = 0;
        rst_n1 = 0;
        en1_i = 0;
        addr1_i = 0;
        we1_i = 0;
        wdata1_i = 0;

        // Reset the DUT
        #20;
        rst_n0 = 1;
        rst_n1 = 1;
        #10;

        // Test write operation on port 0
        @(posedge clk0);
        en0_i = 1;
        we0_i = 1;
        addr0_i = 0;
        wdata0_i = 32'hDEADBEEF;
        @(posedge clk0);
        en0_i = 0;
        we0_i = 0;

        // Test read operation on port 0
        @(posedge clk0);
        en0_i = 1;
        we0_i = 0;
        addr0_i = 0;
        @(posedge clk0);
        en0_i = 0;
        if (rdata0_o == 32'hDEADBEEF) begin
            $display("ERROR: Expected 0xDEADBEEF, got 0x%h", rdata0_o);
        end else begin
            $display("PASS: Read correct data 0x%h from port 0", rdata0_o);
        end

        // Test write operation on port 1
        @(posedge clk1);
        en1_i = 1;
        we1_i = 1;
        addr1_i = 1;
        wdata1_i = 32'hCAFEBABE;
        @(posedge clk1);
        en1_i = 0;
        we1_i = 0;

        // Test read operation on port 1
        @(posedge clk1);
        en1_i = 1;
        we1_i = 0;
        addr1_i = 1;
        @(posedge clk1);
        en1_i = 0;
        if (rdata1_o !== 32'hCAFEBABE) begin
            $display("ERROR: Expected 0xCAFEBABE, got 0x%h", rdata1_o);
        end else begin
            $display("PASS: Read correct data 0x%h from port 1", rdata1_o);
        end

        // Finish the simulation
        $stop;
    end

endmodule
