`timescale 1ns / 1ps

module tb_fft_top_structural_beh();

    localparam int N = 16;
    localparam int DATA_WIDTH = 16;
    localparam int STAGES = $clog2(N); // 10

    logic [$clog2(STAGES):0] stage;
    logic [$clog2(N/2)-1:0]  butterfly_idx;
    logic                    shift_enable;
    logic                    compute_write_en;
    
    logic                    ext_we;
    logic [$clog2(N)-1:0]    ext_addr;
    logic [2*DATA_WIDTH-1:0] ext_din;
    logic [2*DATA_WIDTH-1:0] ext_dout;
    logic signed [15:0] out_real;
    logic signed [15:0] out_imag;

    // Funkcja do odwracania bitow (Bit-Reversal) potrzebna przy ladowaniu
    function automatic int bit_reverse(int val, int bits);
        int res = 0;
        for (int i = 0; i < bits; i++) begin
            res = (res << 1) | (val & 1);
            val = val >> 1;
        end
        return res;
    endfunction

    fft_top_structural_beh #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .shift_enable(shift_enable),
        .compute_write_en(compute_write_en),
        .ext_we(ext_we),
        .ext_addr(ext_addr),
        .ext_din(ext_din),
        .ext_dout(ext_dout)
    );

    initial begin
        $display("=== START SYMULACJI: BEHAWIORALNE FFT %0d-PUNKTOWE ===", N);

        stage = 0;
        butterfly_idx = 0;
        shift_enable = 0; 
        compute_write_en = 0;
        ext_we = 0;
        #20;

        // =========================================================
        // FAZA 1: LADOWANIE DANYCH
        // =========================================================
        $display("--- FAZA 1: Wczytywanie danych ---");
        for (int i = 0; i < N; i++) begin
            int rev_addr = bit_reverse(i, STAGES);
            ext_addr = rev_addr;
            
            if (i%2) 
                ext_din = {16'd1000, 16'd0}; 
            else        
                ext_din = {16'd0, 16'd0};//32'd0;             

            ext_we = 1; #5;
            ext_we = 0; #5;
        end
        $display("Dane zaladowane poprawnie.\n");

       // =========================================================
        // FAZA 2: GLOWNA PETLA FFT
        // =========================================================
        $display("\n--- FAZA 2: Rozpoczecie obliczen Cooleya-Tukeya ---");
        
        for (int s = 1; s <= STAGES; s++) begin
            stage = s;
            $display(">> Uruchamianie Etapu %0d z %0d...", s, STAGES);
            for (int b = 0; b < (N/2); b++) begin
                butterfly_idx = b;
                #1;
                compute_write_en = 1;
                #1;
                compute_write_en = 0; 
                $display("   [Etap %0d] Motylek %0d, ROM_ADDR: %0d", s, b, dut.cu_inst.rom_addr);
            end
            $display("<< Etap %0d zakonczony.\n", s);
        end
        $display("--- Obliczenia FFT zakonczone! ---\n");

        // =========================================================
        // FAZA 3: ROZŁADUNEK DANYCH
        // =========================================================
        $display("--- FAZA 3: Weryfikacja widma ---");
        
        stage = 0; 
        #10;
        
        for (int i = 0; i < 10; i++) begin
            ext_addr = i;
            #10;
            out_real = ext_dout[31:16];
            out_imag = ext_dout[15:0];
            $display("Widmo [K=%0d] -> Real: %0d, Imag: %0d", i, out_real, out_imag);
        end
        
        $display("...\n=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule