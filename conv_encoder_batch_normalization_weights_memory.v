`timescale 1ns/ 1ps

module conv_encoder_batch_normalization_weights_memory(
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire        [3: 0]  filter_sel, // 16 -> according to output filter
    output reg  signed [17: 0] p,
    output reg  signed [35: 0] q,
    output reg                 ready
);
    reg signed [17: 0] ps [0: 15];
    reg signed [35: 0] qs [0: 15];

    initial begin
        ps[0 ]<= 83; ps[1 ]<= 17; ps[2 ]<= 58; ps[3 ]<= 45; ps[4 ]<= 37;
        ps[5 ]<=146; ps[6 ]<= 19; ps[7 ]<=100; ps[8 ]<= 45; ps[9 ]<= 24;
        ps[10]<=159; ps[11]<= 20; ps[12]<=199; ps[13]<= 15; ps[14]<= 23;
        ps[15]<= 13;

        qs[0 ]<= 689350; qs[1 ]<=  95339; qs[2 ]<=-182562; qs[3 ]<=1079762; qs[4 ]<=-940091;
        qs[5 ]<=  -7386; qs[6 ]<=  48137; qs[7 ]<= 817624; qs[8 ]<=-996072; qs[9 ]<= 899001;
        qs[10]<= 684621; qs[11]<= -60764; qs[12]<= 125788; qs[13]<= 632251; qs[14]<=-661095;
        qs[15]<=-791652;
    end

    always@(posedge clk) begin
        if(rst) begin
            p    <=0;
            q    <=0;
            ready<=0;
        end else if(start) begin
            p    <=ps[filter_sel];
            q    <=qs[filter_sel];
            ready<=1;
        end
    end
endmodule