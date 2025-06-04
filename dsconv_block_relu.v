`timescale 1ns/ 1ps

module dsconv_block_relu(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] x,
    output reg  signed [17: 0] output_pixel,
    output reg                 ready
);
    /***** output *****/
    always@(posedge clk) begin
        if(rst) begin
            output_pixel<=0;
            ready<=0;
        end else if(start) begin
            if(x>0) begin
                output_pixel<=x;
            end else begin
                output_pixel<=0;
            end
            ready<=1;
        end
    end
endmodule