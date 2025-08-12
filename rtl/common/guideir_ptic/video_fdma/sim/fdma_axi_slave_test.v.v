`timescale 1ns / 1ps

module fdma_axi_slave_test (
    input sysclk
);
    wire [ 31:0] fdma_raddr;
    reg          fdma_rareq;
    wire         fdma_rbusy;
    wire [127:0] fdma_rdata;
    wire [ 15:0] fdma_rsize;
    wire         fdma_rvalid;
    wire [ 31:0] fdma_waddr;
    reg          fdma_wareq;
    wire         fdma_wbusy;
    wire [127:0] fdma_wdata;
    wire [ 15:0] fdma_wsize;
    wire         fdma_wvalid;
    wire         ui_clk;

    parameter TEST_MEM_SIZE = 32'd4 * 20;
    parameter FDMA_BURST_LEN = 16'd262;
    parameter ADDR_MEM_OFFSET = 0;
    parameter ADDR_INC = 0;
    parameter WRITE1 = 0;
    parameter WRITE2 = 1;
    parameter WAIT = 2;
    parameter READ1 = 3;
    parameter READ2 = 4;

    reg [31:0] t_data;
    reg [ 31:0] fdma_waddr_r;
    reg [2 : 0] T_S = 0;

    assign fdma_waddr = fdma_waddr_r + ADDR_MEM_OFFSET;
    assign fdma_raddr = fdma_waddr;
    assign fdma_wsize = FDMA_BURST_LEN;
    assign fdma_rsize = FDMA_BURST_LEN;
    assign fdma_wdata = {t_data, t_data, t_data, t_data};

    //delay reset

    reg [8:0] rst_cnt = 0;
    always @(posedge ui_clk)
        if (rst_cnt[8] == 1'b0) rst_cnt <= rst_cnt + 1'b1;
        else rst_cnt <= rst_cnt;
    always @(posedge ui_clk) begin
        if (rst_cnt[8] == 1'b0) begin
            T_S <= 0;
            fdma_wareq <= 1'b0;
            fdma_rareq <= 1'b0;
            t_data <= 0;
            fdma_waddr_r <= 0;
        end else begin
            case (T_S)
                WRITE1: begin
                    if (fdma_waddr_r == TEST_MEM_SIZE) fdma_waddr_r <= 0;
                    if (!fdma_wbusy) begin
                        fdma_wareq <= 1'b1;
                        t_data <= 0;
                    end
                    if (fdma_wareq && fdma_wbusy) begin
                        fdma_wareq <= 1'b0;
                        T_S        <= WRITE2;
                    end
                end
                WRITE2: begin
                    if (!fdma_wbusy) begin
                        T_S <= WAIT;
                        t_data <= 32'd0;
                    end else if (fdma_wvalid) begin
                        t_data <= t_data + 1'b1;
                    end
                end
                WAIT: begin  //not needed
                    T_S <= READ1;
                end
                READ1: begin
                    if (!fdma_rbusy) begin
                        fdma_rareq <= 1'b1;
                        t_data <= 0;
                    end
                    if (fdma_rareq && fdma_rbusy) begin
                        fdma_rareq <= 1'b0;
                        T_S        <= READ2;
                    end
                end
                READ2: begin
                    if (!fdma_rbusy) begin
                        T_S <= WRITE1;
                        t_data <= 32'd0;
                        fdma_waddr_r <= fdma_waddr_r + ADDR_INC;  //128/8=16
                    end else if (fdma_rvalid) begin
                        t_data <= t_data + 1'b1;
                    end
                end
                default: T_S <= WRITE1;
            endcase
        end
    end
    wire test_error = (fdma_rvalid && (t_data[15:0] != fdma_rdata[15:0]));
    uiFDMA #(
        .M_AXI_ID_WIDTH(M_AXI_ID_WIDTH),
        .M_AXI_ID(M_AXI_ID),
        .M_AXI_ADDR_WIDTH(M_AXI_ADDR_WIDTH),
        .M_AXI_DATA_WIDTH(M_AXI_DATA_WIDTH)
    ) uiFDMA_inst (
        .fdma_waddr   (fdma_waddr),
        .fdma_wareq   (fdma_wareq),
        .fdma_wsize   (fdma_wsize),
        .fdma_wbusy   (fdma_wbusy),
        .fdma_wdata   (fdma_wdata),
        .fdma_wvalid  (fdma_wvalid),
        .fdma_wready  (fdma_wready),
        .fdma_raddr   (fdma_raddr),
        .fdma_rareq   (fdma_rareq),
        .fdma_rsize   (fdma_rsize),
        .fdma_rbusy   (fdma_rbusy),
        .fdma_rdata   (fdma_rdata),
        .fdma_rvalid  (fdma_rvalid),
        .fdma_rready  (fdma_rready),
        .M_AXI_ACLK   (M_AXI_ACLK),
        .M_AXI_ARESETN(M_AXI_ARESETN),
        .M_AXI_AWID   (M_AXI_AWID),
        .M_AXI_AWADDR (M_AXI_AWADDR),
        .M_AXI_AWLEN  (M_AXI_AWLEN),
        .M_AXI_AWSIZE (M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWLOCK (M_AXI_AWLOCK),
        .M_AXI_AWCACHE(M_AXI_AWCACHE),
        .M_AXI_AWPROT (M_AXI_AWPROT),
        .M_AXI_AWQOS  (M_AXI_AWQOS),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_WID    (M_AXI_WID),
        .M_AXI_WDATA  (M_AXI_WDATA),
        .M_AXI_WSTRB  (M_AXI_WSTRB),
        .M_AXI_WLAST  (M_AXI_WLAST),
        .M_AXI_WVALID (M_AXI_WVALID),
        .M_AXI_WREADY (M_AXI_WREADY),
        .M_AXI_BID    (M_AXI_BID),
        .M_AXI_BRESP  (M_AXI_BRESP),
        .M_AXI_BVALID (M_AXI_BVALID),
        .M_AXI_BREADY (M_AXI_BREADY),
        .M_AXI_ARID   (M_AXI_ARID),
        .M_AXI_ARADDR (M_AXI_ARADDR),
        .M_AXI_ARLEN  (M_AXI_ARLEN),
        .M_AXI_ARSIZE (M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARLOCK (M_AXI_ARLOCK),
        .M_AXI_ARCACHE(M_AXI_ARCACHE),
        .M_AXI_ARPROT (M_AXI_ARPROT),
        .M_AXI_ARQOS  (M_AXI_ARQOS),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_RID    (M_AXI_RID),
        .M_AXI_RDATA  (M_AXI_RDATA),
        .M_AXI_RRESP  (M_AXI_RRESP),
        .M_AXI_RLAST  (M_AXI_RLAST),
        .M_AXI_RVALID (M_AXI_RVALID),
        .M_AXI_RREADY (M_AXI_RREADY)
    );
endmodule
