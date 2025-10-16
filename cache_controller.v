//https://www.edaplayground.com/x/P7YL
`include "cache_fsm.v"

module cache_controller #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8,
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
    output reg [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram // Corrected array declaration
);

reg [TAG_SIZE-1:0] tag_add; // Corrected to single reg
reg [INDEX_SIZE-1:0] index_add; // Corrected to single reg
reg [OFFSET_SIZE-1:0] offset_add; // Corrected to single reg

reg wr_rd_cpu_q;
reg [DATA_WIDTH-1:0] DOut_cpu_q; // Corrected to single reg

reg [1:0] cs_counter = 2'b0; //Wait 4 clock cycles before capturing ADD, DOUT, WR_RD from CPUS
reg cs_sampled;
reg cs_sampled_dly;

reg [2+TAG_SIZE-1:0] cache_line [0:DEPTH-1]; //Upper Bit is valid, next bit is dirty, rest is tag

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        integer i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            cache_line[i] <= 0; // Set all cache_line entries to 0 on reset
        end
    end
end
//RD -> cache_line [index] [depth]
reg hit;
reg dirty;
reg valid;
reg valid_q; //Delay since Dirty is 1 cycle behind hit
reg [OFFSET_SIZE-1:0] addr_offset_counter; // Added declaration for addr_offset_counter
reg dirty_output;



//Counter to wait 4 clock cycles before capturing ADD, DOUT, WR_RD from CPU
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        cs_counter <= 0;
        cs_sampled <= 0;
    end else begin
        cs_sampled <= 0;
        if (cs_cpu == 1)
            cs_counter <= cs_counter + 1;
        if (cs_cpu == 0)
            cs_counter <= 0;
        else if(cs_counter == 2'b11) begin
            cs_counter <= 0;
            cs_sampled <= 1;
            // Split address into tag, index, offset
            tag_add <= Address_cpu[15:8];
            index_add <= Address_cpu[7:5];
            offset_add <= Address_cpu[4:0];
            DOut_cpu_q <= DOut_cpu;             
        end
    end
end

//Cacheline Logic
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        hit <= 0;
        cs_sampled_dly <= 0;    
        valid_q <= 0; 
    end else begin
        wr_rd_cpu_q <= wr_rd_cpu;                           //Align with inputs to FSM
        cs_sampled_dly <= cs_sampled;                       //Align with inputs to FSM
        dirty <= cache_line[index_add][TAG_SIZE];           //Input to FSM
        valid_q <= valid;                                 //Delay since Dirty is 1 cycle behind hit (Update Cacheline Value)
        if (cs_sampled && (cache_line[index_add][TAG_SIZE-1:0] == tag_add && dirty)) begin //If index matches tag and valid. Hit
            hit <= 1;                                           //Hit
        end else if (cs_sampled && (cache_line[index_add][TAG_SIZE-1:0] != tag_add || !dirty)) begin //MISS
            hit <= 0;
        end else if (valid_q) begin
            cache_line[index_add] <= {valid_q, dirty_output, tag_add}; // Update entire cache line after miss
        end else if (!dirty) begin
            address_cache_ctrl_sram <= {index_add,offset_add}; // Update SRAM address
        end
    end
end

//Write to cache line

cache_fsm cache_fsm_inst (
    .clk(clk),
    .rst(rst),
    .hit(hit),
    .wr_rd_cpu_q(wr_rd_cpu_q),
    .cs_sampled_dly(cs_sampled_dly),
    .dirty_input(dirty),

    //Outputs
    .dirty(dirty_output),
    .valid(valid),
    .mux_sel(mux_sel),
    .demux_sel(demux_sel),
    .rdy(rdy_cpu),
    .wen_sram(wen_sram),
    .wr_rd_sdram(wr_rd_sdram),
    .addr_offset_counter(addr_offset_counter), // Ensure this signal is connected
    .memstrb(mstrb_sdram)
);

endmodule