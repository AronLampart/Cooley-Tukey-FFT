`timescale 1ns / 1ps

module fft_top_structural_beh #(
    parameter int N = 1024,
    parameter int DATA_WIDTH = 16
)(
    input  logic [$clog2($clog2(N)):0] stage,           // Obecny etap (0 = LOAD/UNLOAD, 1-10 = Obliczenia)
    input  logic [$clog2(N/2)-1:0]     butterfly_idx,   // Który motylek w etapie
    input  logic                       shift_enable,    // Skalowanie w motylku
    input  logic                       compute_write_en,// Zezwolenie na nadpisanie RAM wynikiem motylka
    
    input  logic                       ext_we,          // Zezwolenie na zapis z zewnątrz
    input  logic [$clog2(N)-1:0]       ext_addr,        // Zewnętrzny adres RAM
    input  logic [2*DATA_WIDTH-1:0]    ext_din,         // Paczka danych z zewnątrz (Real + Imag)
    output logic [2*DATA_WIDTH-1:0]    ext_dout         // Podgląd danych z RAM
);
    // Z Control Unit
    logic [$clog2(N)-1:0]   cu_ram_addr_a, cu_ram_addr_b;
    logic [$clog2(N/2)-1:0] cu_rom_addr;
    
    // Z ROM
    logic signed [DATA_WIDTH-1:0] twiddle_real, twiddle_imag;
    
    // Z RAM
    logic [2*DATA_WIDTH-1:0] ram_dout_a, ram_dout_b;
    
    // Z Motylka
    logic signed [DATA_WIDTH-1:0] sum_real, sum_imag;
    logic signed [DATA_WIDTH-1:0] diff_real, diff_imag;
    
    // Druty do multiplekserów sterujących wejściem RAM
    logic [$clog2(N)-1:0]    final_addra, final_addrb;
    logic [2*DATA_WIDTH-1:0] final_dina,  final_dinb;
    logic                    final_wea,   final_web;

    control_unit_beh #(
        .N(N)
    ) cu_inst (
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .ram_addr_a(cu_ram_addr_a),
        .ram_addr_b(cu_ram_addr_b),
        .rom_addr(cu_rom_addr)
    );

    twiddle_rom_beh #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) rom_inst (
        .addr(cu_rom_addr),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );

    dual_port_ram_beh #(
        .DATA_WIDTH(2*DATA_WIDTH), // 32 bity (16 Real + 16 Imag)
        .ADDR_WIDTH($clog2(N))
    ) ram_inst (
        .wea(final_wea),     .addra(final_addra), .dina(final_dina), .douta(ram_dout_a),
        .web(final_web),     .addrb(final_addrb), .dinb(final_dinb), .doutb(ram_dout_b)
    );

    butterfly_unit_beh #(
        .DATA_WIDTH(DATA_WIDTH)
    ) butterfly_inst (
        .shift_enable(shift_enable),
        // Rozcięcie paczki 32-bit z portu A na dwie liczby 16-bit
        .a_real(ram_dout_a[2*DATA_WIDTH-1 : DATA_WIDTH]), 
        .a_imag(ram_dout_a[DATA_WIDTH-1 : 0]),
        // Rozcięcie paczki 32-bit z portu B na dwie liczby 16-bit
        .b_real(ram_dout_b[2*DATA_WIDTH-1 : DATA_WIDTH]), 
        .b_imag(ram_dout_b[DATA_WIDTH-1 : 0]),
        // Współczynniki z ROM
        .w_real(twiddle_real), 
        .w_imag(twiddle_imag),
        // Wyjścia (Wyniki)
        .sum_real(sum_real),   .sum_imag(sum_imag),
        .diff_real(diff_real), .diff_imag(diff_imag)
    );

    // LOGIKA
    always_comb begin
        if (stage == 0) begin
            //Faza ładowania
            // Port A podpinamy pod zewnętrzny interfejs Testbenchu
            final_addra = ext_addr;
            final_dina  = ext_din;
            final_wea   = ext_we;
            
            // Port B leży odłogiem (zerujemy, żeby zapobiec konfliktom)
            final_addrb = '0;
            final_dinb  = '0;
            final_web   = 1'b0;
        end else begin
            //Faza obliczeń
            // Adresy przejmuje Control Unit
            final_addra = cu_ram_addr_a;
            final_addrb = cu_ram_addr_b;
            
            // Pakujemy 16-bitowe wyjścia z motylka w 32-bitowe bloki dla RAM
            final_dina  = {sum_real, sum_imag};
            final_dinb  = {diff_real, diff_imag};
            
            // Zapis do RAM jest wyzwalany ręcznie z Testbenchu sygnałem compute_write_en,
            // co pozwala nam uniknąć nieskończonej pętli kombinacyjnej!
            final_wea   = compute_write_en;
            final_web   = compute_write_en;
        end
    end

    assign ext_dout = ram_dout_a;

endmodule