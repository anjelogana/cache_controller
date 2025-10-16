module cache_controller_tb;

// Parameters
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH_SRAM = 8;
parameter TAG_SIZE = 8; // Define TAG_SIZE
parameter DEPTH = 8;    // Define DEPTH

// Testbench signals
reg clk;
reg rst;
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
    wire [ADDR_WIDTH_SRAM-1:0] address_cache_ctrl_sram; // Corrected array declaration

    // Instantiate the cache controller
    cache_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .Address_cpu(Address_cpu),
        .DOut_cpu(DOut_cpu),
        .wr_rd_cpu(wr_rd_cpu),
        .cs_cpu(cs_cpu),
        .rdy_cpu(rdy_cpu),
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
    // Select which test case to run (0 to 6)
    parameter integer test_case = 1; // <-- change this number to run a different test

    task display_cache;
    input integer current_time;
    input string user_text; // Added input for user text
    input integer Address_cpu; 
    input integer DOut_cpu;
    input integer wr_rd_cpu;
    begin
      $display("\n----------------------------------------------------------");
        $display("--- Cache Line at time %0d, %s ---", current_time, user_text); // Modified display statement
        $display("--- Address_cpu: %h, DOut_cpu: %h, wr_rd_cpu: %b ---", Address_cpu[ADDR_WIDTH-1:0], DOut_cpu[DATA_WIDTH-1:0], wr_rd_cpu[0]);
        $display("--- Tag %h, Index %h, Offset %h ---", Address_cpu[15:8], Address_cpu[7:5], Address_cpu[4:0]);
        for (i = 0; i < DEPTH; i = i + 1) begin
            line_val = uut.cache_line[i]; // hierarchical access
            line_tag = line_val[TAG_SIZE-1:0];
            line_dirty = line_val[TAG_SIZE];
            line_valid = line_val[TAG_SIZE+1];
          $display("Index %0d: raw=%b  Valid=%b Dirty=%b tag=%h", i, line_val, line_valid, line_dirty, line_tag);
        end
        $writememh("cache_dump_after1.hex", uut.cache_line);
    end
    endtask

integer i;
reg [TAG_SIZE+1:0] line_val;
reg line_valid, line_dirty;
reg [TAG_SIZE-1:0] line_tag;

    // Test sequence
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);

        // Initialize inputs
        rst = 1;
        Address_cpu = {ADDR_WIDTH{1'b0}}; // Correctly initialize Address_cpu with zero
        DOut_cpu = {DATA_WIDTH{1'b0}};
        wr_rd_cpu = 0;
        cs_cpu = 0;
        #10 rst = 0; // release reset

        // Run the selected test case
        case(test_case)
            0: begin
                // Test 0: Cache miss, write
                Address_cpu = 16'b1111_1111_111_00000;
                DOut_cpu = 8'hAA;
                wr_rd_cpu = 1;
                cs_cpu = 1;
                #40;
                cs_cpu = 0;

              #1000
              	display_cache($time, "WR Miss", Address_cpu, DOut_cpu, wr_rd_cpu);
              	Address_cpu = 16'b1001_1111_111_00010;
                DOut_cpu = 8'hBB;
                wr_rd_cpu = 1;
                cs_cpu = 1;
                #40;
                cs_cpu = 0;

              #2000


            display_cache($time, "WR Hit", Address_cpu, DOut_cpu, wr_rd_cpu);
              
            end
            1: begin
                // Test 0: Cache miss, read
                Address_cpu = 16'b1111_1111_111_00000;
                DOut_cpu = 8'hAA;
                wr_rd_cpu = 1;
                cs_cpu = 1;
                #40;
                cs_cpu = 0;

              #1000
              display_cache($time, "RD Miss", Address_cpu, DOut_cpu, wr_rd_cpu);
              	Address_cpu = 16'b1001_1111_111_00010;
                DOut_cpu = 8'hBB;
                wr_rd_cpu = 0;
                cs_cpu = 1;
                #40;
                cs_cpu = 0;

              #2000


              display_cache($time, "RD Hit", Address_cpu, DOut_cpu, wr_rd_cpu);                

            end
            default: begin
                $display("Invalid test case selected: %0d", test_case);
            end
        endcase

        // Finish simulation
        #50;
        $finish;
    end

endmodule
