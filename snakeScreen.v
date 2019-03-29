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
    input clk, up, dowm, left, right, start, resume, pause, esc,
    output reg [11:0] color,
    output reg hsync, vsync
    );
    
    wire clk_5Hz, clk_25MHz, hsig, vsig, visible, newBlock, eraseBlock;
    wire [9:0] hcount, vcount, frontHigh, frontLow, frontLeft, frontRight, endHigh, endLow, endLeft, endRight;
    wire [11:0] RBG;
    
    clkdiv5Hz c0(clk,clk_5Hz);
    clkdiv25MHz c1 (clk, clk_25MHz);
    signals s0 (clk_25MHz, hsig, vsig, visible, hcount, vcount);
    drawBlock d0 (hcount, vcount, frontHigh, frontLow, frontLeft, frontRight, visible, clk_5Hz, newBlock);
    drawBlock d1 (hcount, vcount, endHigh, endLow, endLeft, endRight, visible, clk_5Hz, eraseBlock);
    color c3 (clk_25MHz, newBlock, eraseBlock, RBG);
    
    always @(posedge clk)begin
    hsync <= hsig;
    vsync <= vsig;
    color <= RBG;
   end
    
endmodule

module color(
    input clk_25MHz,
    input newBlock,
    input eraseBlock,
    output reg [11:0] color
);
wire [1:0] choice;
 assign choice = {newBlock,eraseBlock};

    always@(*) begin
        case(choice)
        2'b00: color = {4'hF,4'hF,4'hF}; //white
        2'b10: color = {4'h0,4'h0,4'hF}; //blue
        2'b01: color = {4'hF,4'hF,4'hF}; //white
        default: color = 12'h000; //black
        endcase
    end
endmodule

module signals(
input clk_25MHz,
output reg hsync, vsync, visible,
output [9:0] hcount, vcount
);

reg [9:0] hcount1, vcount1;
reg hsig, vsig;
    
initial begin
hcount1 = 0;
vcount1 = 0;
hsync = 1;
vsync = 1;
visible = 1;
end 

always@(posedge clk_25MHz) begin
    if(hcount == 799) begin
        hcount1 = 0;
        if(vcount1 == 524) vcount1 = 0;
        else vcount1 = vcount1 + 1;
    end
    else hcount1 = hcount1 + 1;
    
    if((659<=hcount1) && (hcount1 <= 755)) hsig = 0;
    else hsig = 1;
    
    if((493<=vcount1)&&(vcount1<=494)) vsig = 0;
    else vsig = 1;
    
    hsync = hsig;
    vsync = vsig;
    if(hsig && vsig) visible = 1;
    else visible = 0;
end

assign hcount = hcount1;
assign vcount = vcount1;

endmodule

module drawBlock(
    input [9:0] hcount, vcount, High, Low, Left, Right,
    input visible, clk_5Hz,
    output draw
);

reg [9:0] hcount1, vcount1, High1, Low1, Left1, Right1;
reg visible1, draw1;

initial begin
    hcount1 = hcount;
    vcount1 = vcount;
    High1 = High;
    Low1 = Low;
    Left1 = Left;
    Right1 = Right;
    visible1 = visible;
end

always @(posedge clk_5Hz) begin
    if(visible1)begin
        if((hcount1>=High1)&&(hcount1<=Low1)) begin
            if((vcount1>=Left1)&&(vcount1<=Right1)) draw1 = 1'b1;
        end
        else draw1 = 0;
    end
    else draw1 = 0;
end

assign draw = draw1;

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

//divides clock to 25MHz
module clkdiv25MHz(
    input clk, 
    output reg clk_out
    );
    
    reg [1:0] COUNT;
    
    initial begin
    COUNT = 0;
    clk_out = 1;
    end
   
    always @(posedge clk)
    begin
        if (COUNT == 1) begin
        clk_out = ~clk_out;
        COUNT = 0;
        end
       
    else COUNT = COUNT + 1;
    end
endmodule
