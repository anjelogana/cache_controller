`timescale 1ns / 1ps
`include "cache_fsm.v"

module cache_controller_tb;

    // Parameters
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 8;

    // Inputs
    reg clk;
    reg rst;
    reg [ADDR_WIDTH-1:0] Address_cpu;
    reg [DATA_WIDTH-1:0] DOut_cpu;
    reg wr_rd_cpu;
    reg cs_cpu;

    // Outputs
    wire rdy_cpu;
    wire [ADDR_WIDTH-1:0] Address_sdram;
    wire wr_rd_sdram;
    wire mstrb_sdram;
    wire hit;

    // Instantiate the Unit Under Test (UUT)
    cache_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .Address_cpu(Address_cpu),
        .DOut_cpu(DOut_cpu),
        .wr_rd_cpu(wr_rd_cpu),
        .cs_cpu(cs_cpu),
        .rdy_cpu(rdy_cpu),
        .Address_sdram(Address_sdram),
        .wr_rd_sdram(wr_rd_sdram),
        .mstrb_sdram(mstrb_sdram),
        .hit(hit)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        Address_cpu = 0;
        DOut_cpu = 0;
        wr_rd_cpu = 0;
        cs_cpu = 0;

        // Wait for global reset
        #10;
        rst = 0;

        // Test Write Hit
        // Write to cache
        Address_cpu = 16'hA0B0; // Example address
        DOut_cpu = 8'hFF; // Example data
        wr_rd_cpu = 1; // Write operation
        cs_cpu = 1; // Chip select
        #10; // Wait for a clock cycle

        // Check if the write was successful
        wr_rd_cpu = 0; // Release write
        cs_cpu = 0; // Release chip select
        #10;

        // Test Read Hit
        // Read from cache
        Address_cpu = 16'hA0B0; // Same address
        wr_rd_cpu = 0; // Read operation
        cs_cpu = 1; // Chip select
        #10; // Wait for a clock cycle

        // Check if the read was successful
        cs_cpu = 0; // Release chip select
        #10;

        // Finish simulation
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | Address: %h | Data Out: %h | Hit: %b | Ready: %b", $time, Address_cpu, DOut_cpu, hit, rdy_cpu);
    end

endmodule