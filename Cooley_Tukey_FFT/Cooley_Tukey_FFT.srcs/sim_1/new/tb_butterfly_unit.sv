`timescale 1ns / 1ps

module tb_butterfly_unit();

    localparam int DATA_WIDTH = 16;

    logic clk;
    logic rst_n;
    logic shift_enable;

    logic signed [DATA_WIDTH-1:0] a_real, a_imag;
    logic signed [DATA_WIDTH-1:0] b_real, b_imag;
    logic signed [DATA_WIDTH-1:0] w_real, w_imag;

    logic signed [DATA_WIDTH-1:0] sum_real, sum_imag;
    logic signed [DATA_WIDTH-1:0] diff_real, diff_imag;

    butterfly_unit#(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .shift_enable(shift_enable),
        .a_real(a_real), .a_imag(a_imag),
        .b_real(b_real), .b_imag(b_imag),
        .w_real(w_real), .w_imag(w_imag),
        .sum_real(sum_real), .sum_imag(sum_imag),
        .diff_real(diff_real), .diff_imag(diff_imag)
    );

    // Generator zegara (okres 10ns -> Okrągłe 100 MHz)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    initial begin
        $display("START SYMULACJI");
        
        // --- KROK 0: Inicjalizacja i Reset Synchroniczny ---
        shift_enable = 0;
        a_real = 0; a_imag = 0;
        b_real = 0; b_imag = 0;
        w_real = 0; w_imag = 0;
        
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);

        // --- TEST 1: Brak obrotu fazy (Mnożenie przez 1.0) ---
        // Matematyka: W = 1.0 (w Q1.15 to 32767). Kanał B przechodzi niezmieniony.
        // Oczekujemy: Sum = A + B = 5000 + 2000 = 7000, Diff = A - B = 5000 - 2000 = 3000
        $display("--- TEST 1: Podanie danych (W = 1.0, Bez skalowania) ---");
        a_real = 16'd5000;  a_imag = 16'd0;
        b_real = 16'd2000;  b_imag = 16'd0;
        w_real = 16'd32767; w_imag = 16'd0; 
        shift_enable = 1'b0;
        
        repeat(3) @(posedge clk); // Przepychamy dane przez 3 etapy rejestrów
        #1; // Małe przesunięcie po zboczu dla stabilnego odczytu logów
        $display("WYNIK TEST 1 -> Sum: (%0d + j%0d), Diff: (%0d + j%0d)\n", 
                 sum_real, sum_imag, diff_real, diff_imag);


        // --- TEST 2: Obrót fazy o 90 stopni (Mnożenie przez -j) ---
        // Matematyka: W = -j (w Q1.15 Real=0, Imag=-32768). 
        // B * W = (1000 + 0j) * (0 - 1j) = 0 - 1000j.
        // Oczekujemy: Sum = A + BW = 1000 + 1000j + (0 - 1000j) = 1000 + 0j
        //             Diff = A - BW = 1000 + 1000j - (0 - 1000j) = 1000 + 2000j
        $display("--- TEST 2: Podanie danych (W = -j, Obrot o 90 stopni) ---");
        a_real = 16'd1000;  a_imag = 16'd1000;
        b_real = 16'd1000;  b_imag = 16'd0;
        w_real = 16'd0;     w_imag = -16'd32768; 
        shift_enable = 1'b0;
        
        repeat(3) @(posedge clk);
        #1;
        $display("WYNIK TEST 2 -> Sum: (%0d + j%0d), Diff: (%0d + j%0d)\n", 
                 sum_real, sum_imag, diff_real, diff_imag);


        // --- TEST 3: Skalowanie bitowe włączone (Dzielenie wyniku przez 2) ---
        // Matematyka: W = 1.0. Dane wejściowe są duże.
        // Oczekujemy: Sum = (A + B)/2 = (10000 + 4000)/2 = 7000
        //             Diff = (A - B)/2 = (10000 - 4000)/2 = 3000
        $display("--- TEST 3: Podanie danych (W = 1.0, Wlaczone shift_enable) ---");
        a_real = 16'd10000; a_imag = 16'd0;
        b_real = 16'd4000;  b_imag = 16'd0;
        w_real = 16'd32767; w_imag = 16'd0;
        shift_enable = 1'b1; // Aktywacja dzielenia przez 2 na końcu motylka
        
        repeat(3) @(posedge clk);
        #1;
        $display("WYNIK TEST 3 -> Sum: (%0d + j%0d), Diff: (%0d + j%0d)\n", 
                 sum_real, sum_imag, diff_real, diff_imag);


        // --- Zakończenie ---
        $display("KONIEC SYMULACJI");
        $finish;
    end

endmodule