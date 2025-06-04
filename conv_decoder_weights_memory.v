`timescale 1ns/ 1ps

module conv_decoder_weights_memory(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire        [3: 0]  filter_sel, // 16
    output reg  signed [17: 0] w,
    output reg                 ready
);
    reg signed [17: 0] ws [0: 15];

    initial begin
        ws[0 ]<=  63; ws[1 ]<= 125; ws[2 ]<=   6; ws[3 ]<=-137; ws[4 ]<=  90;
        ws[5 ]<= -27; ws[6 ]<= 141; ws[7 ]<=  -7; ws[8 ]<=  10; ws[9 ]<=-154;
        ws[10]<=  -1; ws[11]<= -45; ws[12]<= 141; ws[13]<= 128; ws[14]<= -57;
        ws[15]<=-100;
    end

    always@(posedge clk) begin
        if(rst) begin
            w    <=0;
            ready<=0;
        end else if(start) begin
            w    <=ws[filter_sel];
            ready<=1; 
        end
    end
endmodule