`timescale 1ns / 1ps

module tb_butterfly_unit_beh();

    localparam int DATA_WIDTH = 16;
    
    // Wartość 32767 reprezentuje ułamek 1.0 w formacie Q1.15
    localparam int SCALE = (1 << (DATA_WIDTH - 1)) - 1; 

    logic shift_enable;
    logic signed [DATA_WIDTH-1:0] a_real, a_imag;
    logic signed [DATA_WIDTH-1:0] b_real, b_imag;
    logic signed [DATA_WIDTH-1:0] w_real, w_imag;

    logic signed [DATA_WIDTH-1:0] sum_real, sum_imag;
    logic signed [DATA_WIDTH-1:0] diff_real, diff_imag;

    butterfly_unit_beh #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .shift_enable(shift_enable),
        .a_real(a_real), .a_imag(a_imag),
        .b_real(b_real), .b_imag(b_imag),
        .w_real(w_real), .w_imag(w_imag),
        .sum_real(sum_real), .sum_imag(sum_imag),
        .diff_real(diff_real), .diff_imag(diff_imag)
    );

    initial begin
        $display("=== START SYMULACJI: MOTYLEK BEHAWIORALNY ===\n");
        
        shift_enable = 0;
        a_real = 0; a_imag = 0;
        b_real = 0; b_imag = 0;
        w_real = 0; w_imag = 0;
        #10;
        
        // =========================================================
        // TEST 1: Zwykłe dodawanie (W = 1.0 + j0.0)
        // Oczekujemy: SUM = (1000+200) + j(500+100) = 1200 + j600
        //             DIFF = (1000-200) + j(500-100) = 800 + j400
        // =========================================================
        $display("--- TEST 1: W = 1.0 (Brak obrotu), Skalowanie = WYL ---");
        shift_enable = 0;
        a_real = 1000; a_imag = 500;
        b_real = 200;  b_imag = 100;
        w_real = SCALE; w_imag = 0; // W_real = 32767
        #10; 
        $display("A: (%0d, %0dj), B: (%0d, %0dj), W_real: ~1.0", a_real, a_imag, b_real, b_imag);
        $display("SUM:  (%0d, %0dj)", sum_real, sum_imag);
        $display("DIFF: (%0d, %0dj)\n", diff_real, diff_imag);

        // =========================================================
        // TEST 2: Zespolony obrót B o 90 stopni (W = 0.0 + j1.0)
        // Mnożenie B = (500 + j0) przez W = (0 + j1) daje (0 + j500)
        // Oczekujemy: SUM = 100 + j600
        //             DIFF = 100 - j400
        // =========================================================
        $display("--- TEST 2: W = j1.0 (Obrot B o 90 stopni), Skalowanie = WYL ---");
        shift_enable = 0;
        a_real = 100; a_imag = 100;
        b_real = 500; b_imag = 0;
        w_real = 0;   w_imag = SCALE; // W_imag = 32767
        #10;
        $display("A: (%0d, %0dj), B: (%0d, %0dj), W_imag: ~1.0", a_real, a_imag, b_real, b_imag);
        $display("SUM:  (%0d, %0dj)", sum_real, sum_imag);
        $display("DIFF: (%0d, %0dj)\n", diff_real, diff_imag);

        // =========================================================
        // TEST 3: Wpływ sygnału shift_enable
        // Używamy tych samych danych co w Teście 1, ale włączamy >> 1
        // Oczekujemy wyników o połowę mniejszych (SUM = 600 + j300)
        // =========================================================
        $display("--- TEST 3: Test mechanizmu zapobiegania przepelnieniu (Skalowanie = WL) ---");
        shift_enable = 1;
        a_real = 1000; a_imag = 500;
        b_real = 200;  b_imag = 100;
        w_real = SCALE; w_imag = 0;
        #10;
        $display("A: (%0d, %0dj), B: (%0d, %0dj), W_real: ~1.0", a_real, a_imag, b_real, b_imag);
        $display("SUM:  (%0d, %0dj)", sum_real, sum_imag);
        $display("DIFF: (%0d, %0dj)\n", diff_real, diff_imag);

        $display("=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule