`timescale 1ns/ 1ps

module dsconv_block_line_buffer(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire signed [17: 0] input_pixel,
    output reg  signed [17: 0] x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29, x30, x31, x32, x33, x34, x35, x36, x37, x38, x39, x40, x41, x42, x43, x44, x45, x46, x47, x48,
    output reg                 ready
);
    reg [7: 0] row, col;

    /***** shift register *****/
    integer i;
    reg signed [17: 0] buffer [0: 426];

    always@(posedge clk) begin
        if(rst) begin
            for(i=0; i<=426; i=i+1) begin
                buffer[i]<=0;
            end
        end else if(start) begin
            buffer[426]<=input_pixel;
            for(i=0; i<426; i=i+1) begin
                buffer[i]<=buffer[i+1];
            end
        end
    end

    /***** output *****/
    always@(posedge clk) begin
        if(rst) begin
            x0 <=0; x1 <=0; x2 <=0; x3 <=0; x4 <=0; x5 <=0; x6 <=0; 
            x7 <=0; x8 <=0; x9 <=0; x10<=0; x11<=0; x12<=0; x13<=0; 
            x14<=0; x15<=0; x16<=0; x17<=0; x18<=0; x19<=0; x20<=0; 
            x21<=0; x22<=0; x23<=0; x24<=0; x25<=0; x26<=0; x27<=0; 
            x28<=0; x29<=0; x30<=0; x31<=0; x32<=0; x33<=0; x34<=0; 
            x35<=0; x36<=0; x37<=0; x38<=0; x39<=0; x40<=0; x41<=0; 
            x42<=0; x43<=0; x44<=0; x45<=0; x46<=0; x47<=0; x48<=0;
            ready<=0;
        end else if(start) begin
            if((row>=7&&col>=7)&&(row<=70&&col<=186)) begin
                x0 <=buffer[0  ]; x1 <=buffer[1  ]; x2 <=buffer[2  ]; x3 <=buffer[3  ]; x4 <=buffer[4  ]; x5 <=buffer[5  ]; x6 <=buffer[6  ];
                x7 <=buffer[70 ]; x8 <=buffer[71 ]; x9 <=buffer[72 ]; x10<=buffer[73 ]; x11<=buffer[74 ]; x12<=buffer[75 ]; x13<=buffer[76 ];
                x14<=buffer[140]; x15<=buffer[141]; x16<=buffer[142]; x17<=buffer[143]; x18<=buffer[144]; x19<=buffer[145]; x20<=buffer[146];
                x21<=buffer[210]; x22<=buffer[211]; x23<=buffer[212]; x24<=buffer[213]; x25<=buffer[214]; x26<=buffer[215]; x27<=buffer[216];
                x28<=buffer[280]; x29<=buffer[281]; x30<=buffer[282]; x31<=buffer[283]; x32<=buffer[284]; x33<=buffer[285]; x34<=buffer[286];
                x35<=buffer[350]; x36<=buffer[351]; x37<=buffer[352]; x38<=buffer[353]; x39<=buffer[354]; x40<=buffer[355]; x41<=buffer[356];
                x42<=buffer[420]; x43<=buffer[421]; x44<=buffer[422]; x45<=buffer[423]; x46<=buffer[424]; x47<=buffer[425]; x48<=buffer[426];
                ready<=1;
            end else begin
                x0 <=0; x1 <=0; x2 <=0; x3 <=0; x4 <=0; x5 <=0; x6 <=0; 
                x7 <=0; x8 <=0; x9 <=0; x10<=0; x11<=0; x12<=0; x13<=0; 
                x14<=0; x15<=0; x16<=0; x17<=0; x18<=0; x19<=0; x20<=0; 
                x21<=0; x22<=0; x23<=0; x24<=0; x25<=0; x26<=0; x27<=0; 
                x28<=0; x29<=0; x30<=0; x31<=0; x32<=0; x33<=0; x34<=0; 
                x35<=0; x36<=0; x37<=0; x38<=0; x39<=0; x40<=0; x41<=0; 
                x42<=0; x43<=0; x44<=0; x45<=0; x46<=0; x47<=0; x48<=0;
                ready<=0;
            end
        end
    end

    /***** control unit *****/
    always@(posedge clk) begin
        if(rst) begin
            row<=0;
            col<=1;
        end else if(start) begin
            if(row<70) begin
                row<=row+1;
            end else begin
                row<=1;
                if(col<186) begin
                    col<=col+1;
                end else begin
                    col<=1;
                end
            end
        end
    end
endmodule