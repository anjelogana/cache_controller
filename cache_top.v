module cache_top #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 2**ADDR_WIDTH_SRAM
)(
    input clk,
    input rst,
    // CPU - Cache Interface
    input [ADDR_WIDTH-1:0] Address_cpu,
    input wr_rd_cpu,
    input cs_cpu,
    input [DATA_WIDTH-1:0] DOut_cpu,
    output wire [DATA_WIDTH-1:0] din_cpu,    // driven by assign -> wire
    output wire rdy_cpu,                     // driven by controller -> wire

    // Cache - SDRAM Interface 
    input [DATA_WIDTH-1:0] DOut_sdram,
    output wire [ADDR_WIDTH-1:0] Address_sdram, // driven in always -> reg
    output wire wr_rd_sdram,                     // if driven by controller, consider making wire and let controller drive it
    output wire mstrb_sdram,                     // same as above
	output wire [2:0] current_state,
    output wire [DATA_WIDTH-1:0] din_sdram,      // driven by assign -> wire

    //Internal signals for cache_top
    output wire mux_sel,
    output wire demux_sel,
    output wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram,
    output wire [DATA_WIDTH-1:0] din_sram,
    output wire [DATA_WIDTH-1:0] dout_sram,
    output wire wen_sram
);

    // internal nets
    // wire mux_sel;
    // wire demux_sel;
    // wire wen_sram;
    // wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram;

    // wire [DATA_WIDTH-1:0] din_sram;
    // wire [DATA_WIDTH-1:0] dout_sram;
		

    // SRAM instance (data width is DATA_WIDTH inside your SRAM IP; ensure cache_sram uses this)
    cache_sram cache_memory (
        .clka(clk),
        .rsta(rst),
        .addra(address_cache_ctrl_sram),
        .wea(wen_sram),
        .dina(din_sram),
        .douta(dout_sram)
    );

    // Controller instance
    cache_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ADDR_WIDTH_SRAM(ADDR_WIDTH_SRAM),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) controller (
        .clk(clk),
        .rst(rst),

        // CPU - Cache Interface
        .Address_cpu(Address_cpu),
        .DOut_cpu(DOut_cpu),
        .wr_rd_cpu(wr_rd_cpu),
        .cs_cpu(cs_cpu),
        .rdy_cpu(rdy_cpu),      // controller drives rdy_cpu

        // Cache - SDRAM Interface 
        .Address_sdram(Address_sdram),
        .wr_rd_sdram(wr_rd_sdram),
        .mstrb_sdram(mstrb_sdram),

        // Stays in cache_top
        .mux_sel(mux_sel),
        .demux_sel(demux_sel),
        .wen_sram(wen_sram),
        .address_cache_ctrl_sram(address_cache_ctrl_sram),
		  .current_state(current_state)
    );

    // Mux: select source for SRAM data input
    assign din_sram = (mux_sel) ? DOut_sdram : DOut_cpu;

    // Demux: drive SDRAM- and CPU-facing data outputs from cache SRAM output

    assign din_sdram = (~demux_sel) ? dout_sram : {DATA_WIDTH{1'bz}};
    assign din_cpu   = (demux_sel) ? dout_sram : {DATA_WIDTH{1'bz}};




endmodule
