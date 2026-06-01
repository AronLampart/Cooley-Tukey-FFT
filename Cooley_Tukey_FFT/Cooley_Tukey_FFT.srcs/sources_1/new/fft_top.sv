`timescale 1ns / 1ps

module fft_top #(
    parameter int N = 1024,
    parameter int DATA_WIDTH = 16
)(
    input  logic                         clk,
    input  logic                         rst_n,

    // Interfejs sterowania procesem FFT
    input  logic [$clog2($clog2(N)):0]   stage,             // 0 = LOAD/UNLOAD, 1+ = Obliczenia
    input  logic [$clog2(N/2)-1:0]       butterfly_idx,     // Indeks motylka w etapie
    input  logic                         shift_enable,      // Skalowanie w motylku
    input  logic                         compute_write_en,  // Wyzwolenie zapisu w etapie obliczen
    
    // Interfejs do ladowania i rozladunku danych
    input  logic                         ext_we,            // Zapis z zewnatrz
    input  logic [$clog2(N)-1:0]         ext_addr,          // Zewnetrzny adres RAM
    input  logic [2*DATA_WIDTH-1:0]      ext_din,           // Dane z zewnatrz {Real, Imag}
    output logic [2*DATA_WIDTH-1:0]      ext_dout           // Podglad danych z RAM
);

    // Wewnetrzne linie polaczeniowe
    logic [$clog2(N)-1:0]   cu_ram_addr_a, cu_ram_addr_b;
    logic [$clog2(N/2)-1:0] cu_rom_addr;
    
    logic signed [DATA_WIDTH-1:0] twiddle_real, twiddle_imag;
    logic [2*DATA_WIDTH-1:0]      ram_dout_a, ram_dout_b;
    
    logic signed [DATA_WIDTH-1:0] sum_real, sum_imag;
    logic signed [DATA_WIDTH-1:0] diff_real, diff_imag;
    
    logic [$clog2(N)-1:0]    final_addra, final_addrb;
    logic [2*DATA_WIDTH-1:0] final_dina,  final_dinb;
    logic                    final_wea,   final_web;

    // Pipeline Alignment Registers
    logic [$clog2(N)-1:0] delay_addr_a [0:4];
    logic [$clog2(N)-1:0] delay_addr_b [0:4];
    logic                 delay_we     [0:4];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 5; i++) begin
                delay_addr_a[i] <= '0;
                delay_addr_b[i] <= '0;
                delay_we[i]     <= 1'b0;
            end
        end else begin
            // Stopien 0: Zatrzasniecie biezacych sygnalow z Control Unit
            delay_addr_a[0] <= cu_ram_addr_a;
            delay_addr_b[0] <= cu_ram_addr_b;
            delay_we[0]     <= compute_write_en;

            // Stopnie 1 do 4: Przesuwanie w glab rurociagu
            for (int i = 1; i < 5; i++) begin
                delay_addr_a[i] <= delay_addr_a[i-1];
                delay_addr_b[i] <= delay_addr_b[i-1];
                delay_we[i]     <= delay_we[i-1];
            end
        end
    end

    control_unit #(
        .N(N)
    ) cu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stage(stage),
        .butterfly_idx(butterfly_idx),
        .ram_addr_a(cu_ram_addr_a),
        .ram_addr_b(cu_ram_addr_b),
        .rom_addr(cu_rom_addr)
    );

    twiddle_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) rom_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(cu_rom_addr),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );

    dual_port_ram #(
        .DATA_WIDTH(2*DATA_WIDTH),
        .ADDR_WIDTH($clog2(N))
    ) ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wea(final_wea),     .addra(final_addra), .dina(final_dina), .douta(ram_dout_a),
        .web(final_web),     .addrb(final_addrb), .dinb(final_dinb), .doutb(ram_dout_b)
    );

    butterfly_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) butterfly_inst (
        .clk(clk),
        .rst_n(rst_n),
        .shift_enable(shift_enable),
        .a_real(ram_dout_a[2*DATA_WIDTH-1 : DATA_WIDTH]), 
        .a_imag(ram_dout_a[DATA_WIDTH-1 : 0]),
        .b_real(ram_dout_b[2*DATA_WIDTH-1 : DATA_WIDTH]), 
        .b_imag(ram_dout_b[DATA_WIDTH-1 : 0]),
        .w_real(twiddle_real), 
        .w_imag(twiddle_imag),
        .sum_real(sum_real),   .sum_imag(sum_imag),
        .diff_real(diff_real), .diff_imag(diff_imag)
    );

    // logika multiplexerów RAM
    always_comb begin
        if (stage == 0) begin
            // Ladowanie danych wejsciowych lub odczyt wyniku
            final_addra = ext_addr;
            final_dina  = ext_din;
            final_wea   = ext_we;
            
            final_addrb = '0;
            final_dinb  = '0;
            final_web   = 1'b0;
        end else begin
            // Jesli rurociag zapisu zglasza we=1, podajemy opozniony adres zapisu [4].
            // W przeciwnym razie podajemy swiezy adres odczytu z Control Unit.
            final_addra = delay_we[4] ? delay_addr_a[4] : cu_ram_addr_a;
            final_addrb = delay_we[4] ? delay_addr_b[4] : cu_ram_addr_b;
            
            final_dina  = {sum_real, sum_imag};
            final_dinb  = {diff_real, diff_imag};
            
            // Linia zapisu synchronizowana pipeline
            final_wea   = delay_we[4];
            final_web   = delay_we[4];
        end
    end

    assign ext_dout = ram_dout_a;

endmodule