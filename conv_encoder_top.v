`timescale 1ns/ 1ps

module conv_encoder_top(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] input_pixel_0, input_pixel_1, input_pixel_2, input_pixel_3, input_pixel_4, input_pixel_5, input_pixel_6, input_pixel_7, input_pixel_8, input_pixel_9, input_pixel_10, input_pixel_11, input_pixel_12, input_pixel_13,
    output reg         [13: 0] input_pixel_addr,  // 180*64 -> 11520
    output wire signed [17: 0] output_pixel,
    output reg         [13: 0] output_pixel_addr, // 180*64 -> 11520
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

    /***** input buffer *****/
    wire                conv_encoder_input_buffer_start;
    wire                conv_encoder_input_buffer_ready [0: 13];
    wire signed [17: 0] input_pixel                     [0: 13];
    wire signed [17: 0] x                               [0: 13];

    assign conv_encoder_input_buffer_start=start&&delay==1;

    assign input_pixel[0 ]=input_pixel_0 ; assign input_pixel[1 ]=input_pixel_1 ; assign input_pixel[2 ]=input_pixel_2 ; assign input_pixel[3 ]=input_pixel_3 ; assign input_pixel[4 ]=input_pixel_4 ;
    assign input_pixel[5 ]=input_pixel_5 ; assign input_pixel[6 ]=input_pixel_6 ; assign input_pixel[7 ]=input_pixel_7 ; assign input_pixel[8 ]=input_pixel_8 ; assign input_pixel[9 ]=input_pixel_9 ;
    assign input_pixel[10]=input_pixel_10; assign input_pixel[11]=input_pixel_11; assign input_pixel[12]=input_pixel_12; assign input_pixel[13]=input_pixel_13;
    
    generate
        for(i=0; i<14; i=i+1) begin
            conv_encoder_input_buffer u_conv_encoder_input_buffer(
                .clk        (clk),
                .rst        (rst),
                .start      (conv_encoder_input_buffer_start),
                .input_pixel(input_pixel[i]),
                .x          (x[i]),
                .ready      (conv_encoder_input_buffer_ready[i])
            );
        end
    endgenerate

    /***** weights memory *****/
    wire                conv_encoder_weights_memory_start;
    wire                conv_encoder_weights_memory_ready [0: 13];
    wire signed [17: 0] w                                 [0: 13];

    assign conv_encoder_weights_memory_start=start;

    generate
        for(i=0; i<14; i=i+1) begin
            conv_encoder_weights_memory u_conv_encoder_weights_memory(
                .clk          (clk),
                .rst          (rst),
                .start        (conv_encoder_weights_memory_start),
                .input_filter (i),
                .output_filter(output_filter),
                .w            (w[i]),
                .ready        (conv_encoder_weights_memory_ready[i])
            );
        end
    endgenerate

    /***** processing element array *****/
    wire                conv_encoder_processing_element_array_start;
    wire                conv_encoder_processing_element_array_ready;
    wire signed [17: 0] processing_element_array_output_pixel;

    assign conv_encoder_processing_element_array_start=conv_encoder_input_buffer_ready[0]&conv_encoder_input_buffer_ready[1]&conv_encoder_input_buffer_ready[2]&conv_encoder_input_buffer_ready[3]&conv_encoder_input_buffer_ready[4]&conv_encoder_input_buffer_ready[5]&conv_encoder_input_buffer_ready[6]&conv_encoder_input_buffer_ready[7]&conv_encoder_input_buffer_ready[8]&conv_encoder_input_buffer_ready[9]&conv_encoder_input_buffer_ready[10]&conv_encoder_input_buffer_ready[11]&conv_encoder_input_buffer_ready[12]&conv_encoder_input_buffer_ready[13]&conv_encoder_weights_memory_ready[0]&conv_encoder_weights_memory_ready[1]&conv_encoder_weights_memory_ready[2]&conv_encoder_weights_memory_ready[3]&conv_encoder_weights_memory_ready[4]&conv_encoder_weights_memory_ready[5]&conv_encoder_weights_memory_ready[6]&conv_encoder_weights_memory_ready[7]&conv_encoder_weights_memory_ready[8]&conv_encoder_weights_memory_ready[9]&conv_encoder_weights_memory_ready[10]&conv_encoder_weights_memory_ready[11]&conv_encoder_weights_memory_ready[12]&conv_encoder_weights_memory_ready[13];
    
    conv_encoder_processing_element_array u_conv_encoder_processing_element_array(
        .clk         (clk),
        .rst         (rst),
        .start       (conv_encoder_processing_element_array_start),
        .x0(x[0]), .x1(x[1]), .x2(x[2]), .x3(x[3]), .x4(x[4]), .x5(x[5]), .x6(x[6]), .x7(x[7]), .x8(x[8]), .x9(x[9]), .x10(x[10]), .x11(x[11]), .x12(x[12]), .x13(x[13]),
        .w0(w[0]), .w1(w[1]), .w2(w[2]), .w3(w[3]), .w4(w[4]), .w5(w[5]), .w6(w[6]), .w7(w[7]), .w8(w[8]), .w9(w[9]), .w10(w[10]), .w11(w[11]), .w12(w[12]), .w13(w[13]),
        .output_pixel(processing_element_array_output_pixel),
        .ready       (conv_encoder_processing_element_array_ready)
    );

    /***** batch normalization weights memory *****/
    wire                conv_encoder_batch_normalization_weights_memory_start;
    wire                conv_encoder_batch_normalization_weights_memory_ready;
    wire signed [17: 0] batch_normalization_p;
    wire signed [35: 0] batch_normalization_q;

    assign conv_encoder_batch_normalization_weights_memory_start=start;

    conv_encoder_batch_normalization_weights_memory u_conv_encoder_batch_normalization_weights_memory(
        .clk       (clk),
        .rst       (rst),
        .start     (conv_encoder_batch_normalization_weights_memory_start),
        .filter_sel(output_filter),
        .p         (batch_normalization_p),
        .q         (batch_normalization_q),
        .ready     (conv_encoder_batch_normalization_weights_memory_ready)
    );

    /***** batch normalization *****/
    wire conv_encoder_batch_normalization_start;
    wire conv_encoder_batch_normalization_ready;

    assign conv_encoder_batch_normalization_start=conv_encoder_processing_element_array_ready&conv_encoder_batch_normalization_weights_memory_ready;

    conv_encoder_batch_normalization u_conv_encoder_batch_normalization(
        .clk         (clk),
        .rst         (rst),
        .start       (conv_encoder_batch_normalization_start),
        .x           (processing_element_array_output_pixel),
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
            if(input_pixel_addr<11519) begin
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
            if(output_pixel_addr%70>=3&&output_pixel_addr%70<66) begin
                output_pixel_addr<=output_pixel_addr+1;
            end else begin
                output_pixel_addr<=output_pixel_addr+7;
            end
        end
    end

    /*** output filter ***/
    always@(posedge clk) begin
        if(output_pixel_addr==12806) begin
            output_filter<=output_filter+1;
        end
    end

    /*** ready ***/
    assign ready=dsconv_block_batch_normalization_ready;

    /*** done ***/
    always@(posedge clk) begin
        if(output_filter==15&&output_pixel_addr==12806) begin
            done<=1;
        end
    end
endmodule