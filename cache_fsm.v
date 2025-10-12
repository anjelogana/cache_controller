module cache_fsm    (
    input clk,
    input rst,
    input hit,
    input wr_rd_cpu_q,
    input cs_sampled_dly,
    output reg dirty,
    output reg valid,
    output reg mux_sel,
    output reg demux_sel,
    output reg rdy,
    output reg wen_sram,
    output reg wr_rd_sdram,
    output reg [3:0] addr_offset_counter,
  output reg sticky_reg_count,
    output reg memstrb
);
    localparam [2:0] // BEGIN: Changed from typedef enum to localparam
        IDLE = 3'b000,
        WRITE_HIT = 3'b001, 			//1
        READ_HIT = 3'b010, 				//2
        MISS = 3'b011, 					//3
        KEEP_COHERANCY_DIRTY = 3'b100,	//4
        WR_MISS = 3'b101, 				//5
        RD_MISS = 3'b110; 				//6

    reg [2:0] current_state, next_state, previous_state;

    reg start_counting = 0;
	//reg sticky_reg_count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            previous_state <= IDLE;
        end else begin
            current_state <= next_state;
            previous_state <= current_state; // Track the previous state
        end
    end
    
    always @(posedge clk or posedge rst) begin
        //memstrb <= 0; // Default value
        //addr_offset_counter <= 0; //Remove This, this will reset it to 0 each time
      	sticky_reg_count <= sticky_reg_count | start_counting;
        if (rst) begin
            addr_offset_counter <= 4'b0000;
            start_counting <= 0; // Reset start_counting
          	sticky_reg_count <= 0;
            memstrb <= 0;
        end else if (sticky_reg_count == 1'b1) begin
            if (addr_offset_counter < 4'b1111 && memstrb) begin
                addr_offset_counter <= addr_offset_counter + 1;
                memstrb <= 0;
            end else if (addr_offset_counter < 4'b1111 && !memstrb) begin
                memstrb <= 1; 
            end else begin
                addr_offset_counter <= 4'b0000;
                start_counting <= 0; // Reset start_counting when max reached
              	sticky_reg_count <= 0;
                memstrb <= 0; // Reset memstrb as well
            end
        end
    end
    always @(*) begin
        // Default values for outputs
        start_counting = 0; // Default to 0 unless explicitly set
        dirty = 0;
        valid = 0;
        mux_sel = 0;
        demux_sel = 0;
        rdy = 1;
        wen_sram = 0;
        wr_rd_sdram = 0;
    
        case (current_state)
            IDLE: begin //0
                rdy = 1;
                if (hit && wr_rd_cpu_q && cs_sampled_dly) begin
                    next_state = WRITE_HIT;
                end else if (hit && !wr_rd_cpu_q && cs_sampled_dly) begin
                    next_state = READ_HIT;
                end else if (!hit && cs_sampled_dly) begin
                    next_state = MISS;
                end else begin
                    next_state = IDLE;
                end
            end
            WRITE_HIT: begin //1
              	rdy = 0;
                dirty = 1;

                mux_sel = 0;
                //demux_sel = 1; //Not Needed Just For Consistency

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
                if (!dirty && wr_rd_cpu_q)
                    next_state = WR_MISS; 
                else if (!dirty && !wr_rd_cpu_q)
                    next_state = RD_MISS;
                else
                    next_state = KEEP_COHERANCY_DIRTY;
            end
            KEEP_COHERANCY_DIRTY: begin 	//4
                if (addr_offset_counter == 4'b1111) begin
                    mux_sel = 0;
                    demux_sel = 0;

                    wen_sram = 0;
                    wr_rd_sdram = 1; //Write to main memory

                    dirty = 0;
                    valid = 0;
                    next_state = MISS;
                end else begin
                    // Trigger start_counting only when transitioning into KEEP_COHERANCY
                  if (previous_state != KEEP_COHERANCY_DIRTY) begin
                        start_counting = 1;
                    end
                end
            end
            WR_MISS: begin			//5
                if (addr_offset_counter == 4'b1111) begin
                    dirty = 1;
                    valid = 1;
                    mux_sel = 0;
                    next_state = WRITE_HIT;
                end else begin
                    // Trigger start_counting only when transitioning into WR_DIRTY
                  if (previous_state != WR_MISS) begin
                        start_counting = 1;
                    end
                    mux_sel = 1;
                end
            end
            RD_MISS: begin			//6
                if (addr_offset_counter == 4'b1111) begin
                    valid = 1;
                    next_state = WRITE_HIT;
                end else begin
                    // Trigger start_counting only when transitioning into RD_DIRTY
                  if (previous_state != RD_MISS) begin
                        start_counting = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end


endmodule