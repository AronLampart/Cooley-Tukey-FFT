`timescale 1ns / 1ps

module tb_control_unit();

    localparam int N = 16;

    logic                         clk;
    logic                         rst_n;

    logic [$clog2($clog2(N)):0]   stage;
    logic [$clog2(N/2)-1:0]       butterfly_idx;

    logic [$clog2(N)-1:0]         ram_addr_a;
    logic [$clog2(N)-1:0]         ram_addr_b;
    logic [$clog2(N/2)-1:0]       rom_addr;

    control_unit #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .ram_addr_a(ram_addr_a),
        .ram_addr_b(ram_addr_b),
        .rom_addr(rom_addr)
    );

    // Generator zegara (okres 10ns -> 100 MHz)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    initial begin
        $display("START SYMULACJI");

        stage = 0;
        butterfly_idx = 0;
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1; 
        @(posedge clk);

        // KROK 1: Test Etapu 1 (Stage = 1), Motylek 0 ---
        // Matematycznie dla N=16, Stage=1, Butterfly=0:
        // half_step = 1, step = 2, group = 0, element = 0
        // Oczekujemy: RAM A = 0, RAM B = 1, ROM = 0
        $display("--- KROK 1: Uruchomienie Etapu 1, Motylek 0 (T=0) ---");
        stage = 3'd1;
        butterfly_idx = 3'd0;
        
        #1;
        $display("[T=0] Natychmiast po zmianie wejsc -> RAM A: %0d, RAM B: %0d, ROM: %0d (Oczekiwane zera)", 
                 ram_addr_a, ram_addr_b, rom_addr);

        @(posedge clk);
        #1;
        $display("[T+1] Po 1 cyklu zegara (Wynik)     -> RAM A: %0d, RAM B: %0d, ROM: %0d", 
                 ram_addr_a, ram_addr_b, rom_addr);
        $display("--------------------------------------------------\n");


        // --- KROK 2: Test Etapu 2 (Stage = 2), Motylek 1 ---
        // Matematycznie dla N=16, Stage=2, Butterfly=1:
        // half_step = 2, step = 4
        // group = 1 / 2 = 0, element = 1 % 2 = 1
        // RAM A = (0 * 4) + 1 = 1, RAM B = 1 + 2 = 3
        // twiddle_step = 16 / 4 = 4 -> ROM = 1 * 4 = 4
        // Oczekujemy: RAM A = 1, RAM B = 3, ROM = 4
        $display("--- KROK 2: Zmiana na Etap 2, Motylek 1 (NOWY T=0) ---");
        stage = 3'd2;
        butterfly_idx = 3'd1;

        #1;
        $display("[NOWY T=0] Natychmiast po zmianie -> RAM A: %0d, RAM B: %0d, ROM: %0d (Trzyma stary wynik)", 
                 ram_addr_a, ram_addr_b, rom_addr);

        @(posedge clk);
        #1;
        $display("[NOWY T+1] Po 1 cyklu zegara (Wynik)-> RAM A: %0d, RAM B: %0d, ROM: %0d", 
                 ram_addr_a, ram_addr_b, rom_addr);
        $display("--------------------------------------------------\n");


        //KROK 3: Test Etapu 3 (Stage = 3), Motylek 3
        // Matematycznie dla N=16, Stage=3, Butterfly=3:
        // half_step = 4, step = 8
        // group = 3 / 4 = 0, element = 3 % 4 = 3
        // RAM A = (0 * 8) + 3 = 3, RAM B = 3 + 4 = 7
        // twiddle_step = 16 / 8 = 2 -> ROM = 3 * 2 = 6
        // Oczekujemy: RAM A = 3, RAM B = 7, ROM = 6
        $display("--- KROK 3: Zmiana na Etap 3, Motylek 3 (NOWY T=0) ---");
        stage = 3'd3;
        butterfly_idx = 3'd3;

        #1;
        $display("[NOWY T=0] Natychmiast po zmianie -> RAM A: %0d, RAM B: %0d, ROM: %0d (Trzyma stary wynik)", 
                 ram_addr_a, ram_addr_b, rom_addr);

        @(posedge clk);
        #1;
        $display("[NOWY T+1] Po 1 cyklu zegara (Wynik)-> RAM A: %0d, RAM B: %0d, ROM: %0d", 
                 ram_addr_a, ram_addr_b, rom_addr);
        $display("--------------------------------------------------\n");


        //KROK 4: Zabezpieczenie przed Stage = 0
        $display("--- KROK 4: Sprawdzenie stanu spoczynku (Stage = 0) ---");
        stage = 3'd0;
        @(posedge clk);
        #1;
        $display("Po uderzeniu zegara dla Stage=0    -> RAM A: %0d, RAM B: %0d, ROM: %0d (Oczekiwane same zera)", 
                 ram_addr_a, ram_addr_b, rom_addr);

        $display("KONIEC SYMULACJI");
        $finish;
    end

endmodule