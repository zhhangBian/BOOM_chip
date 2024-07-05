// fifo_testbench.sv
`timescale 1ns/1ps

module fifo_testbench;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter DEPTH = 4;

    // Signals
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] data_in;
    logic valid_in;
    logic ready_in;
    logic valid_out;
    logic ready_out;
    logic [DATA_WIDTH-1:0] data_out;

    // Interface instances
    handshake_if #(logic [DATA_WIDTH-1:0]) receiver_if();
    handshake_if #(logic [DATA_WIDTH-1:0]) sender_if();

    // Instantiate the FIFO module
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .receiver(receiver_if.receiver),
        .sender(sender_if.sender)
    );

    // Assigning signals to the interface
    assign receiver_if.data = data_in;
    assign receiver_if.valid = valid_in;
    assign ready_in = receiver_if.ready;

    assign sender_if.ready = ready_out;
    assign valid_out = sender_if.valid;
    assign data_out = sender_if.data;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period clock
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20; // Hold reset for 20ns
        rst_n = 1;
    end

    // Test sequence
    initial begin
        // Initial setup
        data_in = 0;
        valid_in = 0;
        ready_out = 0;

        // Wait for reset deassertion
        #30;

        // Write data into FIFO
        for (int i = 0; i < DEPTH; i++) begin
            data_in = i;
            valid_in = 1;
            @(posedge clk);
            while (!ready_in) @(posedge clk);
        end
        valid_in = 0;

        // Wait for a few cycles
        #20;

        // Read data from FIFO
        for (int i = 0; i < DEPTH; i++) begin
            ready_out = 1;
            @(posedge clk);
            while (!valid_out) @(posedge clk);
            $display("Read data: %0d", data_out);
        end
        ready_out = 0;

        // Finish the simulation
        #100;
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time: %0t, clk = %b, rst_n = %b, data_in = %0d, valid_in = %b, ready_in = %b, data_out = %0d, valid_out = %b, ready_out = %b", 
                 $time, clk, rst_n, data_in, valid_in, ready_in, data_out, valid_out, ready_out);
    end

endmodule
