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
reg [ADDR_WIDTH-1:0] Address_cpu;
reg [DATA_WIDTH-1:0] DOut_cpu;
reg wr_rd_cpu;
reg cs_cpu;
wire din_cpu;

wire rdy_cpu;
wire [ADDR_WIDTH-1:0] Address_sdram;
reg [DATA_WIDTH-1:0] DOut_sdram;
wire [DATA_WIDTH-1:0] din_sdram;
wire wr_rd_sdram;
wire mstrb_sdram;


// Instantiate the cache_top
cache_top uut_cache_top (
    .clk(clk),
    .rst(rst),
    // CPU - Cache Interface
    .Address_cpu(Address_cpu),
    .wr_rd_cpu(wr_rd_cpu),
    .cs_cpu(cs_cpu),
    .DOut_cpu(DOut_cpu),
    .rdy_cpu(rdy_cpu),
    .din_cpu(din_cpu),

    .Address_sdram(Address_sdram),
    .DOut_sdram(DOut_sdram),
    .wr_rd_sdram(wr_rd_sdram),
    .mstrb_sdram(mstrb_sdram),
    .din_sdram(din_sdram)
);

// Clock generation
always begin
    #5 clk = ~clk;
end

parameter integer test_case = 0;

// Test sequence
initial begin
    clk = 0;
    Address_cpu = 0;
    DOut_cpu = 0;
    rst = 1;
    #40 rst = 0;

    case(test_case)
    0: begin
        Address_cpu = 16'b1001_1111_111_00010;
        DOut_cpu = 8'hBB;
        wr_rd_cpu = 1;
        cs_cpu = 1;
        #40;
        cs_cpu = 0;

        // Wait for rdy_cpu to go from 0 to 1 and back to 0
        wait(rdy_cpu == 1);
        wait(rdy_cpu == 0);

        // Change address after rdy_cpu goes back to 0
        Address_cpu = 16'b1010_0000_0000_0011; // New address
        DOut_cpu = 8'hCC;
        #40;
        cs_cpu = 1; // Assert chip select again
        #40;
        cs_cpu = 0;
    end
    1: begin
        
    end
    default: begin
        $display("Invalid test case");
        $finish;
    end
    endcase
    #100;
    $display("Finish");



end

endmodule
