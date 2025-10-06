module sdram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 2**ADDR_WIDTH,
    parameter DELAY_CYCLES = 2 // Specify the number of delay cycles
)(
    input clk,
    input rst,
    input [15:0] Address,
    input wr_rd,
    input mstrb,
    input [DATA_WIDTH-1:0] DIn,
    output reg [DATA_WIDTH-1:0] DOut
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [1:0] delay_counter; // BEGIN: Delay counter

always @(posedge clk or posedge rst) begin
    if (rst) begin
        integer i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] <= 0;                            // If rst, clear memory
        end
        DOut <= 0;                                  // Clear output register
        delay_counter <= 0;                          // Reset delay counter
    end else begin
        if (mstrb) begin
            if (delay_counter < DELAY_CYCLES) begin
                delay_counter <= delay_counter + 1; // Increment delay counter
            end else begin
                delay_counter <= 0; // Reset counter after delay
                if (wr_rd) begin
                    // Write operation
                    mem[Address] <= DIn;
                end else begin
                    // Read operation
                    DOut <= mem[Address];
                end
            end
        end
    end
end // END:

endmodule