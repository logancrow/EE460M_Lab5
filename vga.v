`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2019 08:16:30 AM
// Design Name: 
// Module Name: vga
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


module vga(
    input [7:0] switch,
    input clk,
    output reg [11:0] color,
    output reg hsync, vsync
    );
    
    wire clk_25MHz, hsig, vsig, visible;
    wire [11:0] RBG;
    
    clkdiv25MHz c0 (clk, clk_25MHz);
    
    signals s0 (clk_25MHz, hsig, vsig, visible);
    
    color c1 (clk_25MHz, switch, visible, RBG);
    
   always @(posedge clk)begin
    hsync <= hsig;
    vsync <= vsig;
    color <= RBG;
   end
    
    
endmodule

module signals(
input clk_25MHz,
output reg hsync, vsync, visible
);

reg [9:0] hcount, vcount;
reg hsig, vsig;
    
initial begin
hcount = 0;
vcount = 0;
hsync = 1;
vsync = 1;
visible = 1;
end 

always@(posedge clk_25MHz) begin
    if(hcount == 799) begin
        hcount = 0;
        if(vcount == 524) vcount = 0;
        else vcount = vcount + 1;
    end
    else hcount = hcount + 1;
    
    if((659<=hcount) && (hcount <= 755)) hsig = 0;
    else hsig = 1;
    
    if((493<=vcount)&&(vcount<=494)) vsig = 0;
    else vsig = 1;
    
    hsync = hsig;
    vsync = vsig;
    if(hsig && vsig) visible = 1;
    else visible = 0;
end

endmodule

module color(
    input clk_25MHz,
    input [7:0] switch,
    input visible,
    output reg [11:0] color,
    output reg [7:0] switch1
);

    always@(*) begin
        switch1 <= switch;
        if(visible)begin
            case(switch)
            8'b00000001: color = {4'h0,4'h0,4'h0}; //black
            8'b00000010: color = {4'h0,4'h0,4'hF}; //blue
            8'b00000100: color = {4'hB,4'h3,4'h3}; //brown
            8'b00001000: color = {4'h0,4'hF,4'hF}; //cyan
            8'b00010000: color = {4'hF,4'h0,4'h0}; //red
            8'b00100000: color = {4'hF,4'h0,4'hF}; //magenta
            8'b01000000: color = {4'hF,4'hF,4'h0}; //yellow
            8'b10000000: color = {4'hF,4'hF,4'hF}; //white
            default: color = 12'h000; //black
            endcase
        end
        else color = 12'h000;
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
