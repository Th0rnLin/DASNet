`timescale 1ns/ 1ps

module conv_encoder_processing_element_array(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13,
    input  wire signed [17: 0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13,
    output reg  signed [17: 0] output_pixel,
    output reg                 ready
);
    genvar  i;
    integer j;

    /***** processing element *****/
    wire signed [17: 0] x                       [0: 13];
    wire signed [17: 0] w                       [0: 13];
    wire signed [35: 0] z                       [0: 13];
    wire                filter_adder_tree_start [0: 13];

    assign x[0 ]=x0 ; assign x[1 ]=x1 ; assign x[2 ]=x2 ; assign x[3 ]=x3 ; assign x[4 ]=x4 ;
    assign x[5 ]=x5 ; assign x[6 ]=x6 ; assign x[7 ]=x7 ; assign x[8 ]=x8 ; assign x[9 ]=x9 ;
    assign x[10]=x10; assign x[11]=x11; assign x[12]=x12; assign x[13]=x13;

    assign w[0 ]=w0 ; assign w[1 ]=w1 ; assign w[2 ]=w2 ; assign w[3 ]=w3 ; assign w[4 ]=w4 ;
    assign w[5 ]=w5 ; assign w[6 ]=w6 ; assign w[7 ]=w7 ; assign w[8 ]=w8 ; assign w[9 ]=w9 ;
    assign w[10]=w10; assign w[11]=w11; assign w[12]=w12; assign w[13]=w13;

    generate
        for(i=0; i<14; i=i+1) begin
            conv_encoder_processing_element u_conv_encoder_processing_element(
                .clk  (clk),
                .rst  (rst),
                .start(start),
                .x    (x[i]),
                .w    (w[i]),
                .z    (z[i]),
                .ready(filter_adder_tree_start[i])
            );
        end
    endgenerate

    /***** filter adder tree *****/
    wire               adder_start_0;
    reg                adder_start_1;
    reg                adder_start_2;
    reg                adder_start_3;
    reg                output_start;
    reg signed [36: 0] adder_0 [0: 6];
    reg signed [37: 0] adder_1 [0: 3];
    reg signed [38: 0] adder_2 [0: 1];
    reg signed [39: 0] adder;

    assign adder_start_0=filter_adder_tree_start[0]&filter_adder_tree_start[1]&filter_adder_tree_start[2]&filter_adder_tree_start[3]&filter_adder_tree_start[4]&filter_adder_tree_start[5]&filter_adder_tree_start[6]&filter_adder_tree_start[7]&filter_adder_tree_start[8]&filter_adder_tree_start[9]&filter_adder_tree_start[10]&filter_adder_tree_start[11]&filter_adder_tree_start[12]&filter_adder_tree_start[13];

    /*** adder tree 0 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<7; j=j+1) begin
                adder_0[j]<=0;
            end
            adder_start_1<=0;
        end else if(adder_start_0) begin
            for(j=0; j<7; j=j+1) begin
                adder_0[j]<=z[j*2]+z[j*2+1];
            end
            adder_start_1<=1;
        end
    end

    /*** adder tree 1 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<4; j=j+1) begin
                adder_1[j]<=0;
            end
            adder_start_2<=0;
        end else if(adder_start_1) begin
            for(j=0; j<4; j=j+1) begin
                if(j==3) begin
                    adder_1[j]<=adder_0[j*2];
                end else begin
                    adder_1[j]<=adder_0[j*2]+adder_0[j*2+1];
                end
            end
            adder_start_2<=1;
        end
    end

    /*** adder tree 2 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<2; j=j+1) begin
                adder_2[j]<=0;
            end
            adder_start_3<=0;
        end else if(adder_start_2) begin
            for(j=0; j<2; j=j+1) begin
                adder_2[j]<=adder_1[j*2]+adder_1[j*2+1];
            end
            adder_start_3<=1;
        end
    end

    /*** adder tree 3 ***/
    always@(posedge clk) begin
        if(rst) begin
            adder<=0;
            output_start<=0;
        end else if(adder_start_3) begin
            adder<=adder_2[0]+adder_2[1];
            output_start<=1;
        end
    end

    /***** output *****/
    always@(posedge clk) begin
        if(rst) begin
            output_pixel<=0;
            ready       <=0;
        end else if(output_start) begin
            output_pixel<=adder>>>9;
            ready       <=1;
        end
    end
endmodule