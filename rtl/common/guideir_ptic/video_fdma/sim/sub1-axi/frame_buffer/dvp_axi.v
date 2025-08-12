//=================================================================
//
//  Copyright (C) 2022 Persion All rights reserved.
//  文件名称：dvp_axi.v
//  创 建 者：yinlian
//  创建日期：2022.04.20
//  描    述：这是一个C/Verilog文件，请输入文件描述
//
//=================================================================

module dvp_axi
#(
    parameter                               DVP_DATA_WIDTH              = 16                       ,
    parameter                               DVP_DATA_FRAME_SIZE         = 120*90*(DVP_DATA_WIDTH/2),

    parameter                               AXI_DW                      = 32                       ,
    parameter                               AXI_AW                      = 32                       ,
    parameter                               AXI_LEN                     = 32                       ,//minimum              =1; maximum=256;

    parameter                               FIFO_WR_RST_WAIT_CNT_MAX    = 1                        ,
    parameter                               FIFO_RD_RST_WAIT_CNT_MAX    = 50                       ,

    parameter                               FIFO_DEPTH                  = 512
)
(
    //DVP Signals
    input                                   dvp_wr_rst                  ,
    input                                   dvp_wr_clk                  ,
    input   wire                            dvp_wr_vs                   ,
    input   wire                            dvp_wr_hs                   ,
    input   wire    [DVP_DATA_WIDTH-1:0]    dvp_wr_data                 ,
    input   wire    [AXI_AW-1:0]            dvp_wr_axi_addr             ,

    input                                   dvp_rd_rst                  ,
    input                                   dvp_rd_clk                  ,
    input   wire                            dvp_rd_vs                   ,
    input   wire                            dvp_rd_hs                   ,
    output  reg                             dvp_rd_data_valid           ,
    output  reg     [DVP_DATA_WIDTH-1:0]    dvp_rd_data                 ,
    input   wire    [AXI_AW-1:0]            dvp_rd_axi_addr             ,
    //Master AXI4 Write Bus Interface
    input                                   rst_axi                     ,
    input                                   clk_axi                     ,

    output  wire    [7:0]                   m_axi_awid                  ,
    output  wire    [AXI_AW-1:0]            m_axi_awaddr                ,
    output  reg     [7:0]                   m_axi_awlen                 ,
    output  wire    [2:0]                   m_axi_awsize                ,
    output  wire    [1:0]                   m_axi_awburst               ,
    output  wire                            m_axi_awlock                ,
    output  wire    [3:0]                   m_axi_awcache               ,
    output  wire    [2:0]                   m_axi_awprot                ,
    output  reg                             m_axi_awvalid               ,
    input                                   m_axi_awready               ,
    output  wire    [AXI_DW-1:0]            m_axi_wdata                 ,
    output  wire    [AXI_DW/8-1:0]          m_axi_wstrb                 ,
    output  reg                             m_axi_wlast                 ,
    output  reg                             m_axi_wvalid                ,
    input                                   m_axi_wready                ,
    input           [7:0]                   m_axi_bid                   ,
    input           [1:0]                   m_axi_bresp                 ,
    input                                   m_axi_bvalid                ,
    output  reg                             m_axi_bready                ,
    //Master AXI4 Read Bus Interface
    output  wire    [7:0]                   m_axi_arid                  ,
    output  wire    [AXI_AW-1:0]            m_axi_araddr                ,
    output  reg     [7:0]                   m_axi_arlen                 ,
    output  wire    [2:0]                   m_axi_arsize                ,
    output  wire    [1:0]                   m_axi_arburst               ,
    output  wire                            m_axi_arlock                ,
    output  wire    [3:0]                   m_axi_arcache               ,
    output  wire    [2:0]                   m_axi_arprot                ,
    output  reg                             m_axi_arvalid               ,
    input                                   m_axi_arready               ,
    input           [7:0]                   m_axi_rid                   ,
    input           [AXI_DW-1:0]            m_axi_rdata                 ,
    input           [1:0]                   m_axi_rresp                 ,
    input                                   m_axi_rlast                 ,
    input                                   m_axi_rvalid                ,
    output  reg                             m_axi_rready
);

    parameter FIFO_ADDR_WIDTH               = clogb2(FIFO_DEPTH) + 1    ;

    reg     [3:0]                           dvp_wr_rst_axi              ;
    reg                                     dvp_wr_rst_axi_reg          ;
    reg     [31:0]                          dvp_wr_rst_wait_cnt         ;
    reg                                     dvp_wr_vs_dly               ;
    wire                                    dvp_wr_vs_pluse_pos         ;
    wire                                    dvp_wr_vs_pluse_neg         ;
    reg     [AXI_DW-1:0]                    dvp_wr_data_tmp             ;
    reg     [7:0]                           dvp_wr_data_fifo_wr_en_cnt  ;
    reg                                     dvp_wr_data_fifo_wr_en      ;
    wire    [FIFO_ADDR_WIDTH-1:0]           dvp_wr_data_fifo_wr_cnt     ;
    wire    [FIFO_ADDR_WIDTH-1:0]           dvp_wr_data_fifo_rd_cnt     ;
    reg     [8:0]                           dvp_wr_data_axi_cnt         ;
    reg     [27:0]                          dvp_wr_data_frame_cnt       ;
    wire    [27:0]                          dvp_wr_data_frame_left      ;
    reg     [15:0]                          m_axi_awlen_bytes           ;

    reg     [3:0]                           dvp_rd_rst_axi              ;
    reg                                     dvp_rd_rst_axi_reg          ;
    reg     [31:0]                          dvp_rd_rst_wait_cnt         ;
    reg                                     dvp_rd_vs_dly               ;
    wire                                    dvp_rd_vs_pluse_pos         ;
    wire                                    dvp_rd_vs_pluse_neg         ;
    wire    [AXI_DW-1:0]                    dvp_rd_data_tmp             ;
    reg     [7:0]                           dvp_rd_data_fifo_rd_en_cnt  ;
    reg                                     dvp_rd_data_fifo_rd_en      ;
    wire    [FIFO_ADDR_WIDTH-1:0]           dvp_rd_data_fifo_wr_cnt     ;
    wire    [FIFO_ADDR_WIDTH-1:0]           dvp_rd_data_fifo_rd_cnt     ;
    reg     [8:0]                           dvp_rd_data_axi_cnt         ;
    reg     [27:0]                          dvp_rd_data_frame_cnt       ;
    wire    [27:0]                          dvp_rd_data_frame_left      ;
    reg     [15:0]                          m_axi_arlen_bytes           ;

    parameter                               AXSIZE                    = AXI_DW/8                ;
    parameter                               AXI_ADDR_INC              = AXI_LEN*AXSIZE          ;
    parameter                               AXSIZE_WTH                = clogb2(AXSIZE)          ;
/*----------------------- Fixed Singals Region ----------------------------*/
    assign m_axi_awid                       = 8'h0;
    assign m_axi_awsize                     = AXSIZE_WTH;
    assign m_axi_awburst                    = 2'b01;
    assign m_axi_awprot                     = 3'b010;
    assign m_axi_awlock                     = 1'b0;
    assign m_axi_awcache                    = 4'b0011;
    assign m_axi_wstrb                      = {(AXI_DW/8){1'b1}};

    assign m_axi_arid                       = 8'h0;
    assign m_axi_arsize                     = AXSIZE_WTH;
    assign m_axi_arburst                    = 2'b01;
    assign m_axi_arprot                     = 3'b010;
    assign m_axi_arlock                     = 1'b0;
    assign m_axi_arcache                    = 4'b0011;

    reg     [7:0]                           st_wr_cur,st_wr_nxt;

    parameter                               ST_WR_IDLE                  = 0,
                                            ST_WR_IDLE_WAIT             = 1,
                                            ST_WR_AXI_START             = 2,
                                            ST_WR_AWVALID               = 3,
                                            ST_WR_WVALID                = 4,
                                            ST_WR_BREADY                = 5,
                                            ST_WR_WR_END                = 6,
                                            ST_WR_AXI_END               = 7,
                                            ST_WR_END                   = 'hff;

    reg     [7:0]                           st_rd_cur,st_rd_nxt;

    parameter                               ST_RD_IDLE                  = 0,
                                            ST_RD_IDLE_WAIT             = 1,
                                            ST_RD_AXI_START             = 2,
                                            ST_RD_ARVALID               = 3,
                                            ST_RD_RREADY                = 4,
                                            ST_RD_RD_END                = 5,
                                            ST_RD_AXI_END               = 6,
                                            ST_RD_END                   = 'hff;
///////////////////////////////////////////////////////////////////////////////////////////////////
//write into axi channel
///////////////////////////////////////////////////////////////////////////////////////////////////

    assign dvp_wr_vs_pluse_pos = ~dvp_wr_vs_dly &  dvp_wr_vs;
    assign dvp_wr_vs_pluse_neg =  dvp_wr_vs_dly & ~dvp_wr_vs;
    always @ (posedge dvp_wr_clk or posedge dvp_wr_rst)
    begin
        if (dvp_wr_rst)
            dvp_wr_vs_dly <= 0;
        else
            dvp_wr_vs_dly <= dvp_wr_vs;
    end

    always @ (posedge dvp_wr_clk or posedge dvp_wr_rst)
    begin
        if (dvp_wr_rst)
            dvp_wr_data_fifo_wr_en_cnt <= 0;
        else if (dvp_wr_vs & dvp_wr_hs)
        begin
            if (dvp_wr_data_fifo_wr_en_cnt >= AXI_DW/DVP_DATA_WIDTH - 1)
                dvp_wr_data_fifo_wr_en_cnt <= 0;
            else
                dvp_wr_data_fifo_wr_en_cnt <= dvp_wr_data_fifo_wr_en_cnt + 1;
        end
        else if (dvp_wr_vs_pluse_pos)
            dvp_wr_data_fifo_wr_en_cnt <= 0;
    end

    always @ (posedge dvp_wr_clk or posedge dvp_wr_rst)
    begin
        if (dvp_wr_rst)
            dvp_wr_data_fifo_wr_en <= 0;
        else if (dvp_wr_vs & dvp_wr_hs)
            dvp_wr_data_fifo_wr_en <= (dvp_wr_data_fifo_wr_en_cnt == AXI_DW/DVP_DATA_WIDTH - 1);
        else
            dvp_wr_data_fifo_wr_en <= 0;
    end

    always @ (posedge dvp_wr_clk or posedge dvp_wr_rst)
    begin
        if (dvp_wr_rst)
            dvp_wr_data_tmp <= 0;
        else if (dvp_wr_vs & dvp_wr_hs)
            dvp_wr_data_tmp <= {dvp_wr_data,dvp_wr_data_tmp[AXI_DW -1:DVP_DATA_WIDTH]};
    end

    DC_FIFO
    # (
        .FIFO_MODE      ("ShowAhead"                ) , //"Normal"; //"ShowAhead"
        .DATA_WIDTH     (AXI_DW                     ) ,
        .FIFO_DEPTH     (FIFO_DEPTH                 )
    )
    dvp_wr_data_fifo
    (
        .Reset          (rst_axi | dvp_wr_rst_axi_reg) , //System Reset

        .WrClk          (dvp_wr_clk                  ) , //(I)Wirte Clock
        .WrEn           (dvp_wr_data_fifo_wr_en      ) , //(I)Write Enable
        .WrData         (dvp_wr_data_tmp             ) , //(I)Write Data
        .WrDNum         (dvp_wr_data_fifo_wr_cnt     ) , //(O)Write Data Number In Fifo
        .WrFull         (                            ) , //(O)Write Full

        .RdClk          (clk_axi                     ) , //(I)Read Clock
        .RdEn           (m_axi_wvalid & m_axi_wready ) , //(I)Read Enable
        .RdData         (m_axi_wdata                 ) , //(O)Read Data
        .DataVal        (                            ) , //(O)Data Valid
        .RdDNum         (dvp_wr_data_fifo_rd_cnt     ) , //(O)Radd Data Number In Fifo
        .RdEmpty        (                            )   //(O)Read FifoEmpty
    );

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            dvp_wr_rst_axi <= 0;
        else
            dvp_wr_rst_axi <= {dvp_wr_rst_axi[2:0],dvp_wr_rst};
    end

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            dvp_wr_rst_axi_reg <= 0;
        else if (dvp_wr_rst_axi[3] & ~dvp_wr_rst_axi[2])
            dvp_wr_rst_axi_reg <= 1;
        else if (st_wr_cur == ST_WR_IDLE)
            dvp_wr_rst_axi_reg <= 0;
    end

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            st_wr_cur <= ST_WR_IDLE;
        else if (((st_wr_nxt == ST_WR_AXI_START) | (st_wr_nxt == ST_WR_END) | (st_wr_cur == ST_WR_IDLE)) & (dvp_wr_rst_axi_reg))
            st_wr_cur <= ST_WR_IDLE;
        else
            st_wr_cur <= st_wr_nxt;
    end

    always @ ( * )
    begin
        case (st_wr_cur)
            ST_WR_IDLE:
                st_wr_nxt <= ST_WR_IDLE_WAIT;
            ST_WR_IDLE_WAIT:
                if (dvp_wr_rst_wait_cnt >= FIFO_WR_RST_WAIT_CNT_MAX)
                    st_wr_nxt <= ST_WR_AXI_START;
                else
                    st_wr_nxt <= st_wr_cur;
            ST_WR_AXI_START:
                if (dvp_wr_data_frame_left >= ((AXI_LEN + 1)<<AXSIZE_WTH))
                begin
                    if (dvp_wr_data_fifo_rd_cnt >= AXI_LEN)
                        st_wr_nxt <= ST_WR_AWVALID;
                    else
                        st_wr_nxt <= st_wr_cur;
                end
                else
                begin
                    if (dvp_wr_data_fifo_rd_cnt >= (dvp_wr_data_frame_left>>AXSIZE_WTH))
                        st_wr_nxt <= ST_WR_AWVALID;
                    else
                        st_wr_nxt <= st_wr_cur;
                end
            ST_WR_AWVALID:
                if (m_axi_awvalid & m_axi_awready)
                    st_wr_nxt <= ST_WR_WVALID;
                else
                    st_wr_nxt <= st_wr_cur;
            ST_WR_WVALID:
                if (m_axi_wvalid & m_axi_wready & (dvp_wr_data_axi_cnt == 1))
                    st_wr_nxt <= ST_WR_BREADY;
                else
                    st_wr_nxt <= st_wr_cur;
            ST_WR_BREADY:
                if (m_axi_bvalid & m_axi_bready)
                    st_wr_nxt <= ST_WR_WR_END;
                else
                    st_wr_nxt <= st_wr_cur;
            ST_WR_WR_END:
                st_wr_nxt <= ST_WR_AXI_END;
            ST_WR_AXI_END:
                if (dvp_wr_data_frame_left == 0)
                    st_wr_nxt <= ST_WR_END;
                else
                    st_wr_nxt <= ST_WR_AXI_START;
            ST_WR_END:
                st_wr_nxt <= st_wr_cur;
            default:
                st_wr_nxt <= ST_WR_IDLE;
        endcase
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_wr_rst_wait_cnt <= 0;
        else
        begin
            if (st_wr_cur == ST_WR_IDLE)
                dvp_wr_rst_wait_cnt <= 0;
            else if (st_wr_cur == ST_WR_IDLE_WAIT)
                dvp_wr_rst_wait_cnt <= dvp_wr_rst_wait_cnt + 1;
        end
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
        begin
            m_axi_awlen <= 0;
            m_axi_awlen_bytes <= 0;
        end
        else if(dvp_wr_data_frame_left == 0)
        begin
            m_axi_awlen <= 0;
            m_axi_awlen_bytes <= 0;
        end
        else
        begin
            if(dvp_wr_data_frame_left >= ((AXI_LEN + 1)<<AXSIZE_WTH))
            begin
                m_axi_awlen <= AXI_LEN - 1;
                m_axi_awlen_bytes <= (AXI_LEN << AXSIZE_WTH);
            end
            else
            begin
                m_axi_awlen <= (dvp_wr_data_frame_left>>AXSIZE_WTH) - 1;
                m_axi_awlen_bytes <= dvp_wr_data_frame_left;
            end
        end
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_wr_data_axi_cnt <= 0;
        else if(m_axi_awvalid & m_axi_awready)
            dvp_wr_data_axi_cnt <= m_axi_awlen + 1;
        else if (m_axi_wvalid & m_axi_wready)
            dvp_wr_data_axi_cnt <= dvp_wr_data_axi_cnt - 1;
    end

    assign dvp_wr_data_frame_left = DVP_DATA_FRAME_SIZE - dvp_wr_data_frame_cnt;
    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_wr_data_frame_cnt <= 0;
        else if (dvp_wr_rst_axi_reg)
            dvp_wr_data_frame_cnt <= 0;
        else if(st_wr_nxt == ST_WR_IDLE)
            dvp_wr_data_frame_cnt <= 0;
        else if (st_wr_nxt == ST_WR_WR_END)
            dvp_wr_data_frame_cnt <= dvp_wr_data_frame_cnt + m_axi_awlen_bytes;
    end

    assign m_axi_awaddr = dvp_wr_axi_addr + dvp_wr_data_frame_cnt;

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_awvalid <= 0;
        else if (st_wr_nxt == ST_WR_AWVALID)
            m_axi_awvalid <= 1;
        else
            m_axi_awvalid <= 0;
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_wvalid <= 0;
        else if (st_wr_nxt == ST_WR_WVALID)
            m_axi_wvalid <= 1;
        else
            m_axi_wvalid <= 0;
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_wlast <= 0;
        else if ((st_wr_nxt == ST_WR_WVALID) & (dvp_wr_data_axi_cnt == 2))
            m_axi_wlast <= 1;
        else
            m_axi_wlast <= 0;
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_bready <= 0;
        else if (st_wr_nxt == ST_WR_BREADY)
            m_axi_bready <= 1;
        else
            m_axi_bready <= 0;
    end

///////////////////////////////////////////////////////////////////////////////////////////////////
//read from axi channel
///////////////////////////////////////////////////////////////////////////////////////////////////

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            dvp_rd_rst_axi <= 0;
        else
            dvp_rd_rst_axi <= {dvp_rd_rst_axi[2:0],dvp_rd_rst};
    end

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            dvp_rd_rst_axi_reg <= 0;
        else if (dvp_rd_rst_axi[3] & ~dvp_rd_rst_axi[2])
            dvp_rd_rst_axi_reg <= 1;
        else if (st_rd_cur == ST_RD_IDLE)
            dvp_rd_rst_axi_reg <= 0;
    end

    always @ (posedge clk_axi or posedge rst_axi)
    begin
        if (rst_axi)
            st_rd_cur <= ST_RD_IDLE;
        else if (((st_rd_nxt == ST_RD_AXI_START) | (st_rd_nxt == ST_RD_END) | (st_rd_cur == ST_RD_IDLE)) & (dvp_rd_rst_axi_reg))
            st_rd_cur <= ST_RD_IDLE;
        else
            st_rd_cur <= st_rd_nxt;
    end

    always @ ( * )
    begin
        case (st_rd_cur)
            ST_RD_IDLE:
                st_rd_nxt <= ST_RD_IDLE_WAIT;
            ST_RD_IDLE_WAIT:
                if (dvp_rd_rst_wait_cnt >= FIFO_RD_RST_WAIT_CNT_MAX)
                    st_rd_nxt <= ST_RD_AXI_START;
                else
                    st_rd_nxt <= st_rd_cur;
            ST_RD_AXI_START:
                if (dvp_rd_data_frame_left >= ((AXI_LEN + 1)<<AXSIZE_WTH))
                begin
                    if (dvp_rd_data_fifo_wr_cnt <= FIFO_DEPTH - AXI_LEN - 2)
                        st_rd_nxt <= ST_RD_ARVALID;
                    else
                        st_rd_nxt <= st_rd_cur;
                end
                else
                begin
                    if (dvp_rd_data_fifo_wr_cnt <= FIFO_DEPTH - (dvp_rd_data_frame_left>>AXSIZE_WTH) - 2)
                        st_rd_nxt <= ST_RD_ARVALID;
                    else
                        st_rd_nxt <= st_rd_cur;
                end
            ST_RD_ARVALID:
                if (m_axi_arready & m_axi_arvalid)
                    st_rd_nxt <= ST_RD_RREADY;
                else
                    st_rd_nxt <= st_rd_cur;
            ST_RD_RREADY:
                if (m_axi_rvalid & m_axi_rready & m_axi_rlast)
                    st_rd_nxt <= ST_RD_RD_END;
                else
                    st_rd_nxt <= st_rd_cur;
            ST_RD_RD_END:
                st_rd_nxt <= ST_RD_AXI_END;
            ST_RD_AXI_END:
                if (dvp_rd_data_frame_left == 0)
                    st_rd_nxt <= ST_RD_END;
                else
                    st_rd_nxt <= ST_RD_AXI_START;
            ST_RD_END:
                st_rd_nxt <= st_rd_cur;
            default:
                st_rd_nxt <= ST_RD_IDLE;
        endcase
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_rd_rst_wait_cnt <= 0;
        else
        begin
            if (st_rd_cur == ST_RD_IDLE)
                dvp_rd_rst_wait_cnt <= 0;
            else if (st_rd_cur == ST_RD_IDLE_WAIT)
                dvp_rd_rst_wait_cnt <= dvp_rd_rst_wait_cnt + 1;
        end
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
        begin
            m_axi_arlen <= 0;
            m_axi_arlen_bytes <= 0;
        end
        else if(dvp_rd_data_frame_left == 0)
        begin
            m_axi_arlen <= 0;
            m_axi_arlen_bytes <= 0;
        end
        else
        begin
            if(dvp_rd_data_frame_left >= ((AXI_LEN + 1)<<AXSIZE_WTH))
            begin
                m_axi_arlen <= AXI_LEN - 1;
                m_axi_arlen_bytes <= (AXI_LEN << AXSIZE_WTH);
            end
            else
            begin
                m_axi_arlen <= (dvp_rd_data_frame_left>>AXSIZE_WTH) - 1;
                m_axi_arlen_bytes <= dvp_rd_data_frame_left;
            end
        end
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_rd_data_axi_cnt <= 0;
        else if(m_axi_arvalid & m_axi_arready)
            dvp_rd_data_axi_cnt <= m_axi_arlen + 1;
        else if (m_axi_rvalid & m_axi_rready)
            dvp_rd_data_axi_cnt <= dvp_rd_data_axi_cnt - 1;
    end

    assign dvp_rd_data_frame_left = DVP_DATA_FRAME_SIZE - dvp_rd_data_frame_cnt;
    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            dvp_rd_data_frame_cnt <= 0;
        else if(dvp_rd_rst_axi_reg)
            dvp_rd_data_frame_cnt <= 0;
        else if(st_rd_nxt == ST_RD_IDLE)
            dvp_rd_data_frame_cnt <= 0;
        else if (st_rd_nxt == ST_RD_RD_END)
            dvp_rd_data_frame_cnt <= dvp_rd_data_frame_cnt + m_axi_arlen_bytes;
    end

    assign m_axi_araddr = dvp_rd_axi_addr + dvp_rd_data_frame_cnt;

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_arvalid <= 0;
        else if (st_rd_nxt == ST_RD_ARVALID)
            m_axi_arvalid <= 1;
        else
            m_axi_arvalid <= 0;
    end

    always @(posedge clk_axi or posedge rst_axi)
    begin
        if(rst_axi)
            m_axi_rready <= 0;
        else if (st_rd_nxt == ST_RD_RREADY)
            m_axi_rready <= 1;
        else
            m_axi_rready <= 0;
    end

    DC_FIFO
    # (
        .FIFO_MODE      ("ShowAhead"                ) , //"Normal"; //"ShowAhead"
        .DATA_WIDTH     (AXI_DW                     ) ,
        .FIFO_DEPTH     (FIFO_DEPTH                 )
    )
    dvp_rd_data_fifo
    (
        .Reset          (rst_axi | dvp_rd_rst_axi_reg) , //System Reset

        .WrClk          (clk_axi                     ) , //(I)Wirte Clock
        .WrEn           (m_axi_rvalid & m_axi_rready ) , //(I)Write Enable
        .WrData         (m_axi_rdata                 ) , //(I)Write Data
        .WrDNum         (dvp_rd_data_fifo_wr_cnt     ) , //(O)Write Data Number In Fifo
        .WrFull         (                            ) , //(O)Write Full

        .RdClk          (dvp_rd_clk                  ) , //(I)Read Clock
        .RdEn           (dvp_rd_data_fifo_rd_en      ) , //(I)Read Enable
        .RdData         (dvp_rd_data_tmp             ) , //(O)Read Data
        .DataVal        (                            ) , //(O)Data Valid
        .RdDNum         (dvp_rd_data_fifo_rd_cnt     ) , //(O)Radd Data Number In Fifo
        .RdEmpty        (                            )   //(O)Read FifoEmpty
    );

    assign dvp_rd_vs_pluse_pos = ~dvp_rd_vs_dly &  dvp_rd_vs;
    assign dvp_rd_vs_pluse_neg =  dvp_rd_vs_dly & ~dvp_rd_vs;
    always @ (posedge dvp_rd_clk or posedge dvp_rd_rst)
    begin
        if (dvp_rd_rst)
            dvp_rd_vs_dly <= 0;
        else
            dvp_rd_vs_dly <= dvp_rd_vs;
    end

    always @ (posedge dvp_rd_clk or posedge dvp_rd_rst)
    begin
        if (dvp_rd_rst)
            dvp_rd_data_fifo_rd_en_cnt <= 0;
        else if (dvp_rd_vs & dvp_rd_hs)
        begin
            if (dvp_rd_data_fifo_rd_en_cnt >= AXI_DW/DVP_DATA_WIDTH - 1)
                dvp_rd_data_fifo_rd_en_cnt <= 0;
            else
                dvp_rd_data_fifo_rd_en_cnt <= dvp_rd_data_fifo_rd_en_cnt + 1;
        end
        else if (dvp_rd_vs_pluse_neg)
            dvp_rd_data_fifo_rd_en_cnt <= 0;
    end

    always @ (posedge dvp_rd_clk or posedge dvp_rd_rst)
    begin
        if (dvp_rd_rst)
            dvp_rd_data_fifo_rd_en <= 0;
        else if (dvp_rd_vs & dvp_rd_hs)
            dvp_rd_data_fifo_rd_en <= (dvp_rd_data_fifo_rd_en_cnt == AXI_DW/DVP_DATA_WIDTH - 2);
        else
            dvp_rd_data_fifo_rd_en <= 0;
    end

    always @ (posedge dvp_rd_clk or posedge dvp_rd_rst)
    begin
        if (dvp_rd_rst)
            dvp_rd_data_valid <= 0;
        else
            dvp_rd_data_valid <= dvp_rd_vs & dvp_rd_hs;
    end

    generate
        case (AXI_DW)
            512:
            begin
                always @ (posedge dvp_rd_clk)
                begin
                    case (dvp_rd_data_fifo_rd_en_cnt)
                        00      :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                        01      :dvp_rd_data <= dvp_rd_data_tmp[ 31: 16];
                        02      :dvp_rd_data <= dvp_rd_data_tmp[ 47: 32];
                        03      :dvp_rd_data <= dvp_rd_data_tmp[ 63: 48];
                        04      :dvp_rd_data <= dvp_rd_data_tmp[ 79: 64];
                        05      :dvp_rd_data <= dvp_rd_data_tmp[ 95: 80];
                        06      :dvp_rd_data <= dvp_rd_data_tmp[111: 96];
                        07      :dvp_rd_data <= dvp_rd_data_tmp[127:112];
                        08      :dvp_rd_data <= dvp_rd_data_tmp[143:128];
                        09      :dvp_rd_data <= dvp_rd_data_tmp[159:144];
                        10      :dvp_rd_data <= dvp_rd_data_tmp[175:160];
                        11      :dvp_rd_data <= dvp_rd_data_tmp[191:176];
                        12      :dvp_rd_data <= dvp_rd_data_tmp[207:192];
                        13      :dvp_rd_data <= dvp_rd_data_tmp[223:208];
                        14      :dvp_rd_data <= dvp_rd_data_tmp[239:224];
                        15      :dvp_rd_data <= dvp_rd_data_tmp[255:240];
                        16      :dvp_rd_data <= dvp_rd_data_tmp[271:256];
                        17      :dvp_rd_data <= dvp_rd_data_tmp[287:272];
                        18      :dvp_rd_data <= dvp_rd_data_tmp[303:288];
                        19      :dvp_rd_data <= dvp_rd_data_tmp[319:304];
                        20      :dvp_rd_data <= dvp_rd_data_tmp[335:320];
                        21      :dvp_rd_data <= dvp_rd_data_tmp[351:336];
                        22      :dvp_rd_data <= dvp_rd_data_tmp[367:352];
                        23      :dvp_rd_data <= dvp_rd_data_tmp[383:368];
                        24      :dvp_rd_data <= dvp_rd_data_tmp[399:384];
                        25      :dvp_rd_data <= dvp_rd_data_tmp[415:400];
                        26      :dvp_rd_data <= dvp_rd_data_tmp[431:416];
                        27      :dvp_rd_data <= dvp_rd_data_tmp[447:432];
                        28      :dvp_rd_data <= dvp_rd_data_tmp[463:448];
                        29      :dvp_rd_data <= dvp_rd_data_tmp[479:464];
                        30      :dvp_rd_data <= dvp_rd_data_tmp[495:480];
                        31      :dvp_rd_data <= dvp_rd_data_tmp[511:496];
                        default :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                    endcase
                end
            end
            256:
            begin
                always @ (posedge dvp_rd_clk)
                begin
                    case (dvp_rd_data_fifo_rd_en_cnt)
                        00      :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                        01      :dvp_rd_data <= dvp_rd_data_tmp[ 31: 16];
                        02      :dvp_rd_data <= dvp_rd_data_tmp[ 47: 32];
                        03      :dvp_rd_data <= dvp_rd_data_tmp[ 63: 48];
                        04      :dvp_rd_data <= dvp_rd_data_tmp[ 79: 64];
                        05      :dvp_rd_data <= dvp_rd_data_tmp[ 95: 80];
                        06      :dvp_rd_data <= dvp_rd_data_tmp[111: 96];
                        07      :dvp_rd_data <= dvp_rd_data_tmp[127:112];
                        08      :dvp_rd_data <= dvp_rd_data_tmp[143:128];
                        09      :dvp_rd_data <= dvp_rd_data_tmp[159:144];
                        10      :dvp_rd_data <= dvp_rd_data_tmp[175:160];
                        11      :dvp_rd_data <= dvp_rd_data_tmp[191:176];
                        12      :dvp_rd_data <= dvp_rd_data_tmp[207:192];
                        13      :dvp_rd_data <= dvp_rd_data_tmp[223:208];
                        14      :dvp_rd_data <= dvp_rd_data_tmp[239:224];
                        15      :dvp_rd_data <= dvp_rd_data_tmp[255:240];
                        default :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                    endcase
                end
            end
            128:
            begin
                always @ (posedge dvp_rd_clk)
                begin
                    case (dvp_rd_data_fifo_rd_en_cnt)
                        00      :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                        01      :dvp_rd_data <= dvp_rd_data_tmp[ 31: 16];
                        02      :dvp_rd_data <= dvp_rd_data_tmp[ 47: 32];
                        03      :dvp_rd_data <= dvp_rd_data_tmp[ 63: 48];
                        04      :dvp_rd_data <= dvp_rd_data_tmp[ 79: 64];
                        05      :dvp_rd_data <= dvp_rd_data_tmp[ 95: 80];
                        06      :dvp_rd_data <= dvp_rd_data_tmp[111: 96];
                        07      :dvp_rd_data <= dvp_rd_data_tmp[127:112];
                        default :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                    endcase
                end
            end
            64:
            begin
                always @ (posedge dvp_rd_clk)
                begin
                    case (dvp_rd_data_fifo_rd_en_cnt)
                        00      :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                        01      :dvp_rd_data <= dvp_rd_data_tmp[ 31: 16];
                        02      :dvp_rd_data <= dvp_rd_data_tmp[ 47: 32];
                        03      :dvp_rd_data <= dvp_rd_data_tmp[ 63: 48];
                        default :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                    endcase
                end
            end
            default:
            begin
                always @ (posedge dvp_rd_clk)
                begin
                    case (dvp_rd_data_fifo_rd_en_cnt)
                        00      :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                        01      :dvp_rd_data <= dvp_rd_data_tmp[ 31: 16];
                        default :dvp_rd_data <= dvp_rd_data_tmp[ 15:  0];
                    endcase
                end
            end
        endcase
    endgenerate

/*----------------------------------------------------------------------------------*\
                                The function code
\*----------------------------------------------------------------------------------*/
function integer clogb2;
input [31:0] value;
begin
value = value - 1;
for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
value = value >> 1;
end
endfunction

endmodule
