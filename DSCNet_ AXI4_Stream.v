`timescale 1ns/ 1ps

/*
   *--------*             *-------*
   |        | -> Valid -> |       |
   | master | -> Data  -> | slave |
   |        | <- Ready <- |       |
   *--------*             *-------*
*/

module DSCNet_AXI4_Stream(
    input wire axi_clk,
    input wire axi_reset_n,

    // AXI-S slave interface
    input  wire         s_axis_valid,
    input  wire [31: 0] s_axis_data,
    output wire         s_axis_ready,

    // AXI4-S master interface
    output wire         m_axis_valid,
    output wire [31: 0] m_axis_data,
    input  wire         m_axis_ready,

    // interrupt
    output wire         interrupt
);
    assign s_axis_ready=m_axis_ready;

    DSCNet_top u_DSCNet_top(
        .clk         (axi_clk),
        .rst         (!axi_reset_n),
        .start       (s_axis_valid & m_axis_ready),
        .input_pixel (s_axis_data),
        .input_ready (s_axis_valid),
        .output_pixel(m_axis_data),
        .output_ready(m_axis_valid),
        .done        (interrupt)
    );
endmodule