`timescale 1ns/ 1ps

module DSCNet_top(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [17: 0] input_pixel,
    input  wire         input_ready,
    output wire [17: 0] output_pixel,
    output wire         output_ready,
    output wire         done,
    output wire [17: 0] test
);
    assign test=write_addr;
    /***** DECALRATION *****/
    genvar i;
    reg [5: 0] FSM_STATE, FSM_NEXT_STATE;

    /***** input feature map buffer *****/
    reg                 input_feature_map_en    [0: 13];
    reg                 input_feature_map_wea;
    reg         [13: 0] input_feature_map_addra;
    reg  signed [17: 0] input_feature_map_dina;
    wire signed [17: 0] input_feature_map_douta [0: 13];

    /***** ping feature map buffer *****/
    reg                 ping_feature_map_ena;
    reg                 ping_feature_map_wea   [0: 15];
    reg         [13: 0] ping_feature_map_addra;
    reg  signed [17: 0] ping_feature_map_dina  [0: 15];
    wire signed [17: 0] ping_feature_map_douta [0: 15];

    /***** pong feature map buffer *****/
    reg                 pong_feature_map_ena;
    reg                 pong_feature_map_wea   [0: 15];
    reg         [13: 0] pong_feature_map_addra;
    reg  signed [17: 0] pong_feature_map_dina  [0: 15];
    wire signed [17: 0] pong_feature_map_douta [0: 15];

    /***** convolutional encoder layer *****/
    reg                 conv_encoder_rst;
    reg                 conv_encoder_start;
    reg  signed [17: 0] conv_encoder_input_pixel [0: 13];
    wire        [13: 0] conv_encoder_input_pixel_addr;
    wire signed [17: 0] conv_encoder_output_pixel;
    wire        [13: 0] conv_encoder_output_pixel_addr;
    wire        [3: 0]  conv_encoder_output_filter;
    wire                conv_encoder_ready;
    wire                conv_encoder_done;

    /***** depthwise separable convolutional *****/
    reg                 dsconv_block_rst;
    reg                 dsconv_block_start;
    reg         [2: 0]  dsconv_block_layer_sel;
    reg  signed [17: 0] dsconv_block_input_pixel [0: 15];
    wire        [13: 0] dsconv_block_input_pixel_addr;
    wire signed [17: 0] dsconv_block_output_pixel;
    wire        [13: 0] dsconv_block_output_pixel_addr;
    wire        [3: 0]  dsconv_block_output_filter;
    wire                dsconv_block_ready;
    wire                dsconv_block_done;

    /***** convolutional decoder layer *****/
    reg                 conv_decoder_rst;
    reg                 conv_decoder_start;
    reg  signed [17: 0] conv_decoder_input_pixel [0: 15];
    wire        [13: 0] conv_decoder_input_pixel_addr;
    wire signed [17: 0] conv_decoder_output_pixel;
    wire        [13: 0] conv_decoder_output_pixel_addr;
    wire                conv_decoder_ready;
    wire                conv_decoder_done;

    /***** CONTROL UNIT *****/
    assign output_pixel     =(conv_encoder_ready)? conv_encoder_output_pixel:
                             (dsconv_block_ready)? dsconv_block_output_pixel:
                             (conv_decoder_ready)? conv_decoder_output_pixel: 0;
    assign output_ready     =conv_encoder_ready | dsconv_block_ready | conv_decoder_ready;

    localparam IDLE              =6'd0;
    localparam IFMB_WRITE_0      =6'd1;
    localparam IFMB_WRITE_1      =6'd2;
    localparam IFMB_WRITE_2      =6'd3;
    localparam IFMB_WRITE_3      =6'd4;
    localparam IFMB_WRITE_4      =6'd5;
    localparam IFMB_WRITE_5      =6'd6;
    localparam IFMB_WRITE_6      =6'd7;
    localparam IFMB_WRITE_7      =6'd8;
    localparam IFMB_WRITE_8      =6'd9;
    localparam IFMB_WRITE_9      =6'd10;
    localparam IFMB_WRITE_10     =6'd11;
    localparam IFMB_WRITE_11     =6'd12;
    localparam IFMB_WRITE_12     =6'd13;
    localparam IFMB_WRITE_13     =6'd14;
    localparam IFMB_WRITE_RST    =6'd15;
    localparam CONV_ENCODER      =6'd16;
    localparam CONV_ENCODER_RST  =6'd17;
    localparam DSCONV_BLOCK_0    =6'd18;
    localparam DSCONV_BLOCK_0_RST=6'd19;
    localparam DSCONV_BLOCK_1    =6'd20;
    localparam DSCONV_BLOCK_1_RST=6'd21;
    localparam DSCONV_BLOCK_2    =6'd22;
    localparam DSCONV_BLOCK_2_RST=6'd23;
    localparam DSCONV_BLOCK_3    =6'd24;
    localparam DSCONV_BLOCK_3_RST=6'd25;
    localparam DSCONV_BLOCK_4    =6'd26;
    localparam DSCONV_BLOCK_4_RST=6'd27;
    localparam DSCONV_BLOCK_5    =6'd28;
    localparam DSCONV_BLOCK_5_RST=6'd29;
    localparam DSCONV_BLOCK_6    =6'd30;
    localparam DSCONV_BLOCK_6_RST=6'd31;
    localparam DSCONV_BLOCK_7    =6'd32;
    localparam DSCONV_BLOCK_7_RST=6'd33;
    localparam CONV_DECODER      =6'd34;
    localparam CONV_DECODER_RST  =6'd35;
    localparam DONE              =6'd36;

    // input feature map write controller
    reg [13: 0] write_addr;

    always@(posedge clk) begin
        if(rst) begin
            write_addr<=-1;
        end else if(start&input_ready) begin
            if(write_addr<11519) begin
                write_addr<=write_addr+1;
            end else begin
                write_addr<=0;
            end
        end
    end

    // state register
    always@(posedge clk) begin
        if(rst) begin
            FSM_STATE<=IDLE;
        end else if(start) begin
            FSM_STATE<=FSM_NEXT_STATE;
        end
    end

    // next state logic
    always@(*) begin
        case(FSM_STATE)
            IDLE: begin
                if(start) begin
                    FSM_NEXT_STATE=IFMB_WRITE_0;
                end else begin
                    FSM_NEXT_STATE=IDLE;
                end
            end IFMB_WRITE_0: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_1;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_0;
                end
            end IFMB_WRITE_1: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_2;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_1;
                end
            end IFMB_WRITE_2: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_3;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_2;
                end
            end IFMB_WRITE_3: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_4;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_3;
                end
            end IFMB_WRITE_4: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_5;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_4;
                end
            end IFMB_WRITE_5: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_6;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_5;
                end
            end IFMB_WRITE_6: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_7;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_6;
                end
            end IFMB_WRITE_7: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_8;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_7;
                end
            end IFMB_WRITE_8: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_9;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_8;
                end
            end IFMB_WRITE_9: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_10;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_9;
                end
            end IFMB_WRITE_10: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_11;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_10;
                end
            end IFMB_WRITE_11: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_12;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_11;
                end
            end IFMB_WRITE_12: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_13;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_12;
                end
            end IFMB_WRITE_13: begin
                if(write_addr==11519) begin
                    FSM_NEXT_STATE=IFMB_WRITE_RST;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_13;
                end
            end IFMB_WRITE_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=CONV_ENCODER;
                end else begin
                    FSM_NEXT_STATE=IFMB_WRITE_RST;
                end
            end CONV_ENCODER: begin
                if(conv_encoder_done) begin
                    FSM_NEXT_STATE=CONV_ENCODER_RST;
                end else begin
                    FSM_NEXT_STATE=CONV_ENCODER;
                end
            end CONV_ENCODER_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_0;
                end else begin
                    FSM_NEXT_STATE=CONV_ENCODER_RST;
                end
            end DSCONV_BLOCK_0: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_0_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_0;
                end
            end DSCONV_BLOCK_0_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_1;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_0_RST;
                end
            end DSCONV_BLOCK_1: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_1_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_1;
                end
            end DSCONV_BLOCK_1_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_2;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_1_RST;
                end
            end DSCONV_BLOCK_2: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_2_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_2;
                end
            end DSCONV_BLOCK_2_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_3;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_2_RST;
                end
            end DSCONV_BLOCK_3: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_3_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_3;
                end
            end DSCONV_BLOCK_3_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_4;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_3_RST;
                end
            end DSCONV_BLOCK_4: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_4_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_4;
                end
            end DSCONV_BLOCK_4_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_5;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_4_RST;
                end
            end DSCONV_BLOCK_5: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_5_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_5;
                end
            end DSCONV_BLOCK_5_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_6;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_5_RST;
                end
            end DSCONV_BLOCK_6: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_6_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_6;
                end
            end DSCONV_BLOCK_6_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_7;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_6_RST;
                end
            end DSCONV_BLOCK_7: begin
                if(dsconv_block_done) begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_7_RST;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_7;
                end
            end DSCONV_BLOCK_7_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=CONV_DECODER;
                end else begin
                    FSM_NEXT_STATE=DSCONV_BLOCK_7_RST;
                end
            end CONV_DECODER: begin
                if(conv_decoder_done) begin
                    FSM_NEXT_STATE=CONV_DECODER_RST;
                end else begin
                    FSM_NEXT_STATE=CONV_DECODER;
                end
            end CONV_DECODER_RST: begin
                if(start) begin
                    FSM_NEXT_STATE=DONE;
                end else begin
                    FSM_NEXT_STATE=CONV_DECODER_RST;
                end
            end DONE: begin
                if(start) begin
                    FSM_NEXT_STATE=DONE;
                end else begin
                    FSM_NEXT_STATE=DONE;
                end
            end default: begin
                FSM_NEXT_STATE=IDLE;
            end
        endcase
    end

    // output logic
    always@(*) begin
        case(FSM_STATE)
            IDLE: begin
                /*** reset input feature map buffer ***/
                input_feature_map_en[0]<=0; input_feature_map_en[1]<=0; input_feature_map_en[2]<=0; input_feature_map_en[3]<=0; input_feature_map_en[4]<=0; input_feature_map_en[5]<=0; input_feature_map_en[6]<=0; input_feature_map_en[7]<=0; input_feature_map_en[8]<=0; input_feature_map_en[9]<=0; input_feature_map_en[10]<=0; input_feature_map_en[11]<=0; input_feature_map_en[12]<=0; input_feature_map_en[13]<=0;
                input_feature_map_wea  <=0;
                input_feature_map_addra<=0;
                input_feature_map_dina <=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset conv encoder ***/
                conv_encoder_rst  <=1;
                conv_encoder_start<=0;
                conv_encoder_input_pixel[0]<=0; conv_encoder_input_pixel[1]<=0; conv_encoder_input_pixel[2]<=0; conv_encoder_input_pixel[3]<=0; conv_encoder_input_pixel[4]<=0; conv_encoder_input_pixel[5]<=0; conv_encoder_input_pixel[6]<=0; conv_encoder_input_pixel[7]<=0; conv_encoder_input_pixel[8]<=0; conv_encoder_input_pixel[9]<=0; conv_encoder_input_pixel[10]<=0; conv_encoder_input_pixel[11]<=0; conv_encoder_input_pixel[12]<=0; conv_encoder_input_pixel[13]<=0;

                /*** reset dsconv block ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset conv decoder ***/
                conv_decoder_rst  <=1;
                conv_decoder_start<=0;
                conv_decoder_input_pixel[0]<=0; conv_decoder_input_pixel[1]<=0; conv_decoder_input_pixel[2]<=0; conv_decoder_input_pixel[3]<=0; conv_decoder_input_pixel[4]<=0; conv_decoder_input_pixel[5]<=0; conv_decoder_input_pixel[6]<=0; conv_decoder_input_pixel[7]<=0; conv_decoder_input_pixel[8]<=0; conv_decoder_input_pixel[9]<=0; conv_decoder_input_pixel[10]<=0; conv_decoder_input_pixel[11]<=0; conv_decoder_input_pixel[12]<=0; conv_decoder_input_pixel[13]<=0; conv_decoder_input_pixel[14]<=0; conv_decoder_input_pixel[15]<=0;
            end IFMB_WRITE_0: begin
                input_feature_map_en[0]<=input_ready;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_1: begin
                input_feature_map_en[1]<=input_ready;
                input_feature_map_en[0]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_2: begin
                input_feature_map_en[2]<=input_ready;
                input_feature_map_en[1]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_3: begin
                input_feature_map_en[3]<=input_ready;
                input_feature_map_en[2]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_4: begin
                input_feature_map_en[4]<=input_ready;
                input_feature_map_en[3]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_5: begin
                input_feature_map_en[5]<=input_ready;
                input_feature_map_en[4]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_6: begin
                input_feature_map_en[6]<=input_ready;
                input_feature_map_en[5]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_7: begin
                input_feature_map_en[7]<=input_ready;
                input_feature_map_en[6]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_8: begin
                input_feature_map_en[8]<=input_ready;
                input_feature_map_en[7]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_9: begin
                input_feature_map_en[9]<=input_ready;
                input_feature_map_en[8]<=0;
                input_feature_map_wea  <=1;
                input_feature_map_addra<=write_addr;
                input_feature_map_dina <=input_pixel;
            end IFMB_WRITE_10: begin
                input_feature_map_en[10]<=input_ready;
                input_feature_map_en[9 ]<=0;
                input_feature_map_wea   <=1;
                input_feature_map_addra <=write_addr;
                input_feature_map_dina  <=input_pixel;
            end IFMB_WRITE_11: begin
                input_feature_map_en[11]<=input_ready;
                input_feature_map_en[10]<=0;
                input_feature_map_wea   <=1;
                input_feature_map_addra <=write_addr;
                input_feature_map_dina  <=input_pixel;
            end IFMB_WRITE_12: begin
                input_feature_map_en[12]<=input_ready;
                input_feature_map_en[11]<=0;
                input_feature_map_wea   <=1;
                input_feature_map_addra <=write_addr;
                input_feature_map_dina  <=input_pixel;
            end IFMB_WRITE_13: begin
                input_feature_map_en[13]<=input_ready;
                input_feature_map_en[12]<=0;
                input_feature_map_wea   <=1;
                input_feature_map_addra <=write_addr;
                input_feature_map_dina  <=input_pixel;
            end IFMB_WRITE_RST: begin
                input_feature_map_en[0]<=0; input_feature_map_en[1]<=0; input_feature_map_en[2]<=0; input_feature_map_en[3]<=0; input_feature_map_en[4]<=0; input_feature_map_en[5]<=0; input_feature_map_en[6]<=0; input_feature_map_en[7]<=0; input_feature_map_en[8]<=0; input_feature_map_en[9]<=0; input_feature_map_en[10]<=0; input_feature_map_en[11]<=0; input_feature_map_en[12]<=0; input_feature_map_en[13]<=0;
                input_feature_map_wea  <=0;
                input_feature_map_addra<=0;
                input_feature_map_dina <=0;
            end CONV_ENCODER: begin
                /*** conv encoder ***/
                if(conv_encoder_output_pixel_addr==12806) begin
                    conv_encoder_rst<=1;
                end else begin
                    conv_encoder_rst<=0;
                end
                conv_encoder_start<=1;
                conv_encoder_input_pixel[0]<=input_feature_map_douta[0]; conv_encoder_input_pixel[1]<=input_feature_map_douta[1]; conv_encoder_input_pixel[2]<=input_feature_map_douta[2]; conv_encoder_input_pixel[3]<=input_feature_map_douta[3]; conv_encoder_input_pixel[4]<=input_feature_map_douta[4]; conv_encoder_input_pixel[5]<=input_feature_map_douta[5]; conv_encoder_input_pixel[6]<=input_feature_map_douta[6]; conv_encoder_input_pixel[7]<=input_feature_map_douta[7]; conv_encoder_input_pixel[8]<=input_feature_map_douta[8]; conv_encoder_input_pixel[9]<=input_feature_map_douta[9]; conv_encoder_input_pixel[10]<=input_feature_map_douta[10]; conv_encoder_input_pixel[11]<=input_feature_map_douta[11]; conv_encoder_input_pixel[12]<=input_feature_map_douta[12]; conv_encoder_input_pixel[13]<=input_feature_map_douta[13];

                /*** input feature map buffer ***/
                input_feature_map_en[0]<=1; input_feature_map_en[1]<=1; input_feature_map_en[2]<=1; input_feature_map_en[3]<=1; input_feature_map_en[4]<=1; input_feature_map_en[5]<=1; input_feature_map_en[6]<=1; input_feature_map_en[7]<=1; input_feature_map_en[8]<=1; input_feature_map_en[9]<=1; input_feature_map_en[10]<=1; input_feature_map_en[11]<=1; input_feature_map_en[12]<=1; input_feature_map_en[13]<=1;
                input_feature_map_addra<=conv_encoder_input_pixel_addr;
                input_feature_map_wea  <=0;

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=conv_encoder_output_filter==0; ping_feature_map_wea[1]<=conv_encoder_output_filter==1; ping_feature_map_wea[2]<=conv_encoder_output_filter==2; ping_feature_map_wea[3]<=conv_encoder_output_filter==3; ping_feature_map_wea[4]<=conv_encoder_output_filter==4; ping_feature_map_wea[5]<=conv_encoder_output_filter==5; ping_feature_map_wea[6]<=conv_encoder_output_filter==6; ping_feature_map_wea[7]<=conv_encoder_output_filter==7; ping_feature_map_wea[8]<=conv_encoder_output_filter==8; ping_feature_map_wea[9]<=conv_encoder_output_filter==9; ping_feature_map_wea[10]<=conv_encoder_output_filter==10; ping_feature_map_wea[11]<=conv_encoder_output_filter==11; ping_feature_map_wea[12]<=conv_encoder_output_filter==12; ping_feature_map_wea[13]<=conv_encoder_output_filter==13; ping_feature_map_wea[14]<=conv_encoder_output_filter==14; ping_feature_map_wea[15]<=conv_encoder_output_filter==15;
                ping_feature_map_addra<=conv_encoder_output_pixel_addr;
                ping_feature_map_dina[0]<=conv_encoder_output_pixel; ping_feature_map_dina[1]<=conv_encoder_output_pixel; ping_feature_map_dina[2]<=conv_encoder_output_pixel; ping_feature_map_dina[3]<=conv_encoder_output_pixel; ping_feature_map_dina[4]<=conv_encoder_output_pixel; ping_feature_map_dina[5]<=conv_encoder_output_pixel; ping_feature_map_dina[6]<=conv_encoder_output_pixel; ping_feature_map_dina[7]<=conv_encoder_output_pixel; ping_feature_map_dina[8]<=conv_encoder_output_pixel; ping_feature_map_dina[9]<=conv_encoder_output_pixel; ping_feature_map_dina[10]<=conv_encoder_output_pixel; ping_feature_map_dina[11]<=conv_encoder_output_pixel; ping_feature_map_dina[12]<=conv_encoder_output_pixel; ping_feature_map_dina[13]<=conv_encoder_output_pixel; ping_feature_map_dina[14]<=conv_encoder_output_pixel; ping_feature_map_dina[15]<=conv_encoder_output_pixel;
            end CONV_ENCODER_RST: begin
                /*** reset conv encoder ***/
                conv_encoder_rst  <=1;
                conv_encoder_start<=0;
                conv_encoder_input_pixel[0]<=0; conv_encoder_input_pixel[1]<=0; conv_encoder_input_pixel[2]<=0; conv_encoder_input_pixel[3]<=0; conv_encoder_input_pixel[4]<=0; conv_encoder_input_pixel[5]<=0; conv_encoder_input_pixel[6]<=0; conv_encoder_input_pixel[7]<=0; conv_encoder_input_pixel[8]<=0; conv_encoder_input_pixel[9]<=0; conv_encoder_input_pixel[10]<=0; conv_encoder_input_pixel[11]<=0; conv_encoder_input_pixel[12]<=0; conv_encoder_input_pixel[13]<=0;
                
                /*** reset input feature map buffer ***/
                input_feature_map_en[0]<=0; input_feature_map_en[1]<=0; input_feature_map_en[2]<=0; input_feature_map_en[3]<=0; input_feature_map_en[4]<=0; input_feature_map_en[5]<=0; input_feature_map_en[6]<=0; input_feature_map_en[7]<=0; input_feature_map_en[8]<=0; input_feature_map_en[9]<=0; input_feature_map_en[10]<=0; input_feature_map_en[11]<=0; input_feature_map_en[12]<=0; input_feature_map_en[13]<=0;
                input_feature_map_addra<=0;
                input_feature_map_wea  <=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_0: begin
                /*** dsconv block 0 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=ping_feature_map_douta[0]; dsconv_block_input_pixel[1]<=ping_feature_map_douta[1]; dsconv_block_input_pixel[2]<=ping_feature_map_douta[2]; dsconv_block_input_pixel[3]<=ping_feature_map_douta[3]; dsconv_block_input_pixel[4]<=ping_feature_map_douta[4]; dsconv_block_input_pixel[5]<=ping_feature_map_douta[5]; dsconv_block_input_pixel[6]<=ping_feature_map_douta[6]; dsconv_block_input_pixel[7]<=ping_feature_map_douta[7]; dsconv_block_input_pixel[8]<=ping_feature_map_douta[8]; dsconv_block_input_pixel[9]<=ping_feature_map_douta[9]; dsconv_block_input_pixel[10]<=ping_feature_map_douta[10]; dsconv_block_input_pixel[11]<=ping_feature_map_douta[11]; dsconv_block_input_pixel[12]<=ping_feature_map_douta[12]; dsconv_block_input_pixel[13]<=ping_feature_map_douta[13]; dsconv_block_input_pixel[14]<=ping_feature_map_douta[14]; dsconv_block_input_pixel[15]<=ping_feature_map_douta[15];

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=dsconv_block_output_filter==0; pong_feature_map_wea[1]<=dsconv_block_output_filter==1; pong_feature_map_wea[2]<=dsconv_block_output_filter==2; pong_feature_map_wea[3]<=dsconv_block_output_filter==3; pong_feature_map_wea[4]<=dsconv_block_output_filter==4; pong_feature_map_wea[5]<=dsconv_block_output_filter==5; pong_feature_map_wea[6]<=dsconv_block_output_filter==6; pong_feature_map_wea[7]<=dsconv_block_output_filter==7; pong_feature_map_wea[8]<=dsconv_block_output_filter==8; pong_feature_map_wea[9]<=dsconv_block_output_filter==9; pong_feature_map_wea[10]<=dsconv_block_output_filter==10; pong_feature_map_wea[11]<=dsconv_block_output_filter==11; pong_feature_map_wea[12]<=dsconv_block_output_filter==12; pong_feature_map_wea[13]<=dsconv_block_output_filter==13; pong_feature_map_wea[14]<=dsconv_block_output_filter==14; pong_feature_map_wea[15]<=dsconv_block_output_filter==15;
                pong_feature_map_addra<=dsconv_block_output_pixel_addr;
                pong_feature_map_dina[0]<=dsconv_block_output_pixel; pong_feature_map_dina[1]<=dsconv_block_output_pixel; pong_feature_map_dina[2]<=dsconv_block_output_pixel; pong_feature_map_dina[3]<=dsconv_block_output_pixel; pong_feature_map_dina[4]<=dsconv_block_output_pixel; pong_feature_map_dina[5]<=dsconv_block_output_pixel; pong_feature_map_dina[6]<=dsconv_block_output_pixel; pong_feature_map_dina[7]<=dsconv_block_output_pixel; pong_feature_map_dina[8]<=dsconv_block_output_pixel; pong_feature_map_dina[9]<=dsconv_block_output_pixel; pong_feature_map_dina[10]<=dsconv_block_output_pixel; pong_feature_map_dina[11]<=dsconv_block_output_pixel; pong_feature_map_dina[12]<=dsconv_block_output_pixel; pong_feature_map_dina[13]<=dsconv_block_output_pixel; pong_feature_map_dina[14]<=dsconv_block_output_pixel; pong_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_0_RST: begin
                /*** reset dsconv block 0 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_1: begin
                /*** dsconv block 1 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=1;
                dsconv_block_input_pixel[0]<=pong_feature_map_douta[0]; dsconv_block_input_pixel[1]<=pong_feature_map_douta[1]; dsconv_block_input_pixel[2]<=pong_feature_map_douta[2]; dsconv_block_input_pixel[3]<=pong_feature_map_douta[3]; dsconv_block_input_pixel[4]<=pong_feature_map_douta[4]; dsconv_block_input_pixel[5]<=pong_feature_map_douta[5]; dsconv_block_input_pixel[6]<=pong_feature_map_douta[6]; dsconv_block_input_pixel[7]<=pong_feature_map_douta[7]; dsconv_block_input_pixel[8]<=pong_feature_map_douta[8]; dsconv_block_input_pixel[9]<=pong_feature_map_douta[9]; dsconv_block_input_pixel[10]<=pong_feature_map_douta[10]; dsconv_block_input_pixel[11]<=pong_feature_map_douta[11]; dsconv_block_input_pixel[12]<=pong_feature_map_douta[12]; dsconv_block_input_pixel[13]<=pong_feature_map_douta[13]; dsconv_block_input_pixel[14]<=pong_feature_map_douta[14]; dsconv_block_input_pixel[15]<=pong_feature_map_douta[15];

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=dsconv_block_output_filter==0; ping_feature_map_wea[1]<=dsconv_block_output_filter==1; ping_feature_map_wea[2]<=dsconv_block_output_filter==2; ping_feature_map_wea[3]<=dsconv_block_output_filter==3; ping_feature_map_wea[4]<=dsconv_block_output_filter==4; ping_feature_map_wea[5]<=dsconv_block_output_filter==5; ping_feature_map_wea[6]<=dsconv_block_output_filter==6; ping_feature_map_wea[7]<=dsconv_block_output_filter==7; ping_feature_map_wea[8]<=dsconv_block_output_filter==8; ping_feature_map_wea[9]<=dsconv_block_output_filter==9; ping_feature_map_wea[10]<=dsconv_block_output_filter==10; ping_feature_map_wea[11]<=dsconv_block_output_filter==11; ping_feature_map_wea[12]<=dsconv_block_output_filter==12; ping_feature_map_wea[13]<=dsconv_block_output_filter==13; ping_feature_map_wea[14]<=dsconv_block_output_filter==14; ping_feature_map_wea[15]<=dsconv_block_output_filter==15;
                ping_feature_map_addra<=dsconv_block_output_pixel_addr;
                ping_feature_map_dina[0]<=dsconv_block_output_pixel; ping_feature_map_dina[1]<=dsconv_block_output_pixel; ping_feature_map_dina[2]<=dsconv_block_output_pixel; ping_feature_map_dina[3]<=dsconv_block_output_pixel; ping_feature_map_dina[4]<=dsconv_block_output_pixel; ping_feature_map_dina[5]<=dsconv_block_output_pixel; ping_feature_map_dina[6]<=dsconv_block_output_pixel; ping_feature_map_dina[7]<=dsconv_block_output_pixel; ping_feature_map_dina[8]<=dsconv_block_output_pixel; ping_feature_map_dina[9]<=dsconv_block_output_pixel; ping_feature_map_dina[10]<=dsconv_block_output_pixel; ping_feature_map_dina[11]<=dsconv_block_output_pixel; ping_feature_map_dina[12]<=dsconv_block_output_pixel; ping_feature_map_dina[13]<=dsconv_block_output_pixel; ping_feature_map_dina[14]<=dsconv_block_output_pixel; ping_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_1_RST: begin
                /*** reset dsconv block 1 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;
                
                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_2: begin
                /*** dsconv block 2 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=2;
                dsconv_block_input_pixel[0]<=ping_feature_map_douta[0]; dsconv_block_input_pixel[1]<=ping_feature_map_douta[1]; dsconv_block_input_pixel[2]<=ping_feature_map_douta[2]; dsconv_block_input_pixel[3]<=ping_feature_map_douta[3]; dsconv_block_input_pixel[4]<=ping_feature_map_douta[4]; dsconv_block_input_pixel[5]<=ping_feature_map_douta[5]; dsconv_block_input_pixel[6]<=ping_feature_map_douta[6]; dsconv_block_input_pixel[7]<=ping_feature_map_douta[7]; dsconv_block_input_pixel[8]<=ping_feature_map_douta[8]; dsconv_block_input_pixel[9]<=ping_feature_map_douta[9]; dsconv_block_input_pixel[10]<=ping_feature_map_douta[10]; dsconv_block_input_pixel[11]<=ping_feature_map_douta[11]; dsconv_block_input_pixel[12]<=ping_feature_map_douta[12]; dsconv_block_input_pixel[13]<=ping_feature_map_douta[13]; dsconv_block_input_pixel[14]<=ping_feature_map_douta[14]; dsconv_block_input_pixel[15]<=ping_feature_map_douta[15];

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=dsconv_block_output_filter==0; pong_feature_map_wea[1]<=dsconv_block_output_filter==1; pong_feature_map_wea[2]<=dsconv_block_output_filter==2; pong_feature_map_wea[3]<=dsconv_block_output_filter==3; pong_feature_map_wea[4]<=dsconv_block_output_filter==4; pong_feature_map_wea[5]<=dsconv_block_output_filter==5; pong_feature_map_wea[6]<=dsconv_block_output_filter==6; pong_feature_map_wea[7]<=dsconv_block_output_filter==7; pong_feature_map_wea[8]<=dsconv_block_output_filter==8; pong_feature_map_wea[9]<=dsconv_block_output_filter==9; pong_feature_map_wea[10]<=dsconv_block_output_filter==10; pong_feature_map_wea[11]<=dsconv_block_output_filter==11; pong_feature_map_wea[12]<=dsconv_block_output_filter==12; pong_feature_map_wea[13]<=dsconv_block_output_filter==13; pong_feature_map_wea[14]<=dsconv_block_output_filter==14; pong_feature_map_wea[15]<=dsconv_block_output_filter==15;
                pong_feature_map_addra<=dsconv_block_output_pixel_addr;
                pong_feature_map_dina[0]<=dsconv_block_output_pixel; pong_feature_map_dina[1]<=dsconv_block_output_pixel; pong_feature_map_dina[2]<=dsconv_block_output_pixel; pong_feature_map_dina[3]<=dsconv_block_output_pixel; pong_feature_map_dina[4]<=dsconv_block_output_pixel; pong_feature_map_dina[5]<=dsconv_block_output_pixel; pong_feature_map_dina[6]<=dsconv_block_output_pixel; pong_feature_map_dina[7]<=dsconv_block_output_pixel; pong_feature_map_dina[8]<=dsconv_block_output_pixel; pong_feature_map_dina[9]<=dsconv_block_output_pixel; pong_feature_map_dina[10]<=dsconv_block_output_pixel; pong_feature_map_dina[11]<=dsconv_block_output_pixel; pong_feature_map_dina[12]<=dsconv_block_output_pixel; pong_feature_map_dina[13]<=dsconv_block_output_pixel; pong_feature_map_dina[14]<=dsconv_block_output_pixel; pong_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_2_RST: begin
                /*** reset dsconv block 2 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_3: begin
                /*** dsconv block 3 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=3;
                dsconv_block_input_pixel[0]<=pong_feature_map_douta[0]; dsconv_block_input_pixel[1]<=pong_feature_map_douta[1]; dsconv_block_input_pixel[2]<=pong_feature_map_douta[2]; dsconv_block_input_pixel[3]<=pong_feature_map_douta[3]; dsconv_block_input_pixel[4]<=pong_feature_map_douta[4]; dsconv_block_input_pixel[5]<=pong_feature_map_douta[5]; dsconv_block_input_pixel[6]<=pong_feature_map_douta[6]; dsconv_block_input_pixel[7]<=pong_feature_map_douta[7]; dsconv_block_input_pixel[8]<=pong_feature_map_douta[8]; dsconv_block_input_pixel[9]<=pong_feature_map_douta[9]; dsconv_block_input_pixel[10]<=pong_feature_map_douta[10]; dsconv_block_input_pixel[11]<=pong_feature_map_douta[11]; dsconv_block_input_pixel[12]<=pong_feature_map_douta[12]; dsconv_block_input_pixel[13]<=pong_feature_map_douta[13]; dsconv_block_input_pixel[14]<=pong_feature_map_douta[14]; dsconv_block_input_pixel[15]<=pong_feature_map_douta[15];

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=dsconv_block_output_filter==0; ping_feature_map_wea[1]<=dsconv_block_output_filter==1; ping_feature_map_wea[2]<=dsconv_block_output_filter==2; ping_feature_map_wea[3]<=dsconv_block_output_filter==3; ping_feature_map_wea[4]<=dsconv_block_output_filter==4; ping_feature_map_wea[5]<=dsconv_block_output_filter==5; ping_feature_map_wea[6]<=dsconv_block_output_filter==6; ping_feature_map_wea[7]<=dsconv_block_output_filter==7; ping_feature_map_wea[8]<=dsconv_block_output_filter==8; ping_feature_map_wea[9]<=dsconv_block_output_filter==9; ping_feature_map_wea[10]<=dsconv_block_output_filter==10; ping_feature_map_wea[11]<=dsconv_block_output_filter==11; ping_feature_map_wea[12]<=dsconv_block_output_filter==12; ping_feature_map_wea[13]<=dsconv_block_output_filter==13; ping_feature_map_wea[14]<=dsconv_block_output_filter==14; ping_feature_map_wea[15]<=dsconv_block_output_filter==15;
                ping_feature_map_addra<=dsconv_block_output_pixel_addr;
                ping_feature_map_dina[0]<=dsconv_block_output_pixel; ping_feature_map_dina[1]<=dsconv_block_output_pixel; ping_feature_map_dina[2]<=dsconv_block_output_pixel; ping_feature_map_dina[3]<=dsconv_block_output_pixel; ping_feature_map_dina[4]<=dsconv_block_output_pixel; ping_feature_map_dina[5]<=dsconv_block_output_pixel; ping_feature_map_dina[6]<=dsconv_block_output_pixel; ping_feature_map_dina[7]<=dsconv_block_output_pixel; ping_feature_map_dina[8]<=dsconv_block_output_pixel; ping_feature_map_dina[9]<=dsconv_block_output_pixel; ping_feature_map_dina[10]<=dsconv_block_output_pixel; ping_feature_map_dina[11]<=dsconv_block_output_pixel; ping_feature_map_dina[12]<=dsconv_block_output_pixel; ping_feature_map_dina[13]<=dsconv_block_output_pixel; ping_feature_map_dina[14]<=dsconv_block_output_pixel; ping_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_3_RST: begin
                /*** reset dsconv block 3 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_4: begin
                /*** dsconv block 4 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=4;
                dsconv_block_input_pixel[0]<=ping_feature_map_douta[0]; dsconv_block_input_pixel[1]<=ping_feature_map_douta[1]; dsconv_block_input_pixel[2]<=ping_feature_map_douta[2]; dsconv_block_input_pixel[3]<=ping_feature_map_douta[3]; dsconv_block_input_pixel[4]<=ping_feature_map_douta[4]; dsconv_block_input_pixel[5]<=ping_feature_map_douta[5]; dsconv_block_input_pixel[6]<=ping_feature_map_douta[6]; dsconv_block_input_pixel[7]<=ping_feature_map_douta[7]; dsconv_block_input_pixel[8]<=ping_feature_map_douta[8]; dsconv_block_input_pixel[9]<=ping_feature_map_douta[9]; dsconv_block_input_pixel[10]<=ping_feature_map_douta[10]; dsconv_block_input_pixel[11]<=ping_feature_map_douta[11]; dsconv_block_input_pixel[12]<=ping_feature_map_douta[12]; dsconv_block_input_pixel[13]<=ping_feature_map_douta[13]; dsconv_block_input_pixel[14]<=ping_feature_map_douta[14]; dsconv_block_input_pixel[15]<=ping_feature_map_douta[15];

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=dsconv_block_output_filter==0; pong_feature_map_wea[1]<=dsconv_block_output_filter==1; pong_feature_map_wea[2]<=dsconv_block_output_filter==2; pong_feature_map_wea[3]<=dsconv_block_output_filter==3; pong_feature_map_wea[4]<=dsconv_block_output_filter==4; pong_feature_map_wea[5]<=dsconv_block_output_filter==5; pong_feature_map_wea[6]<=dsconv_block_output_filter==6; pong_feature_map_wea[7]<=dsconv_block_output_filter==7; pong_feature_map_wea[8]<=dsconv_block_output_filter==8; pong_feature_map_wea[9]<=dsconv_block_output_filter==9; pong_feature_map_wea[10]<=dsconv_block_output_filter==10; pong_feature_map_wea[11]<=dsconv_block_output_filter==11; pong_feature_map_wea[12]<=dsconv_block_output_filter==12; pong_feature_map_wea[13]<=dsconv_block_output_filter==13; pong_feature_map_wea[14]<=dsconv_block_output_filter==14; pong_feature_map_wea[15]<=dsconv_block_output_filter==15;
                pong_feature_map_addra<=dsconv_block_output_pixel_addr;
                pong_feature_map_dina[0]<=dsconv_block_output_pixel; pong_feature_map_dina[1]<=dsconv_block_output_pixel; pong_feature_map_dina[2]<=dsconv_block_output_pixel; pong_feature_map_dina[3]<=dsconv_block_output_pixel; pong_feature_map_dina[4]<=dsconv_block_output_pixel; pong_feature_map_dina[5]<=dsconv_block_output_pixel; pong_feature_map_dina[6]<=dsconv_block_output_pixel; pong_feature_map_dina[7]<=dsconv_block_output_pixel; pong_feature_map_dina[8]<=dsconv_block_output_pixel; pong_feature_map_dina[9]<=dsconv_block_output_pixel; pong_feature_map_dina[10]<=dsconv_block_output_pixel; pong_feature_map_dina[11]<=dsconv_block_output_pixel; pong_feature_map_dina[12]<=dsconv_block_output_pixel; pong_feature_map_dina[13]<=dsconv_block_output_pixel; pong_feature_map_dina[14]<=dsconv_block_output_pixel; pong_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_4_RST: begin
                /*** reset dsconv block 4 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_5: begin
                /*** dsconv block 5 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=5;
                dsconv_block_input_pixel[0]<=pong_feature_map_douta[0]; dsconv_block_input_pixel[1]<=pong_feature_map_douta[1]; dsconv_block_input_pixel[2]<=pong_feature_map_douta[2]; dsconv_block_input_pixel[3]<=pong_feature_map_douta[3]; dsconv_block_input_pixel[4]<=pong_feature_map_douta[4]; dsconv_block_input_pixel[5]<=pong_feature_map_douta[5]; dsconv_block_input_pixel[6]<=pong_feature_map_douta[6]; dsconv_block_input_pixel[7]<=pong_feature_map_douta[7]; dsconv_block_input_pixel[8]<=pong_feature_map_douta[8]; dsconv_block_input_pixel[9]<=pong_feature_map_douta[9]; dsconv_block_input_pixel[10]<=pong_feature_map_douta[10]; dsconv_block_input_pixel[11]<=pong_feature_map_douta[11]; dsconv_block_input_pixel[12]<=pong_feature_map_douta[12]; dsconv_block_input_pixel[13]<=pong_feature_map_douta[13]; dsconv_block_input_pixel[14]<=pong_feature_map_douta[14]; dsconv_block_input_pixel[15]<=pong_feature_map_douta[15];

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=dsconv_block_output_filter==0; ping_feature_map_wea[1]<=dsconv_block_output_filter==1; ping_feature_map_wea[2]<=dsconv_block_output_filter==2; ping_feature_map_wea[3]<=dsconv_block_output_filter==3; ping_feature_map_wea[4]<=dsconv_block_output_filter==4; ping_feature_map_wea[5]<=dsconv_block_output_filter==5; ping_feature_map_wea[6]<=dsconv_block_output_filter==6; ping_feature_map_wea[7]<=dsconv_block_output_filter==7; ping_feature_map_wea[8]<=dsconv_block_output_filter==8; ping_feature_map_wea[9]<=dsconv_block_output_filter==9; ping_feature_map_wea[10]<=dsconv_block_output_filter==10; ping_feature_map_wea[11]<=dsconv_block_output_filter==11; ping_feature_map_wea[12]<=dsconv_block_output_filter==12; ping_feature_map_wea[13]<=dsconv_block_output_filter==13; ping_feature_map_wea[14]<=dsconv_block_output_filter==14; ping_feature_map_wea[15]<=dsconv_block_output_filter==15;
                ping_feature_map_addra<=dsconv_block_output_pixel_addr;
                ping_feature_map_dina[0]<=dsconv_block_output_pixel; ping_feature_map_dina[1]<=dsconv_block_output_pixel; ping_feature_map_dina[2]<=dsconv_block_output_pixel; ping_feature_map_dina[3]<=dsconv_block_output_pixel; ping_feature_map_dina[4]<=dsconv_block_output_pixel; ping_feature_map_dina[5]<=dsconv_block_output_pixel; ping_feature_map_dina[6]<=dsconv_block_output_pixel; ping_feature_map_dina[7]<=dsconv_block_output_pixel; ping_feature_map_dina[8]<=dsconv_block_output_pixel; ping_feature_map_dina[9]<=dsconv_block_output_pixel; ping_feature_map_dina[10]<=dsconv_block_output_pixel; ping_feature_map_dina[11]<=dsconv_block_output_pixel; ping_feature_map_dina[12]<=dsconv_block_output_pixel; ping_feature_map_dina[13]<=dsconv_block_output_pixel; ping_feature_map_dina[14]<=dsconv_block_output_pixel; ping_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_5_RST: begin
                /*** reset dsconv block 5 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_6: begin
                /*** dsconv block 6 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=6;
                dsconv_block_input_pixel[0]<=ping_feature_map_douta[0]; dsconv_block_input_pixel[1]<=ping_feature_map_douta[1]; dsconv_block_input_pixel[2]<=ping_feature_map_douta[2]; dsconv_block_input_pixel[3]<=ping_feature_map_douta[3]; dsconv_block_input_pixel[4]<=ping_feature_map_douta[4]; dsconv_block_input_pixel[5]<=ping_feature_map_douta[5]; dsconv_block_input_pixel[6]<=ping_feature_map_douta[6]; dsconv_block_input_pixel[7]<=ping_feature_map_douta[7]; dsconv_block_input_pixel[8]<=ping_feature_map_douta[8]; dsconv_block_input_pixel[9]<=ping_feature_map_douta[9]; dsconv_block_input_pixel[10]<=ping_feature_map_douta[10]; dsconv_block_input_pixel[11]<=ping_feature_map_douta[11]; dsconv_block_input_pixel[12]<=ping_feature_map_douta[12]; dsconv_block_input_pixel[13]<=ping_feature_map_douta[13]; dsconv_block_input_pixel[14]<=ping_feature_map_douta[14]; dsconv_block_input_pixel[15]<=ping_feature_map_douta[15];

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=dsconv_block_output_filter==0; pong_feature_map_wea[1]<=dsconv_block_output_filter==1; pong_feature_map_wea[2]<=dsconv_block_output_filter==2; pong_feature_map_wea[3]<=dsconv_block_output_filter==3; pong_feature_map_wea[4]<=dsconv_block_output_filter==4; pong_feature_map_wea[5]<=dsconv_block_output_filter==5; pong_feature_map_wea[6]<=dsconv_block_output_filter==6; pong_feature_map_wea[7]<=dsconv_block_output_filter==7; pong_feature_map_wea[8]<=dsconv_block_output_filter==8; pong_feature_map_wea[9]<=dsconv_block_output_filter==9; pong_feature_map_wea[10]<=dsconv_block_output_filter==10; pong_feature_map_wea[11]<=dsconv_block_output_filter==11; pong_feature_map_wea[12]<=dsconv_block_output_filter==12; pong_feature_map_wea[13]<=dsconv_block_output_filter==13; pong_feature_map_wea[14]<=dsconv_block_output_filter==14; pong_feature_map_wea[15]<=dsconv_block_output_filter==15;
                pong_feature_map_addra<=dsconv_block_output_pixel_addr;
                pong_feature_map_dina[0]<=dsconv_block_output_pixel; pong_feature_map_dina[1]<=dsconv_block_output_pixel; pong_feature_map_dina[2]<=dsconv_block_output_pixel; pong_feature_map_dina[3]<=dsconv_block_output_pixel; pong_feature_map_dina[4]<=dsconv_block_output_pixel; pong_feature_map_dina[5]<=dsconv_block_output_pixel; pong_feature_map_dina[6]<=dsconv_block_output_pixel; pong_feature_map_dina[7]<=dsconv_block_output_pixel; pong_feature_map_dina[8]<=dsconv_block_output_pixel; pong_feature_map_dina[9]<=dsconv_block_output_pixel; pong_feature_map_dina[10]<=dsconv_block_output_pixel; pong_feature_map_dina[11]<=dsconv_block_output_pixel; pong_feature_map_dina[12]<=dsconv_block_output_pixel; pong_feature_map_dina[13]<=dsconv_block_output_pixel; pong_feature_map_dina[14]<=dsconv_block_output_pixel; pong_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_6_RST: begin
                /*** reset dsconv block 6 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;
            end DSCONV_BLOCK_7: begin
                /*** dsconv block 7 ***/
                if(dsconv_block_output_pixel_addr==12806) begin
                    dsconv_block_rst<=1;
                end else begin
                    dsconv_block_rst<=0;
                end
                dsconv_block_start    <=1;
                dsconv_block_layer_sel<=7;
                dsconv_block_input_pixel[0]<=pong_feature_map_douta[0]; dsconv_block_input_pixel[1]<=pong_feature_map_douta[1]; dsconv_block_input_pixel[2]<=pong_feature_map_douta[2]; dsconv_block_input_pixel[3]<=pong_feature_map_douta[3]; dsconv_block_input_pixel[4]<=pong_feature_map_douta[4]; dsconv_block_input_pixel[5]<=pong_feature_map_douta[5]; dsconv_block_input_pixel[6]<=pong_feature_map_douta[6]; dsconv_block_input_pixel[7]<=pong_feature_map_douta[7]; dsconv_block_input_pixel[8]<=pong_feature_map_douta[8]; dsconv_block_input_pixel[9]<=pong_feature_map_douta[9]; dsconv_block_input_pixel[10]<=pong_feature_map_douta[10]; dsconv_block_input_pixel[11]<=pong_feature_map_douta[11]; dsconv_block_input_pixel[12]<=pong_feature_map_douta[12]; dsconv_block_input_pixel[13]<=pong_feature_map_douta[13]; dsconv_block_input_pixel[14]<=pong_feature_map_douta[14]; dsconv_block_input_pixel[15]<=pong_feature_map_douta[15];

                /*** pong feature map buffer ***/
                pong_feature_map_ena  <=1;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=dsconv_block_input_pixel_addr;

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=dsconv_block_output_filter==0; ping_feature_map_wea[1]<=dsconv_block_output_filter==1; ping_feature_map_wea[2]<=dsconv_block_output_filter==2; ping_feature_map_wea[3]<=dsconv_block_output_filter==3; ping_feature_map_wea[4]<=dsconv_block_output_filter==4; ping_feature_map_wea[5]<=dsconv_block_output_filter==5; ping_feature_map_wea[6]<=dsconv_block_output_filter==6; ping_feature_map_wea[7]<=dsconv_block_output_filter==7; ping_feature_map_wea[8]<=dsconv_block_output_filter==8; ping_feature_map_wea[9]<=dsconv_block_output_filter==9; ping_feature_map_wea[10]<=dsconv_block_output_filter==10; ping_feature_map_wea[11]<=dsconv_block_output_filter==11; ping_feature_map_wea[12]<=dsconv_block_output_filter==12; ping_feature_map_wea[13]<=dsconv_block_output_filter==13; ping_feature_map_wea[14]<=dsconv_block_output_filter==14; ping_feature_map_wea[15]<=dsconv_block_output_filter==15;
                ping_feature_map_addra<=dsconv_block_output_pixel_addr;
                ping_feature_map_dina[0]<=dsconv_block_output_pixel; ping_feature_map_dina[1]<=dsconv_block_output_pixel; ping_feature_map_dina[2]<=dsconv_block_output_pixel; ping_feature_map_dina[3]<=dsconv_block_output_pixel; ping_feature_map_dina[4]<=dsconv_block_output_pixel; ping_feature_map_dina[5]<=dsconv_block_output_pixel; ping_feature_map_dina[6]<=dsconv_block_output_pixel; ping_feature_map_dina[7]<=dsconv_block_output_pixel; ping_feature_map_dina[8]<=dsconv_block_output_pixel; ping_feature_map_dina[9]<=dsconv_block_output_pixel; ping_feature_map_dina[10]<=dsconv_block_output_pixel; ping_feature_map_dina[11]<=dsconv_block_output_pixel; ping_feature_map_dina[12]<=dsconv_block_output_pixel; ping_feature_map_dina[13]<=dsconv_block_output_pixel; ping_feature_map_dina[14]<=dsconv_block_output_pixel; ping_feature_map_dina[15]<=dsconv_block_output_pixel;
            end DSCONV_BLOCK_7_RST: begin
                /*** reset dsconv block 7 ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end CONV_DECODER: begin
                /*** conv decoder ***/
                conv_decoder_rst<=0;
                conv_decoder_start<=1;
                conv_decoder_input_pixel[0]<=ping_feature_map_douta[0]; conv_decoder_input_pixel[1]<=ping_feature_map_douta[1]; conv_decoder_input_pixel[2]<=ping_feature_map_douta[2]; conv_decoder_input_pixel[3]<=ping_feature_map_douta[3]; conv_decoder_input_pixel[4]<=ping_feature_map_douta[4]; conv_decoder_input_pixel[5]<=ping_feature_map_douta[5]; conv_decoder_input_pixel[6]<=ping_feature_map_douta[6]; conv_decoder_input_pixel[7]<=ping_feature_map_douta[7]; conv_decoder_input_pixel[8]<=ping_feature_map_douta[8]; conv_decoder_input_pixel[9]<=ping_feature_map_douta[9]; conv_decoder_input_pixel[10]<=ping_feature_map_douta[10]; conv_decoder_input_pixel[11]<=ping_feature_map_douta[11]; conv_decoder_input_pixel[12]<=ping_feature_map_douta[12]; conv_decoder_input_pixel[13]<=ping_feature_map_douta[13]; conv_decoder_input_pixel[14]<=ping_feature_map_douta[14]; conv_decoder_input_pixel[15]<=ping_feature_map_douta[15];

                /*** ping feature map buffer ***/
                ping_feature_map_ena  <=1;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=conv_decoder_input_pixel_addr;
            end CONV_DECODER_RST: begin
                /*** reset conv decoder ***/
                conv_decoder_rst  <=1;
                conv_decoder_start<=0;
                conv_decoder_input_pixel[0]<=0; conv_decoder_input_pixel[1]<=0; conv_decoder_input_pixel[2]<=0; conv_decoder_input_pixel[3]<=0; conv_decoder_input_pixel[4]<=0; conv_decoder_input_pixel[5]<=0; conv_decoder_input_pixel[6]<=0; conv_decoder_input_pixel[7]<=0; conv_decoder_input_pixel[8]<=0; conv_decoder_input_pixel[9]<=0; conv_decoder_input_pixel[10]<=0; conv_decoder_input_pixel[11]<=0; conv_decoder_input_pixel[12]<=0; conv_decoder_input_pixel[13]<=0; conv_decoder_input_pixel[14]<=0; conv_decoder_input_pixel[15]<=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;
            end DONE: begin 
                /*** reset input feature map buffer ***/
                input_feature_map_en[0]<=0; input_feature_map_en[1]<=0; input_feature_map_en[2]<=0; input_feature_map_en[3]<=0; input_feature_map_en[4]<=0; input_feature_map_en[5]<=0; input_feature_map_en[6]<=0; input_feature_map_en[7]<=0; input_feature_map_en[8]<=0; input_feature_map_en[9]<=0; input_feature_map_en[10]<=0; input_feature_map_en[11]<=0; input_feature_map_en[12]<=0; input_feature_map_en[13]<=0;
                input_feature_map_addra<=0;
                input_feature_map_wea  <=0;
                input_feature_map_dina <=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset conv encoder ***/
                conv_encoder_rst  <=1;
                conv_encoder_start<=0;
                conv_encoder_input_pixel[0]<=0; conv_encoder_input_pixel[1]<=0; conv_encoder_input_pixel[2]<=0; conv_encoder_input_pixel[3]<=0; conv_encoder_input_pixel[4]<=0; conv_encoder_input_pixel[5]<=0; conv_encoder_input_pixel[6]<=0; conv_encoder_input_pixel[7]<=0; conv_encoder_input_pixel[8]<=0; conv_encoder_input_pixel[9]<=0; conv_encoder_input_pixel[10]<=0; conv_encoder_input_pixel[11]<=0; conv_encoder_input_pixel[12]<=0; conv_encoder_input_pixel[13]<=0;

                /*** reset dsconv block ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset conv decoder ***/
                conv_decoder_rst  <=1;
                conv_decoder_start<=0;
                conv_decoder_input_pixel[0]<=0; conv_decoder_input_pixel[1]<=0; conv_decoder_input_pixel[2]<=0; conv_decoder_input_pixel[3]<=0; conv_decoder_input_pixel[4]<=0; conv_decoder_input_pixel[5]<=0; conv_decoder_input_pixel[6]<=0; conv_decoder_input_pixel[7]<=0; conv_decoder_input_pixel[8]<=0; conv_decoder_input_pixel[9]<=0; conv_decoder_input_pixel[10]<=0; conv_decoder_input_pixel[11]<=0; conv_decoder_input_pixel[12]<=0; conv_decoder_input_pixel[13]<=0; conv_decoder_input_pixel[14]<=0; conv_decoder_input_pixel[15]<=0;
            end default: begin
                /*** reset input feature map buffer ***/
                input_feature_map_en[0]<=0; input_feature_map_en[1]<=0; input_feature_map_en[2]<=0; input_feature_map_en[3]<=0; input_feature_map_en[4]<=0; input_feature_map_en[5]<=0; input_feature_map_en[6]<=0; input_feature_map_en[7]<=0; input_feature_map_en[8]<=0; input_feature_map_en[9]<=0; input_feature_map_en[10]<=0; input_feature_map_en[11]<=0; input_feature_map_en[12]<=0; input_feature_map_en[13]<=0;
                input_feature_map_addra<=0;
                input_feature_map_wea  <=0;
                input_feature_map_dina <=0;

                /*** reset ping feature map buffer ***/
                ping_feature_map_ena  <=0;
                ping_feature_map_wea[0]<=0; ping_feature_map_wea[1]<=0; ping_feature_map_wea[2]<=0; ping_feature_map_wea[3]<=0; ping_feature_map_wea[4]<=0; ping_feature_map_wea[5]<=0; ping_feature_map_wea[6]<=0; ping_feature_map_wea[7]<=0; ping_feature_map_wea[8]<=0; ping_feature_map_wea[9]<=0; ping_feature_map_wea[10]<=0; ping_feature_map_wea[11]<=0; ping_feature_map_wea[12]<=0; ping_feature_map_wea[13]<=0; ping_feature_map_wea[14]<=0; ping_feature_map_wea[15]<=0;
                ping_feature_map_addra<=0;
                ping_feature_map_dina[0]<=0; ping_feature_map_dina[1]<=0; ping_feature_map_dina[2]<=0; ping_feature_map_dina[3]<=0; ping_feature_map_dina[4]<=0; ping_feature_map_dina[5]<=0; ping_feature_map_dina[6]<=0; ping_feature_map_dina[7]<=0; ping_feature_map_dina[8]<=0; ping_feature_map_dina[9]<=0; ping_feature_map_dina[10]<=0; ping_feature_map_dina[11]<=0; ping_feature_map_dina[12]<=0; ping_feature_map_dina[13]<=0; ping_feature_map_dina[14]<=0; ping_feature_map_dina[15]<=0;

                /*** reset pong feature map buffer ***/
                pong_feature_map_ena  <=0;
                pong_feature_map_wea[0]<=0; pong_feature_map_wea[1]<=0; pong_feature_map_wea[2]<=0; pong_feature_map_wea[3]<=0; pong_feature_map_wea[4]<=0; pong_feature_map_wea[5]<=0; pong_feature_map_wea[6]<=0; pong_feature_map_wea[7]<=0; pong_feature_map_wea[8]<=0; pong_feature_map_wea[9]<=0; pong_feature_map_wea[10]<=0; pong_feature_map_wea[11]<=0; pong_feature_map_wea[12]<=0; pong_feature_map_wea[13]<=0; pong_feature_map_wea[14]<=0; pong_feature_map_wea[15]<=0;
                pong_feature_map_addra<=0;
                pong_feature_map_dina[0]<=0; pong_feature_map_dina[1]<=0; pong_feature_map_dina[2]<=0; pong_feature_map_dina[3]<=0; pong_feature_map_dina[4]<=0; pong_feature_map_dina[5]<=0; pong_feature_map_dina[6]<=0; pong_feature_map_dina[7]<=0; pong_feature_map_dina[8]<=0; pong_feature_map_dina[9]<=0; pong_feature_map_dina[10]<=0; pong_feature_map_dina[11]<=0; pong_feature_map_dina[12]<=0; pong_feature_map_dina[13]<=0; pong_feature_map_dina[14]<=0; pong_feature_map_dina[15]<=0;

                /*** reset conv encoder ***/
                conv_encoder_rst  <=1;
                conv_encoder_start<=0;
                conv_encoder_input_pixel[0]<=0; conv_encoder_input_pixel[1]<=0; conv_encoder_input_pixel[2]<=0; conv_encoder_input_pixel[3]<=0; conv_encoder_input_pixel[4]<=0; conv_encoder_input_pixel[5]<=0; conv_encoder_input_pixel[6]<=0; conv_encoder_input_pixel[7]<=0; conv_encoder_input_pixel[8]<=0; conv_encoder_input_pixel[9]<=0; conv_encoder_input_pixel[10]<=0; conv_encoder_input_pixel[11]<=0; conv_encoder_input_pixel[12]<=0; conv_encoder_input_pixel[13]<=0;

                /*** reset dsconv block ***/
                dsconv_block_rst      <=1;
                dsconv_block_start    <=0;
                dsconv_block_layer_sel<=0;
                dsconv_block_input_pixel[0]<=0; dsconv_block_input_pixel[1]<=0; dsconv_block_input_pixel[2]<=0; dsconv_block_input_pixel[3]<=0; dsconv_block_input_pixel[4]<=0; dsconv_block_input_pixel[5]<=0; dsconv_block_input_pixel[6]<=0; dsconv_block_input_pixel[7]<=0; dsconv_block_input_pixel[8]<=0; dsconv_block_input_pixel[9]<=0; dsconv_block_input_pixel[10]<=0; dsconv_block_input_pixel[11]<=0; dsconv_block_input_pixel[12]<=0; dsconv_block_input_pixel[13]<=0; dsconv_block_input_pixel[14]<=0; dsconv_block_input_pixel[15]<=0;

                /*** reset conv decoder ***/
                conv_decoder_rst  <=1;
                conv_decoder_start<=0;
                conv_decoder_input_pixel[0]<=0; conv_decoder_input_pixel[1]<=0; conv_decoder_input_pixel[2]<=0; conv_decoder_input_pixel[3]<=0; conv_decoder_input_pixel[4]<=0; conv_decoder_input_pixel[5]<=0; conv_decoder_input_pixel[6]<=0; conv_decoder_input_pixel[7]<=0; conv_decoder_input_pixel[8]<=0; conv_decoder_input_pixel[9]<=0; conv_decoder_input_pixel[10]<=0; conv_decoder_input_pixel[11]<=0; conv_decoder_input_pixel[12]<=0; conv_decoder_input_pixel[13]<=0; conv_decoder_input_pixel[14]<=0; conv_decoder_input_pixel[15]<=0;
            end
        endcase
    end

    /***** FEATURE MAP BUFFER *****/
    /***** input feature map buffer *****/
    input_feature_map_buffer_0  u_input_feature_map_buffer_0 (.clka(clk), .ena(input_feature_map_en[0 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[0 ]));
    input_feature_map_buffer_1  u_input_feature_map_buffer_1 (.clka(clk), .ena(input_feature_map_en[1 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[1 ]));
    input_feature_map_buffer_2  u_input_feature_map_buffer_2 (.clka(clk), .ena(input_feature_map_en[2 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[2 ]));
    input_feature_map_buffer_3  u_input_feature_map_buffer_3 (.clka(clk), .ena(input_feature_map_en[3 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[3 ]));
    input_feature_map_buffer_4  u_input_feature_map_buffer_4 (.clka(clk), .ena(input_feature_map_en[4 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[4 ]));
    input_feature_map_buffer_5  u_input_feature_map_buffer_5 (.clka(clk), .ena(input_feature_map_en[5 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[5 ]));
    input_feature_map_buffer_6  u_input_feature_map_buffer_6 (.clka(clk), .ena(input_feature_map_en[6 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[6 ]));
    input_feature_map_buffer_7  u_input_feature_map_buffer_7 (.clka(clk), .ena(input_feature_map_en[7 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[7 ]));
    input_feature_map_buffer_8  u_input_feature_map_buffer_8 (.clka(clk), .ena(input_feature_map_en[8 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[8 ]));
    input_feature_map_buffer_9  u_input_feature_map_buffer_9 (.clka(clk), .ena(input_feature_map_en[9 ]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[9 ]));
    input_feature_map_buffer_10 u_input_feature_map_buffer_10(.clka(clk), .ena(input_feature_map_en[10]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[10]));
    input_feature_map_buffer_11 u_input_feature_map_buffer_11(.clka(clk), .ena(input_feature_map_en[11]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[11]));
    input_feature_map_buffer_12 u_input_feature_map_buffer_12(.clka(clk), .ena(input_feature_map_en[12]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[12]));
    input_feature_map_buffer_13 u_input_feature_map_buffer_13(.clka(clk), .ena(input_feature_map_en[13]), .wea(input_feature_map_wea), .addra(input_feature_map_addra), .dina(input_feature_map_dina), .douta(input_feature_map_douta[13]));
    
    /***** ping feature map buffer *****/
    generate
        for(i=0; i<16; i=i+1) begin
            ping_feature_map_buffer u_ping_feature_map_buffer(
                .clka (clk),
                .ena  (ping_feature_map_ena),
                .wea  (ping_feature_map_wea[i]),
                .addra(ping_feature_map_addra),
                .dina (ping_feature_map_dina[i]),
                .douta(ping_feature_map_douta[i])
            );
        end
    endgenerate

    /***** pong feature map buffer *****/
    generate
        for(i=0; i<16; i=i+1) begin
            pong_feature_map_buffer u_pong_feature_map_buffer(
                .clka (clk),
                .ena  (pong_feature_map_ena),
                .wea  (pong_feature_map_wea[i]),
                .addra(pong_feature_map_addra),
                .dina (pong_feature_map_dina[i]),
                .douta(pong_feature_map_douta[i])
            );
        end
    endgenerate

    /***** NEURAL NETWORK *****/
    /***** convolutional encoder layer *****/
    conv_encoder_top u_conv_encoder_top(
        .clk              (clk),
        .rst              (conv_encoder_rst),
        .start            (conv_encoder_start),
        .input_pixel_0(conv_encoder_input_pixel[0]), .input_pixel_1(conv_encoder_input_pixel[1]), .input_pixel_2(conv_encoder_input_pixel[2]), .input_pixel_3(conv_encoder_input_pixel[3]), .input_pixel_4(conv_encoder_input_pixel[4]), .input_pixel_5(conv_encoder_input_pixel[5]), .input_pixel_6(conv_encoder_input_pixel[6]), .input_pixel_7(conv_encoder_input_pixel[7]), .input_pixel_8(conv_encoder_input_pixel[8]), .input_pixel_9(conv_encoder_input_pixel[9]), .input_pixel_10(conv_encoder_input_pixel[10]), .input_pixel_11(conv_encoder_input_pixel[11]), .input_pixel_12(conv_encoder_input_pixel[12]), .input_pixel_13(conv_encoder_input_pixel[13]),
        .input_pixel_addr (conv_encoder_input_pixel_addr),
        .output_pixel     (conv_encoder_output_pixel),
        .output_pixel_addr(conv_encoder_output_pixel_addr),
        .output_filter    (conv_encoder_output_filter),
        .ready            (conv_encoder_ready),
        .done             (conv_encoder_done)
    );

    /***** depthwise separable convolutional block *****/
    dsconv_block_top u_dsconv_block_top(
        .clk              (clk),
        .rst              (dsconv_block_rst),
        .start            (dsconv_block_start),
        .layer_sel        (dsconv_block_layer_sel),
        .input_pixel_0(dsconv_block_input_pixel[0]), .input_pixel_1(dsconv_block_input_pixel[1]), .input_pixel_2(dsconv_block_input_pixel[2]), .input_pixel_3(dsconv_block_input_pixel[3]), .input_pixel_4(dsconv_block_input_pixel[4]), .input_pixel_5(dsconv_block_input_pixel[5]), .input_pixel_6(dsconv_block_input_pixel[6]), .input_pixel_7(dsconv_block_input_pixel[7]), .input_pixel_8(dsconv_block_input_pixel[8]), .input_pixel_9(dsconv_block_input_pixel[9]), .input_pixel_10(dsconv_block_input_pixel[10]), .input_pixel_11(dsconv_block_input_pixel[11]), .input_pixel_12(dsconv_block_input_pixel[12]), .input_pixel_13(dsconv_block_input_pixel[13]), .input_pixel_14(dsconv_block_input_pixel[14]), .input_pixel_15(dsconv_block_input_pixel[15]),
        .input_pixel_addr (dsconv_block_input_pixel_addr),
        .output_pixel     (dsconv_block_output_pixel),
        .output_pixel_addr(dsconv_block_output_pixel_addr),
        .output_filter    (dsconv_block_output_filter),
        .ready            (dsconv_block_ready),
        .done             (dsconv_block_done)
    );

    /***** convolutional decoder layer *****/
    conv_decoder_top u_conv_decoder_top(
        .clk              (clk),
        .rst              (conv_decoder_rst),
        .start            (conv_decoder_start),
        .input_pixel_0(conv_decoder_input_pixel[0]), .input_pixel_1(conv_decoder_input_pixel[1]), .input_pixel_2(conv_decoder_input_pixel[2]), .input_pixel_3(conv_decoder_input_pixel[3]), .input_pixel_4(conv_decoder_input_pixel[4]), .input_pixel_5(conv_decoder_input_pixel[5]), .input_pixel_6(conv_decoder_input_pixel[6]), .input_pixel_7(conv_decoder_input_pixel[7]), .input_pixel_8(conv_decoder_input_pixel[8]), .input_pixel_9(conv_decoder_input_pixel[9]), .input_pixel_10(conv_decoder_input_pixel[10]), .input_pixel_11(conv_decoder_input_pixel[11]), .input_pixel_12(conv_decoder_input_pixel[12]), .input_pixel_13(conv_decoder_input_pixel[13]), .input_pixel_14(conv_decoder_input_pixel[14]), .input_pixel_15(conv_decoder_input_pixel[15]),
        .input_pixel_addr (conv_decoder_input_pixel_addr),
        .output_pixel     (conv_decoder_output_pixel),
        .output_pixel_addr(conv_decoder_output_pixel_addr),
        .ready            (conv_decoder_ready),
        .done             (conv_decoder_done)
    );
endmodule