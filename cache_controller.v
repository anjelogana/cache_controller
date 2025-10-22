`include "cache_fsm.v"

module cache_controller #(
    parameter ADDR_WIDTH = 16,
    parameter ADDR_WIDTH_SRAM = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8,
    parameter TAG_SIZE = 8,
    parameter INDEX_SIZE = 3,
    parameter BLOCKSIZE_W = 5,
    parameter OFFSET_SIZE = 5
)(
    input clk,
    input rst,
    //CPU - Cache Interface
    input [ADDR_WIDTH-1:0] Address_cpu,
    input [DATA_WIDTH-1:0] DOut_cpu,
    input wr_rd_cpu,
    input cs_cpu,

    output wire rdy_cpu,
    //Cache - SDRAM Interface 
    output reg [ADDR_WIDTH-1:0] Address_sdram,
    output wire wr_rd_sdram,

    output reg mstrb_sdram,
    output wire [2:0] current_state,

    //Staying in Cache_top
    output wire mux_sel,
    output wire demux_sel,
    output wire wen_sram,
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
integer i;

reg hit;
reg dirty;
wire valid;
reg valid_q; //Delay since Dirty is 1 cycle behind hit

wire [OFFSET_SIZE-1:0] addr_offset_counter; // Changed to wire
wire dirty_output;

reg [ADDR_WIDTH-1:0] Address_sdram_q; //Delay 1 Clk Cycle to Delay

wire mstrb_sdram_fsm;
reg mstrb_sdram_q; //Delay by 2 clk to allign with Memstrb updating ADD for SRAM and SDRAM


// Combined always block for cache_line and related logic
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        // Reset cache_line and other signals
        for (i = 0; i < DEPTH; i = i + 1) begin
            cache_line[i] <= 0; // Set all cache_line entries to 0 on reset
        end
        cs_counter <= 0;
        cs_sampled <= 0;
        hit <= 0;
        cs_sampled_dly <= 0;    
        valid_q <= 0; 
        Address_sdram <= {ADDR_WIDTH{1'b0}}; 
		  mstrb_sdram <= 0;
        mstrb_sdram_q <= 0;
    end else begin
        // Counter to wait 4 clock cycles before capturing ADD, DOUT, WR_RD from CPU
        cs_sampled <= 0;
        mstrb_sdram_q <= mstrb_sdram_fsm;
        mstrb_sdram <= mstrb_sdram_q;
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

        // Cacheline Logic
        wr_rd_cpu_q <= wr_rd_cpu;                           //Align with inputs to FSM
        cs_sampled_dly <= cs_sampled;                       //Align with inputs to FSM
        dirty <= cache_line[index_add][TAG_SIZE];           //Input to FSM
        valid_q <= valid;                                   //Delay since Dirty is 1 cycle behind hit (Update Cacheline Value)
        if (cs_sampled && (cache_line[index_add][TAG_SIZE-1:0] == tag_add && dirty)) begin //If index matches tag and valid. Hit
            hit <= 1;                                           //Hit
        end else if (cs_sampled && (cache_line[index_add][TAG_SIZE-1:0] != tag_add || !dirty)) begin //MISS
            hit <= 0;
        end else if (valid_q) begin
            cache_line[index_add] <= {valid_q, dirty_output, tag_add}; // Update entire cache line after miss
        end else if (mstrb_sdram_fsm && dirty) begin //Fix Coherancy SRAM to SDRAM
            // Make sure the concat widths match ADDR_WIDTH
            Address_sdram <= {cache_line[index_add][TAG_SIZE-1:0], index_add, addr_offset_counter };
            address_cache_ctrl_sram <= {index_add, addr_offset_counter};
        end else if (mstrb_sdram_fsm && !dirty) begin //SDRAM to SRAM when miss
            address_cache_ctrl_sram <= {index_add,addr_offset_counter};
            Address_sdram <= {tag_add, index_add, addr_offset_counter };
            if (addr_offset_counter == 5'b11111) 
                address_cache_ctrl_sram <= {index_add,offset_add}; //Write to SRAM
        end else if (dirty) begin //Update SRAM Address When Hit
            address_cache_ctrl_sram <= {index_add,offset_add}; // Update SRAM address when hit
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
    .addr_offset_counter(addr_offset_counter),
    .memstrb(mstrb_sdram_fsm),
    .current_state(current_state)
);

endmodule