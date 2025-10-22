module tutorial1 (
    input clk,
    output [7:0] led,
    input [3:0] switches
);

// ChipScope signals
wire [35:0] control0, control1;
wire [31:0] ila_data;
wire [7:0] trig0;
wire [17:0] vio_out;

// Cache signals
wire rst;
wire [31:0] Address_cpu;
wire wr_rd_cpu;
wire cs_cpu;
wire [31:0] DOut_cpu;
wire [31:0] din_cpu;
wire rdy_cpu;

wire [31:0] Dout_sdram;
wire [31:0] Address_sdram;
wire wr_rd_sdram;
wire mstrb_sdram;
wire [31:0] din_sdram;


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

cache_top cache_top_uut (
    .clk(clk),
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
    .din_sdram(din_sdram)
);


// Assign VIO outputs to cache inputs (for interactive debug)
assign rst         = vio_out[0];
assign wr_rd_cpu   = vio_out[1];
assign cs_cpu      = vio_out[2];
assign Address_cpu = vio_out[17:3]; // 15 bits for address (adjust as needed)
assign din_cpu     = 32'b0;         // Or connect more VIO bits if needed

// Assign cache outputs to ILA for monitoring
assign ila_data = {DOut_cpu[7:0], rdy_cpu, 7'b0, Dout_sdram[7:0], mstrb_sdram, wr_rd_sdram, Address_sdram[7:0]}; // Example packing
assign trig0 = {cs_cpu, wr_rd_cpu, rst, 5'b0}; // Example triggers

endmodule
