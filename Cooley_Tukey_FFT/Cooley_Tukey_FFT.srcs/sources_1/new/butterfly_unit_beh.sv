`timescale 1ns / 1ps

module butterfly_unit_beh #(
    parameter DATA_WIDTH = 16
)(
    input  logic                     shift_enable,
    
    input  logic signed [DATA_WIDTH-1:0] a_real, a_imag,
    input  logic signed [DATA_WIDTH-1:0] b_real, b_imag,
    input  logic signed [DATA_WIDTH-1:0] w_real, w_imag,
    
    output logic signed [DATA_WIDTH-1:0] sum_real, sum_imag,
    output logic signed [DATA_WIDTH-1:0] diff_real, diff_imag
);

    localparam FRACT_BITS = DATA_WIDTH - 1;

    logic signed [2*DATA_WIDTH-1:0] bw_real_full, bw_imag_full;
    logic signed [DATA_WIDTH-1:0]   bw_real, bw_imag;

    always_comb begin
        bw_real_full = (b_real * w_real) - (b_imag * w_imag);
        bw_imag_full = (b_real * w_imag) + (b_imag * w_real);

        bw_real = bw_real_full >>> FRACT_BITS;
        bw_imag = bw_imag_full >>> FRACT_BITS;

        if (shift_enable) begin
            sum_real  = (a_real + bw_real) >>> 1;
            sum_imag  = (a_imag + bw_imag) >>> 1;
            diff_real = (a_real - bw_real) >>> 1;
            diff_imag = (a_imag - bw_imag) >>> 1;
        end else begin
            sum_real  = a_real + bw_real;
            sum_imag  = a_imag + bw_imag;
            diff_real = a_real - bw_real;
            diff_imag = a_imag - bw_imag;
        end
    end

endmodule