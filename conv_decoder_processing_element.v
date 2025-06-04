`timescale 1ns/ 1ps

module conv_decoder_processing_element(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] x,
    input  wire signed [17: 0] w,
    output reg  signed [35: 0] z,
    output reg                 ready
);
    /***** multiply *****/
    wire signed [35: 0] p;

    conv_mult u_conv_mult(.A(x), .B(w), .P(p));

    /***** kernel adder tree *****/ // if needed
    
    /***** output *****/
    always@(posedge clk) begin
        if(rst) begin
            z    <=0;
            ready<=0;
        end else if(start) begin
            z    <=p;
            ready<=1;
        end
    end
endmodule