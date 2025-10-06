module cache_fsm    (
    input clk,
    input rst,
    input hit,
    input wr_rd_cpu_q,
    output reg dirty,
    output reg valid,
    output reg mux_sel,
    output reg demux_sel,
    output reg rdy,
    output reg wen_sram,
    output reg wr_rd_sdram,
    output reg [3:0] addr_offset_counter,
    output reg memstrb
);
    localparam [2:0] // BEGIN: Changed from typedef enum to localparam
        IDLE = 3'b000,
        WRITE_HIT = 3'b001,
        READ_HIT = 3'b010,
        MISS = 3'b011,
        KEEP_COHERANCY = 3'b100,
        WR_DIRTY = 3'b101,
        RD_DIRTY = 3'b110; // END: Changed from typedef enum to localparam

    reg [2:0] current_state, next_state, previous_state;

    reg start_counting = 0;

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
        memstrb <= 0; // Default value
        addr_offset_counter <= 0;
        if (rst) begin
            addr_offset_counter <= 4'b0000;
            start_counting <= 0; // Reset start_counting
            memstrb <= 0;
        end else if (start_counting == 1'b1) begin
            if (addr_offset_counter < 4'b1111 && memstrb) begin
                addr_offset_counter <= addr_offset_counter + 1;
                memstrb <= 0;
            end else if (addr_offset_counter < 4'b1111 && !memstrb) begin
                memstrb <= 1; 
            end else begin
                addr_offset_counter <= 4'b0000;
                start_counting <= 0; // Reset start_counting when max reached
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
        rdy = 0;
        wen_sram = 0;
        wr_rd_sdram = 0;
    
        case (current_state)
            IDLE: begin
                if (hit && wr_rd_cpu_q) 
                    next_state = WRITE_HIT;
                else if (hit && !wr_rd_cpu_q)
                    next_state = MISS;
                else
                    next_state = IDLE;
            end
            WRITE_HIT: begin
                dirty = 1;

                mux_sel = 0;
                demux_sel = 1; //Not Needed Just For Consistency

                wen_sram = 1;
                wr_rd_sdram = 0;
                rdy = 1;

                next_state = IDLE;
            end
            READ_HIT: begin
                mux_sel = 0;
                demux_sel = 1; //Since hit no need to interact with main memory
                
                wen_sram = 0;
                wr_rd_sdram = 0;
                rdy = 1;

                next_state = IDLE;
            end
            MISS: begin
                if (!dirty && wr_rd_cpu_q)
                    next_state = WR_DIRTY; 
                else if (!dirty && !wr_rd_cpu_q)
                    next_state = RD_DIRTY;
                else
                    next_state = KEEP_COHERANCY;
            end
            KEEP_COHERANCY: begin //State to put data back to main memory
                if (addr_offset_counter == 4'b1111) begin
                    mux_sel = 0;
                    demux_sel = 0;

                    wen_sram = 0;
                    wr_rd_sdram = 1; //Write to main memory
                    rdy = 0;

                    dirty = 0;
                    valid = 0;
                    next_state = MISS;
                end else begin
                    // Trigger start_counting only when transitioning into KEEP_COHERANCY
                    if (previous_state != KEEP_COHERANCY) begin
                        start_counting = 1;
                    end
                end
            end
            WR_DIRTY: begin
                if (addr_offset_counter == 4'b1111) begin
                    dirty = 1;
                    valid = 1;
                    mux_sel = 0;
                    next_state = WRITE_HIT;
                end else begin
                    // Trigger start_counting only when transitioning into WR_DIRTY
                    if (previous_state != WR_DIRTY) begin
                        start_counting = 1;
                    end
                    mux_sel = 1;
                end
            end
            RD_DIRTY: begin
                if (addr_offset_counter == 4'b1111) begin
                    valid = 1;
                    next_state = WRITE_HIT;
                end else begin
                    // Trigger start_counting only when transitioning into RD_DIRTY
                    if (previous_state != RD_DIRTY) begin
                        start_counting = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end


endmodule