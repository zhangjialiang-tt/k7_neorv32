// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20241114
// Author Name                  : zhangjl
// Module Name                  : video_fdma
// Project Name                 : zp55a
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinix Efinity-2023.2.307.1.14
// Description                  : 该文件设计思路是
//                              
//                              
//                              
// Parameter Description        : W_XSIZE-->图像宽度
//                                W_YSIZE-->图像高度
// Port Description             :
// Revision                     : 1.00.0
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module video_fdma #(
    parameter         VENDOR         = "EFINITY",
    // write
    parameter integer W_XSTRIDE      = 640 ,//写通道设置X方向的Stride值，主要用于图形缓存应用
    parameter integer W_XSIZE        = 640 ,//写通道设置X方向的数据大小，代表了每次FDMA 传输的数据长度
    parameter integer W_YSIZE        = 480 ,//写通道设置Y方向值，代表了进行了多少次XSIZE传输
    // read
    parameter integer R_XSTRIDE      = 640 ,//读通道设置Y方向值，代表了进行了多少次XSIZE传输
    parameter integer R_XSIZE        = 640 ,//读通道设置X方向的数据大小，代表了每次FDMA 传输的数据长度
    parameter integer R_YSIZE        = 480 ,//读通道设置X方向的Stride值，主要用于图形缓存应用

    parameter integer AXI_ID_DW      = 8,
    parameter integer AXI_ID         = 0,
    parameter integer AXI_AW         = 32,
    parameter integer AXI_DW         = 256,
    parameter integer DVP_DATA_WIDTH = 16
) (
    //DVP Signals
    input   wire    [1              - 1 : 0]dvp_wr_rst                  ,
    input   wire    [1              - 1 : 0]dvp_wr_clk                  ,
    input   wire    [1              - 1 : 0]dvp_wr_vs                   ,
    input   wire    [1              - 1 : 0]dvp_wr_hs                   ,
    input   wire    [DVP_DATA_WIDTH - 1 : 0]dvp_wr_data                 ,
    input   wire    [AXI_AW         - 1 : 0]dvp_wr_axi_addr             ,

    input   wire    [1              -1 : 0]dvp_rd_rst                  ,
    input   wire    [1              -1 : 0]dvp_rd_clk                  ,
    input   wire    [1              -1 : 0]dvp_rd_vs                   ,
    input   wire    [1              -1 : 0]dvp_rd_hs                   ,
    output  reg     [1              -1 : 0]dvp_rd_data_valid           ,
    output  reg     [DVP_DATA_WIDTH -1 : 0]dvp_rd_data=0               ,
    input   wire    [AXI_AW         -1 : 0]dvp_rd_axi_addr             ,

    input  wire        [1           -1 : 0]clk_axi                    ,
    input  wire        [1           -1 : 0]rst_axi                    ,
    output wire        [AXI_ID_DW   -1 : 0]m_axi_awid                 ,
    output wire        [AXI_AW      -1 : 0]m_axi_awaddr               ,
    output wire        [8           -1 : 0]m_axi_awlen                ,
    output wire        [3           -1 : 0]m_axi_awsize               ,
    output wire        [2           -1 : 0]m_axi_awburst              ,
    output wire        [1           -1 : 0]m_axi_awlock               ,
    output wire        [4           -1 : 0]m_axi_awcache              ,
    output wire        [3           -1 : 0]m_axi_awprot               ,
    output wire        [4           -1 : 0]m_axi_awqos                ,
    output wire        [1           -1 : 0]m_axi_awvalid              ,
    input  wire        [1           -1 : 0]m_axi_awready              ,
    output wire        [AXI_ID_DW   -1 : 0]m_axi_wid                  ,
    output wire        [AXI_DW      -1 : 0]m_axi_wdata                ,
    output wire        [AXI_DW/8    -1 : 0]m_axi_wstrb                ,
    output wire        [1           -1 : 0]m_axi_wlast                ,
    output wire        [1           -1 : 0]m_axi_wvalid               ,
    input  wire        [1           -1 : 0]m_axi_wready               ,
    input  wire        [AXI_ID_DW   -1 : 0]m_axi_bid                  ,
    input  wire        [2           -1 : 0]m_axi_bresp                ,
    input  wire        [1           -1 : 0]m_axi_bvalid               ,
    output wire        [1           -1 : 0]m_axi_bready               ,
    //Master AXI4 Read Bus Interface
    output wire        [AXI_ID_DW   -1 : 0]m_axi_arid                 ,
    output wire        [AXI_AW      -1 : 0]m_axi_araddr               ,
    output wire        [8           -1 : 0]m_axi_arlen                ,
    output wire        [3           -1 : 0]m_axi_arsize               ,
    output wire        [2           -1 : 0]m_axi_arburst              ,
    output wire        [1           -1 : 0]m_axi_arlock               ,
    output wire        [4           -1 : 0]m_axi_arcache              ,
    output wire        [3           -1 : 0]m_axi_arprot               ,
    output wire        [4           -1 : 0]m_axi_arqos                ,
    output wire        [1           -1 : 0]m_axi_arvalid              ,
    input  wire        [1           -1 : 0]m_axi_arready              ,
    input  wire        [AXI_ID_DW   -1 : 0]m_axi_rid                  ,
    input  wire        [AXI_DW      -1 : 0]m_axi_rdata                ,
    input  wire        [2           -1 : 0]m_axi_rresp                ,
    input  wire        [1           -1 : 0]m_axi_rlast                ,
    input  wire        [1           -1 : 0]m_axi_rvalid               ,
    output wire        [1           -1 : 0]m_axi_rready                
);  //video_fdma
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    // 总像素点
    localparam integer TOTAL_PIXEL    = W_XSIZE*W_YSIZE;

    //**********************************************************************************************
    // FIFO参数设置
    //**********************************************************************************************
    //fifo的深度-以像素个数为单位
    localparam integer  FIFO_PIXEL_DEEPTH     = 2048;//1024;
    //fifo的深度-以位宽为AXI_DW的fdma传输个数为单位
    localparam integer  FIFO_DEEPTH     = FIFO_PIXEL_DEEPTH * DVP_DATA_WIDTH / AXI_DW;
    // fifo的深度的位宽
    localparam integer  FIFO_DEEPTH_W   = $clog2(FIFO_DEEPTH);

    //**********************************************************************************************
    // 拼接参数设置
    //**********************************************************************************************
    // 拼接次数-对输入数据进行打包，拼接为位宽与AXI_DW相同的数据
    localparam integer  PACKECT_SIZE    = AXI_DW/DVP_DATA_WIDTH;
    // 拼接次数的位宽
    localparam integer  PACKECT_SIZE_W  = $clog2(PACKECT_SIZE);

    // 解包移位个数-对axi读出的数据解包为DVP_DATA_WIDTH位宽的数据
    localparam integer  UNPACK_SFT      = $clog2(DVP_DATA_WIDTH);

    //**********************************************************************************************
    // fdma参数设置
    //**********************************************************************************************
    // 写通道每次fdma通信长度，单位是个像素点
    localparam W_FDMA_PIXEL_LEN = W_XSIZE;
    // 写通道每次fdma通信长度，单位是fdma位宽
    localparam W_FDMA_PACKET_LEN = W_FDMA_PIXEL_LEN * DVP_DATA_WIDTH / AXI_DW;
    //写通道每次fdma传输后地址递增
    localparam W_ADDR_INC = (W_FDMA_PIXEL_LEN + (W_XSTRIDE - W_XSIZE)) * DVP_DATA_WIDTH / 8;
    // 总共进行fdma通信的次数
    localparam W_FDMA_TRANC_TIMES = W_XSIZE * W_YSIZE / W_FDMA_PIXEL_LEN;//一帧时间内总共进行fdma通信的次数

    // 读通道每次fdma通信长度，单位是个像素点
    localparam R_FDMA_PIXEL_LEN = R_XSIZE;
    // 读通道每次fdma通信长度，单位是fdma位宽
    localparam R_FDMA_PACKET_LEN = R_FDMA_PIXEL_LEN * DVP_DATA_WIDTH / AXI_DW;
    //读通道每次fdma传输后地址递增
    localparam R_ADDR_INC = (R_FDMA_PIXEL_LEN + (R_XSTRIDE - R_XSIZE)) * DVP_DATA_WIDTH / 8;//每次fdma传输后地址递增
    // 总共进行fdma通信的次数
    localparam R_FDMA_TRANC_TIMES = R_XSIZE * R_YSIZE / R_FDMA_PIXEL_LEN;//一帧时间内总共进行fdma通信的次数

    localparam integer  M_AXI_MAX_BURST_LEN    = 64;//W_FDMA_PACKET_LEN;//axi4最大长度为256//?

    //**********************************************************************************************
    reg                [AXI_AW          - 1 : 0]fdma_waddr                 ;
    reg                [1               - 1 : 0]fdma_wareq=1'b0            ;
    wire               [16              - 1 : 0]fdma_wsize                 ;
    wire               [1               - 1 : 0]fdma_wbusy                 ;
    wire               [AXI_DW          - 1 : 0]fdma_wdata                 ;
    wire               [1               - 1 : 0]fdma_wvalid                ;
    reg                [1               - 1 : 0]fdma_wready=1'b0           ;
    reg                [AXI_AW          - 1 : 0]fdma_raddr                 ;
    reg                [1               - 1 : 0]fdma_rareq                 ;
    wire               [16              - 1 : 0]fdma_rsize                 ;
    wire               [1               - 1 : 0]fdma_rbusy                 ;
    wire               [AXI_DW          - 1 : 0]fdma_rdata                 ;
    wire               [1               - 1 : 0]fdma_rvalid                ;
    reg                [1               - 1 : 0]fdma_rready                ;
    // wire               [1               - 1 : 0]field_rst_neg_delay        ;
    localparam                              W_IDLE   = 0            ;
    localparam                              W_STATE1 = 1            ;
    localparam                              W_STATE2 = 2            ;
    localparam                              W_STATE3 = 3            ;
    localparam                              W_STATE4 = 4            ;
    reg                [ 8              - 1 : 0]wr_state_c               ;
    reg                [ 8              - 1 : 0]wr_state_n               ;
    wire               [ 1              - 1 : 0]wr_condition1            ;
    wire               [ 1              - 1 : 0]wr_condition2            ;
    wire               [ 1              - 1 : 0]wr_condition3            ;
    wire               [ 1              - 1 : 0]wr_condition4            ;
    wire               [ 1              - 1 : 0]wr_condition5            ;
    reg                [PACKECT_SIZE_W  - 1 : 0]wr_pkt_cnt               ;
    wire               [1               - 1 : 0]wr_pkt_flag              ;
    wire               [FIFO_DEEPTH_W   - 1 : 0]w_fifo_wr_cnt            ;
    wire               [FIFO_DEEPTH_W   - 1 : 0]w_fifo_rd_cnt            ;
    reg                [1               - 1 : 0]w_fifo_wr                ;
    reg                [AXI_DW          - 1 : 0]w_fifo_wr_data           ;
    wire               [1               - 1 : 0]w_fifo_rd                ;
    wire               [AXI_DW          - 1 : 0]w_fifo_rd_data           ;
    reg                [1               - 1 : 0]fdma_wbusy_d1            ;
    wire               [1               - 1 : 0]fdma_wbusy_pos           ;
    
    reg                [AXI_AW          - 1 : 0]dvp_wr_axi_addr_reg                 ;
    reg                [AXI_AW          - 1 : 0]dvp_rd_axi_addr_reg                 ;
    always @ ( posedge clk_axi ) begin
        if(rst_axi)    dvp_wr_axi_addr_reg <= 'd0;
        else            dvp_wr_axi_addr_reg <= dvp_wr_axi_addr;
    end
    always @ ( posedge clk_axi ) begin
        if(rst_axi)    dvp_rd_axi_addr_reg <= 'd0;
        else            dvp_rd_axi_addr_reg <= dvp_rd_axi_addr;
    end
    //**********************************************************************************************
    //wr port control
    //**********************************************************************************************
    reg           [ 1  - 1 : 0 ]          wr_field_rst_d1               ;
    reg           [ 1  - 1 : 0 ]          wr_field_rst_d2               ;
    reg           [ 1  - 1 : 0 ]          rd_field_rst_d1               ;
    reg           [ 1  - 1 : 0 ]          rd_field_rst_d2               ;
    wire          [ 1  - 1 : 0 ]          dvp_wr_rst_sync               ;
    wire          [ 1  - 1 : 0 ]          dvp_rd_rst_sync               ;
    //**********************************************************************************************
    //****************************************wr port control
    //**********************************************************************************************
    // ?如果读侧或者写侧的时钟大于axi的时钟，会出现无法采样
    always @ ( posedge clk_axi ) begin
        wr_field_rst_d1 <= dvp_wr_rst;
        wr_field_rst_d2 <= wr_field_rst_d1;
        rd_field_rst_d1 <= dvp_rd_rst;
        rd_field_rst_d2 <= rd_field_rst_d1;
    end
    assign dvp_wr_rst_sync = ~wr_field_rst_d1 && wr_field_rst_d2;
    assign dvp_rd_rst_sync = ~rd_field_rst_d1 && rd_field_rst_d2;

    //**********************************************************************************************
    //****************************************axi
    //**********************************************************************************************    
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) begin
            wr_state_c <= W_IDLE;
        end
        else begin
            wr_state_c <= wr_state_n;
        end
    end
    always @(*) begin 
        case(wr_state_c) 
        W_IDLE :begin
            if(wr_condition1) 
                wr_state_n = W_STATE1 ;
            else 
                wr_state_n = W_IDLE ;
            end
        W_STATE1 :begin
            if(dvp_wr_rst_sync) 
                wr_state_n = W_IDLE ;
            else if(wr_condition2) 
                wr_state_n = W_STATE2 ;
            else 
                wr_state_n = W_STATE1 ;
            end
        W_STATE2 :begin
            if(dvp_wr_rst_sync) 
                wr_state_n = W_IDLE ;
            else if(wr_condition3) 
                wr_state_n = W_STATE3 ;
            else 
                wr_state_n = W_STATE2 ;
            end
        W_STATE3 :begin
            if(dvp_wr_rst_sync) 
                wr_state_n = W_IDLE ;
            else if(wr_condition4) 
                wr_state_n = W_STATE4 ;
            else 
                wr_state_n = W_STATE3 ;
            end
        W_STATE4 :begin
            if(dvp_wr_rst_sync) 
                wr_state_n = W_IDLE ;
            else if(wr_condition5) 
                wr_state_n = W_STATE1 ;
            else 
                wr_state_n = W_STATE4 ;
            end
        default : wr_state_n = W_IDLE ;
        endcase
    end
    assign wr_condition1  = wr_state_c==W_IDLE;//     && dvp_wr_rst_sync;
    assign wr_condition2  = wr_state_c==W_STATE1   && w_fifo_rd_cnt>=W_FDMA_PACKET_LEN;
    assign wr_condition3  = wr_state_c==W_STATE2;
    assign wr_condition4  = wr_state_c==W_STATE3   && fdma_wbusy==1'b1;
    assign wr_condition5  = wr_state_c==W_STATE4   && fdma_wbusy==1'b0;
    //**********************************************************************************************
    //fdma控制信号
    assign fdma_wsize = W_FDMA_PACKET_LEN;
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) fdma_wbusy_d1 <= 'd0;
        else fdma_wbusy_d1 <= fdma_wbusy;
    end
    assign fdma_wbusy_pos = ~fdma_wbusy_d1&fdma_wbusy;
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) fdma_wareq <= 'd0;
        else if(wr_condition3)          fdma_wareq <= 'd1;
        else if(fdma_wbusy_pos)      fdma_wareq <= 'd0;
        else                         fdma_wareq <= fdma_wareq;
    end
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1)      fdma_wready <= 'd0;
        else if(wr_condition3)          fdma_wready <= 'd1;
        else if(wr_condition5)          fdma_wready <= 'd0;
        else                         fdma_wready <= fdma_wready;
    end
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1)           fdma_waddr <= dvp_wr_axi_addr_reg;//dvp_wr_axi_addr;
        else if(dvp_wr_rst_sync)    fdma_waddr <= dvp_wr_axi_addr_reg;//dvp_wr_axi_addr;
        else if(wr_condition5)      fdma_waddr <= fdma_waddr+W_ADDR_INC;
        else                        fdma_waddr <= fdma_waddr;
    end
    //**********************************************************************************************
    //输入数据组包
    // 每隔AXI_DW/DVP_DATA_WIDTH个时钟，写入一次fifo
    always @ ( posedge dvp_wr_clk ) begin
        if(dvp_wr_vs&&dvp_wr_hs)       begin
            if(wr_pkt_cnt == PACKECT_SIZE-1)   wr_pkt_cnt <= 'd0;
            else                            wr_pkt_cnt <= wr_pkt_cnt + 1'b1;
        end else                            wr_pkt_cnt <= 'd0;
    end
    assign wr_pkt_flag = (wr_pkt_cnt == PACKECT_SIZE-1) ? 1'b1 : 1'b0;
    // assign w_fifo_wr = wr_pkt_flag;

    always @ ( posedge dvp_wr_clk ) begin
        w_fifo_wr <= wr_pkt_flag;
    end

    genvar i;
    generate begin : g_packaged_data
            for (i = 0; i < PACKECT_SIZE; i = i + 1) begin : g_pac
                always @ ( posedge dvp_wr_clk ) begin
                    if(dvp_wr_vs&&dvp_wr_hs) w_fifo_wr_data <= {dvp_wr_data,w_fifo_wr_data[DVP_DATA_WIDTH +: AXI_DW-DVP_DATA_WIDTH]};
                    else w_fifo_wr_data <= 'd0;
                end
            end
        end
    endgenerate
	// DC_FIFO #(
    //     .FIFO_MODE                          ("ShowAhead"               ),//"Normal"; //"ShowAhead"
    //     .DATA_WIDTH                         (AXI_DW                    ),
    //     .FIFO_DEPTH                         (FIFO_DEEPTH               ) 
	// )dvp_wr_data_fifo(
    //     .Reset                              (dvp_wr_rst_sync           ),//System Reset
    //     .WrClk                              (dvp_wr_clk                ),
    //     .WrEn                               (w_fifo_wr                 ),
    //     .WrData                             (w_fifo_wr_data            ),
    //     .WrDNum                             (w_fifo_wr_cnt             ),
    //     .WrFull                             (                          ),
    //     .RdClk                              (clk_axi                   ),
    //     .RdEn                               (w_fifo_rd                 ),
    //     .RdData                             (w_fifo_rd_data            ),
    //     .DataVal                            (                          ),
    //     .RdDNum                             (w_fifo_rd_cnt             ),
    //     .RdEmpty                            (                          ) 
	// 	);
    xilinx_general_fifo # (
        .VENDOR                             (VENDOR                    ),
        .FIFO_MODE                          ("fwft"                    ),
        .DATA_W                             (AXI_DW                    ),
        .DEPT_W                             (FIFO_DEEPTH               ) 
      )
      dvp_wr_data_fifo (
        .i_rst                              (dvp_wr_rst                  ),
        .i_wr_clk                           (dvp_wr_clk                ),
        .i_wr_en                            (w_fifo_wr                 ),
        .i_wr_data                          (w_fifo_wr_data            ),
        .i_rd_clk                           (clk_axi                   ),
        .i_rd_en                            (w_fifo_rd                 ),
        .o_rd_data                          (w_fifo_rd_data            ),
        .o_full                             (                          ),
        .o_empty                            (                          ),
        .o_al_full                          (                          ),
        .o_al_empty                         (                          ),
        .o_wrusedw                          (w_fifo_wr_cnt             ),
        .o_rdusedw                          (w_fifo_rd_cnt             ) 
      );        
    assign w_fifo_rd = fdma_wvalid;
    assign fdma_wdata = w_fifo_rd_data;
    //**********************************************************************************************
    //rd port control
    //**********************************************************************************************

    localparam                              R_IDLE   = 0            ;
    localparam                              R_STATE1 = 1            ;
    localparam                              R_STATE2 = 2            ;
    localparam                              R_STATE3 = 3            ;
    localparam                              R_STATE4 = 4            ;
    localparam                              R_STATE5 = 5            ;
    reg                [8              - 1 : 0]rd_state_c           ;
    reg                [8              - 1 : 0]rd_state_n           ;
    wire               [1              - 1 : 0]rd_condition1        ;
    wire               [1              - 1 : 0]rd_condition2        ;
    wire               [1              - 1 : 0]rd_condition3        ;
    wire               [1              - 1 : 0]rd_condition4        ;
    wire               [1              - 1 : 0]rd_condition5        ;
    wire               [1              - 1 : 0]rd_condition6        ;
    wire               [1              - 1 : 0]rd_condition7        ;
    reg                [8              - 1 : 0]rd_rst_wait          ;
    wire               [1              - 1 : 0]rd_rst_wait_done     ;
    reg                [11             - 1 : 0]fdma_rd_length       ;
    wire               [FIFO_DEEPTH_W  - 1 : 0]r_fifo_wr_cnt        ;
    wire               [FIFO_DEEPTH_W  - 1 : 0]r_fifo_rd_cnt        ;
    wire               [1              - 1 : 0]r_fifo_wr            ;
    wire               [AXI_DW         - 1 : 0]r_fifo_wr_data       ;
    wire               [AXI_DW         - 1 : 0]r_fifo_rd_data       ;
    // reg                [AXI_DW         - 1 : 0]r_fifo_rd_data_sft   ;
    reg                [1              - 1 : 0]fdma_rbusy_d1        ;
    wire               [1              - 1 : 0]fdma_rbusy_pos       ;
    reg                [PACKECT_SIZE_W - 1 : 0]rd_unpkt_cnt         ;
    wire               [8              - 1 : 0]unpack_sft_bit       ;
    wire               [1              - 1 : 0]rd_unpkt_flag        ;
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) begin
            rd_state_c <= R_IDLE;
        end
        else begin
            rd_state_c <= rd_state_n;
        end
    end
    always @(*) begin 
        case(rd_state_c) 
        R_IDLE :begin
            if(rd_condition1) 
                rd_state_n = R_STATE1 ;
            else 
                rd_state_n = R_IDLE ;
            end
        R_STATE1 :begin
            if(rd_condition2) 
                rd_state_n = R_STATE2 ;
            else if(rd_condition6) 
                rd_state_n = R_STATE5 ;
            else 
                rd_state_n = R_STATE1 ;
            end
        R_STATE2 :begin
            if(rd_condition3) 
                rd_state_n = R_STATE3 ;
            else 
                rd_state_n = R_STATE2 ;
            end
        R_STATE3 :begin
            if(rd_condition4) 
                rd_state_n = W_STATE4 ;
            else 
                rd_state_n = R_STATE3 ;
            end
        R_STATE4 :begin
            if(rd_condition5) 
                rd_state_n = R_STATE1 ;
            else 
                rd_state_n = R_STATE4 ;
            end
        R_STATE5 :begin
            if(rd_condition7) 
                rd_state_n = R_IDLE ;
            else 
                rd_state_n = R_STATE5 ;
            end
        default : rd_state_n = R_IDLE ;
        endcase
    end
    assign rd_condition1  = rd_state_c==R_IDLE;// && rd_rst_wait_done;
    assign rd_condition2  = rd_state_c==R_STATE1   && r_fifo_wr_cnt<R_FDMA_PACKET_LEN && fdma_rd_length<R_FDMA_TRANC_TIMES;
    assign rd_condition3  = rd_state_c==R_STATE2;
    assign rd_condition4  = rd_state_c==R_STATE3   && fdma_rbusy==1'b1;
    assign rd_condition5  = rd_state_c==R_STATE4   && fdma_rbusy==1'b0;
    assign rd_condition6  = rd_state_c==R_STATE1   && dvp_rd_rst_sync;
    assign rd_condition7  = rd_state_c==R_STATE5   && rd_rst_wait=='d200;
    always @ ( posedge clk_axi ) begin
        if(rd_state_c==R_STATE5)begin
            if(rd_rst_wait=='d200)      rd_rst_wait <= rd_rst_wait;
            else                        rd_rst_wait <= rd_rst_wait + 'd1;
        end else                        rd_rst_wait <= 'd0;
    end
    assign rd_rst_wait_done = rd_rst_wait=='d199;
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) fdma_rbusy_d1 <= 'd0;
        else fdma_rbusy_d1 <= fdma_rbusy;
    end
    assign fdma_rbusy_pos = ~fdma_rbusy_d1&fdma_rbusy;
    assign fdma_rsize = R_FDMA_PACKET_LEN;
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1) fdma_rareq <= 'd0;
        else if(rd_condition3)  fdma_rareq <= 'd1;
        else if(fdma_rbusy_pos) fdma_rareq <= 'd0;
        else                    fdma_rareq <= fdma_rareq;
    end
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1)      fdma_rready <= 'd0;
        else if(rd_condition3)       fdma_rready <= 'd1;
        else if(rd_condition5)       fdma_rready <= 'd0;
        else                         fdma_rready <= fdma_rready;
    end
    always @ ( posedge clk_axi ) begin
        if(rst_axi==1'b1)      fdma_raddr <= dvp_rd_axi_addr_reg;
        else if(dvp_rd_rst)          fdma_raddr <= dvp_rd_axi_addr_reg;
        // else if(fdma_rbusy_pos)      fdma_raddr <= fdma_raddr+1024;
        else if(rd_condition5)      fdma_raddr <= fdma_raddr+R_ADDR_INC;
        else                         fdma_raddr <= fdma_raddr;
    end
    wire           [ 1  - 1 : 0 ]          r_fifo_rd               ;
    // DC_FIFO #(
    //     .FIFO_MODE                          ("ShowAhead"               ),//"Normal"; //"ShowAhead"
    //     .DATA_WIDTH                         (AXI_DW                    ),
    //     .FIFO_DEPTH                         (FIFO_DEEPTH               ) 
    //     )
    //     dvp_rd_data_fifo
    //     (
    //     .Reset                              (dvp_rd_rst_sync       ),//System Reset
    //     .WrClk                              (clk_axi                ),
    //     .WrEn                               (r_fifo_wr                 ),
    //     .WrData                             (r_fifo_wr_data            ),
    //     .WrDNum                             (r_fifo_wr_cnt             ),
    //     .WrFull                             (                          ),
    //     .RdClk                              (dvp_wr_clk                ),
    //     .RdEn                               (r_fifo_rd                 ),
    //     .RdData                             (r_fifo_rd_data            ),
    //     .DataVal                            (                          ),
    //     .RdDNum                             (r_fifo_rd_cnt             ),
    //     .RdEmpty                            (                          ) 
    //     );

    xilinx_general_fifo # (
        .VENDOR                             (VENDOR                    ),
        .FIFO_MODE                          ("fwft"                    ),
        .DATA_W                             (AXI_DW                    ),
        .DEPT_W                             (FIFO_DEEPTH               ) 
    )dvp_rd_data_fifo (
        .i_rst                              (dvp_rd_rst_sync                  ),
        .i_wr_clk                           (clk_axi                   ),
        .i_wr_en                            (r_fifo_wr                 ),
        .i_wr_data                          (r_fifo_wr_data            ),
        .i_rd_clk                           (dvp_rd_clk                ),
        .i_rd_en                            (r_fifo_rd                 ),
        .o_rd_data                          (r_fifo_rd_data            ),
        .o_full                             (                          ),
        .o_empty                            (                          ),
        .o_al_full                          (                          ),
        .o_al_empty                         (                          ),
        .o_wrusedw                          (r_fifo_wr_cnt             ),
        .o_rdusedw                          (r_fifo_rd_cnt             ) 
    );
    assign r_fifo_wr = fdma_rvalid;
    assign r_fifo_wr_data = fdma_rdata;
    always @ ( posedge dvp_rd_clk ) begin
        if(dvp_rd_vs&&dvp_rd_hs)       begin
            if(rd_unpkt_cnt == PACKECT_SIZE-1)   rd_unpkt_cnt <= 'd0;
            else                            rd_unpkt_cnt <= rd_unpkt_cnt + 1'b1;
        end else                            rd_unpkt_cnt <= 'd0;
    end
`ifdef DEBUG
    reg [11:0]rd_hcnt=0;
    reg [11:0]rd_vcnt=0;
    always @ ( posedge dvp_rd_clk ) begin
        if(dvp_rd_vs&&dvp_rd_hs) rd_hcnt <= rd_hcnt + 'd1;
        else rd_hcnt <=0;
    end
    always @ ( posedge dvp_rd_clk ) begin
        if(dvp_rd_vs)       begin 
            rd_vcnt <= rd_hcnt==639 ? rd_vcnt + 'd1 : rd_vcnt;
        end
    end
`endif
    assign rd_unpkt_flag = (dvp_rd_vs&&dvp_rd_hs&&rd_unpkt_cnt == PACKECT_SIZE-1) ? 1'b1 : 1'b0;
    assign r_fifo_rd = rd_unpkt_flag;

    assign unpack_sft_bit = rd_unpkt_cnt<<UNPACK_SFT; 
    genvar j;
    generate begin : g_unpackaged_data
            for (j = 0; j < PACKECT_SIZE; j = j + 1) begin : g_unpac
                always @ ( posedge dvp_rd_clk ) begin
                    if(dvp_rd_vs&&dvp_rd_hs) dvp_rd_data <= r_fifo_rd_data>>unpack_sft_bit;
                    else dvp_rd_data <= 0;
                end
            end
        end
    endgenerate
    always @ ( posedge dvp_rd_clk ) begin
        dvp_rd_data_valid <= dvp_rd_vs&&dvp_rd_hs;
    end
    //**********************************************************************************************
    always @(posedge clk_axi) begin
        if(dvp_rd_rst_sync)     fdma_rd_length <= 0;
        else if(rd_condition4)  fdma_rd_length <= fdma_rd_length+1;
    end
    reg           [ 11  - 1 : 0 ]          fdma_wr_length                ;
    always @(posedge clk_axi) begin
        if(dvp_wr_rst_sync)     fdma_wr_length <= 0;
        else if(wr_condition4)  fdma_wr_length <= fdma_wr_length+1;
    end


    //**********************************************************************************************
    // fast direct memory access
    //**********************************************************************************************
    uiFDMA #(
        .M_AXI_ID_WIDTH                     (AXI_ID_DW                 ),
        .M_AXI_ID                           (AXI_ID                    ),
        .M_AXI_ADDR_WIDTH                   (AXI_AW                    ),
        .M_AXI_DATA_WIDTH                   (AXI_DW                    ), 
        .M_AXI_MAX_BURST_LEN                (M_AXI_MAX_BURST_LEN       )
    ) uiFDMA_inst (
        .fdma_waddr                         (fdma_waddr                ),//in
        .fdma_wareq                         (fdma_wareq                ),//in
        .fdma_wsize                         (fdma_wsize                ),//in
        .fdma_wbusy                         (fdma_wbusy                ),//out
        .fdma_wdata                         (fdma_wdata                ),//in
        .fdma_wvalid                        (fdma_wvalid               ),//out
        .fdma_wready                        (fdma_wready               ),//in
        .fdma_raddr                         (fdma_raddr                ),
        .fdma_rareq                         (fdma_rareq                ),
        .fdma_rsize                         (fdma_rsize                ),
        .fdma_rbusy                         (fdma_rbusy                ),
        .fdma_rdata                         (fdma_rdata                ),
        .fdma_rvalid                        (fdma_rvalid               ),
        .fdma_rready                        (fdma_rready               ),
        .M_AXI_ACLK                         (clk_axi                   ),
        .M_AXI_ARESETN                      (~rst_axi                  ),
        .M_AXI_AWID                         (m_axi_awid                ),//M_AXI_AWID
        .M_AXI_AWADDR                       (m_axi_awaddr              ),//M_AXI_AWADDR
        .M_AXI_AWLEN                        (m_axi_awlen               ),//M_AXI_AWLEN
        .M_AXI_AWSIZE                       (m_axi_awsize              ),//M_AXI_AWSIZE
        .M_AXI_AWBURST                      (m_axi_awburst             ),//M_AXI_AWBURST
        .M_AXI_AWLOCK                       (m_axi_awlock              ),//M_AXI_AWLOCK
        .M_AXI_AWCACHE                      (m_axi_awcache             ),//M_AXI_AWCACHE
        .M_AXI_AWPROT                       (m_axi_awprot              ),//M_AXI_AWPROT
        .M_AXI_AWQOS                        (m_axi_awqos               ),//M_AXI_AWQOS//?
        .M_AXI_AWVALID                      (m_axi_awvalid             ),//M_AXI_AWVALID
        .M_AXI_AWREADY                      (m_axi_awready             ),//M_AXI_AWREADY
        .M_AXI_WID                          (m_axi_wid                 ),//M_AXI_WID//?
        .M_AXI_WDATA                        (m_axi_wdata               ),//M_AXI_WDATA
        .M_AXI_WSTRB                        (m_axi_wstrb               ),//M_AXI_WSTRB
        .M_AXI_WLAST                        (m_axi_wlast               ),//M_AXI_WLAST
        .M_AXI_WVALID                       (m_axi_wvalid              ),//M_AXI_WVALID
        .M_AXI_WREADY                       (m_axi_wready              ),//M_AXI_WREADY
        .M_AXI_BID                          (m_axi_bid                 ),//M_AXI_BID
        .M_AXI_BRESP                        (m_axi_bresp               ),//M_AXI_BRESP
        .M_AXI_BVALID                       (m_axi_bvalid              ),//M_AXI_BVALID
        .M_AXI_BREADY                       (m_axi_bready              ),//M_AXI_BREADY
        .M_AXI_ARID                         (m_axi_arid                ),//M_AXI_ARID
        .M_AXI_ARADDR                       (m_axi_araddr              ),//M_AXI_ARADDR
        .M_AXI_ARLEN                        (m_axi_arlen               ),//M_AXI_ARLEN
        .M_AXI_ARSIZE                       (m_axi_arsize              ),//M_AXI_ARSIZE
        .M_AXI_ARBURST                      (m_axi_arburst             ),//M_AXI_ARBURST
        .M_AXI_ARLOCK                       (m_axi_arlock              ),//M_AXI_ARLOCK
        .M_AXI_ARCACHE                      (m_axi_arcache             ),//M_AXI_ARCACHE
        .M_AXI_ARPROT                       (m_axi_arprot              ),//M_AXI_ARPROT
        .M_AXI_ARQOS                        (m_axi_arqos               ),//M_AXI_ARQOS//?
        .M_AXI_ARVALID                      (m_axi_arvalid             ),//M_AXI_ARVALID
        .M_AXI_ARREADY                      (m_axi_arready             ),//M_AXI_ARREADY
        .M_AXI_RID                          (m_axi_rid                 ),//M_AXI_RID
        .M_AXI_RDATA                        (m_axi_rdata               ),//M_AXI_RDATA
        .M_AXI_RRESP                        (m_axi_rresp               ),//M_AXI_RRESP
        .M_AXI_RLAST                        (m_axi_rlast               ),//M_AXI_RLAST
        .M_AXI_RVALID                       (m_axi_rvalid              ),//M_AXI_RVALID
        .M_AXI_RREADY                       (m_axi_rready              ) //M_AXI_RREADY
    );
    //**********************************************************************************************
endmodule
