`timescale 1ns/ 1ps

module dsconv_block_top(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire        [2: 0]  layer_sel,         // 8
    input  wire signed [17: 0] input_pixel_0, input_pixel_1, input_pixel_2, input_pixel_3, input_pixel_4, input_pixel_5, input_pixel_6, input_pixel_7, input_pixel_8, input_pixel_9, input_pixel_10, input_pixel_11, input_pixel_12, input_pixel_13, input_pixel_14, input_pixel_15,
    output reg         [13: 0] input_pixel_addr,  // (180+6)*(64+6) -> 13020
    output wire signed [17: 0] output_pixel,
    output reg         [13: 0] output_pixel_addr, // (180+6)*(64+6) -> 13020
    output reg         [3: 0]  output_filter=0,   // 16
    output wire                ready,
    output reg                 done=0
);
    genvar i;

    /***** delay *****/
    reg [1: 0] delay;

    always@(posedge clk) begin
        if(rst) begin
            delay<=0;
        end else if(start) begin
            if(delay<1) begin
                delay<=delay+1;
            end else begin
                delay<=delay;
            end
        end
    end

    /***** line buffer *****/
    wire                dsconv_block_line_buffer_start;
    wire                dsconv_block_line_buffer_ready [0: 15];
    wire signed [17: 0] input_pixel                    [0: 15];
    wire signed [17: 0] x                              [0: 15][0: 48];

    assign input_pixel[0 ]=input_pixel_0 ; assign input_pixel[1 ]=input_pixel_1 ; assign input_pixel[2 ]=input_pixel_2 ; assign input_pixel[3 ]=input_pixel_3 ; assign input_pixel[4 ]=input_pixel_4 ;
    assign input_pixel[5 ]=input_pixel_5 ; assign input_pixel[6 ]=input_pixel_6 ; assign input_pixel[7 ]=input_pixel_7 ; assign input_pixel[8 ]=input_pixel_8 ; assign input_pixel[9 ]=input_pixel_9 ;
    assign input_pixel[10]=input_pixel_10; assign input_pixel[11]=input_pixel_11; assign input_pixel[12]=input_pixel_12; assign input_pixel[13]=input_pixel_13; assign input_pixel[14]=input_pixel_14;
    assign input_pixel[15]=input_pixel_15;
    
    assign dsconv_block_line_buffer_start=start&&delay==1;

    generate
        for(i=0; i<16; i=i+1) begin
            dsconv_block_line_buffer u_dsconv_block_line_buffer(
                .clk        (clk),
                .rst        (rst),
                .start      (dsconv_block_line_buffer_start),
                .input_pixel(input_pixel[i]),
                .x0(x[i][0]), .x1(x[i][1]), .x2(x[i][2]), .x3(x[i][3]), .x4(x[i][4]), .x5(x[i][5]), .x6(x[i][6]), .x7(x[i][7]), .x8(x[i][8]), .x9(x[i][9]), .x10(x[i][10]), .x11(x[i][11]), .x12(x[i][12]), .x13(x[i][13]), .x14(x[i][14]), .x15(x[i][15]), .x16(x[i][16]), .x17(x[i][17]), .x18(x[i][18]), .x19(x[i][19]), .x20(x[i][20]), .x21(x[i][21]), .x22(x[i][22]), .x23(x[i][23]), .x24(x[i][24]), .x25(x[i][25]), .x26(x[i][26]), .x27(x[i][27]), .x28(x[i][28]), .x29(x[i][29]), .x30(x[i][30]), .x31(x[i][31]), .x32(x[i][32]), .x33(x[i][33]), .x34(x[i][34]), .x35(x[i][35]), .x36(x[i][36]), .x37(x[i][37]), .x38(x[i][38]), .x39(x[i][39]), .x40(x[i][40]), .x41(x[i][41]), .x42(x[i][42]), .x43(x[i][43]), .x44(x[i][44]), .x45(x[i][45]), .x46(x[i][46]), .x47(x[i][47]), .x48(x[i][48]),
                .ready      (dsconv_block_line_buffer_ready[i])
            );
        end
    endgenerate

    /***** depthwise weights memory *****/
    wire                dsconv_block_depthwise_weights_memory_start;
    wire                dsconv_block_depthwise_weights_memory_ready [0: 15];
    wire signed [17: 0] depthwise_w                                 [0: 15][0: 48];

    assign dsconv_block_depthwise_weights_memory_start=start;

    generate
        for(i=0; i<16; i=i+1) begin
            dsconv_block_depthwise_weights_memory u_dsconv_block_depthwise_weights_memory(
                .clk       (clk),
                .rst       (rst),
                .start     (dsconv_block_depthwise_weights_memory_start),
                .layer_sel (layer_sel),
                .filter_sel(i),
                .w0(depthwise_w[i][0]), .w1(depthwise_w[i][1]), .w2(depthwise_w[i][2]), .w3(depthwise_w[i][3]), .w4(depthwise_w[i][4]), .w5(depthwise_w[i][5]), .w6(depthwise_w[i][6]), .w7(depthwise_w[i][7]), .w8(depthwise_w[i][8]), .w9(depthwise_w[i][9]), .w10(depthwise_w[i][10]), .w11(depthwise_w[i][11]), .w12(depthwise_w[i][12]), .w13(depthwise_w[i][13]), .w14(depthwise_w[i][14]), .w15(depthwise_w[i][15]), .w16(depthwise_w[i][16]), .w17(depthwise_w[i][17]), .w18(depthwise_w[i][18]), .w19(depthwise_w[i][19]), .w20(depthwise_w[i][20]), .w21(depthwise_w[i][21]), .w22(depthwise_w[i][22]), .w23(depthwise_w[i][23]), .w24(depthwise_w[i][24]), .w25(depthwise_w[i][25]), .w26(depthwise_w[i][26]), .w27(depthwise_w[i][27]), .w28(depthwise_w[i][28]), .w29(depthwise_w[i][29]), .w30(depthwise_w[i][30]), .w31(depthwise_w[i][31]), .w32(depthwise_w[i][32]), .w33(depthwise_w[i][33]), .w34(depthwise_w[i][34]), .w35(depthwise_w[i][35]), .w36(depthwise_w[i][36]), .w37(depthwise_w[i][37]), .w38(depthwise_w[i][38]), .w39(depthwise_w[i][39]), .w40(depthwise_w[i][40]), .w41(depthwise_w[i][41]), .w42(depthwise_w[i][42]), .w43(depthwise_w[i][43]), .w44(depthwise_w[i][44]), .w45(depthwise_w[i][45]), .w46(depthwise_w[i][46]), .w47(depthwise_w[i][47]), .w48(depthwise_w[i][48]),
                .ready     (dsconv_block_depthwise_weights_memory_ready[i])
            );
        end
    endgenerate

    /***** depthwise processing element *****/
    wire                dsconv_block_depthwise_processing_element_start;
    wire                dsconv_block_depthwise_processing_element_ready [0: 15];
    wire signed [17: 0] depthwise_output_pixel                          [0: 15];

    assign dsconv_block_depthwise_processing_element_start=dsconv_block_line_buffer_ready[0]&dsconv_block_line_buffer_ready[1]&dsconv_block_line_buffer_ready[2]&dsconv_block_line_buffer_ready[3]&dsconv_block_line_buffer_ready[4]&dsconv_block_line_buffer_ready[5]&dsconv_block_line_buffer_ready[6]&dsconv_block_line_buffer_ready[7]&dsconv_block_line_buffer_ready[8]&dsconv_block_line_buffer_ready[9]&dsconv_block_line_buffer_ready[10]&dsconv_block_line_buffer_ready[11]&dsconv_block_line_buffer_ready[12]&dsconv_block_line_buffer_ready[13]&dsconv_block_line_buffer_ready[14]&dsconv_block_line_buffer_ready[15]&dsconv_block_depthwise_weights_memory_ready[0]&dsconv_block_depthwise_weights_memory_ready[1]&dsconv_block_depthwise_weights_memory_ready[2]&dsconv_block_depthwise_weights_memory_ready[3]&dsconv_block_depthwise_weights_memory_ready[4]&dsconv_block_depthwise_weights_memory_ready[5]&dsconv_block_depthwise_weights_memory_ready[6]&dsconv_block_depthwise_weights_memory_ready[7]&dsconv_block_depthwise_weights_memory_ready[8]&dsconv_block_depthwise_weights_memory_ready[9]&dsconv_block_depthwise_weights_memory_ready[10]&dsconv_block_depthwise_weights_memory_ready[11]&dsconv_block_depthwise_weights_memory_ready[12]&dsconv_block_depthwise_weights_memory_ready[13]&dsconv_block_depthwise_weights_memory_ready[14]&dsconv_block_depthwise_weights_memory_ready[15];

    generate
        for(i=0; i<16; i=i+1) begin
            dsconv_block_depthwise_processing_element u_dsconv_block_depthwise_processing_element(
                .clk         (clk),
                .rst         (rst),
                .start       (dsconv_block_depthwise_processing_element_start),
                .x0(x[i][0]), .x1(x[i][1]), .x2(x[i][2]), .x3(x[i][3]), .x4(x[i][4]), .x5(x[i][5]), .x6(x[i][6]), .x7(x[i][7]), .x8(x[i][8]), .x9(x[i][9]), .x10(x[i][10]), .x11(x[i][11]), .x12(x[i][12]), .x13(x[i][13]), .x14(x[i][14]), .x15(x[i][15]), .x16(x[i][16]), .x17(x[i][17]), .x18(x[i][18]), .x19(x[i][19]), .x20(x[i][20]), .x21(x[i][21]), .x22(x[i][22]), .x23(x[i][23]), .x24(x[i][24]), .x25(x[i][25]), .x26(x[i][26]), .x27(x[i][27]), .x28(x[i][28]), .x29(x[i][29]), .x30(x[i][30]), .x31(x[i][31]), .x32(x[i][32]), .x33(x[i][33]), .x34(x[i][34]), .x35(x[i][35]), .x36(x[i][36]), .x37(x[i][37]), .x38(x[i][38]), .x39(x[i][39]), .x40(x[i][40]), .x41(x[i][41]), .x42(x[i][42]), .x43(x[i][43]), .x44(x[i][44]), .x45(x[i][45]), .x46(x[i][46]), .x47(x[i][47]), .x48(x[i][48]), 
                .w0(depthwise_w[i][0]), .w1(depthwise_w[i][1]), .w2(depthwise_w[i][2]), .w3(depthwise_w[i][3]), .w4(depthwise_w[i][4]), .w5(depthwise_w[i][5]), .w6(depthwise_w[i][6]), .w7(depthwise_w[i][7]), .w8(depthwise_w[i][8]), .w9(depthwise_w[i][9]), .w10(depthwise_w[i][10]), .w11(depthwise_w[i][11]), .w12(depthwise_w[i][12]), .w13(depthwise_w[i][13]), .w14(depthwise_w[i][14]), .w15(depthwise_w[i][15]), .w16(depthwise_w[i][16]), .w17(depthwise_w[i][17]), .w18(depthwise_w[i][18]), .w19(depthwise_w[i][19]), .w20(depthwise_w[i][20]), .w21(depthwise_w[i][21]), .w22(depthwise_w[i][22]), .w23(depthwise_w[i][23]), .w24(depthwise_w[i][24]), .w25(depthwise_w[i][25]), .w26(depthwise_w[i][26]), .w27(depthwise_w[i][27]), .w28(depthwise_w[i][28]), .w29(depthwise_w[i][29]), .w30(depthwise_w[i][30]), .w31(depthwise_w[i][31]), .w32(depthwise_w[i][32]), .w33(depthwise_w[i][33]), .w34(depthwise_w[i][34]), .w35(depthwise_w[i][35]), .w36(depthwise_w[i][36]), .w37(depthwise_w[i][37]), .w38(depthwise_w[i][38]), .w39(depthwise_w[i][39]), .w40(depthwise_w[i][40]), .w41(depthwise_w[i][41]), .w42(depthwise_w[i][42]), .w43(depthwise_w[i][43]), .w44(depthwise_w[i][44]), .w45(depthwise_w[i][45]), .w46(depthwise_w[i][46]), .w47(depthwise_w[i][47]), .w48(depthwise_w[i][48]), 
                .output_pixel(depthwise_output_pixel[i]),
                .ready       (dsconv_block_depthwise_processing_element_ready[i])
            );
        end
    endgenerate

    /***** pointwise weights memory *****/
    wire                dsconv_block_pointwise_weights_memory_start;
    wire                dsconv_block_pointwise_weights_memory_ready [0: 15];
    wire signed [17: 0] pointwise_w                                 [0: 15];

    assign dsconv_block_pointwise_weights_memory_start=start;

    generate
        for(i=0; i<16; i=i+1) begin
            dsconv_block_pointwise_weights_memory u_dsconv_block_pointwise_weights_memory(
                .clk          (clk),
                .rst          (rst),
                .start        (dsconv_block_pointwise_weights_memory_start),
                .layer_sel    (layer_sel),
                .input_filter (i),
                .output_filter(output_filter),
                .w            (pointwise_w[i]),
                .ready        (dsconv_block_pointwise_weights_memory_ready[i])
            );
        end
    endgenerate

    /***** pointwise processing element *****/
    wire                dsconv_block_pointwise_processing_element_start;
    wire                dsconv_block_pointwise_processing_element_ready;
    wire signed [17: 0] pointwise_output_pixel;

    assign dsconv_block_pointwise_processing_element_start=dsconv_block_depthwise_processing_element_ready[0]&dsconv_block_depthwise_processing_element_ready[1]&dsconv_block_depthwise_processing_element_ready[2]&dsconv_block_depthwise_processing_element_ready[3]&dsconv_block_depthwise_processing_element_ready[4]&dsconv_block_depthwise_processing_element_ready[5]&dsconv_block_depthwise_processing_element_ready[6]&dsconv_block_depthwise_processing_element_ready[7]&dsconv_block_depthwise_processing_element_ready[8]&dsconv_block_depthwise_processing_element_ready[9]&dsconv_block_depthwise_processing_element_ready[10]&dsconv_block_depthwise_processing_element_ready[11]&dsconv_block_depthwise_processing_element_ready[12]&dsconv_block_depthwise_processing_element_ready[13]&dsconv_block_depthwise_processing_element_ready[14]&dsconv_block_depthwise_processing_element_ready[15]&dsconv_block_pointwise_weights_memory_ready[0]&dsconv_block_pointwise_weights_memory_ready[1]&dsconv_block_pointwise_weights_memory_ready[2]&dsconv_block_pointwise_weights_memory_ready[3]&dsconv_block_pointwise_weights_memory_ready[4]&dsconv_block_pointwise_weights_memory_ready[5]&dsconv_block_pointwise_weights_memory_ready[6]&dsconv_block_pointwise_weights_memory_ready[7]&dsconv_block_pointwise_weights_memory_ready[8]&dsconv_block_pointwise_weights_memory_ready[9]&dsconv_block_pointwise_weights_memory_ready[10]&dsconv_block_pointwise_weights_memory_ready[11]&dsconv_block_pointwise_weights_memory_ready[12]&dsconv_block_pointwise_weights_memory_ready[13]&dsconv_block_pointwise_weights_memory_ready[14]&dsconv_block_pointwise_weights_memory_ready[15];

    dsconv_block_pointwise_processing_element u_dsconv_block_pointwise_processing_element(
        .clk         (clk),
        .rst         (rst),
        .start       (dsconv_block_pointwise_processing_element_start),
        .x0(depthwise_output_pixel[0]), .x1(depthwise_output_pixel[1]), .x2(depthwise_output_pixel[2]), .x3(depthwise_output_pixel[3]), .x4(depthwise_output_pixel[4]), .x5(depthwise_output_pixel[5]), .x6(depthwise_output_pixel[6]), .x7(depthwise_output_pixel[7]), .x8(depthwise_output_pixel[8]), .x9(depthwise_output_pixel[9]), .x10(depthwise_output_pixel[10]), .x11(depthwise_output_pixel[11]), .x12(depthwise_output_pixel[12]), .x13(depthwise_output_pixel[13]), .x14(depthwise_output_pixel[14]), .x15(depthwise_output_pixel[15]),
        .w0(pointwise_w[0]), .w1(pointwise_w[1]), .w2(pointwise_w[2]), .w3(pointwise_w[3]), .w4(pointwise_w[4]), .w5(pointwise_w[5]), .w6(pointwise_w[6]), .w7(pointwise_w[7]), .w8(pointwise_w[8]), .w9(pointwise_w[9]), .w10(pointwise_w[10]), .w11(pointwise_w[11]), .w12(pointwise_w[12]), .w13(pointwise_w[13]), .w14(pointwise_w[14]), .w15(pointwise_w[15]),
        .output_pixel(pointwise_output_pixel),
        .ready       (dsconv_block_pointwise_processing_element_ready)
    );

    /***** relu *****/
    wire                dsconv_block_relu_start;
    wire                dsconv_block_relu_ready;
    wire signed [17: 0] relu_output_pixel;

    assign dsconv_block_relu_start=dsconv_block_pointwise_processing_element_ready;

    dsconv_block_relu u_dsconv_block_relu(
        .clk         (clk),
        .rst         (rst),
        .start       (dsconv_block_relu_start),
        .x           (pointwise_output_pixel),
        .output_pixel(relu_output_pixel),
        .ready       (dsconv_block_relu_ready)
    );

    /***** batch normalization weights memory *****/
    wire                dsconv_block_batch_normalization_weights_memory_start;
    wire                dsconv_block_batch_normalization_weights_memory_ready;
    wire signed [17: 0] batch_normalization_p;
    wire signed [35: 0] batch_normalization_q;

    assign dsconv_block_batch_normalization_weights_memory_start=start;

    dsconv_block_batch_normalization_weights_memory u_dsconv_block_batch_normalization_weights_memory(
        .clk       (clk),
        .rst       (rst),
        .start     (dsconv_block_batch_normalization_weights_memory_start),
        .layer_sel (layer_sel),
        .filter_sel(output_filter),
        .p         (batch_normalization_p),
        .q         (batch_normalization_q),
        .ready     (dsconv_block_batch_normalization_weights_memory_ready)
    );

    /***** batch normalization *****/
    wire dsconv_block_batch_normalization_start;
    wire dsconv_block_batch_normalization_ready;

    assign dsconv_block_batch_normalization_start=dsconv_block_relu_ready&dsconv_block_batch_normalization_weights_memory_ready;

    dsconv_block_batch_normalization u_dsconv_block_batch_normalization(
        .clk         (clk),
        .rst         (rst),
        .start       (dsconv_block_batch_normalization_start),
        .x           (relu_output_pixel),
        .p           (batch_normalization_p),
        .q           (batch_normalization_q),
        .output_pixel(output_pixel),
        .ready       (dsconv_block_batch_normalization_ready)
    );

    /***** control unit *****/
    /*** input pixel address ***/
    always@(posedge clk) begin
        if(rst) begin
            input_pixel_addr<=0;
        end else if(start) begin
            if(input_pixel_addr<13019) begin
                input_pixel_addr<=input_pixel_addr+1;
            end else begin
                input_pixel_addr<=input_pixel_addr;
            end
        end
    end

    /*** output pixel address ***/
    always@(posedge clk) begin
        if(rst) begin
            output_pixel_addr<=213;
        end else if(dsconv_block_batch_normalization_ready) begin
            // if(output_pixel_addr%70>=3&&output_pixel_addr%70<66) begin
            //     output_pixel_addr<=output_pixel_addr+1;
            // end else begin
            //     output_pixel_addr<=output_pixel_addr+7;
            // end
            output_pixel_addr<=output_pixel_addr+1;
        end
    end

    /*** output filter ***/
    always@(posedge clk) begin
        if(output_pixel_addr==12806) begin
            output_filter<=output_filter+1;
        end
    end

    /*** ready ***/
    assign ready=(output_pixel_addr%70>=3&&output_pixel_addr%70<=66)? dsconv_block_batch_normalization_ready: 0;

    /*** done ***/
    always@(posedge clk) begin
        if(output_filter==15&&output_pixel_addr==12806) begin
            done<=1;
        end else begin
            done<=0;
        end
    end
endmodule