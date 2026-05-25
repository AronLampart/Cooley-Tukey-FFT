`timescale 1ns / 1ps

module dual_port_ram_beh #(
    parameter int DATA_WIDTH = 32, // Szerokosc danych (np. 16 bitow Real + 16 bitow Imag)
    parameter int ADDR_WIDTH = 10  // 10 bitow dla N=1024
)(
    input  logic                    wea,    // Zezwolenie na zapis w porcie A (1=Zapis, 0=Odczyt)
    input  logic [ADDR_WIDTH-1:0]   addra,  // Adres portu A
    input  logic [DATA_WIDTH-1:0]   dina,   // Dane wejsciowe portu A
    output logic [DATA_WIDTH-1:0]   douta,  // Dane wyjsciowe portu A

    input  logic                    web,    // Zezwolenie na zapis w porcie B (1=Zapis, 0=Odczyt)
    input  logic [ADDR_WIDTH-1:0]   addrb,  // Adres portu B
    input  logic [DATA_WIDTH-1:0]   dinb,   // Dane wejsciowe portu B
    output logic [DATA_WIDTH-1:0]   doutb   // Dane wyjsciowe portu B
);

    logic [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];
    
    assign douta = ram[addra];
    assign doutb = ram[addrb];

    // Pamięć zapisuje dane TYLKO w momencie gdy "wea" zmienia się z 0 na 1.
    always_ff @(posedge wea) begin
        ram[addra] <= dina;
    end

    always_ff @(posedge web) begin
        ram[addrb] <= dinb;
    end

endmodule