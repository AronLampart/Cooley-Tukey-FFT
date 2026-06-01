`timescale 1ns / 1ps

module control_unit #(
    parameter int N = 1024
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic [$clog2($clog2(N)):0]   stage,         
    input  logic [$clog2(N/2)-1:0]       butterfly_idx, 

    output logic [$clog2(N)-1:0]         ram_addr_a,  
    output logic [$clog2(N)-1:0]         ram_addr_b,  
    output logic [$clog2(N/2)-1:0]       rom_addr     
);

    localparam int STAGES = $clog2(N);

    // Sygnaly pomocnicze
    logic [$clog2(N)-1:0]   half_step;
    logic [$clog2(N)-1:0]   group_idx;
    logic [$clog2(N)-1:0]   element_in_group;
    logic [$clog2(N/2)-1:0] twiddle_step;
    
    // Maski bitowe uzywane do natychmiastowego wycinania modulo/dzielenia
    logic [$clog2(N/2)-1:0] mask;

    // logika kombinacyjna
    always_comb begin
        if (stage == 0) begin
            half_step        = '0;
            mask             = '0;
            group_idx        = '0;
            element_in_group = '0;
            twiddle_step     = '0;
        end else begin
            // half_step = 2^(stage-1)
            half_step = 1'b1 << (stage - 1);
            
            // Maska bitowa do operacji modulo. 
            mask = half_step - 1'b1;

            // Element in group = butterfly_idx % half_step
            element_in_group = butterfly_idx & mask;

            // Group idx = butterfly_idx / half_step
            group_idx = butterfly_idx >> (stage - 1);

            // Twiddle step = N / (half_step * 2)
            twiddle_step = (N >> stage);
        end
    end

    // Rejestry wyjściowe
    always_ff @(posedge clk) begin
        if (!rst_n || stage == 0) begin
            ram_addr_a <= '0;
            ram_addr_b <= '0;
            rom_addr   <= '0;
        end else begin
            // ram_addr_a = (group_idx * step) + element_in_group
            ram_addr_a <= (group_idx << stage) + element_in_group;
            
            // ram_addr_b = ram_addr_a + half_step
            ram_addr_b <= ((group_idx << stage) + element_in_group) + half_step;

            // rom_addr = element_in_group * twiddle_step
            rom_addr   <= element_in_group * twiddle_step;
        end
    end

endmodule