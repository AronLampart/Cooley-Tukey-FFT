`timescale 1ns / 1ps

module tb_dual_port_ram();

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 4; // Mala pamiec 16-elementowa do szybkich testow

    logic                    clk;
    logic                    rst_n;

    logic                    wea;
    logic [ADDR_WIDTH-1:0]   addra;
    logic [DATA_WIDTH-1:0]   dina;
    logic [DATA_WIDTH-1:0]   douta;

    logic                    web;
    logic [ADDR_WIDTH-1:0]   addrb;
    logic [DATA_WIDTH-1:0]   dinb;
    logic [DATA_WIDTH-1:0]   doutb;

    dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wea(wea), .addra(addra), .dina(dina), .douta(douta),
        .web(web), .addrb(addrb), .dinb(dinb), .doutb(doutb)
    );

    // Generator zegara (okres 10ns -> 100 MHz)
    always begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end

    initial begin
        $display("START SYMULACJI");

        // Inicjalizacja sygnalow wejsciowych
        wea = 0; addra = 0; dina = 0;
        web = 0; addrb = 0; dinb = 0;
        
        //Reset Synchroniczny
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);

        // KROK 1: Zapis do pamieci
        // Zapisujemy pod adres 5 (Port A) oraz pod adres 12 (Port B)
        $display("--- KROK 1: Zapis danych pod adresy 5 (Port A) oraz 12 (Port B) ---");
        
        addra = 4'd5;
        dina  = 32'hAAAA_BBBB;
        wea   = 1'b1;

        addrb = 4'd12;
        dinb  = 32'hCCCC_DDDD;
        web   = 1'b1;

        @(posedge clk);
        #1;
        addra = 4'd2;
        dina  = 32'h1111_1111;
        wea   = 1'b1;

        addrb = 4'd3;
        dinb  = 32'h2222_2222;
        web   = 1'b1;

        @(posedge clk);
        #1;
        // Wylaczamy tryb zapisu, przechodzimy w tryb odczytu
        wea = 1'b0;
        web = 1'b0;

        //KROK 2: Test Opoznienia Odczytu
        $display("--- KROK 2: Wystawienie adresow do odczytu (T=0) ---");
        addra = 4'd5;
        addrb = 4'd12;
        
        #1;
        $display("[T=0] Wyjscia natychmiast po zmianie adresu -> douta: %h, doutb: %h", douta, doutb);

        @(posedge clk);
        #1;
        $display("[T+1] Po pierwszym cyklu (wewnetrzny rejestr BRAM) -> douta: %h, doutb: %h", douta, doutb);

        @(posedge clk);
        #1;
        $display("[T+2] Po drugim cyklu (kolejka wyjsciowa) -> douta: %h, doutb: %h", douta, doutb);
        
        if (douta == 32'hAAAA_BBBB && doutb == 32'hCCCC_DDDD) begin
            $display("[SUKCES] Dane odczytane poprawnie po 2 cyklach opoznienia.\n");
        end else begin
            $display("[BLAD!!!] Dane wyjsciowe sa niepoprawne!\n");
        end

        // KROK 2B: Test rzeczywistej latencji dla NOWEGO adresu
        $display("--- KROK 2B: Zmiana adresu na nowy (Adres 2 - Port A, Adres 3 - Port B) ---");
        addra = 4'd2;
        addrb = 4'd3;

        #1;
        $display("[NOWY T=0] Natychmiast po zmianie adresu (stary stan) -> douta: %h, doutb: %h", douta, doutb);

        @(posedge clk);
        #1;
        $display("[NOWY T+1] Po 1 cyklu (dane wewnatrz dout_reg)      -> douta: %h, doutb: %h", douta, doutb);

        @(posedge clk);
        #1;
        $display("[NOWY T+2] Po 2 cyklach (nowe dane na wyjsciu)       -> douta: %h, doutb: %h", douta, doutb);
        
        if (douta == 32'h1111_1111 && doutb == 32'h2222_2222) begin
            $display("[SUKCES] Nowy adres prawidlowo odswiezyl wyjscie po 2 cyklach.\n");
        end else begin
            $display("[BLAD!!!] Latencja pamieci nie dziala prawidlowo!\n");
        end

        // KROK 3: Test Resetu Kolejki Wyjsciowej
        $display("--- KROK 3: Test resetu synchronicznego linii wyjsciowych ---");
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        $display("Po wlaczeniu resetu -> douta: %h, doutb: %h (Oczekiwane same zera)", douta, doutb);
        
        rst_n = 1'b1; 
        @(posedge clk); // Dajemy 2 cykle na ponowne odczytanie tych samych adresow
        @(posedge clk);
        #1;
        $display("Po wylaczeniu resetu i 2 cyklach -> douta: %h, doutb: %h", douta, doutb);

        // --- Zakonczenie ---
        $display("KONIEC SYMULACJI");
        $finish;
    end

endmodule