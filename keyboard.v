`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2019 04:29:18 PM
// Design Name: 
// Module Name: keyboard
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


module keyboard(
    input clk, ps2clk, ps2data,
    output reg [1:0] an,
    output [6:0] sseg,
    output reg strobe
    );
    
   wire [6:0] sseg0, sseg1;
   wire [21:0] code;
   wire [7:0] code_out;
   reg [7:0] hold;
   wire [1:0] anout;
   wire clk10hz;
   
   assign code_out = hold;
   
   initial begin
   hold = 0;
   an = 2'b11;
   strobe = 0;
   end
   
   clkdiv10hz c0 (clk,clk10hz);
   
   hexto7segment h0 (code_out[3:0],sseg0);
   hexto7segment h1 (code_out[7:4],sseg1);
   
   displayLogic d0 (clk,sseg0,sseg1,anout,sseg);
   
   inputcapture(ps2clk,ps2data,code);
   
   always@(*)begin
        if(code[8:1] == 8'hf0) hold = code[19:12];
   end
   
   always@(hold) an = anout;
   

endmodule


//send a hex value, returns seven segment
module hexto7segment(
    input [3:0] x,
    output reg [6:0] r
    );
    always@(*)
        case(x)
            4'b0000 : r = 7'b1000000;
            4'b0001 : r = 7'b1111001;
            4'b0010 : r = 7'b0100100;
            4'b0011 : r = 7'b0110000;
            4'b0100 : r = 7'b0011001;
            4'b0101 : r = 7'b0010010;
            4'b0110 : r = 7'b0000010;
            4'b0111 : r = 7'b1111000;
            4'b1000 : r = 7'b0000000;
            4'b1001 : r = 7'b0010000;
            4'b1010 : r = 7'b0001000;
            4'b1011 : r = 7'b0000011;
            4'b1100 : r = 7'b1000110;
            4'b1101 : r = 7'b0100001;
            4'b1110 : r = 7'b0000110;
            4'b1111 : r = 7'b0001110;
        endcase   
endmodule

//rotates 2 digits on 2 seven segment displays
module displayLogic(
    input clk,
    input [6:0] sseg0, sseg1,
    output reg [1:0] an, 
    output reg [6:0] sseg
    );
    reg state, next_state;
    reg [9:0] counter;
    initial begin
        state = 2'b00;
        counter = 0;
    end 
    
    always@(*) begin
    if(state)
        begin an = 2'b01; next_state = 1'b0; sseg = sseg1; end
    else
        begin an = 2'b10; next_state = 1'b1; sseg = sseg0; end        
    end
    
    always@(posedge clk) begin        
        if(counter == 999) begin
        state <= next_state;
        counter <= 0;
        end else counter <= counter + 1;
        end              
endmodule

//captures serial input using a shift register
module inputcapture(
    input ps2clk, ps2data,
    output reg [21:0] code
    );
    
    initial code = 0;
    
    always@(negedge ps2clk) begin
        code[20:0] = code[21:1];
        code[21] = ps2data;   
    end
endmodule

//divides clock to 10 hz for strobe
module clkdiv10hz(
    input clk, 
    output reg clk_out
    );

    reg [26:0] COUNT;
    
    initial begin
    COUNT = 0;
    end
   
    always @(posedge clk)
    begin
        if (COUNT == 1000000) begin
        clk_out = ~clk_out;
        COUNT = 0;
        end
       
    else COUNT = COUNT + 1;
    end
endmodule
