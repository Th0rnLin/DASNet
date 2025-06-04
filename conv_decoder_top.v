`timescale 1ns/ 1ps

module conv_decoder_top(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] input_pixel_0, input_pixel_1, input_pixel_2, input_pixel_3, input_pixel_4, input_pixel_5, input_pixel_6, input_pixel_7, input_pixel_8, input_pixel_9, input_pixel_10, input_pixel_11, input_pixel_12, input_pixel_13, input_pixel_14, input_pixel_15,
    output reg         [13: 0] input_pixel_addr,  // (180+6)*(64+6) -> 13020
    output wire signed [17: 0] output_pixel,
    output reg         [13: 0] output_pixel_addr, // 180*64         -> 11520
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

    /***** input buffer *****/
    wire                conv_decoder_input_buffer_start;
    wire                conv_decoder_input_buffer_ready [0: 15];
    wire signed [17: 0] input_pixel                     [0: 15];
    wire signed [17: 0] x                               [0: 15];

    assign conv_decoder_input_buffer_start=start&&delay==1;

    assign input_pixel[0 ]=input_pixel_0 ; assign input_pixel[1 ]=input_pixel_1 ; assign input_pixel[2 ]=input_pixel_2 ; assign input_pixel[3 ]=input_pixel_3 ; assign input_pixel[4 ]=input_pixel_4 ; 
    assign input_pixel[5 ]=input_pixel_5 ; assign input_pixel[6 ]=input_pixel_6 ; assign input_pixel[7 ]=input_pixel_7 ; assign input_pixel[8 ]=input_pixel_8 ; assign input_pixel[9 ]=input_pixel_9 ; 
    assign input_pixel[10]=input_pixel_10; assign input_pixel[11]=input_pixel_11; assign input_pixel[12]=input_pixel_12; assign input_pixel[13]=input_pixel_13; assign input_pixel[14]=input_pixel_14; 
    assign input_pixel[15]=input_pixel_15;

    generate
        for(i=0; i<16; i=i+1) begin
            conv_decoder_input_buffer u_conv_decoder_input_buffer(
                .clk        (clk),
                .rst        (rst),
                .start      (conv_decoder_input_buffer_start),
                .input_pixel(input_pixel[i]),
                .x          (x[i]),
                .ready      (conv_decoder_input_buffer_ready[i])
            );
        end
    endgenerate

    /***** weights memory *****/
    wire                conv_decoder_weights_memory_start;
    wire                conv_decoder_weights_memory_ready [0: 15];
    wire signed [17: 0] w                                 [0: 15];

    assign conv_decoder_weights_memory_start=start;

    generate
        for(i=0; i<16; i=i+1) begin
            conv_decoder_weights_memory u_conv_decoder_weights_memory(
                .clk       (clk),
                .rst       (rst),
                .start     (conv_decoder_weights_memory_start),
                .filter_sel(i),
                .w         (w[i]),
                .ready     (conv_decoder_weights_memory_ready[i])
            );
        end
    endgenerate

    /***** processing element array *****/
    wire conv_decoder_processing_element_array_start;
    wire conv_decoder_processing_element_array_ready;

    assign conv_decoder_processing_element_array_start=conv_decoder_input_buffer_ready[0]&conv_decoder_input_buffer_ready[1]&conv_decoder_input_buffer_ready[2]&conv_decoder_input_buffer_ready[3]&conv_decoder_input_buffer_ready[4]&conv_decoder_input_buffer_ready[5]&conv_decoder_input_buffer_ready[6]&conv_decoder_input_buffer_ready[7]&conv_decoder_input_buffer_ready[8]&conv_decoder_input_buffer_ready[9]&conv_decoder_input_buffer_ready[10]&conv_decoder_input_buffer_ready[11]&conv_decoder_input_buffer_ready[12]&conv_decoder_input_buffer_ready[13]&conv_decoder_input_buffer_ready[14]&conv_decoder_input_buffer_ready[15]&conv_decoder_weights_memory_ready[0]&conv_decoder_weights_memory_ready[1]&conv_decoder_weights_memory_ready[2]&conv_decoder_weights_memory_ready[3]&conv_decoder_weights_memory_ready[4]&conv_decoder_weights_memory_ready[5]&conv_decoder_weights_memory_ready[6]&conv_decoder_weights_memory_ready[7]&conv_decoder_weights_memory_ready[8]&conv_decoder_weights_memory_ready[9]&conv_decoder_weights_memory_ready[10]&conv_decoder_weights_memory_ready[11]&conv_decoder_weights_memory_ready[12]&conv_decoder_weights_memory_ready[13]&conv_decoder_weights_memory_ready[14]&conv_decoder_weights_memory_ready[15];

    conv_decoder_processing_element_array u_conv_decoder_processing_element_array(
        .clk         (clk),
        .rst         (rst),
        .start       (conv_decoder_processing_element_array_start),
        .x0(x[0]), .x1(x[1]), .x2(x[2]), .x3(x[3]), .x4(x[4]), .x5(x[5]), .x6(x[6]), .x7(x[7]), .x8(x[8]), .x9(x[9]), .x10(x[10]), .x11(x[11]), .x12(x[12]), .x13(x[13]), .x14(x[14]), .x15(x[15]),
        .w0(w[0]), .w1(w[1]), .w2(w[2]), .w3(w[3]), .w4(w[4]), .w5(w[5]), .w6(w[6]), .w7(w[7]), .w8(w[8]), .w9(w[9]), .w10(w[10]), .w11(w[11]), .w12(w[12]), .w13(w[13]), .w14(w[14]), .w15(w[15]),
        .output_pixel(output_pixel),
        .ready       (conv_decoder_processing_element_array_ready)
    );

    /***** control unit *****/
    /*** input pixel address ***/
    always@(posedge clk) begin
        if(rst) begin
            input_pixel_addr<=213;
        end else if(start) begin
            if(input_pixel_addr%70>=3&&input_pixel_addr%70<66) begin
                input_pixel_addr<=input_pixel_addr+1;
            end else begin
                input_pixel_addr<=input_pixel_addr+7;
            end
        end
    end

    /*** output pixel address ***/
    always@(posedge clk) begin
        if(rst) begin
            output_pixel_addr<=0;
        end else if(conv_decoder_processing_element_array_ready) begin
            output_pixel_addr<=output_pixel_addr+1;
        end
    end

    /*** ready ***/
    assign ready=conv_decoder_processing_element_array_ready;

    /*** done ***/
    always@(posedge clk) begin
        if(output_pixel_addr==11519) begin
            done<=1;
        end
    end
endmodule