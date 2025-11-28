module tb_data_writer_sv #( parameter int NT = 16,
                            parameter int N = 16,
                            parameter int B = 16)();

    // Inputs
    logic clk, rstn, s_axis_tvalid, WE_REG;
    logic [B-1:0] s_axis_tdata;
    logic [31:0] START_ADDR_REG;

    // Specific Outputs
    logic s_axis_tready_vhdl, mem_we_vhdl;  // VHDL
    logic [NT-1:0] mem_en_vhdl;
    logic [N-1:0] mem_addr_vhdl;
    logic [B-1:0] mem_di_vhdl;
    logic s_axis_tready_sv, mem_we_sv;  // SV
    logic [NT-1:0] mem_en_sv;
    logic [N-1:0] mem_addr_sv;
    logic [B-1:0] mem_di_sv;

    // compare vhdl module with translated version
    // VHDL Module
    data_writer #(.NT(NT), .N(N), .B(B))
    vhdl_dut(rstn, clk, s_axis_tready_vhdl, s_axis_tdata, s_axis_tvalid, mem_en_vhdl, mem_we_vhdl, mem_addr_vhdl, mem_di_vhdl, START_ADDR_REG, WE_REG);

    // Translated Module
    data_writer_sv #(.NT(NT), .N(N), .B(B))
    sv_dut(clk, rstn, s_axis_tready_sv, s_axis_tdata, s_axis_tvalid, mem_en_sv, mem_we_sv, mem_addr_sv, mem_di_sv, START_ADDR_REG, WE_REG);

    

endmodule