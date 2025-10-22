module cache_fsm    #(
parameter BLOCKSIZE_W = 5 //For easy debugging for counter, but default is 5
)(
    input clk,
    input rst,
    input hit,
    input wr_rd_cpu_q,
    input cs_sampled_dly,
  	input dirty_input, //SIMULATE DIRTY SCENARIO TO DELETE AFTER
    output reg dirty,
    output reg valid,
    output reg mux_sel,
    output reg demux_sel,
    output reg rdy,
    output reg wen_sram,
    output reg wr_rd_sdram, //Delay by 5 clk cycle to align
    output reg [BLOCKSIZE_W-1:0] addr_offset_counter, //4:0
    output reg sticky_reg_count, //DELETE, CAN BE INTERNAL?
    output reg memstrb,
	 output reg [2:0] current_state
);
    localparam [2:0] // BEGIN: Changed from typedef enum to localparam
        IDLE = 3'b000,
        WRITE_HIT = 3'b001, 			//1
        READ_HIT = 3'b010, 				//2
        MISS = 3'b011, 					//3
        KEEP_COHERANCY_DIRTY = 3'b100,	//4
        WR_MISS = 3'b101, 				//5
        RD_MISS = 3'b110, 				//6
        RST_STATE = 3'b111;			    //7

    reg [2:0] next_state, previous_state;
	 
    reg start_counting;
    reg start_counting_next;

    reg [BLOCKSIZE_W-1:0] addr_offset_counter_q, addr_offset_counter_qq;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= RST_STATE;
            previous_state <= RST_STATE;
            start_counting <= 0;
        end else begin
            current_state <= next_state;
            previous_state <= current_state; // Track the previous state
            start_counting <= start_counting_next;
        end
    end

    always @(posedge clk or posedge rst) begin
        sticky_reg_count <= sticky_reg_count | start_counting; //To Stay as 1
        addr_offset_counter_q <= addr_offset_counter;
        addr_offset_counter_qq <= addr_offset_counter_q;
        if (rst) begin
            addr_offset_counter_q <= {BLOCKSIZE_W{1'b0}};
            addr_offset_counter_qq <= {BLOCKSIZE_W{1'b0}}; //Delay since Valid will instantly turn 1 and update  cacheline before memstrb gets last value of 32 for offset
            addr_offset_counter <= {BLOCKSIZE_W{1'b0}}; // BEGIN: Use parameter for reset
            sticky_reg_count <= 0;
            memstrb <= 0;
        end else if (sticky_reg_count == 1'b1) begin
            if (addr_offset_counter < {BLOCKSIZE_W{1'b1}} && memstrb) begin
                addr_offset_counter <= addr_offset_counter + 1;
                memstrb <= 0;
            end else if ((addr_offset_counter < {BLOCKSIZE_W{1'b1}} && !memstrb) || addr_offset_counter == {BLOCKSIZE_W{1'b1}} & !memstrb) begin
                memstrb <= 1; 
            end else begin
                addr_offset_counter <= {BLOCKSIZE_W{1'b0}}; // BEGIN: Use parameter for reset
                sticky_reg_count <= 0;
                memstrb <= 0; // Reset memstrb as well
            end
        end
    end

    always @(*) begin
        // Default values for outputs
        start_counting_next = 0; // Default to 0 unless explicitly set
        dirty = 0;
        valid = 0;
        mux_sel = 0;
        demux_sel = 0;
        rdy = 0;
        wen_sram = 0;
        wr_rd_sdram = 0;
    
        case (current_state)
            IDLE: begin //0
                if (hit && wr_rd_cpu_q && cs_sampled_dly) begin
                    next_state = WRITE_HIT;
                end else if (hit && !wr_rd_cpu_q && cs_sampled_dly) begin
                    next_state = READ_HIT;
                end else if (!hit && cs_sampled_dly) begin
                    next_state = MISS;
                end else begin
                    next_state = IDLE;
                    if (previous_state != IDLE) begin // Check if we just entered IDLE
                        rdy = 1; // Set rdy to 1
                    end else begin
                        rdy = 0; // Reset rdy to 0
                    end
                end
            end
            WRITE_HIT: begin //1
              	rdy = 0;
                dirty = 1;
                mux_sel = 0;
                wen_sram = 1;
                wr_rd_sdram = 0;
                next_state = IDLE;
            end
            READ_HIT: begin 	//2
              	rdy = 0;
                mux_sel = 0;
                demux_sel = 1; //Since hit no need to interact with main memory
                wen_sram = 0;
                wr_rd_sdram = 0;
                next_state = IDLE;
            end
            MISS: begin			//3
              	rdy = 0;
                valid = 0;
              if ((!dirty_input || previous_state == KEEP_COHERANCY_DIRTY)&& wr_rd_cpu_q) 
                    next_state = WR_MISS; 
              else if ((!dirty_input || previous_state == KEEP_COHERANCY_DIRTY) && !wr_rd_cpu_q)
                    next_state = RD_MISS;
                else
                    next_state = KEEP_COHERANCY_DIRTY;
            end
            KEEP_COHERANCY_DIRTY: begin 	//4
                wr_rd_sdram = 1; //Write to main memory
                demux_sel = 0;
                wen_sram = 0;
                if (addr_offset_counter_qq == {BLOCKSIZE_W{1'b1}}) begin
                    wr_rd_sdram = 0; //Write to main memory
                    dirty = 0;
                    valid = 1; //Update Cache Line to show no more dirty
                    next_state = MISS;
                end else begin
                  if (previous_state != KEEP_COHERANCY_DIRTY) begin // Trigger start_counting only when transitioning into KEEP_COHERANCY_DIRTY
                    start_counting_next = 1;
                    wr_rd_sdram = 1; //Write to main memory
                  end
                    next_state = KEEP_COHERANCY_DIRTY;
                end
            end
            WR_MISS: begin			//5
                if (addr_offset_counter_qq == {BLOCKSIZE_W{1'b1}}) begin
                    valid = 1;
                    mux_sel = 0;
                    next_state = WRITE_HIT;
                end else begin
                  if (previous_state != WR_MISS) begin // Trigger start_counting only when transitioning into WR_DIRTY
                    start_counting_next = 1;
                  end
                    mux_sel = 1;
                    next_state = WR_MISS;
                end
            end
            RD_MISS: begin			//6
                if (addr_offset_counter_qq == {BLOCKSIZE_W{1'b1}}) begin
                    valid = 1;
                  	mux_sel = 0;
                    next_state = READ_HIT;
                end else begin
                  if (previous_state != RD_MISS) begin // Trigger start_counting only when transitioning into RD_DIRTY
                    start_counting_next = 1;
                  end
                  	mux_sel = 1;
                    next_state = RD_MISS;
                end
            end
            RST_STATE: begin // BEGIN: Implement RST_STATE
                // Reset logic here
                next_state = IDLE;
            end // END: Implement RST_STATE

            default: next_state = IDLE;
        endcase
    end
endmodule
