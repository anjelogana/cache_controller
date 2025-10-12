module cache_controller #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 2**ADDR_WIDTH_SRAM
    parameter TAG_SIZE = 8,
    parameter INDEX_SIZE = 3,
    parameter OFFSET_SIZE = 5
)(
    input clk,
    input rst,
    //CPU - Cache Interface
    input [ADDR_WIDTH-1:0] Address_cpu,
    input [DATA_WIDTH-1:0] DOut_cpu,
    input wr_rd_cpu,
    input cs_cpu,

    output reg rdy_cpu,
    //Cache - SDRAM Interface 
    output reg [ADDR_WIDTH-1:0] Address_sdram,
    output reg wr_rd_sdram,
    output reg mstrb_sdram,

    //Staying in Cache_top
    output reg mux_sel,
    output reg demux_sel,
    output reg wen_sram,
    output reg address_cache_ctrl_sram [ADDR_WIDTH_SRAM-1:0]

);


reg tag_add [TAG_SIZE-1:0];
reg index_add [INDEX_SIZE-1:0];
reg offset_add [OFFSET_SIZE-1:0];

reg wr_rd_cpu_q;
reg DOut_cpu_q [DATA_WIDTH-1:0];


reg cs_counter [1:0] = 2'b0; //Wait 4 clock cycles before capturing ADD, DOUT, WR_RD from CPUS
reg cs_sampled;
reg cs_sampled_dly;

reg [2+TAG_SIZE-1:0] cache_line [0:DEPTH-1]; //Upper Bit is valid, next bit is dirty, rest is tag
//RD -> cache_line [index] [depth]
reg hit;
reg dirty;
reg valid;
//Counter to wait 4 clock cycles before capturing ADD, DOUT, WR_RD from CPU
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        cs_counter <= 0;
        cs_sampled <= 0;
    end else begin
            cs_counter <= cs_counter + 1;
            if (cs_counter == 2'b11) begin
            cs_counter <= 0;
            cs_sampled <=1;
            // Split address into tag, index, offset
            tag_add <= Address_cpu[15:8];
            index_add <= Address_cpu[7:5];
            offset_add <= Address_cpu[4:0];
            DOut_cpu_q <= DOut_cpu;
            wr_rd_cpu_q <= wr_rd_cpu;
            end else begin
                cs_sampled <= 0;
            end
    end
end

//Cacheline Logic
always @ (posedge clk or posedge rst) begin
    cs_sampled_dly <= cs_sampled;
    if (rst) begin
        hit <= 0;     
    end else begin
        if (cs_sampled && (cache_line[index_add][TAG_SIZE-1:0 == tag_add] && valid)) begin
            hit <= 1; //Hit
            dirty <= cache_line[index_add][TAG_SIZE-1+1]; //Capture dirty bit
        end else if (valid) begin
            cache_line[index_add][2+TAG_SIZE-1:0] <= {valid, dirty, tag_add}; //Update tag after miss
        end else begin
            hit <= 0; //Miss
        end
    end

end

//Write to cache line

cache_fsm fsm (
    .clk(clk),
    .rst(rst),
    .hit(hit),
    .dirty(dirty),


    .cs_sampled_dly (cs_sampled_dly),
    .wr_rd_cpu_q(wr_rd_cpu_q), // from CPU to check if it's a RD or WR instruction
    .rdy_cpu(rdy_cpu),
    
    .Address_sdram(Address_sdram), // Connect Address to SDRAM
    .wr_rd_sdram(wr_rd_sdram),     // Connect write/read signal to SDRAM
    .mstrb_sdram(mstrb_sdram),     // Connect master strobe to SDRAM
    .mux_sel(mux_sel),             // Connect mux select signal
    .demux_sel(demux_sel),         // Connect demux select signal
    .wen_sram(wen_sram)            // Connect write enable to SRAM
);

endmodule