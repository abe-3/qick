`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: HRL Clinic
// Engineer: Abraham Rock
// 
// Create Date: 10/06/2025 02:55:41 PM
// Design Name: 
// Module Name: bmem_testbench
// Project Name: 
// Target Devices: n/a
// Tool Versions: 
// Description: testbench the outputs of the open source and ip blocks
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// use with bram_dp_behav (OSS)
// found in firmware > openhdl

// use with bram_dp_xpm (IP)
// found in firmware > hdl


module bram_dp_testbench #(parameter int ADDR_WIDTH = $clog2(1024),
                        parameter int DATA_WIDTH = 32)();
    
    // common inputs
    logic RSTA, CLKA, PIPE_ENA, REA, WEA, DOA_DV;
    logic RSTB, CLKB, PIPE_ENB, REB, WEB, DOB_DV;
    logic [ADDR_WIDTH-1:0] ADDRA, ADDRB;
    logic [DATA_WIDTH-1:0] DIA, DIB;
    
    // OSS Outputs
    logic [DATA_WIDTH-1:0] DOA_OSS, DOB_OSS;
    
    // IP Outputs
    logic [DATA_WIDTH-1:0] DOA_IP, DOB_IP;
    
    // open source module
    bram_dp_behav #(.OUT_REG_ENA(1), .N(ADDR_WIDTH), .B(DATA_WIDTH))
                    ip_dut(CLKA, CLKB, PIPE_ENA, PIPE_ENB, WEA, WEB, ADDRA, ADDRB, DIA, DIB, DOA_IP, DOB_IP);
                                
    // IP module
    bram_dp_xpm #(.OUT_REG_ENA(1), .N(ADDR_WIDTH), .B(DATA_WIDTH))
                    ip_dut(CLKA, CLKB, PIPE_ENA, PIPE_ENB, WEA, WEB, ADDRA, ADDRB, DIA, DIB, DOA_IP, DOB_IP);
    
    // Generate Clock
    always begin
        CLKA = 1;
        #5;
        CLKA = 0;
        #5;
    end

    always begin
        #9;
        CLKB = 1;
        #9;
        CLKB = 0;
    end
    
    // Pulse Reset and set some logic
    initial begin
        RSTA = 1; RSTB = 1;
        #22;
        RSTA = 0; RSTB=0;
        PIPE_ENA = 1; PIPE_ENB = 1;
        REA = 0; WEA = 0;
        REB = 0; WEB = 0;
    end

    // randomize inputs
    // urandom by default makes a 32 bit number
    always @(posedge CLKA) begin
        if (~RSTA) begin
            std::randomize(WEA)
            std::randomize(REA)
            std::randomize(ADDRA)
            std::randomize(DIA)
        end else begin
            WEA <= 0;
            REA <= 0;
            ADDRA <= '0;
            DIA <= '0;
        end
    end
    
    always @(posedge CLKB) begin
        if (~RSTB) begin
            std::randomize(WEB)
            std::randomize(REB)
            std::randomize(ADDRB)
            std::randomize(DIB)
        end else begin
            WEB <= 0;
            REB <= 0;
            ADDRB <= '0;
            DIB <= '0;
        end
    end
    
    // check if outputs are equivalent on falling edge
    // Port A
    always @(negedge CLKA) begin
        if (~RSTA) begin
            assert (DOA_OSS == DOA_IP) else begin
                $error("Error: DOA_OSS = %h and DOA_IP = %h", DOA_OSS, DOA_IP);
            end
        end
    end
    
    // Port B
    always @(negedge CLKB) begin
        if (~RSTB) begin
            assert (DOB_OSS == DOB_IP) else begin
                $error("Error: DOB_OSS = %h and DOB_IP = %h", DOB_OSS, DOB_IP);
            end
        end
    end
    
endmodule
