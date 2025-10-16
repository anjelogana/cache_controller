//https://www.edaplayground.com/x/Usfr
//----------------------------------------------------------------------------------
// Company:				            Ryerson University 
// Engineer VHDL Version: 			Victor Dumitriu
// Engineer Verilog Version:        Anjelo Gana
// Design Name: 		CPU Read/Write Transaction Generator
// Module Name:		CPU_gen - Behavioral 
// Target Devices: 	XC3S500E
//
// Description: 		A testbench circuit for course COE758, Project 1.
//							The circuit plays the role of a CPU, generating read
//							and write transactions to various addresses. The Cache
//							Controller being designed for Project 1 must respond to
//							these transactions.
//
// Dependencies: 		None.
//--------------------------------------------------------------------------------
//https://www.edaplayground.com/x/H5i6
module CPU_gen (
    input clk,
    input rst,
    input trig,
    output reg [15:0] Address,
    output reg wr_rd,
    output reg cs,
    output reg [7:0] DOut
);

    // Pattern storage and control.
    reg [24:0] patOut;
    reg [2:0] patCtrl = 3'b111;
    reg updPat;

    // Main control.
    reg [2:0] st1 = 3'b000;
    reg [2:0] st1N;

    // Rising edge detection.
    reg rReg1, rReg2;
    wire trig_r;

    // Main control FSM.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            st1 <= 3'b000;
        end else begin
            st1 <= st1N;
        end
    end

    // Next state generation.
    always @(*) begin
        case (st1)
            3'b000: st1N = (trig_r) ? 3'b001 : 3'b000;
            3'b001: st1N = 3'b010;
            3'b010: st1N = 3'b011;
            3'b011: st1N = 3'b100;
            3'b100: st1N = 3'b101;
            3'b101: st1N = 3'b000;
            default: st1N = 3'b000;
        endcase
    end

    // Output generation.
    always @(*) begin
        case (st1)
            3'b000: begin
                updPat = 1'b0;
                cs = 1'b0;
            end
            3'b001: begin
                updPat = 1'b1;
                cs = 1'b0;
            end
            3'b010, 3'b011, 3'b100, 3'b101: begin
                updPat = 1'b0;
                cs = 1'b1;
            end
            default: begin
                updPat = 1'b0;
                cs = 1'b0;
            end
        endcase
    end

    // Pattern generator and control circuit.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            patCtrl <= 3'b111;
        end else if (updPat) begin
            patCtrl <= patCtrl + 3'b001;
        end
    end

    // Pattern storage.
    always @(*) begin
        case (patCtrl)
            3'b000: patOut = 25'b0001000100000000101010101;
            3'b001: patOut = 25'b0001000100000010101110111;
            3'b010: patOut = 25'b0001000100000000000000000;
            3'b011: patOut = 25'b0001000100000010000000000;
            3'b100: patOut = 25'b0011001101000110000000000;
            3'b101: patOut = 25'b0100010001000100000000000;
            3'b110: patOut = 25'b0101010100000100110011001;
            default: patOut = 25'b0110011000000110000000000;
        endcase
    end

    // Rising edge detector.
    always @(posedge clk) begin
        rReg1 <= trig;
    end

    always @(posedge clk) begin
        rReg2 <= rReg1;
    end

    assign trig_r = rReg1;

    // Output connections.
    always @(*) begin
        Address = patOut[24:9];
        DOut = patOut[8:1];
        wr_rd = patOut[0];
    end

endmodule
