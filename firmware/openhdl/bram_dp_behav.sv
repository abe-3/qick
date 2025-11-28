/* verilator lint_off MULTIDRIVEN */

module bram_dp_behav #(
    parameter bit OUT_REG_ENA = 0,
    parameter int N = 16,
    parameter int B = 16) (
input logic clka,           // Clock A
input logic clkb,           // Clock B
input logic ena,            // Pipe Enable
input logic enb,            // Pipe Enable
input logic wea,            // Write Enable
input logic web,            // Write Enable
input logic [N-1:0] addra,  // Address A
input logic [N-1:0] addrb,  // Address B
input logic [B-1:0] dia,    // Data A In
input logic [B-1:0] dib,    // Data B In
output logic [B-1:0] doa,   // Data A Out
output logic [B-1:0] dob    // Data B Out
);

    // unpacked datatype
    // access through unpacked then packed e.g. [items][data]
    logic [B-1:0] memory [2**N-1:0];

    // Internal Logic
    logic [B-1:0] doa_to_reg, dob_to_reg;
    logic [B-1:0] reg_doa, reg_dob;

    // Internal output for pulling down
    logic [B-1:0] doa_undriven, dob_undriven;
    
    logic [B-1:0] doa_delayed, dob_delayed;
    
    // Port A mem write
    always_ff @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                memory[addra] <= dia;
            end else begin // read when not writing
                doa_to_reg <= memory[addra];
            end
        end
    end

    // Port B mem write
    always_ff @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                memory[addrb] <= dib;
            end else begin // read when not writing
                dob_to_reg <= memory[addrb];
            end
        end
    end
    /*
    always @(posedge clka, posedge clkb) begin
        if ($rose(clka) && ena) begin
            if (wea) begin
                if ($rose(clkb) && enb && web && (addra == addrb)) begin
                    memory[addra] <= 'x;
                end else begin
                    memory[addra] <= dia;
                end
            end else begin
                doa_to_reg <= memory[addra];
            end
        end
        
        if ($rose(clkb) && enb) begin
            if (web) begin
                if (!($rose(clka) && ena && wea && (addra == addrb))) begin
                    memory[addrb] <= dib;
                end
            end else begin
                dob_to_reg <= memory[addrb];
            end
        end
    end
    */
    // Output Registers
    generate
        if (OUT_REG_ENA) begin : gen_output_reg
            always_ff @(posedge clka) begin
                reg_doa <= doa_to_reg;
            end

            always_ff @(posedge clkb) begin
                reg_dob <= dob_to_reg;
            end

            assign doa_undriven = reg_doa;
            assign dob_undriven = reg_dob;

        end else begin : gen_no_output_reg
            assign doa_undriven = doa_to_reg;
            assign dob_undriven = dob_to_reg;
        end
    endgenerate
    
    always_ff @(posedge clka) begin
        //doa_delayed <= doa_undriven;
        doa_delayed <= $isunknown(doa_undriven) ? '0 : doa_undriven;
    end
    
    always_ff @(posedge clkb) begin
        //dob_delayed <= dob_undriven;
        dob_delayed <= $isunknown(dob_undriven) ? '0 : dob_undriven;
    end
    // if any bit is x or z, make 0
    // otherwise no change
    //assign doa = $isunknown(doa_undriven) ? '0 : doa_undriven;
    //assign dob = $isunknown(dob_undriven) ? '0 : dob_undriven;
    assign dob = dob_delayed;
    assign doa = doa_delayed;    
endmodule

/* verilator lint_on MULTIDRIVEN */