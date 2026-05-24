`timescale 1ns / 1ps

module dual_port_ram_beh #(
    parameter int DATA_WIDTH = 32, // Szerokość danych (np. 16 bitów Real + 16 bitów Imag)
    parameter int ADDR_WIDTH = 10  // 10 bitów dla N=1024
)(
    input  logic                    wea,    // Zezwolenie na zapis w porcie A (1=Zapis, 0=Odczyt)
    input  logic [ADDR_WIDTH-1:0]   addra,  // Adres portu A
    input  logic [DATA_WIDTH-1:0]   dina,   // Dane wejściowe portu A
    output logic [DATA_WIDTH-1:0]   douta,  // Dane wyjściowe portu A

    input  logic                    web,    // Zezwolenie na zapis w porcie B (1=Zapis, 0=Odczyt)
    input  logic [ADDR_WIDTH-1:0]   addrb,  // Adres portu B
    input  logic [DATA_WIDTH-1:0]   dinb,   // Dane wejściowe portu B
    output logic [DATA_WIDTH-1:0]   doutb   // Dane wyjściowe portu B
);

    logic [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always_comb begin
        
        if (wea) begin
            ram[addra] = dina;
            douta = dina; 
        end else begin
            douta = ram[addra];
        end

        if (web) begin
            ram[addrb] = dinb;
            doutb = dinb;
        end else begin
            doutb = ram[addrb];
        end
        
    end

endmodule