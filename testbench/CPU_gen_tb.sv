module CPU_gen_tb;

    // Inputs
    reg clk;
    reg rst;
    reg trig;

    // Outputs
  	wire [15:0] Address;
    wire wr_rd;
    wire cs;
  	wire [7:0] DOut;


  CPU_gen uut(
        .clk(clk),
        .rst(rst),
        .trig(trig),
    	.Address(Address),
    	.wr_rd(wr_rd),
    	.cs(cs),
    	.DOut(DOut)
    );

    // Clock generation: 10 time units period
    initial clk = 0;
    always #5 clk = ~clk;  
  	
    // Test sequence
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);

       	trig = 0;
        rst = 1; 
      	#50;
      	rst =0;
      #50;
      for (int i = 0; i < 1000; i += 10) begin
        trig = ~trig;
        #10;
      end

        // Finish simulation
        #10;
        $finish;
    end

endmodule
