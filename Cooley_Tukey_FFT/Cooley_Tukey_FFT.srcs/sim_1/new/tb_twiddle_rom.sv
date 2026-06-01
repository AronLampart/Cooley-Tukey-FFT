`timescale 1ns / 1ps

module tb_twiddle_rom();

    localparam int DATA_WIDTH = 16;
    localparam int N = 16;

    logic                         clk;
    logic                         rst_n;
    
    logic [$clog2(N/2)-1:0]       addr;
    logic signed [DATA_WIDTH-1:0] twiddle_real;
    logic signed [DATA_WIDTH-1:0] twiddle_imag;

    twiddle_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );

    // Generator zegara (okres 10ns -> 100 MHz)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    initial begin
        $display("START SYMULACJI");

        //nicjalizacja i Reset Synchroniczny
        addr = 0;
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);

        //KROK 1: Test Latencji dla Adresu 0 (Wspolczynnik W^0)
        // Matematycznie W^0 = 1.0 + 0j. W pliku .mem pod adresem 0 powinna byc wartosc 7FFF0000.
        $display("--- KROK 1: Wystawienie adresu 0 (T=0) ---");
        addr = 3'd0;
        
        #1;
        $display("[T=0] Natychmiast po zmianie adresu -> Real: %d, Imag: %d", 
                 twiddle_real, twiddle_imag);

        // Czekamy 1 cykl zegara (T+1)
        @(posedge clk);
        #1;
        $display("[T+1] Po 1 cyklu (dane w rom_data_reg) -> Real: %d, Imag: %d", 
                 twiddle_real, twiddle_imag);

        // Czekamy 2 cykl zegara (T+2)
        @(posedge clk);
        #1;
        $display("[T+2] Po 2 cyklach (kolejka wyjsciowa) -> Real: %d, Imag: %d (Oczekiwane poprawne dane dla W^0)", 
                 twiddle_real, twiddle_imag);
        $display("--------------------------------------------------\n");


        // --- KROK 2: Zmiana adresu na Adres 2 (Test potokowania w locie) ---
        // Sprawdzamy co sie stanie, gdy zmienimy adres, gdy pamiec juz pracuje.
        $display("--- KROK 2: Zmiana adresu na adres 2 (NOWY T=0) ---");
        addr = 3'd2;

        #1;
        $display("[NOWY T=0] Natychmiast po zmianie -> Real: %d, Imag: %d (Trzyma stary wynik z adresu 0)", 
                 twiddle_real, twiddle_imag);

        @(posedge clk);
        #1;
        $display("[NOWY T+1] Po 1 cyklu             -> Real: %d, Imag: %d (Nadal trzyma stary wynik)", 
                 twiddle_real, twiddle_imag);

        @(posedge clk);
        #1;
        $display("[NOWY T+2] Po 2 cyklach            -> Real: %d, Imag: %d (Nowy wspolczynnik z adresu 2)", 
                 twiddle_real, twiddle_imag);
        $display("--------------------------------------------------\n");


        // KROK 3: Test Resetu Synchronicznego
        $display("--- KROK 3: Test resetu linii wyjsciowych ---");
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        $display("Po uderzeniu resetu -> Real: %d, Imag: %d (Oczekiwane same zera)", 
                 twiddle_real, twiddle_imag);
        
        rst_n = 1'b1;
        @(posedge clk);
        @(posedge clk);
        #1;
        $display("Po wylaczeniu resetu i 2 cyklach -> Real: %d, Imag: %d (Dane powinny wrocic)", 
                 twiddle_real, twiddle_imag);

        $display("KONIEC SYMULACJI");
        $finish;
    end

endmodule