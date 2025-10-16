module cache_sram # (
parameter ADDR_WIDTH = 8,
parameter DEPTH = 2**8// 2^ADDR_WIDTH
) (
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] Address,
    input wr_rd,
    input [ADDR_WIDTH-1:0] DIn,
    output reg [ADDR_WIDTH-1:0] DOut
);

reg [ADDR_WIDTH-1:0] mem [0:DEPTH-1];
reg hit;


always @(posedge clk or posedge rst) begin
    if (rst) begin
        integer i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] <= 0;                            //If rst, clear memory
        end
        DOut <= 0;                                  // Clear output register
    end else begin
        if (wr_rd) begin
            // Write operation
            mem[Address] <= DIn;
        end else begin
            // Read operation
            DOut <= mem[Address];
        end
    end
end


//Make logic to detect a hit

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        hit <= 0;     
    end 
end
endmodule


