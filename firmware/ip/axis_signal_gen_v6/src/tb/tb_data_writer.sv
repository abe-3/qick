// uses the following files
// sv: qick > firmware > ip > axis_signal_gen_v6 > src > data_writer_sv
// vhdl: qick > firmware > ip > axis_signal_gen_v6 > src > data_writer

module tb_data_writer #(parameter NT = 16, parameter N = 16, parameter B = 16) ()

    // Common Inputs
    logic clk, rstn, s_axis_tvalid, we_reg;
    logic [B-1:0] s_axis_tdata;
    logic [31:0] start_addr_reg;

    // System Verilog Outputs
    logic s_axis_tready_sv, mem_we_sv;
    logic [NT-1:0] mem_en_sv;
    logic [N-1:0] mem_addr_sv;
    logic [B-1:0] mem_di_sv;

    // VHDL Outputs
    logic s_axis_tready_vhdl, mem_we_vhdl;
    logic [NT-1:0] mem_en_vhdl;
    logic [N-1:0] mem_addr_vhdl;
    logic [B-1:0] mem_di_vhdl;

    // System Verilog Module Inst
    data_writer_sv #(.NT(NT), .N(N), .B(B))
    sv_dut( clk, rstn, s_axis_tready_sv, s_axis_tdata, s_axis_tvalid, mem_en_sv, mem_we_sv, mem_addr_sv, mem_di_sv, start_addr_reg, we_reg);

    // VHDL Module Inst
    data_writer #(.NT(NT), .N(N), .B(B))
    vhdl_dut( rstn, clk, s_axis_tready_vhdl, s_axis_tdata, s_axis_tvalid, mem_en_vhdl, mem_we_vhdl, mem_addr_vhdl, mem_di_vhdl, start_addr_reg, we_reg);

    // Generate Clock
    always begin
        clk = 1;
        #5;
        clk = 0;
        #5;
    end

    // Pulse Reset and set some logic
    initial begin
        rstn = 1;
        #22;
        rstn = 0;
    end

    // randomize inputs waiting for each transaction
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axis_tvalid <= $urandom;
            we_reg <= $urandom;
            s_axis_tdata <= $urandom % B;
            start_addr_reg <= $urandom % 32;
            
        end else begin
            // reset
            s_axis_tvalid <= 0;
            we_reg <= 0;
            s_axis_tdata <= 0;
            start_addr_reg <= 0;
        end
    end

    // assert output equivalency on falling edge
    always @(negedge clk) begin
        if (!rstn) begin
            assert(s_axis_tready_sv == s_axis_tready_vhdl)  else $error("s_axis_tready mismatch: sv: %h, vhdl: %h", s_axis_tready_sv, s_axis_tready_vhdl);
            assert(mem_we_sv  == mem_we_vhdl)               else $error("mem_we mismatch: sv: %h, vhdl: %h", mem_we_sv, mem_we_vhdl);
            assert(mem_en_sv  == mem_en_vhdl)               else $error("mem_en mismatch: sv: %h, vhdl: %h", mem_en_sv, mem_en_vhdl);
            assert(mem_addr_sv   == mem_addr_vhdl)          else $error("mem_addr mismatch: sv: %h, vhdl: %h", mem_addr_sv, mem_addr_vhdl);
            assert(mem_di_sv == mem_di_vhdl)                else $error("mem_di mismatch: sv: %h, vhdl: %h", mem_di_sv, mem_di_vhdl);
        end
    end
endmodule
