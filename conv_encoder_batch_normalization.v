`timescale 1ns/ 1ps

/*
    batch normalization
    m-> mean;
    v-> variance;
    r-> gamma;
    b-> beta
    e-> 0.001
    y=g*(x-m)/((v+e)^0.5)+b
*/

module conv_encoder_batch_normalization(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] x,
    input  wire signed [17: 0] p, // p=r/((v+e)^0.5)
    input  wire signed [35: 0] q, // q=b-m*r/((v+e)^0.5)
    output reg  signed [17: 0] output_pixel,
    output reg                 ready
);
    /***** multiply *****/
    wire signed [35: 0] z;

    bn_mult u_bn_mult(.A(x), .B(p), .C(q), .P(z));

    /***** output *****/
    always@(posedge clk) begin
        if(rst) begin
            output_pixel<=0;
            ready       <=0;
        end else if(start) begin
            output_pixel<=z>>>9;
            ready       <=1;
        end
    end
endmodule