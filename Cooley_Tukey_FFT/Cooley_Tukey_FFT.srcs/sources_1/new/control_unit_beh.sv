`timescale 1ns / 1ps

module control_unit_beh #(
    parameter int N = 1024
)(
    input  logic [$clog2($clog2(N)):0] stage,         
    
    // butterfly_idx: Który to motylek w danym etapie (od 0 do N/2 - 1)
    input  logic [$clog2(N/2)-1:0]     butterfly_idx, 

    output logic [$clog2(N)-1:0]       ram_addr_a,  // Adres próbki A w RAM
    output logic [$clog2(N)-1:0]       ram_addr_b,  // Adres próbki B w RAM
    output logic [$clog2(N/2)-1:0]     rom_addr     // Adres czynnika W w ROM
);

    int step, half_step, group_idx, element_in_group;
    int twiddle_step;

    always_comb begin
        
        // Zabezpieczenie: jeśli algorytm jeszcze nie wystartował (stage = 0), wyzeruj adresy
        if (stage == 0) begin
            ram_addr_a = '0;
            ram_addr_b = '0;
            rom_addr   = '0;
        end else begin
            // 1. Obliczenie szerokości "skrzydeł" motylka dla danego etapu.
            // Przesunięcie o (stage - 1) to potęgowanie dwójki. 
            // Dla stage=1 -> half_step=1. Dla stage=2 -> half_step=2 itd.
            half_step = 1 << (stage - 1);
            step      = half_step << 1;

            // 2. Dekodowanie indeksu motylka (butterfly_idx) na pozycję w grupach
            group_idx        = butterfly_idx / half_step;
            element_in_group = butterfly_idx % half_step;

            // 3. Generowanie adresów do pamięci RAM (Struktura Ping-Pong)
            ram_addr_a = (group_idx * step) + element_in_group;
            ram_addr_b = ram_addr_a + half_step;

            // 4. Generowanie adresu współczynnika z pamięci ROM (Twiddle Factor)
            twiddle_step = N / step;
            rom_addr     = element_in_group * twiddle_step;
        end
        
    end

endmodule