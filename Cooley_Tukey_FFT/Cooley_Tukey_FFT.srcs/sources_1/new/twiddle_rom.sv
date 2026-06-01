`timescale 1ns / 1ps

module twiddle_rom #(
    parameter int DATA_WIDTH = 16, // Szerokosc jednej skladowej (Real/Imag)
    parameter int N = 1024         // Liczba probek FFT
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic [$clog2(N/2)-1:0]       addr,  
    
    output logic signed [DATA_WIDTH-1:0] twiddle_real,
    output logic signed [DATA_WIDTH-1:0] twiddle_imag
);

    localparam int ROM_DEPTH = N / 2;
    
    // Tablica pamieci
    logic [2*DATA_WIDTH-1:0] rom_memory [0:ROM_DEPTH-1];
    
    // Rejestr buforujacy
    logic [2*DATA_WIDTH-1:0] rom_data_reg;
    
    // Inicjalizacja pamieci
    initial begin
        $readmemh("twiddle_factors.mem", rom_memory);
    end
    
    // Odczyt synchroniczny
    always_ff @(posedge clk) begin
        rom_data_reg <= rom_memory[addr];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            twiddle_real <= '0;
            twiddle_imag <= '0;
        end else begin
            twiddle_real <= rom_data_reg[2*DATA_WIDTH-1 : DATA_WIDTH];
            twiddle_imag <= rom_data_reg[DATA_WIDTH-1 : 0];
        end
    end

endmodule