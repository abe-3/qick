// uses the following files
// sv: qick > firmware > ip > axis_signal_gen_v6 > src > axi_slv_sg_v6_sv
// vhdl: qick > firmware > ip > axis_signal_gen_v6 > src > axi_slv_sg_v6

module tb_axi_slv_sg_v6_sv #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 6) ()

    // Common Inputs
    logic aclk, aresetn, awvalid, wvalid, bready, arvalid, rready;
    logic [ADDR_WIDTH-1:0] awaddr, araddr;
    logic [2:0] awprot, arprot;
    logic [DATA_WIDTH-1:0] wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;

    // System Verilog Outputs
    logic awready_sv, wready_sv, bvalid_sv, aready_sv, rvalid_sv, WE_REG_sv;
    logic [1:0] bresp_sv, rresp_sv;
    logic [DATA_WIDTH-1:0] rdata_sv;
    logic [31:0] START_ADDR_REG_sv;

    // VHDL Outputs
    logic awready_vhdl, wready_vhdl, bvalid_vhdl, aready_vhdl, rvalid_vhdl, WE_REG_vhdl;
    logic [1:0] bresp_vhdl, rresp_vhdl;
    logic [DATA_WIDTH-1:0] rdata_vhdl;
    logic [31:0] START_ADDR_REG_vhdl;

    // System Verilog Module Inst
    axi_slv_sg_v6_sv #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
    sv_dut( aclk, aresetn, awaddr, awprot, awvalid, awready_sv, wdata, wstrb, wvalid, wready_sv, bresp_sv, bvalid_sv, bready,
            araddr, arprot, arvalid, arready_sv, rdata_sv, rresp_sv, rvalid_sv, rready, START_ADDR_REG_sv, WE_REG_sv);

    // VHDL Module Inst
    axi_slv_sg_v6 #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
    vhdl_dut(   aclk, aresetn, awaddr, awprot, awvalid, awready_vhdl, wdata, wstrb, wvalid, wready_vhdl, bresp_vhdl, bvalid_vhdl, bready,
                araddr, arprot, arvalid, arready_vhdl, rdata_vhdl, rresp_vhdl, rvalid_vhdl, rready, START_ADDR_REG_vhdl, WE_REG_vhdl);

    // Generate Clock
    always begin
        aclk = 1;
        #5;
        aclk = 0;
        #5;
    end

    // Pulse Reset and set some logic
    initial begin
        aresetn = 1;
        #22;
        aresetn = 0;
    end

    // randomize inputs
    /*
    always @(posedge aclk) begin
        if (aresetn) begin
            std::randomize(awvalid);
            std::randomize(wvalid);
            std::randomize(bready);
            std::randomize(arvalid);
            std::randomize(rready);
            std::randomize(awaddr);
            std::randomize(araddr);
            std::randomize(awprot);
            std::randomize(arprot);
            std::randomize(wdata);
            std::randomize(wstrb);
        end
    end*/

    // randomize inputs waiting for each transaction
    always @(posedge aclk) begin
        if (!aresetn) begin
            // Write Address
            // Hold the transaction if it's active and EITHER DUT is not ready
            if (awvalid && (!awready_sv || !awready_vhdl)) begin
                awvalid <= 1'b1; // Hold
            end else begin
                // new transaction
                std::randomize(awvalid, awaddr, awprot);
            end

            // Write Data
            if (wvalid && (!wready_sv || !wready_vhdl)) begin
                wvalid <= 1'b1;
            end else begin
                std::randomize(wvalid, wdata, wstrb);
            end

            // Read Address
            if (arvalid && (!aready_sv || !aready_vhdl)) begin
                arvalid <= 1'b1;
            end else begin
                std::randomize(arvalid, araddr, arprot);
            end

            std::randomize(bready, rready);
            
        end else begin
            // reset
            awvalid <= 0; awaddr <= 0; awprot <= 0;
            wvalid <= 0;  wdata <= 0;  wstrb <= 0;
            arvalid <= 0; araddr <= 0; arprot <= 0;
            bready <= 0;  rready <= 0;
        end
    end

    // assert output equivalency on falling edge
    always @(negedge aclk) begin
        if (!aresetn) begin
            assert(awready_sv == awready_vhdl) else $error("awready mismatch: sv: %h, vhdl: %h", awready_sv, awready_vhdl);
            assert(wready_sv  == wready_vhdl)  else $error("wready mismatch: sv: %h, vhdl: %h", wready_sv, wready_vhdl);
            assert(bvalid_sv  == bvalid_vhdl)  else $error("bvalid mismatch: sv: %h, vhdl: %h", bvalid_sv, bvalid_vhdl);
            assert(bresp_sv   == bresp_vhdl)   else $error("bresp mismatch: sv: %h, vhdl: %h", bresp_sv, bresp_vhdl);
            assert(arready_sv == arready_vhdl) else $error("arready mismatch: sv: %h, vhdl: %h", arready_sv, arready_vhdl);
            assert(rvalid_sv  == rvalid_vhdl)  else $error("rvalid mismatch: sv: %h, vhdl: %h", rvalid_sv, rvalid_vhdl);
            assert(rdata_sv   == rdata_vhdl)   else $error("rdata mismatch: sv: %h, vhdl: %h", rdata_sv, rdata_vhdl);
            assert(rresp_sv   == rresp_vhdl)   else $error("rresp mismatch: sv: %h, vhdl: %h", rresp_sv, rresp_vhdl);
            assert(START_ADDR_REG_sv == START_ADDR_REG_vhdl) else $error("START_ADDR_REG mismatch");
            assert(WE_REG_sv == WE_REG_vhdl)   else $error("WE_REG mismatch");
        end
    end
endmodule
