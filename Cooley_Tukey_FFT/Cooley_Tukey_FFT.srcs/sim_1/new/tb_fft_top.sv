`timescale 1ns / 1ps

module tb_fft_top();

    localparam int N = 16;
    localparam int DATA_WIDTH = 16;
    localparam int STAGES = $clog2(N);

    logic                         clk;
    logic                         rst_n;

    // Linie sterowania procesem FFT
    logic [$clog2($clog2(N)):0]   stage;
    logic [$clog2(N/2)-1:0]       butterfly_idx;
    logic                         shift_enable;
    logic                         compute_write_en;
    
    // Interfejs do ladowania i rozladunku danych
    logic                         ext_we;
    logic [$clog2(N)-1:0]         ext_addr;
    logic [2*DATA_WIDTH-1:0]      ext_din;
    logic [2*DATA_WIDTH-1:0]      ext_dout;

    // Linie pomocnicze do wyswietlania wynikow
    logic signed [DATA_WIDTH-1:0] out_real;
    logic signed [DATA_WIDTH-1:0] out_imag;

    // Funkcja do odwracania bitow (Bit-Reversal) przy ladowaniu danych
    function automatic int bit_reverse(int val, int bits);
        int res = 0;
        for (int i = 0; i < bits; i++) begin
            res = (res << 1) | (val & 1);
            val = val >> 1;
        end
        return res;
    endfunction

    fft_top #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .shift_enable(shift_enable),
        .compute_write_en(compute_write_en),
        .ext_we(ext_we),
        .ext_addr(ext_addr),
        .ext_din(ext_din),
        .ext_dout(ext_dout)
    );

    // Generator zegara (okres 10ns -> 100 MHz)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    initial begin
        $display("START SYMULACJI", N);

        stage = 0;
        butterfly_idx = 0;
        shift_enable = 0; 
        compute_write_en = 0;
        ext_we = 0;
        ext_addr = 0;
        ext_din = '0;
        
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);

        // FAZA 1: ladowanie danych
        $display("--- FAZA 1: Wczytywanie danych do Block RAM ---");
        stage = 0; // Przełączenie RAM na porty zewnetrzne
        @(posedge clk);

        for (int i = 0; i < N; i++) begin
            int rev_addr = bit_reverse(i, STAGES);
            ext_addr = rev_addr;
            
            if (i % 2) 
                ext_din = {16'd1000, 16'd0};  // Real = 1000, Imag = 0
            else        
                ext_din = {16'd0, 16'd0};     // Real = 0, Imag = 0             

            ext_we = 1; 
            @(posedge clk); // Zapis nastepuje synchronicznie z zegarem BRAM
            #1;
            ext_we = 0;
        end
        $display("Dane zostaly zaladowane poprawnie.\n");
        @(posedge clk);

        // FAZA 2: Glowna petla fft
        $display("--- FAZA 2: Rozpoczecie obliczen Cooleya-Tukeya ---");
        
        for (int s = 1; s <= STAGES; s++) begin
            stage = s;
            $display(">> Uruchamianie Etapu %0d z %0d...", s, STAGES);
            
            for (int b = 0; b < (N/2); b++) begin
                butterfly_idx = b;
                // 1. Czekamy na zbocze zegara, aby Control Unit wyliczyl i zatrzasnal adresy
                @(posedge clk); 
                #1;
                // 2. Teraz, gdy adresy juz wedruja w rurociagu, wlaczamy sygnal zapisu
                compute_write_en = 1;
                
                @(posedge clk);
                #1;
                compute_write_en = 0;
            end
            
            $display("   Oczekiwanie na oproznienie rurociagu dla Etapu %0d...", s);
            repeat(5) @(posedge clk);
            
            $display("<< Etap %0d zakonczony.\n", s);
        end
        $display("--- Obliczenia FFT zakonczone! ---\n");
        @(posedge clk);

        // FAZA 3: rozladunek danych
        $display("--- FAZA 3: Weryfikacja widma ---");
        stage = 0; // Przejecie kontroli nad RAM przez linie zewnetrzne
        @(posedge clk);
        
        // Odczytujemy pierwsze 10 binow czestotliwosci
        for (int i = 0; i < 10; i++) begin
            ext_addr = i;
            
            // Pamiec BRAM potrzebuje 2 cykli opoznienia na odswiezenie linii ext_dout
            repeat(2) @(posedge clk);
            #1;
            
            out_real = ext_dout[31:16];
            out_imag = ext_dout[15:0];
            $display("Widmo [K=%0d] -> Real: %0d, Imag: %0d", i, out_real, out_imag);
        end
        
        $display("...\n=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule