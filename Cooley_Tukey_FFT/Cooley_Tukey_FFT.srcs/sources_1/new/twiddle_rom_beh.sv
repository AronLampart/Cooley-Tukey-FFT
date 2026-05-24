`timescale 1ns / 1ps

module twiddle_rom_beh #(
    parameter int DATA_WIDTH = 16, // Szerokość jednej składowej (Real/Imag)
    parameter int N = 1024         // Liczba próbek FFT
)(
    input  logic [$clog2(N/2)-1:0]   addr,  
    
    output logic signed [DATA_WIDTH-1:0] twiddle_real,
    output logic signed [DATA_WIDTH-1:0] twiddle_imag
);

    localparam int ROM_DEPTH = N / 2;
    
    // Tablica dwuwymiarowa przechowująca współczynniki (spakowane 32 bity)
    logic [2*DATA_WIDTH-1:0] rom_memory [0:ROM_DEPTH-1];
    
    initial begin
        $readmemh("twiddle_factors.mem", rom_memory);
    end
    
    assign twiddle_real = rom_memory[addr][2*DATA_WIDTH-1 : DATA_WIDTH];
    assign twiddle_imag = rom_memory[addr][DATA_WIDTH-1 : 0];

endmodule