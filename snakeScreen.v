`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2019 11:07:22 PM
// Design Name: 
// Module Name: snakeScreen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module snakeScreen(

    );
endmodule

module direction(
    input left, right, up, down, clk,
    output reg [1:0] direction
);
    reg [1:0] state, nextstate;
    wire [3:0] buttons;
    
    initial begin
    direction = 4'b0100;
    state = 4'b0100;
    end
    
    assign buttons = {left,right,up,down};

    always@(*) begin
        case(state)
        2'b00: //down
            case(buttons)
                4'b1000: nextstate =  2'b11;
                4'b0100: nextstate = 2'b10;
                default: nextstate = state;
            endcase
        2'b01: //up
            case(buttons)
                4'b1000: nextstate =  2'b11;
                4'b0100: nextstate = 2'b10;
                default: nextstate = state;
            endcase            
        2'b10: //right
            case(buttons)
                4'b0010: nextstate =  2'b01;
                4'b0001: nextstate = 2'b00;
                default: nextstate = state;
            endcase
        2'b11: //left
            case(buttons)
                4'b0010: nextstate =  2'b01;
                4'b0001: nextstate = 2'b00;
                default: nextstate = state;
            endcase
        endcase
    end
    
    always@(posedge clk) begin
        state = nextstate;
        direction = nextstate;
    end
    
endmodule

module movement(
inout [9:0] frontHigh, frontLow, frontLeft, frontRight, endHigh, endLow, endLeft, endRight,
input clk_5Hz, start, resume, pause, esc,
input [1:0] direction
);

reg move, reset;
reg frontHigh1, frontLow1, frontLeft1, frontRight1, endHigh1, endLow1, endLeft1, endRight1;

initial begin
frontHigh1 = 135; //block starting positions
frontLow1 = 145; 
frontLeft1 = 30; 
frontRight1 = 40; 
endHigh1 = 135;
endLow1 = 145;
endLeft1 = 0;
endRight1 = 10;

move = 1;
//reset = 1;
end

always @(posedge start)begin
    frontHigh1 = 135; //block starting positions
    frontLow1 = 145; 
    frontLeft1 = 30; 
    frontRight1 = 40; 
    endHigh1 = 135;
    endLow1 = 145;
    endLeft1 = 0;
    endRight1 = 10;
end

always@(*) begin
    case({move,esc})
        2'b00 : move = resume|start;
        2'b01 : move = start;
        2'b10 : move = ~pause|~esc;
        default : move = 0;
    endcase
end

always@(posedge clk_5Hz) begin
    if(move ==1)
    begin
        case(direction)
            2'b00: begin
                if((frontLow1+10)>= 480) begin
                    frontLow1= 479;
                    frontHigh1 = 469;
                end
                else begin 
                    frontLow1 = frontLow1+10;
                    frontHigh1 = frontHigh1+10;
                end
                endLow1 = endLow1 + 10;
                endHigh1 = endHigh1 + 10;
                end
            2'b01: begin
                if((frontHigh1-10)<= 0) begin
                    frontLow1= 9;
                    frontHigh1 = 0;
                end
                else begin 
                    frontLow1 = frontLow1-10;
                    frontHigh1 = frontHigh1-10;
                end
                endLow1 = endLow1 - 10;
                endHigh1 = endHigh1 - 10;
                end
            2'b10:begin
                if((frontRight1+10)>= 640) begin
                    frontRight1= 639;
                    frontLeft1 = 629;
                end
                else begin 
                    frontRight1 = frontRight1+10;
                    frontLeft1 = frontLeft1+10;
                end
                endLeft1 = endLeft1 + 10;
                endRight1 = endRight1 + 10;
                end
            2'b11:begin
                if((frontLeft1-10)<= 0) begin
                    frontLeft1= 0;
                    frontRight1 = 9;
                end
                else begin 
                    frontRight1 = frontRight1-10;
                    frontLeft1 = frontLeft1-10;
                end
                endLeft1 = endLeft1 - 10;
                endRight1 = endRight1 - 10;
                end
        endcase
    end    
end

assign frontHigh = frontHigh1;
assign frontLow = frontLow1;
assign frontLeft = frontLeft1;
assign frontRight =frontRight1;
assign endHigh = endHigh1;
assign endLow = endLow1;
assign endLeft = endLeft1;
assign endRight = endRight1;

endmodule

module clkdiv5Hz(
    input clk, 
    output reg clk_out
    );
    
    reg [23:0] COUNT;
    
    initial begin
    COUNT = 0;
    clk_out = 1;
    end
   
    always @(posedge clk)
    begin
        if (COUNT == 9999999) begin
        clk_out = ~clk_out;
        COUNT = 0;
        end
       
    else COUNT = COUNT + 1;
    end
endmodule
