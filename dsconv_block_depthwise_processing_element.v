`timescale 1ns/ 1ps

module dsconv_block_depthwise_processing_element(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29, x30, x31, x32, x33, x34, x35, x36, x37, x38, x39, x40, x41, x42, x43, x44, x45, x46, x47, x48,
    input  wire signed [17: 0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16, w17, w18, w19, w20, w21, w22, w23, w24, w25, w26, w27, w28, w29, w30, w31, w32, w33, w34, w35, w36, w37, w38, w39, w40, w41, w42, w43, w44, w45, w46, w47, w48,
    output reg  signed [17: 0] output_pixel,
    output reg                 ready
);
    genvar  i;
    integer j;

    /***** multiply *****/
    wire signed [17: 0] x [0: 48];
    wire signed [17: 0] w [0: 48];
    wire signed [35: 0] p [0: 48];

    assign x[0 ]=x0 ; assign x[1 ]=x1 ; assign x[2 ]=x2 ; assign x[3 ]=x3 ; assign x[4 ]=x4 ;
    assign x[5 ]=x5 ; assign x[6 ]=x6 ; assign x[7 ]=x7 ; assign x[8 ]=x8 ; assign x[9 ]=x9 ;
    assign x[10]=x10; assign x[11]=x11; assign x[12]=x12; assign x[13]=x13; assign x[14]=x14;
    assign x[15]=x15; assign x[16]=x16; assign x[17]=x17; assign x[18]=x18; assign x[19]=x19;
    assign x[20]=x20; assign x[21]=x21; assign x[22]=x22; assign x[23]=x23; assign x[24]=x24;
    assign x[25]=x25; assign x[26]=x26; assign x[27]=x27; assign x[28]=x28; assign x[29]=x29;
    assign x[30]=x30; assign x[31]=x31; assign x[32]=x32; assign x[33]=x33; assign x[34]=x34;
    assign x[35]=x35; assign x[36]=x36; assign x[37]=x37; assign x[38]=x38; assign x[39]=x39;
    assign x[40]=x40; assign x[41]=x41; assign x[42]=x42; assign x[43]=x43; assign x[44]=x44;
    assign x[45]=x45; assign x[46]=x46; assign x[47]=x47; assign x[48]=x48;

    assign w[0 ]=w0 ; assign w[1 ]=w1 ; assign w[2 ]=w2 ; assign w[3 ]=w3 ; assign w[4 ]=w4 ;
    assign w[5 ]=w5 ; assign w[6 ]=w6 ; assign w[7 ]=w7 ; assign w[8 ]=w8 ; assign w[9 ]=w9 ;
    assign w[10]=w10; assign w[11]=w11; assign w[12]=w12; assign w[13]=w13; assign w[14]=w14;
    assign w[15]=w15; assign w[16]=w16; assign w[17]=w17; assign w[18]=w18; assign w[19]=w19;
    assign w[20]=w20; assign w[21]=w21; assign w[22]=w22; assign w[23]=w23; assign w[24]=w24;
    assign w[25]=w25; assign w[26]=w26; assign w[27]=w27; assign w[28]=w28; assign w[29]=w29;
    assign w[30]=w30; assign w[31]=w31; assign w[32]=w32; assign w[33]=w33; assign w[34]=w34;
    assign w[35]=w35; assign w[36]=w36; assign w[37]=w37; assign w[38]=w38; assign w[39]=w39;
    assign w[40]=w40; assign w[41]=w41; assign w[42]=w42; assign w[43]=w43; assign w[44]=w44;
    assign w[45]=w45; assign w[46]=w46; assign w[47]=w47; assign w[48]=w48;

    generate
        for(i=0; i<49; i=i+1) begin
            conv_mult u_conv_mult(
                .A(x[i]),
                .B(w[i]),
                .P(p[i])
            );
        end
    endgenerate

    /***** kernel adder tree *****/
    reg                adder_start_1;
    reg                adder_start_2;
    reg                adder_start_3;
    reg                adder_start_4;
    reg                adder_start_5;
    reg                output_start;
    reg signed [36: 0] adder_0 [0: 24];
    reg signed [37: 0] adder_1 [0: 12];
    reg signed [38: 0] adder_2 [0: 6];
    reg signed [39: 0] adder_3 [0: 3];
    reg signed [40: 0] adder_4 [0: 1];
    reg signed [41: 0] adder;

    /*** adder tree 0 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<25; j=j+1) begin
                adder_0[j]<=0;
            end
            adder_start_1<=0;
        end else if(start) begin
            for(j=0; j<25; j=j+1) begin
                if(j==24) begin
                    adder_0[j]<=p[j*2];
                end else begin
                    adder_0[j]<=p[j*2]+p[j*2+1];
                end
            end
            adder_start_1<=1;
        end
    end

    /*** adder tree 1 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<13; j=j+1) begin
                adder_1[j]<=0;
            end
            adder_start_2<=0;
        end else if(adder_start_1) begin
            for(j=0; j<13; j=j+1) begin
                if(j==12) begin
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
            for(j=0; j<7; j=j+1) begin
                adder_2[j]<=0;
            end
            adder_start_3<=0;
        end else if(adder_start_2) begin
            for(j=0; j<7; j=j+1) begin
                if(j==6) begin
                    adder_2[j]<=adder_1[j*2];
                end else begin
                    adder_2[j]<=adder_1[j*2]+adder_1[j*2+1];
                end
            end
            adder_start_3<=1;
        end
    end

    /*** adder tree 3 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<4; j=j+1) begin
                adder_3[j]<=0;
            end
            adder_start_4<=0;
        end else if(adder_start_3) begin
            for(j=0; j<4; j=j+1) begin
                if(j==3) begin
                    adder_3[j]<=adder_2[j*2];
                end else begin
                    adder_3[j]<=adder_2[j*2]+adder_2[j*2+1];
                end
            end
            adder_start_4<=1;
        end
    end

    /*** adder tree 4 ***/
    always@(posedge clk) begin
        if(rst) begin
            for(j=0; j<2; j=j+1) begin
                adder_4[j]<=0;
            end
            adder_start_5<=0;
        end else if(adder_start_4) begin
            for(j=0; j<2; j=j+1) begin
                adder_4[j]<=adder_3[j*2]+adder_3[j*2+1];
            end
            adder_start_5<=1;
        end
    end

    /*** adder tree 5 ***/
    always@(posedge clk) begin
        if(rst) begin
            adder<=0;
            output_start<=0;
        end else if(adder_start_5) begin
            adder<=adder_4[0]+adder_4[1];
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