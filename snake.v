`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2019 10:42:20 PM
// Design Name: 
// Module Name: snake
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


module snake(
    input clk, ps2clk, ps2data,
    output [11:0] color,
    output hsync, vsync
    );
    
    wire up, down, left, right, start, resume, pause, escape;
    
    keyboardcapture k0 (ps2clk,ps2data,up,down,left,right,start,resume,pause,escape);
    
endmodule

//captures data from keyboard and returns signals based on most recent key pressed
module keyboardcapture(
    input ps2clk, ps2data,
    output up, down, left, right, start, resume, pause, escape    
    );
    
    wire [21:0] shiftreg;
    reg [7:0] code_reg;
    wire [7:0] code;
    
    assign code = code_reg;
    
    inputcapture i0 (ps2clk,ps2data,shiftreg);
    
    decoder d0 (code,up,down,left,right,start,resume,pause,escape);
    
    always@(posedge (shiftreg[8:1] == 8'hf0))begin
         code_reg = shiftreg[19:12]; 
    end
    
endmodule

//captures serial input using a shift register
module inputcapture(
    input ps2clk, ps2data,
    inout [21:0] code
    );
    
    reg [21:0] code_temp;
    
    initial code_temp = 0;
    
    assign code = code_temp;
    
    always@(negedge ps2clk) begin
        code_temp[20:0] = code[21:1];
        code_temp[21] = ps2data;   
    end
endmodule

//decodes 8 bit break code into output signals
module decoder(
    input [7:0] code,
    output reg up, down, left, right, start, resume, pause, escape
    );
    
    always@(*) begin
        case(code)
            8'h75 : {up,down,left,right,start,resume,pause,escape} = 8'b10000000;
            8'h72 : {up,down,left,right,start,resume,pause,escape} = 8'b01000000;
            8'h6b : {up,down,left,right,start,resume,pause,escape} = 8'b00100000;
            8'h74 : {up,down,left,right,start,resume,pause,escape} = 8'b00010000;
            8'h1b : {up,down,left,right,start,resume,pause,escape} = 8'b00001000;
            8'h2d : {up,down,left,right,start,resume,pause,escape} = 8'b00000100;
            8'h4d : {up,down,left,right,start,resume,pause,escape} = 8'b00000010;
            8'h76 : {up,down,left,right,start,resume,pause,escape} = 8'b00000001;
            default : {up,down,left,right,start,resume,pause,escape} = 8'b00000000;
        endcase
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

//draws screen all black upon escape
module drawblack(
    input clk_25MHz, escape,
    output reg hsync, vsync, visible
    );

    reg [9:0] hcount, vcount;
    reg hsig, vsig;
    
    initial begin
    hcount = 800;
    vcount = 525;
    hsync = 1;
    vsync = 1;
    visible = 1;
    end 

    always@(posedge clk_25MHz) begin
        if(hcount == 799) begin
            hcount = 0;
            if(vcount <= 524) vcount = vcount + 1;
                else if(escape) vcount = 0;
        end
            else if(hcount < 799) hcount = hcount + 1;
                else if(escape) hcount = 0;
    
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

//draws screen upon starting and pressing start button
module drawinitial(
    input clk_25MHz, escape,
    output reg hsync, vsync, visible, start
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
            if(vcount <= 524) vcount = vcount + 1;
                else if(start) vcount = 0;
        end
            else if(hcount < 799) hcount = hcount + 1;
                else if(start) hcount = 0;
    
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