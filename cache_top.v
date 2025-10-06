module cache_top #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8
    parameter DEPTH = 2**ADDR_WIDTH_SRAM;
)(
    input clk,
    input rst,
    //CPU - Cache Interface
    input [ADDR_WIDTH-1:0] Address_cpu,
    input wr_rd_cpu,
    input cs_cpu,
    input [DATA_WIDTH-1:0] DOut_cpu,
    output reg din_cpu,
    output reg rdy_cpu,
    //Cache - SDRAM Interface 
    input [ADDR_WIDTH-1:0] DOut_sdram,
    output reg [15:0] Address_sdram,
    output reg wr_rd_sdram,
    output reg mstrb_sdram,
    output reg din_sdram
);

wire din_sram;
wire dout_sram;

wire address_cache_ctrl_sram [ADDR_WIDTH_SRAM-1:0];

cache_sram #(
    .ADDR_WIDTH(ADDR_WIDTH_SRAM),
    .DEPTH(DEPTH)
) cache_memory (
    .clk(clk),
    .rst(rst),
    .Address(address_cache_ctrl_sram), // Using lower 8 bits for cache addressing
    .wr_rd(wr_rd_cpu),
    .DIn(din_sram),
    .DOut(dout_sram)
);

cache_controller #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .ADDR_WIDTH_SRAM(ADDR_WIDTH_SRAM),
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) controller (
    .clk(clk),
    .rst(rst),

    //CPU - Cache Interface
    .Address_cpu(Address_cpu),
    .wr_rd_cpu(wr_rd_cpu),
    .cs_cpu(cs_cpu),
    .rdy_cpu(rdy_cpu),
    .DOut_cpu(DOut_cpu),

    //Cache - SDRAM Interface 
    .Address_sdram(Address_sdram),
    .wr_rd_sdram(wr_rd_sdram),
    .mstrb_sdram(mstrb_sdram),

    //Staying in Cache_top
    .mux_sel(mux_sel),
    .demux_sel(demux_sel),
    .wen_sram(wen_sram),
    .address_cache_ctrl_sram(address_cache_ctrl_sram)
);
//Mux
assign din_sram = (mux_sel) ? DOut_sdram : din_cpu;

//Demux
assign din_sdram = (~demux_sel) ? dout_sram : 8'bz;
assign din_cpu = (demux_sel) ? : dout_sram : 8'bz;
endmodule