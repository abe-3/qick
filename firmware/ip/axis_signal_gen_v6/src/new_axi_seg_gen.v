module new_axi_sig_gen (
    // Processor side clocks & resets
    input  logic        t_clk,
    input  logic        t_resetn,

    // SigGen side clocks & resets
    input  logic        s_axi_clk,    // control plane
    input  logic        s0_axi_clk,   // sample loader
    input  logic        aclk,         // waveform queue + output
    input  logic        s_resetn
);

    //---------------------------------------------------------
    // 1. AXI4 CDC (control plane, s_axi_* of signal generator)
    //---------------------------------------------------------

    AXI_BUS #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(32),
        .AXI_ID_WIDTH  (0),
        .AXI_USER_WIDTH(0)
    ) s_axi_if ();

    axi_cdc_intf #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(32)
    ) axi_cdc_inst (
        // slave (processor domain)
        .src_clk_i (t_clk),
        .src_rst_ni(t_resetn),
        .src       (/* tProcessor AXI master interface */),

        // master (signal generator domain)
        .dst_clk_i (s_axi_clk),
        .dst_rst_ni(s_resetn),
        .dst       (s_axi_if)
    );

    //---------------------------------------------------------
    // 2. AXI-Stream async FIFOs (data plane)
    //---------------------------------------------------------

    // FIFO for s0_axis (sample loader)
    taxi_axis_async_fifo #(
        .DEPTH(1024)
    ) s0_fifo (
        .s_clk   (t_clk),
        .s_rst   (~t_resetn),
        .s_axis  (/* tProcessor source AXIS */),

        .m_clk   (s0_axi_clk),
        .m_rst   (~s_resetn),
        .m_axis  (/* connects to siggen.s0_axis_* */),

        // Pause (not used)
        .s_pause_req(1'b0),
        .s_pause_ack(),
        .m_pause_req(1'b0),
        .m_pause_ack(),

        // Status (unused)
        .s_status_depth(),
        .s_status_depth_commit(),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );

    // FIFO for s1_axis (waveform queue)
    taxi_axis_async_fifo #(
        .DEPTH(1024)
    ) s1_fifo (
        .s_clk   (t_clk),
        .s_rst   (~t_resetn),
        .s_axis  (/* tProcessor source AXIS */),

        .m_clk   (aclk),
        .m_rst   (~s_resetn),
        .m_axis  (/* connects to siggen.s1_axis_* */),

        // Pause (not used)
        .s_pause_req(1'b0),
        .s_pause_ack(),
        .m_pause_req(1'b0),
        .m_pause_ack(),

        // Status (unused)
        .s_status_depth(),
        .s_status_depth_commit(),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );

    // FIFO for m_axis (SigGen output back to processor)
    taxi_axis_async_fifo #(
        .DEPTH(1024)
    ) m_axis_fifo (
        .s_clk   (aclk),
        .s_rst   (~s_resetn),
        .s_axis  (/* connect from siggen.m_axis_* */),

        .m_clk   (t_clk),
        .m_rst   (~t_resetn),
        .m_axis  (/* tProcessor sink AXIS */),

        // Pause (not used)
        .s_pause_req(1'b0),
        .s_pause_ack(),
        .m_pause_req(1'b0),
        .m_pause_ack(),

        // Status (unused)
        .s_status_depth(),
        .s_status_depth_commit(),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );

    //---------------------------------------------------------
    // 3. Signal Generator Instance
    //---------------------------------------------------------

    axis_signal_gen_v6 siggen (
        // AXI4-Lite slave interface (control plane)
        .s_axi_aclk   (s_axi_clk),
        .s_axi_aresetn(s_resetn),

        .s_axi_awaddr (s_axi_if.aw.addr),
        .s_axi_awprot (s_axi_if.aw.prot),
        .s_axi_awvalid(s_axi_if.aw.valid),
        .s_axi_awready(s_axi_if.aw.ready),

        .s_axi_wdata  (s_axi_if.w.data),
        .s_axi_wstrb  (s_axi_if.w.strb),
        .s_axi_wvalid (s_axi_if.w.valid),
        .s_axi_wready (s_axi_if.w.ready),

        .s_axi_bresp  (s_axi_if.b.resp),
        .s_axi_bvalid (s_axi_if.b.valid),
        .s_axi_bready (s_axi_if.b.ready),

        .s_axi_araddr (s_axi_if.ar.addr),
        .s_axi_arprot (s_axi_if.ar.prot),
        .s_axi_arvalid(s_axi_if.ar.valid),
        .s_axi_arready(s_axi_if.ar.ready),

        .s_axi_rdata  (s_axi_if.r.data),
        .s_axi_rresp  (s_axi_if.r.resp),
        .s_axi_rvalid (s_axi_if.r.valid),
        .s_axi_rready (s_axi_if.r.ready),

        // AXIS sample loader (slave)
        .s0_axis_aclk   (s0_axi_clk),
        .s0_axis_aresetn(s_resetn),
        .s0_axis_tdata  (s0_fifo.m_axis.tdata),
        .s0_axis_tvalid (s0_fifo.m_axis.tvalid),
        .s0_axis_tready (s0_fifo.m_axis.tready),

        // AXIS waveform queue (slave)
        .aclk           (aclk),
        .aresetn        (s_resetn),
        .s1_axis_tdata  (s1_fifo.m_axis.tdata),
        .s1_axis_tvalid (s1_fifo.m_axis.tvalid),
        .s1_axis_tready (s1_fifo.m_axis.tready),

        // AXIS output (master)
        .m_axis_tready  (m_axis_fifo.s_axis.tready),
        .m_axis_tvalid  (m_axis_fifo.s_axis.tvalid),
        .m_axis_tdata   (m_axis_fifo.s_axis.tdata)
    );

endmodule