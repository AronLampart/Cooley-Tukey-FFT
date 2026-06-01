`timescale 1ns / 1ps

module dual_port_ram #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 10
)(
    input  logic                    clk,
    input  logic                    rst_n, 
    
    // PORT A
    input  logic                    wea,    // Zezwolenie na zapis portu A
    input  logic [ADDR_WIDTH-1:0]   addra,  // Adres portu A
    input  logic [DATA_WIDTH-1:0]   dina,   // Dane wejsciowe portu A
    output logic [DATA_WIDTH-1:0]   douta,  // Dane wyjsciowe portu A

    // PORT B
    input  logic                    web,    // Zezwolenie na zapis portu B
    input  logic [ADDR_WIDTH-1:0]   addrb,  // Adres portu B
    input  logic [DATA_WIDTH-1:0]   dinb,   // Dane wejsciowe portu B
    output logic [DATA_WIDTH-1:0]   doutb   // Dane wyjsciowe portu B
);

    // Tablica pamieci
    logic [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // Rejestry na adresy lub dane wyjsciowe
    logic [DATA_WIDTH-1:0] douta_reg;
    logic [DATA_WIDTH-1:0] doutb_reg;

    // PORT A
    always_ff @(posedge clk) begin
        if (wea) begin
            ram[addra] <= dina;
            douta_reg  <= dina;
        end else begin
            douta_reg  <= ram[addra]; 
        end
    end

    // PORT B
    always_ff @(posedge clk) begin
        if (web) begin
            ram[addrb] <= dinb;
            doutb_reg  <= dinb;
        end else begin
            doutb_reg  <= ram[addrb];
        end
    end

    // Buforowanie
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            douta <= '0;
            doutb <= '0;
        end else begin
            douta <= douta_reg;
            doutb <= doutb_reg;
        end
    end

endmodule