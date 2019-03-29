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
    output reg [11:0] color,
    output reg hsync, vsync
    );
    
    wire up, down, left, right, start, resume, pause, escape, clk5hz, clk25Mhz, visible, hsig, vsig, toggle;
    wire [1:0] direction; //down = 00  up = 01  right = 10  left = 11
    wire [9:0] hcount, vcount, block1h, block1v, block2h, block2v, block3h, block3v, block4h, block4v;
    wire [11:0] RGB;
    reg [9:0] i,j;
    
    
    keyboardcapture k0 (ps2clk,ps2data,up,down,left,right,start,resume,pause,escape,toggle);
    
    direction d0 (left,right,up,down,clk,start,direction);
    
    clkdiv25MHz c0 (clk,clk25Mhz);
    clkdiv5Hz c1 (clk,clk5hz,toggle);
    
    signals s0 (clk25Mhz,hsig,vsig,visible,hcount,vcount);
    
    movement m0 (start,pause,escape,resume,clk5hz,direction,block1h,block1v,block2h,block2v,block3h,block3v,block4h,block4v);
    
    colorselector c2 (hcount,vcount,block1h,block1v,block2h,block2v,block3h,block3v,block4h,block4v,escape,start,clk,visible,RGB);
    
    always@(posedge clk) begin
        color <= RGB;
        hsync <= hsig;
        vsync <= vsig;
    end
    
endmodule


//captures data from keyboard and returns signals based on most recent key pressed
module keyboardcapture(
    input ps2clk, ps2data,
    output up, down, left, right, start, resume, pause, escape, toggle    
    );
    
    wire [21:0] shiftreg;
    reg [7:0] code_reg;
    wire [7:0] code;
    
    assign code = code_reg;
    
    inputcapture i0 (ps2clk,ps2data,shiftreg);
    
    decoder d0 (code,toggle,up,down,left,right,start,resume,pause,escape);
    
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
    inout toggle,
    output reg up, down, left, right, start, resume, pause, escape
    );
    
    reg toggle1;
    
    initial begin
        toggle1 = 0;
    end
    
    assign toggle = toggle1;
    
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
            8'h2c : begin {up,down,left,right,start,resume,pause,escape} = 8'b00000000; toggle1 = ~toggle; end
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


//divides clock to 5hz
module clkdiv5Hz(
    input clk, 
    output reg clk_out,
    input toggle
    );
    
    reg [23:0] COUNT, MAX;
    
    
    initial begin
    COUNT = 0;
    clk_out = 1;
    MAX = 9999999;
    end
   
    always @(posedge clk)
    begin
        if (COUNT >= MAX) begin
        clk_out = ~clk_out;
        COUNT = 0;
        end
       
    else COUNT = COUNT + 1;
    end
    
    always@(*) begin
        if(toggle) MAX = 2499999;
            else MAX = 9999999;
    end 
    
endmodule


//state machine controlling direction of snake
module direction(
    input left, right, up, down, clk, start,
    output reg [1:0] direction
    );
    reg [1:0] state, nextstate;
    wire [4:0] buttons;
    
    initial begin
    direction = 2'b10;
    state = 2'b10;
    end
    
    assign buttons = {left,right,up,down,start};

    always@(*) begin
        case(state)
        2'b00: //down
            case(buttons)
                5'b10000: nextstate = 2'b11;
                5'b01000: nextstate = 2'b10;
                5'b00001: nextstate = 2'b10;
                default: nextstate = state;
            endcase
        2'b01: //up
            case(buttons)
                5'b10000: nextstate = 2'b11;
                5'b01000: nextstate = 2'b10;
                5'b00001: nextstate = 2'b10;
                default: nextstate = state;
            endcase            
        2'b10: //right
            case(buttons)
                5'b00100: nextstate = 2'b01;
                5'b00010: nextstate = 2'b00;
                5'b00001: nextstate = 2'b10;
                default: nextstate = state;
            endcase
        2'b11: //left
            case(buttons)
                5'b00100: nextstate = 2'b01;
                5'b00010: nextstate = 2'b00;
                5'b00001: nextstate = 2'b10;
                default: nextstate = state;
            endcase
        endcase
    end
    
    always@(posedge clk) begin
        state = nextstate;
        direction = nextstate;
    end
    
endmodule


//passes through every pixel on the screen
module signals(
    input clk_25MHz,
    output reg hsync, vsync, visible,
    output reg [9:0] hcount, vcount
    );

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
        if((hcount >= 0)&&(hcount <= 639)&&(vcount >= 0)&&(vcount <=479)) visible = 1;
        else visible = 0;
    end

endmodule


//moves snake based on parameters
module movement(
    input start, pause, escape, resume, clk5hz,
    input [1:0] direction,
    inout [9:0] block1h, block1v, block2h, block2v, block3h, block3v, block4h, block4v
    );
    
    reg [1:0] state, next_state;
    reg [9:0] block1h_next, block1v_next, block2h_next, block2v_next, block3h_next, block3v_next, block4h_next, block4v_next, block1h_hold, block1v_hold, block2h_hold, block2v_hold, block3h_hold, block3v_hold, block4h_hold, block4v_hold;
    reg crash;
    
    assign block1h = block1h_hold;
    assign block1v = block1v_hold;    
    assign block2h = block2h_hold;
    assign block2v = block2v_hold;
    assign block3h = block3h_hold;
    assign block3v = block3v_hold;    
    assign block4h = block4h_hold;
    assign block4v = block4v_hold;    
        
    initial begin
        state = 2'b00;
    end
    
    always@(*) begin
        case(state)
            2'b00 : begin if(start) next_state = 2'b01;
                                else next_state = 2'b00;
                          block1h_next = 39;
                          block1v_next = 240;
                          block2h_next = 29;
                          block2v_next = 240;
                          block3h_next = 19;
                          block3v_next = 240;
                          block4h_next = 9;
                          block4v_next = 240;                         
                    end
            2'b01 : begin case({crash,escape,pause})
                            3'b100 : next_state = 2'b11;
                            3'b010 : next_state = 2'b00;
                            3'b001 : next_state = 2'b10;
                            default : next_state = 2'b01;
                          endcase
                          case(direction)
                            2'b00 : begin block1h_next = block1h; block1v_next = block1v + 10; end
                            2'b01 : begin block1h_next = block1h; block1v_next = block1v - 10; end
                            2'b10 : begin block1h_next = block1h + 10; block1v_next = block1v; end
                            2'b11 : begin block1h_next = block1h - 10; block1v_next = block1v; end
                          endcase
                          block2h_next = block1h;
                          block2v_next = block1v;
                          block3h_next = block2h;
                          block3v_next = block2v;
                          block4h_next = block3h;
                          block4v_next = block3v;                          
                    end
            2'b10 : begin case({resume,start,escape})
                            3'b100 : begin 
                                        next_state = 2'b01; 
                                        block1h_next = block1h;
                                        block1v_next = block1v;
                                        block2h_next = block2h;
                                        block2v_next = block2v;
                                        block3h_next = block3h;
                                        block3v_next = block3v;
                                        block4h_next = block4h;
                                        block4v_next = block4v;                                       
                                     end
                            3'b010 : begin 
                                        next_state = 2'b01; 
                                        block1h_next = 39;
                                        block1v_next = 240;
                                        block2h_next = 29;
                                        block2v_next = 240;
                                        block3h_next = 19;
                                        block3v_next = 240;
                                        block4h_next = 9;
                                        block4v_next = 240;
                                     end
                            3'b001 : begin 
                                        next_state = 2'b00; 
                                        block1h_next = 39;
                                        block1v_next = 240;
                                        block2h_next = 29;
                                        block2v_next = 240;
                                        block3h_next = 19;
                                        block3v_next = 240;
                                        block4h_next = 9;
                                        block4v_next = 240;                                        
                                     end
                            default : begin 
                                        next_state = 2'b10;
                                        block1h_next = block1h;
                                        block1v_next = block1v;
                                        block2h_next = block2h;
                                        block2v_next = block2v;
                                        block3h_next = block3h;
                                        block3v_next = block3v;
                                        block4h_next = block4h;
                                        block4v_next = block4v;                                         
                                      end                           
                          endcase
                    
                    end
        2'b11 : begin
                    if(start) begin next_state = 2'b01;
                                    block1h_next = 39;
                                    block1v_next = 240;
                                    block2h_next = 29;
                                    block2v_next = 240;
                                    block3h_next = 19;
                                    block3v_next = 240;
                                    block4h_next = 9;
                                    block4v_next = 240;
                                    end
                        else  begin next_state = 2'b11;
                                    block1h_next = block1h;
                                    block1v_next = block1v;
                                    block2h_next = block2h;
                                    block2v_next = block2v;
                                    block3h_next = block3h;
                                    block3v_next = block3v;
                                    block4h_next = block4h;
                                    block4v_next = block4v;
                                    end                     
                end
        endcase
    end
    
    always@(posedge clk5hz) begin
        state <= next_state;
        block1h_hold <= block1h_next;
        block1v_hold <= block1v_next;
        block2h_hold <= block2h_next;
        block2v_hold <= block2v_next;
        block3h_hold <= block3h_next;
        block3v_hold <= block3v_next;
        block4h_hold <= block4h_next;
        block4v_hold <= block4v_next;
    end
    
    always@(*) begin
        if((block1h > 639) || (block1h < 9) || (block1v > 479) || (block1v < 1)) crash = 1;
            else crash = 0;   
    end
endmodule


//picks color based on parameters
module colorselector(
    input [9:0] hcount, vcount, block1h, block1v, block2h, block2v, block3h, block3v, block4h, block4v,
    input escape, start, clk, visible,
    output  reg [11:0] color
    );
    
    reg state, next_state;
    
    initial begin
    state = 0;
    end
    
    always@(*) begin
       case(state)
            1'b0 : if(start) next_state = 1'b1; else next_state = 1'b0;
            1'b1 : if(escape) next_state = 1'b0; else next_state = 1'b1;
       endcase        
    end
    
    always@(posedge clk) begin
        state <= next_state;
    end
    
    always@(*) begin
        if(visible)begin
            if(state) begin
                if((((block1h - 9 <= hcount) && (hcount <= block1h)) && ((block1v <= vcount) && (vcount <= block1v + 9))) || (((block2h - 9 <= hcount) && (hcount <= block2h)) && ((block2v <= vcount) && (vcount <= block2v + 9))) || (((block3h - 9 <= hcount) && (hcount <= block3h)) && ((block3v <= vcount) && (vcount <= block3v + 9))) || (((block4h - 9 <= hcount) && (hcount <= block4h)) && ((block4v <= vcount) && (vcount <= block4v + 9))))
                    color = {4'h0,4'h0,4'hF}; //blue
                else color = {4'hF,4'hF,4'hF}; //white
            end
            else color = 12'h000;
        end
        else color = 12'h000; //black
    end
    
endmodule
