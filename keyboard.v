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
    output [3:0] an,
    output [6:0] sseg,
    output strobe
    );
    
   wire [6:0] sseg0, sseg1;
   wire [21:0] code;
   wire [7:0] code_out;
   reg [7:0] hold;//, code_hold;
   
   assign code_out = hold;
   
   initial begin
   hold = 0;
   //code_hold = 0;
   end
   
   
   hexto7segment h0 (code_out[3:0],sseg0);
   hexto7segment h1 (code_out[7:4],sseg1);
   
   displayLogic d0 (clk,sseg0,sseg1,code_out,an,sseg);
   
   inputcapture(ps2clk,ps2data,code);
   
   strobe s0 (clk,code_out,strobe);
   
   always@(posedge (code[8:1] == 8'hf0))begin
        hold = code[19:12]; 
   end
   
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
    input [7:0] code,
    output reg [3:0] an, 
    output reg [6:0] sseg
    );
    reg [1:0] state, next_state;
    reg [9:0] counter;
    initial begin
        state = 2'b00;
        counter = 0;
        an = 4'b1111;
    end 
    
    always@(*) begin
    case(state)
        2'b00 : begin an = 4'b1111; if(code != 0) next_state = 2'b01; else next_state = 2'b00; sseg = sseg0; end
        2'b01 : begin an = 4'b1101; next_state = 2'b10; sseg = sseg1; end
        2'b10 : begin an = 4'b1110; next_state = 2'b01; sseg = sseg0; end    
        endcase    
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


//flashes for 100 ms following change in code
module strobe(
    input clk,
    input [7:0] code,
    output reg strobe
    );
    reg [7:0] code_prev;
    reg [26:0] count;
    
    initial begin
    code_prev = 0;
    strobe = 0;
    count = 0;
    end
    
    always@(posedge clk) begin
        if(code != code_prev) begin count = 1; strobe = 1; end
            else begin if((count != 0)&&(count < 2000000)) count = count + 1;
                            else if(count == 2000000) begin count = 0; strobe = 0; end
            end
        code_prev <= code;
    end
    

    
endmodule
