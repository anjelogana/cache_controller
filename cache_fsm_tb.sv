//https://www.edaplayground.com/x/acMT
module cache_fsm_tb;

    // Inputs
    reg clk;
    reg rst;
    reg hit;
    reg wr_rd_cpu_q;
  	reg cs_sampled_dly;

    // Outputs
    wire dirty;
    wire valid;
    wire mux_sel;
    wire demux_sel;
    wire rdy;
    wire wen_sram;
    wire wr_rd_sdram;
    wire [3:0] addr_offset_counter;
    wire memstrb;

    // Instantiate the cache_fsm module
    cache_fsm uut (
        .clk(clk),
        .rst(rst),
        .hit(hit),
      	.cs_sampled_dly(cs_sampled_dly),
        .wr_rd_cpu_q(wr_rd_cpu_q),
        .dirty(dirty),
        .valid(valid),
        .mux_sel(mux_sel),
        .demux_sel(demux_sel),
        .rdy(rdy),
        .wen_sram(wen_sram),
        .wr_rd_sdram(wr_rd_sdram),
        .addr_offset_counter(addr_offset_counter),
        .memstrb(memstrb)
    );

    // Clock generation: 10 time units period
    initial clk = 0;
    always #5 clk = ~clk;

    // Select which test case to run (0 to 6)
    parameter integer test_case = 2; // <-- change this number to run a different test

    // Test sequence
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);

        // Initialize inputs
        rst = 1;
        hit = 0;
        wr_rd_cpu_q = 0;
        cs_sampled_dly =0;
        #10 rst = 0; // release reset

        // Run the selected test case
        case(test_case)
            0: begin
                // Test 0: Cache hit, write
                hit = 1;
                wr_rd_cpu_q = 1;
              	cs_sampled_dly = 1;
                #10;
              	cs_sampled_dly = 0;
              	hit = 0;
            end
            1: begin
                // Test 1: Cache hit, read
                hit = 1;
                wr_rd_cpu_q = 0;
                cs_sampled_dly = 1;
                #10;
              	cs_sampled_dly = 0;
              	hit = 0;
            end
            2: begin
                // Test 2: Cache miss, dirty=0, write
                hit = 0;
                wr_rd_cpu_q = 1;
                cs_sampled_dly = 1;
                #10;
                cs_sampled_dly = 0;
              	#500;

            end
            3: begin
                // Test 3: Cache miss, dirty=0, read
                hit = 0;
                wr_rd_cpu_q = 0;
                cs_sampled_dly = 1;
                #10;
                cs_sampled_dly = 0;
            end
            4: begin
                // Test 4: Cache miss, dirty=1, write
                hit = 0;
                // force dirty = 1; // optional if you want to override
                wr_rd_cpu_q = 1;
                cs_sampled_dly = 1;
                #10;
                cs_sampled_dly = 0;
            end
            5: begin
                // Test 5: Cache miss, dirty=1, read
                hit = 0;
                // force dirty = 1; // optional if you want to override
                wr_rd_cpu_q = 0;
                cs_sampled_dly = 1;
                #10;
                cs_sampled_dly = 0;
            end
            6: begin
                // Test 6: Reset FSM
                rst = 1;
                #10;
                rst = 0;
                #10;
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
