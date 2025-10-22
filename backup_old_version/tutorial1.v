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

// Block RAM signals
wire [7:0] bram_addr;
wire [7:0] bram_din, bram_dout;
wire [0:0] bram_wen;

// System signals
reg [29:0] counter;

// ChipScope components (assume black-box modules)
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

// Block RAM
bram system_bram (
    .clka(clk),
    .wea(bram_wen),
    .addra(bram_addr),
    .dina(bram_din),
    .douta(bram_dout)
);

// Selectable up/down counter
always @(posedge clk) begin
    if (switches[0])
        counter <= counter + 1;
    else
        counter <= counter - 1;
end

// Registered multiplexer for BRAM data input
reg [7:0] bram_din_reg;
always @(posedge clk) begin
    if (vio_out[17])
        bram_din_reg <= counter[7:0];
    else
        bram_din_reg <= vio_out[7:0];
end
assign bram_din = bram_din_reg;

// BRAM data out connection to led outputs
assign led = bram_dout;

// ILA data signal connections
assign ila_data[7:0]    = bram_din;
assign ila_data[15:8]   = bram_dout;
assign ila_data[23:16]  = bram_addr;
assign ila_data[31:24]  = counter[7:0];

// VIO signal connections
assign bram_addr = vio_out[15:8];
assign bram_wen[0] = vio_out[16];

// ILA trigger signal connections
assign trig0[0] = bram_wen[0];
assign trig0[7:1] = 7'b0;

endmodule
