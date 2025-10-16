//https://www.edaplayground.com/x/Usfr
module cache_tb;

// Parameters
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH_SRAM = 8;
parameter TAG_SIZE = 8; // Define TAG_SIZE
parameter DEPTH = 8;    // Define DEPTH

// Testbench signals
reg clk;
reg rst;
reg trig;
reg [ADDR_WIDTH-1:0] Address_cpu;
reg [DATA_WIDTH-1:0] DOut_cpu;
reg wr_rd_cpu;
reg cs_cpu;

wire rdy_cpu;
wire [ADDR_WIDTH-1:0] Address_sdram;
wire wr_rd_sdram;
wire mstrb_sdram;

// Staying in Cache_top
wire mux_sel;
wire demux_sel;
wire wen_sram;
wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram;


// Instantiate the CPU_gen
CPU_gen uut_cpu_gen (
    .clk(clk),
    .rst(rst),
    .trig(rdy_cpu),               // BEGIN: Connect trig to rdy_cpu
    .Address(Address_cpu),      // Connect to Address_cpu
    .wr_rd(wr_rd_cpu),         // Connect to wr_rd_cpu
    .cs(cs_cpu),               // Connect to cs_cpu
    .DOut(DOut_cpu)            // Connect to DOut_cpu
); // END: Connect trig to rdy_cpu

// Instantiate the cache_top
cache_top uut_cache_top (
    .clk(clk),
    .rst(rst),
    .Address_cpu(Address_cpu),
    .DOut_cpu(DOut_cpu),
    .wr_rd_cpu(wr_rd_cpu),
    .cs_cpu(cs_cpu),
    .rdy_cpu(rdy_cpu),         // Connect rdy_cpu to trig
    .Address_sdram(Address_sdram),
    .wr_rd_sdram(wr_rd_sdram),
    .mstrb_sdram(mstrb_sdram),
    .mux_sel(mux_sel),
    .demux_sel(demux_sel),
    .wen_sram(wen_sram),
    .address_cache_ctrl_sram(address_cache_ctrl_sram)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time units period
end
  
  
  
task display_cache;
input integer current_time;
input string user_text; // Added input for user text
input integer Address_cpu; 
input integer DOut_cpu;
input integer wr_rd_cpu;
integer i; // Declare i here
begin
  $display("\n----------------------------------------------------------");
    $display("--- Cache Line at time %0d, %s ---", current_time, user_text); // Modified display statement
    $display("--- Address_cpu: %h, DOut_cpu: %h, wr_rd_cpu: %b ---", Address_cpu[ADDR_WIDTH-1:0], DOut_cpu[DATA_WIDTH-1:0], wr_rd_cpu[0]);
    $display("--- Tag %h, Index %h, Offset %h ---", Address_cpu[15:8], Address_cpu[7:5], Address_cpu[4:0]);
    for (i = 0; i < DEPTH; i = i + 1) begin
        line_val = uut_cache_top.controller.cache_line[i]; // hierarchical access
        line_tag = line_val[TAG_SIZE-1:0];
        line_dirty = line_val[TAG_SIZE];
        line_valid = line_val[TAG_SIZE+1];
      $display("Index %0d: raw=%b  Valid=%b Dirty=%b tag=%h", i, line_val, line_valid, line_dirty, line_tag);
    end
    $writememh("cache_dump_after1.hex", uut_cache_top.controller.cache_line); // Corrected reference
end
endtask

task display_sram;
input integer current_time;
input string user_text; // Added input for user text
integer i, j; // Declare i and j here
begin
        $display("\n----------------------------------------------------------");
        $display("--- SRAM State at time %0d, %s ---", current_time, user_text); // Modified display statement
        $display("Offset: ");
  $write("---------"); // Separator for readability
        for (j = 0; j < 32; j = j + 1) begin
            $write("%02d ", j); // Display offset header with two digits
        end
        $display(""); // New line after offset header
        for (i = 0; i < DEPTH; i = i + 1) begin
            $write("Index %0d: ", i); // Display index
            for (j = 0; j < 32; j = j + 1) begin // Loop for offset 0-31
                $write("%02h ", uut_cache_top.cache_memory.mem[i][j]); // Corrected indexing to 2D access
            end
            $display(""); // New line after each index
        end
    end

endtask
reg [TAG_SIZE+1:0] line_val;
reg line_valid, line_dirty;
reg [TAG_SIZE-1:0] line_tag;

// Test sequence
initial begin
    $dumpfile("cache_dump.vcd");
    $dumpvars(0);
	rst = 1;
  	#40 rst = 0;
    
    #2000;
    display_cache($time, "Initial State", Address_cpu, DOut_cpu, wr_rd_cpu);
    display_sram($time, "Initial SRAM State");
    $finish;
end

endmodule
