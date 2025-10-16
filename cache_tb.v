`timescale 1ns/1ps

module cache_tb();

// Parameters
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH_SRAM = 8;
parameter TAG_SIZE = 8;
parameter DEPTH = 8;

// Testbench signals
reg clk;
reg rst;

wire [ADDR_WIDTH-1:0] Address_cpu;
wire [DATA_WIDTH-1:0] DOut_cpu;
wire wr_rd_cpu;
wire cs_cpu;

wire rdy_cpu;
wire [ADDR_WIDTH-1:0] Address_sdram;
wire wr_rd_sdram;
wire mstrb_sdram;

// Staying in Cache_top
wire mux_sel;
wire demux_sel;
wire wen_sram;
wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram;

// Instantiate the CPU_gen
CPU_gen uut_cpu_gen (
    .clk(clk),
    .rst(rst),
    .trig(rdy_cpu),
    .Address(Address_cpu),
    .wr_rd(wr_rd_cpu),
    .cs(cs_cpu),
    .DOut(DOut_cpu)
);

// Instantiate the cache_top
cache_top uut_cache_top (
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
    .mux_sel(mux_sel),
    .demux_sel(demux_sel),
    .wen_sram(wen_sram),
    .address_cache_ctrl_sram(address_cache_ctrl_sram)
);

// Clock generation
always begin
    #5 clk = ~clk;
end

// Test sequence
initial begin
    clk = 0;
    rst = 1;

    #40 rst = 0;

    #10000; // Run the simulation for a sufficient time
    $display("Testbench completed");



end

endmodule
