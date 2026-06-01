`timescale 1ns / 1ps

module tb_dual_port_ram_beh();

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 10;

    logic                    wea;
    logic [ADDR_WIDTH-1:0]   addra;
    logic [DATA_WIDTH-1:0]   dina;
    logic [DATA_WIDTH-1:0]   douta;

    logic                    web;
    logic [ADDR_WIDTH-1:0]   addrb;
    logic [DATA_WIDTH-1:0]   dinb;
    logic [DATA_WIDTH-1:0]   doutb;

    dual_port_ram_beh #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wea(wea), .addra(addra), .dina(dina), .douta(douta),
        .web(web), .addrb(addrb), .dinb(dinb), .doutb(doutb)
    );

    initial begin
        $display("=== START SYMULACJI: BEHAWIORALNY DUAL-PORT RAM ===\n");

        wea = 0; addra = 0; dina = 0;
        web = 0; addrb = 0; dinb = 0;
        #10;

        // =========================================================
        // TEST 1: Zapis na Porcie A, sprawdzenie "Write-First"
        // =========================================================
        $display("--- TEST 1: Zapis na Porcie A (Adres 42) ---");
        wea = 1; 
        addra = 42; 
        dina = 32'hDEADBEEF; // Przykładowa stała w Hex
        #10;
        $display("Zapisano: %h pod adres %0d", dina, addra);
        $display("Odczyt z Portu A w tym samym czasie: %h", douta);

        // Wyłączamy zapis na A
        wea = 0;
        #10;

        // =========================================================
        // TEST 2: Odczyt z Portu B tego, co zapisał Port A
        // =========================================================
        $display("--- TEST 2: Odczyt z Portu B (Adres 42) ---");
        web = 0; // Tryb odczytu
        addrb = 42;
        #10;
        $display("Odczyt z Portu B (Adres %0d): %h", addrb, doutb);

        // =========================================================
        // TEST 3: Zapis na Porcie B, Odczyt na Porcie A
        // =========================================================
        $display("--- TEST 3: Zapis na Porcie B (Adres 128), Odczyt na A ---");
        web = 1; 
        addrb = 128; 
        dinb = 32'hCAFEBABE;
        #10;
        wea = 0;
        addra = 128;
        #10;
        $display("Zapisano (Port B): %h pod adres %0d", dinb, addrb);
        $display("Odczytano (Port A): %h", douta);
        
        web = 0;
        #10;

        // =========================================================
        // TEST 4: Jednoczesny odczyt z dwóch różnych adresów
        // =========================================================
        $display("--- TEST 4: Jednoczesny odczyt z dwoch roznych miejsc ---");
        wea = 0; addra = 42;  // Tu powinno być DEADBEEF
        web = 0; addrb = 128; // Tu powinno być CAFEBABE
        #10;
        $display("Port A (Adres 42): %h", douta);
        $display("Port B (Adres 128): %h\n", doutb);

        $display("=== KONIEC SYMULACJI ===");
        $finish;
    end

endmodule