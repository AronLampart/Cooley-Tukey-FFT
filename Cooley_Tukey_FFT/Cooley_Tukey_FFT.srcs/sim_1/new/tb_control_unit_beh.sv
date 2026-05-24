`timescale 1ns / 1ps

module tb_control_unit_beh();

    localparam int N = 1024;
    localparam int STAGES = $clog2(N); // Dla N=1024 wynosi 10

    logic [$clog2(STAGES):0] stage;         
    logic [$clog2(N/2)-1:0]  butterfly_idx; 

    logic [$clog2(N)-1:0]    ram_addr_a;
    logic [$clog2(N)-1:0]    ram_addr_b;
    logic [$clog2(N/2)-1:0]  rom_addr;

    control_unit_beh #(
        .N(N)
    ) dut (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .ram_addr_a(ram_addr_a),
        .ram_addr_b(ram_addr_b),
        .rom_addr(rom_addr)
    );

    initial begin
        $display("=== START SYMULACJI: BEHAWIORALNY GENERATOR ADRESOW ===\n");

        // =========================================================
        // TEST 1: Stan zerowy (Zabezpieczenie)
        // =========================================================
        stage = 0;
        butterfly_idx = 0;
        #10;
        $display("--- TEST 1: Algorytm nie wystartowal (stage = 0) ---");
        $display("RAM_A: %0d, RAM_B: %0d, ROM: %0d (Oczekiwane: 0, 0, 0)\n", ram_addr_a, ram_addr_b, rom_addr);

        // =========================================================
        // TEST 2: Etap 1 (Stage 1) - Pierwszy motylek
        // Rozstaw motylka wynosi 1. Odstęp między parami to 2.
        // Adres ROM (Twiddle) dla Etapu 1 zawsze wynosi 0 (kąt 0).
        // =========================================================
        stage = 1;
        butterfly_idx = 0;
        #10;
        $display("--- TEST 2: Etap 1, Motylek 0 ---");
        $display("RAM_A: %0d, RAM_B: %0d (Oczekiwane: 0, 1)", ram_addr_a, ram_addr_b);
        $display("ROM:   %0d (Oczekiwane: 0)\n", rom_addr);

        // Kolejny motylek w tym samym etapie
        stage = 1;
        butterfly_idx = 1;
        #10;
        $display("--- TEST 3: Etap 1, Motylek 1 ---");
        $display("RAM_A: %0d, RAM_B: %0d (Oczekiwane: 2, 3)", ram_addr_a, ram_addr_b);
        $display("ROM:   %0d (Oczekiwane: 0)\n", rom_addr);

        // =========================================================
        // TEST 4: Etap 2 (Stage 2) - Rozszerzenie motylka
        // Rozstaw motylka wynosi 2. Odstęp między grupami to 4.
        // Dla pierwszej próbki Twiddle = 0. Dla drugiej Twiddle = N/4 = 256.
        // =========================================================
        stage = 2;
        butterfly_idx = 1; // Pytamy o drugi motylek w pierwszej grupie
        #10;
        $display("--- TEST 4: Etap 2, Motylek 1 ---");
        $display("RAM_A: %0d, RAM_B: %0d (Oczekiwane: 1, 3)", ram_addr_a, ram_addr_b);
        $display("ROM:   %0d (Oczekiwane: 256)\n", rom_addr);

        // =========================================================
        // TEST 5: Etap 10 (Stage 10) - Ostatni etap dla N=1024
        // W ostatnim etapie jest tylko JEDNA wielka grupa. 
        // Rozstaw motylka to równe 512.
        // =========================================================
        stage = 10;
        butterfly_idx = 0; // Pierwszy motylek łączy próbkę 0 i 512
        #10;
        $display("--- TEST 5: Etap 10, Motylek 0 ---");
        $display("RAM_A: %0d, RAM_B: %0d (Oczekiwane: 0, 512)", ram_addr_a, ram_addr_b);
        $display("ROM:   %0d (Oczekiwane: 0)\n", rom_addr);

        stage = 10;
        butterfly_idx = 15; // Jakiś losowy motylek w środku
        #10;
        $display("--- TEST 6: Etap 10, Motylek 15 ---");
        $display("RAM_A: %0d, RAM_B: %0d (Oczekiwane: 15, 527)", ram_addr_a, ram_addr_b);
        $display("ROM:   %0d (Oczekiwane: 15)\n", rom_addr);

        $display("=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule