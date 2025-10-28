module tutorial1 #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 2**ADDR_WIDTH_SRAM
) (
    input clk,
    output [7:0] led,
    input [3:0] switches
);

// ChipScope signals
reg rst;

wire [7:0] trig0;
wire [255:0] ila_data;
// Cache signals
wire [31:0] Address_cpu;
wire wr_rd_cpu;
wire cs_cpu;
wire [7:0] DOut_cpu;
wire [7:0] din_cpu;
wire rdy_cpu;

wire [31:0] Dout_sdram;
wire [31:0] Address_sdram;
wire wr_rd_sdram;
wire mstrb_sdram;
wire [31:0] din_sdram;

wire [2:0] current_state;

wire [35:0] control0,control1;
wire [17:0] vio_out;
reg clk_half;


//Internal signals from cache_top
wire mux_sel;
wire demux_sel;
wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram;
wire [DATA_WIDTH-1:0] din_sram;
wire [DATA_WIDTH-1:0] dout_sram;
wire wen_sram;

// ChipScope components
icon sys_icon (
    .CONTROL0(control0),
	 .CONTROL1(control1)
);

ila sys_ila (
    .CONTROL(control0),
    .CLK(clk),
    .DATA(ila_data),
    .TRIG0(trig0)
);

vio system_vio (
	.CONTROL(control1),
	.ASYNC_OUT(vio_out)
);


// CPU_gen instantiation
CPU_gen uut_cpu_gen (
    .clk(clk_half),
    .rst(rst),
    .trig(rdy_cpu),
    .Address(Address_cpu),
    .wr_rd(wr_rd_cpu),
    .cs(cs_cpu),
    .DOut(DOut_cpu)
);

cache_top cache_top_uut (
    .clk(clk_half),
    .rst(rst),
    .Address_cpu(Address_cpu),
    .wr_rd_cpu(wr_rd_cpu),
    .cs_cpu(cs_cpu),
    .DOut_cpu(DOut_cpu),
    .din_cpu(din_cpu),
    .rdy_cpu(rdy_cpu),
    .DOut_sdram(Dout_sdram),
    .Address_sdram(Address_sdram),
    .wr_rd_sdram(wr_rd_sdram),
    .mstrb_sdram(mstrb_sdram),
    .din_sdram(din_sdram),
    .current_state(current_state),
    
    .mux_sel(mux_sel),
    .demux_sel(demux_sel),
    .address_cache_ctrl_sram(address_cache_ctrl_sram),
    .din_sram(din_sram),
    .dout_sram(dout_sram),
    .wen_sram(wen_sram)
    
);

// Assign cache outputs to ILA for monitoring (individual assignments)

assign ila_data[0]	  = clk_half;
assign ila_data[1]     = rst;                    // Reset signal

//CPU
assign ila_data[17:2] = Address_cpu[15:0];      // CPU address bus
assign ila_data[25:18] = DOut_cpu[7:0];          // CPU data output
assign ila_data[26]    = wr_rd_cpu;              // CPU write/read control
assign ila_data[27]    = cs_cpu;                 // CPU chip select

//SDRAM
assign ila_data[33:28] = Address_sdram[15:0];    // SDRAM address bus
assign ila_data[41:34] = din_sdram[7:0];         // SDRAM data input
assign ila_data[42]    = wr_rd_sdram;            // SDRAM write/read control
assign ila_data[43]    = mstrb_sdram;            // SDRAM memory strobe

//SRAM
assign ila_data[49:44] = address_cache_ctrl_sram[5:0]; // SRAM address bus
assign ila_data[57:50] = din_sram[7:0];              // SRAM data input
assign ila_data[65:58] = dout_sram[7:0];            // SRAM data output
assign ila_data[66]    = wen_sram;                 // SRAM write enable

//MUX
assign ila_data[67]    = mux_sel;                // SRAM data input select
assign ila_data[68]    = demux_sel;              // SRAM data output select

//FSM
assign ila_data[71:69]  = current_state;          // Current FSM state


// Synchronize rst with clock from VIO

always @(posedge clk) begin
    rst <= vio_out[0];
    clk_half <= ~clk_half;
end
assign trig0[0] = rst;

// Route cache output or debug signals to LEDs
assign led = {current_state, 5'b0};

endmodule