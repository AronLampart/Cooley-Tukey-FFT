`timescale 1ns / 1ps

module butterfly_unit #(
    parameter int DATA_WIDTH = 16
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         shift_enable,
    
    input  logic signed [DATA_WIDTH-1:0] a_real, a_imag,
    input  logic signed [DATA_WIDTH-1:0] b_real, b_imag,
    input  logic signed [DATA_WIDTH-1:0] w_real, w_imag,
    
    output logic signed [DATA_WIDTH-1:0] sum_real, sum_imag,
    output logic signed [DATA_WIDTH-1:0] diff_real, diff_imag
);

    localparam int FRACT_BITS = DATA_WIDTH - 1;
    // Wartość do zaokrąglenia (0.5 w formacie stałoprzecinkowym)
    localparam logic signed [2*DATA_WIDTH-1:0] ROUND_VAL = (1 << (FRACT_BITS - 1));

    //ETAP 1: Mnożenie
    logic signed [2*DATA_WIDTH-1:0] mult_br_wr, mult_bi_wi;
    logic signed [2*DATA_WIDTH-1:0] mult_br_wi, mult_bi_wr;
    
    // Rejestry opóźniające
    logic signed [DATA_WIDTH-1:0] a_real_r1, a_imag_r1;
    logic                         shift_enable_r1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            mult_br_wr      <= '0;
            mult_bi_wi      <= '0;
            mult_br_wi      <= '0;
            mult_bi_wr      <= '0;
            a_real_r1       <= '0;
            a_imag_r1       <= '0;
            shift_enable_r1 <= 1'b0;
        end else begin
            mult_br_wr      <= b_real * w_real;
            mult_bi_wi      <= b_imag * w_imag;
            mult_br_wi      <= b_real * w_imag;
            mult_bi_wr      <= b_imag * w_real;
            a_real_r1       <= a_real;
            a_imag_r1       <= a_imag;
            shift_enable_r1 <= shift_enable;
        end
    end

    //ETAP 2: Redukcja iloczynu zespolonego i skalowanie
    logic signed [DATA_WIDTH-1:0] bw_real, bw_imag;
    logic signed [DATA_WIDTH-1:0] a_real_r2, a_imag_r2;
    logic                         shift_enable_r2;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bw_real         <= '0;
            bw_imag         <= '0;
            a_real_r2       <= '0;
            a_imag_r2       <= '0;
            shift_enable_r2 <= 1'b0;
        end else begin
            // Dodajemy ROUND_VAL przed ucięciem bitów
            bw_real         <= (mult_br_wr - mult_bi_wi + ROUND_VAL) >>> FRACT_BITS;
            bw_imag         <= (mult_br_wi + mult_bi_wr + ROUND_VAL) >>> FRACT_BITS;
            a_real_r2       <= a_real_r1;
            a_imag_r2       <= a_imag_r1;
            shift_enable_r2 <= shift_enable_r1;
        end
    end

    //ETAP 3: Dodawanie/Odejmowanie motylkowe
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sum_real  <= '0;
            sum_imag  <= '0;
            diff_real <= '0;
            diff_imag <= '0;
        end else begin
            if (shift_enable_r2) begin
                sum_real  <= (a_real_r2 + bw_real) >>> 1;
                sum_imag  <= (a_imag_r2 + bw_imag) >>> 1;
                diff_real <= (a_real_r2 - bw_real) >>> 1;
                diff_imag <= (a_imag_r2 - bw_imag) >>> 1;
            end else begin
                sum_real  <= a_real_r2 + bw_real;
                sum_imag  <= a_imag_r2 + bw_imag;
                diff_real <= a_real_r2 - bw_real;
                diff_imag <= a_imag_r2 - bw_imag;
            end
        end
    end

endmodule