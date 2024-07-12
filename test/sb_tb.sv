`timescale 1ns/1ps
`include "a_structure.vh"

module storebuffer_tb;

// Parameter definitions
parameter int unsigned SB_SIZE = 4;
parameter int unsigned SB_DEPTH_LEN = $clog2(SB_SIZE);

// Clock and reset signals
logic clk;
logic rst_n;
logic flush_i;

// Control signals
logic c_w_mem_i;

// Store Buffer interfaces
logic [SB_DEPTH_LEN - 1:0] sb_num;
sb_entry_t [SB_SIZE - 1:0] sb_entry_o;

handshake_if#(sb_entry_t) sb_entry_receiver();
handshake_if#(sb_entry_t) sb_entry_sender();

  // Store Buffer instance
storebuffer #(
    .SB_SIZE(SB_SIZE)
) uut (
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush_i),
    .c_w_mem_i(c_w_mem_i),
    .sb_num(sb_num),
    .sb_entry_o(sb_entry_o),
    .sb_entry_receiver(sb_entry_receiver),
    .sb_entry_sender(sb_entry_sender)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Testbench variables
sb_entry_t sb_entry_data;

// Testbench initial block
initial begin
    // Initialize signals
    rst_n = 0;
    flush_i = 0;
    c_w_mem_i = 2'b00;
    sb_entry_receiver.valid = 0;
    sb_entry_sender.ready = 0;
    sb_entry_data = '{default: 0};

    // Reset
    #10 rst_n = 1;

    // Test case 1: Push a few entries into the Store Buffer
    $display("Pushing entries into Store Buffer...");
    for (int i = 0; i < 5; i++) begin
        sb_entry_data.target_addr = i * 4;
        sb_entry_data.write_data = i * 10;
        sb_entry_data.wstrb = 4'b1111;
        sb_entry_data.valid = 1;
        sb_entry_receiver.data = sb_entry_data;
        sb_entry_receiver.valid = 1;

        //wait (sb_entry_receiver.ready);
        #10;
      //sb_entry_receiver.valid = 0;
      //wait (sb_entry_sender.ready);
    end

    // Test case 2: Commit and pop entries from the Store Buffer
    $display("Committing and popping entries from Store Buffer...");
    sb_entry_sender.ready = 0;
    c_w_mem_i = 'b1; // Commit all entries
    #10
    c_w_mem_i = 'b1;
    
    #10
    sb_entry_sender.ready = 1;
    c_w_mem_i = 'b1;
    #10;
    c_w_mem_i = 'b0;
    sb_entry_sender.ready = 0;

    // Test case 3: Flush the Store Buffer
    $display("Flushing Store Buffer...");
    flush_i = 1;
    #10 flush_i = 0;

    // Test case 4: Check Store Buffer after flush
    $display("Checking Store Buffer after flush...");
    #200
    assert(sb_num == 0) else $fatal("Store Buffer should be empty after flush.");
    
    $finish;
end

endmodule
