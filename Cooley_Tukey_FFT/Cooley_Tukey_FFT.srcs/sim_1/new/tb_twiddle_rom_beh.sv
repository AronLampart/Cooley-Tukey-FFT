`timescale 1ns / 1ps

module tb_twiddle_rom_beh();

    localparam int DATA_WIDTH = 16;
    localparam int N = 1024;
    localparam int ADDR_WIDTH = $clog2(N/2); // Dla N=1024 wynosi to 9 bitów

    logic [ADDR_WIDTH-1:0]          addr;
    logic signed [DATA_WIDTH-1:0]   twiddle_real;
    logic signed [DATA_WIDTH-1:0]   twiddle_imag;

    twiddle_rom_beh #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) dut (
        .addr(addr),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );

    initial begin
        $display("=== START SYMULACJI: BEHAWIORALNY TWIDDLE ROM ===\n");

        addr = 0;
        #10;
        // =========================================================
        // TEST 1: Kąt 0 (k = 0)
        // Oczekiwane Q1.15: Real = 32767 (7FFF), Imag = 0
        // =========================================================
        addr = 0;
        #10;
        $display("--- TEST 1: k = %0d (Kat 0 rad) ---", addr);
        $display("Real (Oczekiwane ~32767): %0d", twiddle_real);
        $display("Imag (Oczekiwane 0):      %0d\n", twiddle_imag);

        // =========================================================
        // TEST 2: Kąt -90 stopni / -pi/2 (k = N/4 = 256)
        // Oczekiwane Q1.15: Real = 0, Imag = -32767
        // =========================================================
        addr = N / 4; // Dla 1024 to adres 256
        #10;
        $display("--- TEST 2: k = %0d (Kat -90 stopni) ---", addr);
        $display("Real (Oczekiwane 0):      %0d", twiddle_real);
        $display("Imag (Oczekiwane ~-32767): %0d\n", twiddle_imag);

        // =========================================================
        // TEST 3: Lekki obrót (k = 1)
        // Oczekujemy wartości Real bardzo blisko 1.0 (32767)
        // oraz lekko ujemnej wartości Imag (mały ujemny sinus)
        // =========================================================
        addr = 1;
        #10;
        $display("--- TEST 3: k = %0d (Maly kat) ---", addr);
        $display("Real (Oczekiwane blisko 32767): %0d", twiddle_real);
        $display("Imag (Oczekiwane male ujemne):   %0d\n", twiddle_imag);

        // =========================================================
        // TEST 4: Ostatni dopuszczalny współczynnik (k = N/2 - 1 = 511)
        // Kąt to prawie -180 stopni (-pi). 
        // Cosinus jest prawie -1.0, Sinus prawie 0 (ale wciąż ujemny przed przekroczeniem osi).
        // =========================================================
        addr = (N / 2) - 1; // Dla 1024 to adres 511
        #10;
        $display("--- TEST 4: k = %0d (Kat prawie -180 stopni) ---", addr);
        $display("Real (Oczekiwane ~-32767): %0d", twiddle_real);
        $display("Imag (Oczekiwane blisko 0): %0d\n", twiddle_imag);

        $display("=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule