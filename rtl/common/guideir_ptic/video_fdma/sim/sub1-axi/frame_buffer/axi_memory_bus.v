// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20230817
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti60f100
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 该文件是
//                              
//                              
//                              
// Revision                     : 1.00.0000
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module axi_memory_bus #(
    // parameter CW = 10,
    parameter DW = 16,
    // parameter BASE_ADDR1 = 0,
    // parameter BASE_ADDR2 = 0,
    parameter IMAGE_WIDTH = 'd640,
    parameter IMAGE_HEIGHT = 'd480
) (
    //global input interface
    input  wire [1       - 1 : 0] i_Sys_clk,
    input  wire [1       - 1 : 0] i_axi_clk,
    input  wire [1       - 1 : 0] i_axi_rst_n,

    input  wire    [  1        - 1 : 0] user_wr_rst,
    input  wire    [  1        - 1 : 0] user_wr_req,
    input  wire    [  DW       - 1 : 0] user_wr_data,
    input  wire    [      32   - 1 : 0] user_wr_addr,
    input  wire    [  1        - 1 : 0] user_rd_rst,
    input  wire    [  1        - 1 : 0] user_rd_req,
    output wire    [  1        - 1 : 0] user_rd_valid,
    output wire    [  DW       - 1 : 0] user_rd_data,
    input  wire    [      32   - 1 : 0] user_rd_addr

    // input  wire [1       - 1 : 0] i_Din_valid,
    // input  wire [DW      - 1 : 0] i_Din,
    // output wire [1       - 1 : 0] o_Dout_valid,
    // output wire [DW      - 1 : 0] o_Dout

);  //axi_memory_bus
//**********************************************************************************************
    //************************parameter defination***********************
    localparam AXI_ID_WIDTH = 8;  //256;
    localparam AXI_DW = 256;  //256;
    localparam AXI_AW = 32;
    localparam AXI_SW = AXI_DW / 8;  //256;
    localparam AXI_LEN = 32;
    localparam S_COUNT = 2;
    localparam M_COUNT = 1;
    localparam AXI_CNT = S_COUNT + M_COUNT;

    // localparam AXI_DW = 32;  //Data Width
    // localparam AXI_AW = 32;  //Address Width
    // localparam AXI_SW = AXI_DW / 8;  //Write Strobes Width
    // localparam AXI_LEN = 128;  //minimum=1; maximum=256;
    // localparam AXI_CNT = 3;
    localparam PIXEL_CLK_AXI = 200;  //50MHz
    localparam AXI_CLK_PERIOD = 1000 / PIXEL_CLK_AXI;  //像素时钟周期-20ns

    `define S0_NUMBER 0
    `define S1_NUMBER 1
    `define M0_NUMBER 2
    //**********************************************************************************************

    wire    [  1        - 1 : 0] o_scaler_wr_rst;
    wire    [  1        - 1 : 0] o_scaler_wr_req;
    wire    [  DW       - 1 : 0] o_scaler_wr_data;
    wire    [      32   - 1 : 0] o_scaler_wr_addr;
    wire    [  1        - 1 : 0] o_scaler_rd_rst;
    wire    [  1        - 1 : 0] o_scaler_rd_req;
    wire    [  1        - 1 : 0] i_scaler_rd_valid;
    wire    [  DW       - 1 : 0] i_scaler_rd_data;
    wire    [      32   - 1 : 0] o_scaler_rd_addr;
    //--AXI4 Interface
    wire [          AXI_CNT*8-1:0] axi_awid;
    wire [     AXI_CNT*AXI_AW-1:0] axi_awaddr;
    wire [          AXI_CNT*8-1:0] axi_awlen;
    wire [          AXI_CNT*3-1:0] axi_awsize;
    wire [          AXI_CNT*2-1:0] axi_awburst;
    wire [            AXI_CNT-1:0] axi_awlock;
    wire [          AXI_CNT*4-1:0] axi_awcache;
    wire [          AXI_CNT*3-1:0] axi_awprot;
    wire [            AXI_CNT-1:0] axi_awvalid;
    wire [            AXI_CNT-1:0] axi_awready;
    wire [     AXI_CNT*AXI_DW-1:0] axi_wdata;
    wire [     AXI_CNT*AXI_SW-1:0] axi_wstrb;
    wire [            AXI_CNT-1:0] axi_wlast;
    wire [            AXI_CNT-1:0] axi_wvalid;
    wire [            AXI_CNT-1:0] axi_wready;
    wire [          AXI_CNT*8-1:0] axi_bid;
    wire [          AXI_CNT*2-1:0] axi_bresp;
    wire [            AXI_CNT-1:0] axi_bvalid;
    wire [            AXI_CNT-1:0] axi_bready;
    wire [          AXI_CNT*8-1:0] axi_arid;
    wire [     AXI_CNT*AXI_AW-1:0] axi_araddr;
    wire [          AXI_CNT*8-1:0] axi_arlen;
    wire [          AXI_CNT*3-1:0] axi_arsize;
    wire [          AXI_CNT*2-1:0] axi_arburst;
    wire [            AXI_CNT-1:0] axi_arlock;
    wire [          AXI_CNT*4-1:0] axi_arcache;
    wire [          AXI_CNT*3-1:0] axi_arprot;
    wire [            AXI_CNT-1:0] axi_arvalid;
    wire [            AXI_CNT-1:0] axi_arready;
    wire [          AXI_CNT*8-1:0] axi_rid;
    wire [     AXI_CNT*AXI_DW-1:0] axi_rdata;
    wire [          AXI_CNT*2-1:0] axi_rresp;
    wire [            AXI_CNT-1:0] axi_rlast;
    wire [            AXI_CNT-1:0] axi_rvalid;
    wire [            AXI_CNT-1:0] axi_rready;
    wire [ 1*8-1      : 0 ] m0_axi_awid     ,s0_axi_awid     ,s1_axi_awid     ;
    wire [ 1*AXI_AW-1 : 0 ] m0_axi_awaddr   ,s0_axi_awaddr   ,s1_axi_awaddr   ;
    wire [ 1*8-1      : 0 ] m0_axi_awlen    ,s0_axi_awlen    ,s1_axi_awlen    ;
    wire [ 1*3-1      : 0 ] m0_axi_awsize   ,s0_axi_awsize   ,s1_axi_awsize   ;
    wire [ 1*2-1      : 0 ] m0_axi_awburst  ,s0_axi_awburst  ,s1_axi_awburst  ;
    wire [ 1-1        : 0 ] m0_axi_awlock   ,s0_axi_awlock   ,s1_axi_awlock   ;
    wire [ 1*4-1      : 0 ] m0_axi_awcache  ,s0_axi_awcache  ,s1_axi_awcache  ;
    wire [ 1*3-1      : 0 ] m0_axi_awprot   ,s0_axi_awprot   ,s1_axi_awprot   ;
    wire [ 1-1        : 0 ] m0_axi_awvalid  ,s0_axi_awvalid  ,s1_axi_awvalid  ;
    wire [ 1-1        : 0 ] m0_axi_awready  ,s0_axi_awready  ,s1_axi_awready  ;
    wire [ 1*AXI_DW-1 : 0 ] m0_axi_wdata    ,s0_axi_wdata    ,s1_axi_wdata    ;
    wire [ 1*AXI_SW-1 : 0 ] m0_axi_wstrb    ,s0_axi_wstrb    ,s1_axi_wstrb    ;
    wire [ 1-1        : 0 ] m0_axi_wlast    ,s0_axi_wlast    ,s1_axi_wlast    ;
    wire [ 1-1        : 0 ] m0_axi_wvalid   ,s0_axi_wvalid   ,s1_axi_wvalid   ;
    wire [ 1-1        : 0 ] m0_axi_wready   ,s0_axi_wready   ,s1_axi_wready   ;
    wire [ 1*8-1      : 0 ] m0_axi_bid      ,s0_axi_bid      ,s1_axi_bid      ;
    wire [ 1*2-1      : 0 ] m0_axi_bresp    ,s0_axi_bresp    ,s1_axi_bresp    ;
    wire [ 1-1        : 0 ] m0_axi_bvalid   ,s0_axi_bvalid   ,s1_axi_bvalid   ;
    wire [ 1-1        : 0 ] m0_axi_bready   ,s0_axi_bready   ,s1_axi_bready   ;
    wire [ 1*8-1      : 0 ] m0_axi_arid     ,s0_axi_arid     ,s1_axi_arid     ;
    wire [ 1*AXI_AW-1 : 0 ] m0_axi_araddr   ,s0_axi_araddr   ,s1_axi_araddr   ;
    wire [ 1*8-1      : 0 ] m0_axi_arlen    ,s0_axi_arlen    ,s1_axi_arlen    ;
    wire [ 1*3-1      : 0 ] m0_axi_arsize   ,s0_axi_arsize   ,s1_axi_arsize   ;
    wire [ 1*2-1      : 0 ] m0_axi_arburst  ,s0_axi_arburst  ,s1_axi_arburst  ;
    wire [ 1-1        : 0 ] m0_axi_arlock   ,s0_axi_arlock   ,s1_axi_arlock   ;
    wire [ 1*4-1      : 0 ] m0_axi_arcache  ,s0_axi_arcache  ,s1_axi_arcache  ;
    wire [ 1*3-1      : 0 ] m0_axi_arprot   ,s0_axi_arprot   ,s1_axi_arprot   ;
    wire [ 1-1        : 0 ] m0_axi_arvalid  ,s0_axi_arvalid  ,s1_axi_arvalid  ;
    wire [ 1-1        : 0 ] m0_axi_arready  ,s0_axi_arready  ,s1_axi_arready  ;
    wire [ 1*8-1      : 0 ] m0_axi_rid      ,s0_axi_rid      ,s1_axi_rid      ;
    wire [ 1*AXI_DW-1 : 0 ] m0_axi_rdata    ,s0_axi_rdata    ,s1_axi_rdata    ;
    wire [ 1*2-1      : 0 ] m0_axi_rresp    ,s0_axi_rresp    ,s1_axi_rresp    ;
    wire [ 1-1        : 0 ] m0_axi_rlast    ,s0_axi_rlast    ,s1_axi_rlast    ;
    wire [ 1-1        : 0 ] m0_axi_rvalid   ,s0_axi_rvalid   ,s1_axi_rvalid   ;
    wire [ 1-1        : 0 ] m0_axi_rready   ,s0_axi_rready   ,s1_axi_rready   ;

    assign m0_axi_awid     = axi_awid    [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_awaddr   = axi_awaddr  [`M0_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign m0_axi_awlen    = axi_awlen   [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_awsize   = axi_awsize  [`M0_NUMBER*3         +: 1*3      ];
    assign m0_axi_awburst  = axi_awburst [`M0_NUMBER*2         +: 1*2      ];
    assign m0_axi_awlock   = axi_awlock  [`M0_NUMBER           +: 1        ];
    assign m0_axi_awcache  = axi_awcache [`M0_NUMBER*4         +: 1*4      ];
    assign m0_axi_awprot   = axi_awprot  [`M0_NUMBER*3         +: 1*3      ];
    assign m0_axi_awvalid  = axi_awvalid [`M0_NUMBER           +: 1        ];
    assign m0_axi_awready  = axi_awready [`M0_NUMBER           +: 1        ];
    assign m0_axi_wdata    = axi_wdata   [`M0_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign m0_axi_wstrb    = axi_wstrb   [`M0_NUMBER*AXI_SW    +: 1*AXI_SW ];
    assign m0_axi_wlast    = axi_wlast   [`M0_NUMBER           +: 1        ];
    assign m0_axi_wvalid   = axi_wvalid  [`M0_NUMBER           +: 1        ];
    assign m0_axi_wready   = axi_wready  [`M0_NUMBER           +: 1        ];
    assign m0_axi_bid      = axi_bid     [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_bresp    = axi_bresp   [`M0_NUMBER*2         +: 1*2      ];
    assign m0_axi_bvalid   = axi_bvalid  [`M0_NUMBER           +: 1        ];
    assign m0_axi_bready   = axi_bready  [`M0_NUMBER           +: 1        ];
    assign m0_axi_arid     = axi_arid    [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_araddr   = axi_araddr  [`M0_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign m0_axi_arlen    = axi_arlen   [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_arsize   = axi_arsize  [`M0_NUMBER*3         +: 1*3      ];
    assign m0_axi_arburst  = axi_arburst [`M0_NUMBER*2         +: 1*2      ];
    assign m0_axi_arlock   = axi_arlock  [`M0_NUMBER           +: 1        ];
    assign m0_axi_arcache  = axi_arcache [`M0_NUMBER*4         +: 1*4      ];
    assign m0_axi_arprot   = axi_arprot  [`M0_NUMBER*3         +: 1*3      ];
    assign m0_axi_arvalid  = axi_arvalid [`M0_NUMBER           +: 1        ];
    assign m0_axi_arready  = axi_arready [`M0_NUMBER           +: 1        ];
    assign m0_axi_rid      = axi_rid     [`M0_NUMBER*8         +: 1*8      ];
    assign m0_axi_rdata    = axi_rdata   [`M0_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign m0_axi_rresp    = axi_rresp   [`M0_NUMBER*2         +: 1*2      ];
    assign m0_axi_rlast    = axi_rlast   [`M0_NUMBER           +: 1        ];
    assign m0_axi_rvalid   = axi_rvalid  [`M0_NUMBER           +: 1        ];
    assign m0_axi_rready   = axi_rready  [`M0_NUMBER           +: 1        ];
    assign s0_axi_awid     = axi_awid    [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_awaddr   = axi_awaddr  [`S0_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign s0_axi_awlen    = axi_awlen   [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_awsize   = axi_awsize  [`S0_NUMBER*3         +: 1*3      ];
    assign s0_axi_awburst  = axi_awburst [`S0_NUMBER*2         +: 1*2      ];
    assign s0_axi_awlock   = axi_awlock  [`S0_NUMBER           +: 1        ];
    assign s0_axi_awcache  = axi_awcache [`S0_NUMBER*4         +: 1*4      ];
    assign s0_axi_awprot   = axi_awprot  [`S0_NUMBER*3         +: 1*3      ];
    assign s0_axi_awvalid  = axi_awvalid [`S0_NUMBER           +: 1        ];
    assign s0_axi_awready  = axi_awready [`S0_NUMBER           +: 1        ];
    assign s0_axi_wdata    = axi_wdata   [`S0_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign s0_axi_wstrb    = axi_wstrb   [`S0_NUMBER*AXI_SW    +: 1*AXI_SW ];
    assign s0_axi_wlast    = axi_wlast   [`S0_NUMBER           +: 1        ];
    assign s0_axi_wvalid   = axi_wvalid  [`S0_NUMBER           +: 1        ];
    assign s0_axi_wready   = axi_wready  [`S0_NUMBER           +: 1        ];
    assign s0_axi_bid      = axi_bid     [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_bresp    = axi_bresp   [`S0_NUMBER*2         +: 1*2      ];
    assign s0_axi_bvalid   = axi_bvalid  [`S0_NUMBER           +: 1        ];
    assign s0_axi_bready   = axi_bready  [`S0_NUMBER           +: 1        ];
    assign s0_axi_arid     = axi_arid    [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_araddr   = axi_araddr  [`S0_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign s0_axi_arlen    = axi_arlen   [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_arsize   = axi_arsize  [`S0_NUMBER*3         +: 1*3      ];
    assign s0_axi_arburst  = axi_arburst [`S0_NUMBER*2         +: 1*2      ];
    assign s0_axi_arlock   = axi_arlock  [`S0_NUMBER           +: 1        ];
    assign s0_axi_arcache  = axi_arcache [`S0_NUMBER*4         +: 1*4      ];
    assign s0_axi_arprot   = axi_arprot  [`S0_NUMBER*3         +: 1*3      ];
    assign s0_axi_arvalid  = axi_arvalid [`S0_NUMBER           +: 1        ];
    assign s0_axi_arready  = axi_arready [`S0_NUMBER           +: 1        ];
    assign s0_axi_rid      = axi_rid     [`S0_NUMBER*8         +: 1*8      ];
    assign s0_axi_rdata    = axi_rdata   [`S0_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign s0_axi_rresp    = axi_rresp   [`S0_NUMBER*2         +: 1*2      ];
    assign s0_axi_rlast    = axi_rlast   [`S0_NUMBER           +: 1        ];
    assign s0_axi_rvalid   = axi_rvalid  [`S0_NUMBER           +: 1        ];
    assign s0_axi_rready   = axi_rready  [`S0_NUMBER           +: 1        ];
    assign s1_axi_awid     = axi_awid    [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_awaddr   = axi_awaddr  [`S1_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign s1_axi_awlen    = axi_awlen   [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_awsize   = axi_awsize  [`S1_NUMBER*3         +: 1*3      ];
    assign s1_axi_awburst  = axi_awburst [`S1_NUMBER*2         +: 1*2      ];
    assign s1_axi_awlock   = axi_awlock  [`S1_NUMBER           +: 1        ];
    assign s1_axi_awcache  = axi_awcache [`S1_NUMBER*4         +: 1*4      ];
    assign s1_axi_awprot   = axi_awprot  [`S1_NUMBER*3         +: 1*3      ];
    assign s1_axi_awvalid  = axi_awvalid [`S1_NUMBER           +: 1        ];
    assign s1_axi_awready  = axi_awready [`S1_NUMBER           +: 1        ];
    assign s1_axi_wdata    = axi_wdata   [`S1_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign s1_axi_wstrb    = axi_wstrb   [`S1_NUMBER*AXI_SW    +: 1*AXI_SW ];
    assign s1_axi_wlast    = axi_wlast   [`S1_NUMBER           +: 1        ];
    assign s1_axi_wvalid   = axi_wvalid  [`S1_NUMBER           +: 1        ];
    assign s1_axi_wready   = axi_wready  [`S1_NUMBER           +: 1        ];
    assign s1_axi_bid      = axi_bid     [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_bresp    = axi_bresp   [`S1_NUMBER*2         +: 1*2      ];
    assign s1_axi_bvalid   = axi_bvalid  [`S1_NUMBER           +: 1        ];
    assign s1_axi_bready   = axi_bready  [`S1_NUMBER           +: 1        ];
    assign s1_axi_arid     = axi_arid    [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_araddr   = axi_araddr  [`S1_NUMBER*AXI_AW    +: 1*AXI_AW ];
    assign s1_axi_arlen    = axi_arlen   [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_arsize   = axi_arsize  [`S1_NUMBER*3         +: 1*3      ];
    assign s1_axi_arburst  = axi_arburst [`S1_NUMBER*2         +: 1*2      ];
    assign s1_axi_arlock   = axi_arlock  [`S1_NUMBER           +: 1        ];
    assign s1_axi_arcache  = axi_arcache [`S1_NUMBER*4         +: 1*4      ];
    assign s1_axi_arprot   = axi_arprot  [`S1_NUMBER*3         +: 1*3      ];
    assign s1_axi_arvalid  = axi_arvalid [`S1_NUMBER           +: 1        ];
    assign s1_axi_arready  = axi_arready [`S1_NUMBER           +: 1        ];
    assign s1_axi_rid      = axi_rid     [`S1_NUMBER*8         +: 1*8      ];
    assign s1_axi_rdata    = axi_rdata   [`S1_NUMBER*AXI_DW    +: 1*AXI_DW ];
    assign s1_axi_rresp    = axi_rresp   [`S1_NUMBER*2         +: 1*2      ];
    assign s1_axi_rlast    = axi_rlast   [`S1_NUMBER           +: 1        ];
    assign s1_axi_rvalid   = axi_rvalid  [`S1_NUMBER           +: 1        ];
    assign s1_axi_rready   = axi_rready  [`S1_NUMBER           +: 1        ];
    //**********************************************************************************************

    axi_interconnect #(
        .S_COUNT   (S_COUNT),
        .M_COUNT   (M_COUNT),
        .DATA_WIDTH(AXI_DW),
        .ADDR_WIDTH(AXI_AW),
        .ID_WIDTH  (AXI_ID_WIDTH)
    ) u_axi_interconnect (
        .clk          (i_axi_clk),
        .rst          (!i_axi_rst_n),
        //AXI slave interfaces
        .s_axi_awid   ({s1_axi_awid    , s0_axi_awid    }),//(axi_awid[0*8+:2*8]),
        .s_axi_awaddr ({s1_axi_awaddr  , s0_axi_awaddr  }),//(axi_awaddr[0*AXI_AW+:2*AXI_AW]),
        .s_axi_awlen  ({s1_axi_awlen   , s0_axi_awlen   }),//(axi_awlen[0*8+:2*8]),
        .s_axi_awsize ({s1_axi_awsize  , s0_axi_awsize  }),//(axi_awsize[0*3+:2*3]),
        .s_axi_awburst({s1_axi_awburst , s0_axi_awburst }),//(axi_awburst[0*2+:2*2]),
        .s_axi_awlock ({s1_axi_awlock  , s0_axi_awlock  }),//(axi_awlock[0*1+:2*1]),
        .s_axi_awcache({s1_axi_awcache , s0_axi_awcache }),//(axi_awcache[0*4+:2*4]),
        .s_axi_awprot ({s1_axi_awprot  , s0_axi_awprot  }),//(axi_awprot[0*3+:2*3]),
        .s_axi_awvalid({s1_axi_awvalid , s0_axi_awvalid }),//(axi_awvalid[0*1+:2*1]),
        .s_axi_awready({s1_axi_awready , s0_axi_awready }),//(axi_awready[0*1+:2*1]),
        .s_axi_wdata  ({s1_axi_wdata   , s0_axi_wdata   }),//(axi_wdata[0*AXI_DW+:2*AXI_DW]),
        .s_axi_wstrb  ({s1_axi_wstrb   , s0_axi_wstrb   }),//(axi_wstrb[0*AXI_SW+:2*AXI_SW]),
        .s_axi_wlast  ({s1_axi_wlast   , s0_axi_wlast   }),//(axi_wlast[0*1+:2*1]),
        .s_axi_wvalid ({s1_axi_wvalid  , s0_axi_wvalid  }),//(axi_wvalid[0*1+:2*1]),
        .s_axi_wready ({s1_axi_wready  , s0_axi_wready  }),//(axi_wready[0*1+:2*1]),
        .s_axi_bid    ({s1_axi_bid     , s0_axi_bid     }),//(axi_bid[0*8+:2*8]),
        .s_axi_bresp  ({s1_axi_bresp   , s0_axi_bresp   }),//(axi_bresp[0*2+:2*2]),
        .s_axi_bvalid ({s1_axi_bvalid  , s0_axi_bvalid  }),//(axi_bvalid[0*1+:2*1]),
        .s_axi_bready ({s1_axi_bready  , s0_axi_bready  }),//(axi_bready[0*1+:2*1]),
        .s_axi_arid   ({s1_axi_arid    , s0_axi_arid    }),//(axi_arid[0*8+:2*8]),
        .s_axi_araddr ({s1_axi_araddr  , s0_axi_araddr  }),//(axi_araddr[0*AXI_AW+:2*AXI_AW]),
        .s_axi_arlen  ({s1_axi_arlen   , s0_axi_arlen   }),//(axi_arlen[0*8+:2*8]),
        .s_axi_arsize ({s1_axi_arsize  , s0_axi_arsize  }),//(axi_arsize[0*3+:2*3]),
        .s_axi_arburst({s1_axi_arburst , s0_axi_arburst }),//(axi_arburst[0*2+:2*2]),
        .s_axi_arlock ({s1_axi_arlock  , s0_axi_arlock  }),//(axi_arlock[0*1+:2*1]),
        .s_axi_arcache({s1_axi_arcache , s0_axi_arcache }),//(axi_arcache[0*4+:2*4]),
        .s_axi_arprot ({s1_axi_arprot  , s0_axi_arprot  }),//(axi_arprot[0*3+:2*3]),
        .s_axi_arvalid({s1_axi_arvalid , s0_axi_arvalid }),//(axi_arvalid[0*1+:2*1]),
        .s_axi_arready({s1_axi_arready , s0_axi_arready }),//(axi_arready[0*1+:2*1]),
        .s_axi_rid    ({s1_axi_rid     , s0_axi_rid     }),//(axi_rid[0*8+:2*8]),
        .s_axi_rdata  ({s1_axi_rdata   , s0_axi_rdata   }),//(axi_rdata[0*AXI_DW+:2*AXI_DW]),
        .s_axi_rresp  ({s1_axi_rresp   , s0_axi_rresp   }),//(axi_rresp[0*2+:2*2]),
        .s_axi_rlast  ({s1_axi_rlast   , s0_axi_rlast   }),//(axi_rlast[0*1+:2*1]),
        .s_axi_rvalid ({s1_axi_rvalid  , s0_axi_rvalid  }),//(axi_rvalid[0*1+:2*1]),
        .s_axi_rready ({s1_axi_rready  , s0_axi_rready  }),//(axi_rready[0*1+:2*1]),
        //AXI master interfaces
        .m_axi_awid   (m0_axi_awid                       ),//(axi_awid[2*8+:1*8]),
        .m_axi_awaddr (m0_axi_awaddr                     ),//(axi_awaddr[2*AXI_AW+:1*AXI_AW]),
        .m_axi_awlen  (m0_axi_awlen                      ),//(axi_awlen[2*8+:1*8]),
        .m_axi_awsize (m0_axi_awsize                     ),//(axi_awsize[2*3+:1*3]),
        .m_axi_awburst(m0_axi_awburst                    ),//(axi_awburst[2*2+:1*2]),
        .m_axi_awlock (m0_axi_awlock                     ),//(axi_awlock[2*1+:1*1]),
        .m_axi_awcache(m0_axi_awcache                    ),//(axi_awcache[2*4+:1*4]),
        .m_axi_awprot (m0_axi_awprot                     ),//(axi_awprot[2*3+:1*3]),
        .m_axi_awvalid(m0_axi_awvalid                    ),//(axi_awvalid[2*1+:1*1]),
        .m_axi_awready(m0_axi_awready                    ),//(axi_awready[2*1+:1*1]),
        .m_axi_wdata  (m0_axi_wdata                      ),//(axi_wdata[2*AXI_DW+:1*AXI_DW]),
        .m_axi_wstrb  (m0_axi_wstrb                      ),//(axi_wstrb[2*AXI_SW+:1*AXI_SW]),
        .m_axi_wlast  (m0_axi_wlast                      ),//(axi_wlast[2*1+:1*1]),
        .m_axi_wvalid (m0_axi_wvalid                     ),//(axi_wvalid[2*1+:1*1]),
        .m_axi_wready (m0_axi_wready                     ),//(axi_wready[2*1+:1*1]),
        .m_axi_bid    (m0_axi_bid                        ),//(axi_bid[2*8+:1*8]),
        .m_axi_bresp  (m0_axi_bresp                      ),//(axi_bresp[2*2+:1*2]),
        .m_axi_bvalid (m0_axi_bvalid                     ),//(axi_bvalid[2*1+:1*1]),
        .m_axi_bready (m0_axi_bready                     ),//(axi_bready[2*1+:1*1]),
        .m_axi_arid   (m0_axi_arid                       ),//(axi_arid[2*8+:1*8]),
        .m_axi_araddr (m0_axi_araddr                     ),//(axi_araddr[2*AXI_AW+:1*AXI_AW]),
        .m_axi_arlen  (m0_axi_arlen                      ),//(axi_arlen[2*8+:1*8]),
        .m_axi_arsize (m0_axi_arsize                     ),//(axi_arsize[2*3+:1*3]),
        .m_axi_arburst(m0_axi_arburst                    ),//(axi_arburst[2*2+:1*2]),
        .m_axi_arlock (m0_axi_arlock                     ),//(axi_arlock[2*1+:1*1]),
        .m_axi_arcache(m0_axi_arcache                    ),//(axi_arcache[2*4+:1*4]),
        .m_axi_arprot (m0_axi_arprot                     ),//(axi_arprot[2*3+:1*3]),
        .m_axi_arvalid(m0_axi_arvalid                    ),//(axi_arvalid[2*1+:1*1]),
        .m_axi_arready(m0_axi_arready                    ),//(axi_arready[2*1+:1*1]),
        .m_axi_rid    (m0_axi_rid                        ),//(axi_rid[2*8+:1*8]),
        .m_axi_rdata  (m0_axi_rdata                      ),//(axi_rdata[2*AXI_DW+:1*AXI_DW]),
        .m_axi_rresp  (m0_axi_rresp                      ),//(axi_rresp[2*2+:1*2]),
        .m_axi_rlast  (m0_axi_rlast                      ),//(axi_rlast[2*1+:1*1]),
        .m_axi_rvalid (m0_axi_rvalid                     ),//(axi_rvalid[2*1+:1*1]),
        .m_axi_rready (m0_axi_rready                     )//(axi_rready[2*1+:1*1])
    );
    //**********************************************************************************************

    axi_master_gen #(
        .AXI_DW (AXI_DW),
        .AXI_AW (AXI_AW),
        .AXI_LEN(AXI_LEN)
    ) u_axi_master_gen (
        .clk          (i_axi_clk),
        .rstn         (i_axi_rst_n),
        .m_axi_awid   (s0_axi_awid),//(axi_awid[0*8+:1*8]),
        // .m_axi_awaddr                       (axi_awaddr [0*AXI_AW +: 1*AXI_AW]  ),
        .m_axi_awaddr (),
        .m_axi_awlen  (s0_axi_awlen                    ),//(axi_awlen[0*8+:1*8]),
        .m_axi_awsize (s0_axi_awsize                   ),//(axi_awsize[0*3+:1*3]),
        .m_axi_awburst(s0_axi_awburst                  ),//(axi_awburst[0*2+:1*2]),
        .m_axi_awlock (s0_axi_awlock                   ),//(axi_awlock[0*1+:1*1]),
        .m_axi_awcache(s0_axi_awcache                  ),//(axi_awcache[0*4+:1*4]),
        .m_axi_awprot (s0_axi_awprot                   ),//(axi_awprot[0*3+:1*3]),
        .m_axi_awvalid(s0_axi_awvalid                  ),//(axi_awvalid[0*1+:1*1]),
        .m_axi_awready(s0_axi_awready                  ),//(axi_awready[0*1+:1*1]),
        .m_axi_wdata  (s0_axi_wdata                    ),//(axi_wdata[0*AXI_DW+:1*AXI_DW]),
        .m_axi_wstrb  (s0_axi_wstrb                    ),//(axi_wstrb[0*AXI_SW+:1*AXI_SW]),
        .m_axi_wlast  (s0_axi_wlast                    ),//(axi_wlast[0*1+:1*1]),
        .m_axi_wvalid (s0_axi_wvalid                   ),//(axi_wvalid[0*1+:1*1]),
        .m_axi_wready (s0_axi_wready                   ),//(axi_wready[0*1+:1*1]),
        .m_axi_bid    (s0_axi_bid                      ),//(axi_bid[0*8+:1*8]),
        .m_axi_bresp  (s0_axi_bresp                    ),//(axi_bresp[0*2+:1*2]),
        .m_axi_bvalid (s0_axi_bvalid                   ),//(axi_bvalid[0*1+:1*1]),
        .m_axi_bready (s0_axi_bready                   ),//(axi_bready[0*1+:1*1]),
        .m_axi_arid   (s0_axi_arid                     ),//(axi_arid[0*8+:1*8]),
        // .m_axi_araddr                       (axi_araddr [0*AXI_AW +: 1*AXI_AW]  ),
        .m_axi_araddr (),
        .m_axi_arlen  (s0_axi_arlen                    ),//(axi_arlen[0*8+:1*8]),
        .m_axi_arsize (s0_axi_arsize                   ),//(axi_arsize[0*3+:1*3]),
        .m_axi_arburst(s0_axi_arburst                  ),//(axi_arburst[0*2+:1*2]),
        .m_axi_arlock (s0_axi_arlock                   ),//(axi_arlock[0*1+:1*1]),
        .m_axi_arcache(s0_axi_arcache                  ),//(axi_arcache[0*4+:1*4]),
        .m_axi_arprot (s0_axi_arprot                   ),//(axi_arprot[0*3+:1*3]),
        .m_axi_arvalid(s0_axi_arvalid                  ),//(axi_arvalid[0*1+:1*1]),
        .m_axi_arready(s0_axi_arready                  ),//(axi_arready[0*1+:1*1]),
        .m_axi_rid    (s0_axi_rid                      ),//(axi_rid[0*8+:1*8]),
        .m_axi_rdata  (s0_axi_rdata                    ),//(axi_rdata[0*AXI_DW+:1*AXI_DW]),
        .m_axi_rresp  (s0_axi_rresp                    ),//(axi_rresp[0*2+:1*2]),
        .m_axi_rlast  (s0_axi_rlast                    ),//(axi_rlast[0*1+:1*1]),
        .m_axi_rvalid (s0_axi_rvalid                   ),//(axi_rvalid[0*1+:1*1]),
        .m_axi_rready (s0_axi_rready                   )//(axi_rready[0*1+:1*1])
    );
    //**********************************************************************************************

    axi_ram #(
        .DATA_WIDTH     (AXI_DW),
        .ADDR_WIDTH     (AXI_AW),
        .ID_WIDTH       (AXI_ID_WIDTH),
        .PIPELINE_OUTPUT(0)
    ) u_axi_ram (
        .clk          (i_axi_clk),
        .rst          (!i_axi_rst_n),
        .s_axi_awid   (m0_axi_awid                          ),//(axi_awid[2*8+:1*8]),
        .s_axi_awaddr (m0_axi_awaddr                        ),//(axi_awaddr[2*AXI_AW+:1*AXI_AW]),
        .s_axi_awlen  (m0_axi_awlen                         ),//(axi_awlen[2*8+:1*8]),
        .s_axi_awsize (m0_axi_awsize                        ),//(axi_awsize[2*3+:1*3]),
        .s_axi_awburst(m0_axi_awburst                       ),//(axi_awburst[2*2+:1*2]),
        .s_axi_awlock (m0_axi_awlock                        ),//(axi_awlock[2*1+:1*1]),
        .s_axi_awcache(m0_axi_awcache                       ),//(axi_awcache[2*4+:1*4]),
        .s_axi_awprot (m0_axi_awprot                        ),//(axi_awprot[2*3+:1*3]),
        .s_axi_awvalid(m0_axi_awvalid                       ),//(axi_awvalid[2*1+:1*1]),
        .s_axi_awready(m0_axi_awready                       ),//(axi_awready[2*1+:1*1]),
        .s_axi_wdata  (m0_axi_wdata                         ),//(axi_wdata[2*AXI_DW+:1*AXI_DW]),
        .s_axi_wstrb  (m0_axi_wstrb                         ),//(axi_wstrb[2*AXI_SW+:1*AXI_SW]),
        .s_axi_wlast  (m0_axi_wlast                         ),//(axi_wlast[2*1+:1*1]),
        .s_axi_wvalid (m0_axi_wvalid                        ),//(axi_wvalid[2*1+:1*1]),
        .s_axi_wready (m0_axi_wready                        ),//(axi_wready[2*1+:1*1]),
        .s_axi_bid    (m0_axi_bid                           ),//(axi_bid[2*8+:1*8]),
        .s_axi_bresp  (m0_axi_bresp                         ),//(axi_bresp[2*2+:1*2]),
        .s_axi_bvalid (m0_axi_bvalid                        ),//(axi_bvalid[2*1+:1*1]),
        .s_axi_bready (m0_axi_bready                        ),//(axi_bready[2*1+:1*1]),
        .s_axi_arid   (m0_axi_arid                          ),//(axi_arid[2*8+:1*8]),
        .s_axi_araddr (m0_axi_araddr                        ),//(axi_araddr[2*AXI_AW+:1*AXI_AW]),
        .s_axi_arlen  (m0_axi_arlen                         ),//(axi_arlen[2*8+:1*8]),
        .s_axi_arsize (m0_axi_arsize                        ),//(axi_arsize[2*3+:1*3]),
        .s_axi_arburst(m0_axi_arburst                       ),//(axi_arburst[2*2+:1*2]),
        .s_axi_arlock (m0_axi_arlock                        ),//(axi_arlock[2*1+:1*1]),
        .s_axi_arcache(m0_axi_arcache                       ),//(axi_arcache[2*4+:1*4]),
        .s_axi_arprot (m0_axi_arprot                        ),//(axi_arprot[2*3+:1*3]),
        .s_axi_arvalid(m0_axi_arvalid                       ),//(axi_arvalid[2*1+:1*1]),
        .s_axi_arready(m0_axi_arready                       ),//(axi_arready[2*1+:1*1]),
        .s_axi_rid    (m0_axi_rid                           ),//(axi_rid[2*8+:1*8]),
        .s_axi_rdata  (m0_axi_rdata                         ),//(axi_rdata[2*AXI_DW+:1*AXI_DW]),
        .s_axi_rresp  (m0_axi_rresp                         ),//(axi_rresp[2*2+:1*2]),
        .s_axi_rlast  (m0_axi_rlast                         ),//(axi_rlast[2*1+:1*1]),
        .s_axi_rvalid (m0_axi_rvalid                        ),//(axi_rvalid[2*1+:1*1]),
        .s_axi_rready (m0_axi_rready                        )//(axi_rready[2*1+:1*1])
    );
    //**********************************************************************************************
    

    //**********************************************************************************************
    dvp_axi #(
        .DVP_DATA_WIDTH     (16),
        .DVP_DATA_FRAME_SIZE(IMAGE_WIDTH * IMAGE_HEIGHT * 2),
        .AXI_DW             (AXI_DW),
        .AXI_AW             (AXI_AW),
        .AXI_LEN            (AXI_LEN)             //minimum=1; maximum
    ) u_dvp_axi_scaler (
        //DVP Signals
        //****dvp_in
        .dvp_wr_rst       (o_scaler_wr_rst),
        .dvp_wr_clk       (i_Sys_clk),
        .dvp_wr_vs        (o_scaler_wr_req),
        .dvp_wr_hs        (o_scaler_wr_req),
        .dvp_wr_data      (o_scaler_wr_data),
        .dvp_wr_axi_addr  (o_scaler_wr_addr),
        //****dvp_out
        .dvp_rd_rst       (o_scaler_rd_rst),
        .dvp_rd_clk       (i_Sys_clk),
        .dvp_rd_vs        (1'b1),
        .dvp_rd_hs        (o_scaler_rd_req),
        .dvp_rd_data_valid(i_scaler_rd_valid),
        .dvp_rd_data      (i_scaler_rd_data),
        .dvp_rd_axi_addr  (o_scaler_rd_addr),
        //Master AXI4 Bus clock and reset
        .clk_axi          (i_axi_clk),
        .rst_axi          (~i_axi_rst_n),
        //Master AXI4 Write Bus Interface
        //***********写地址通道
        .m_axi_awid       (s1_axi_awid                    ),//(axi_awid[1*8+:1*8]),
        .m_axi_awaddr     (s1_axi_awaddr                  ),//(axi_awaddr[1*AXI_AW+:1*AXI_AW]),
        .m_axi_awlen      (s1_axi_awlen                   ),//(axi_awlen[1*8+:1*8]),
        .m_axi_awsize     (s1_axi_awsize                  ),//(axi_awsize[1*3+:1*3]),
        .m_axi_awburst    (s1_axi_awburst                 ),//(axi_awburst[1*2+:1*2]),
        .m_axi_awlock     (s1_axi_awlock                  ),//(axi_awlock[1*1+:1*1]),
        .m_axi_awcache    (s1_axi_awcache                 ),//(axi_awcache[1*4+:1*4]),
        .m_axi_awprot     (s1_axi_awprot                  ),//(axi_awprot[1*3+:1*3]),
        .m_axi_awvalid    (s1_axi_awvalid                 ),//(axi_awvalid[1*1+:1*1]),
        .m_axi_awready    (s1_axi_awready                 ),//(axi_awready[1*1+:1*1]),
        //***********写数据通道
        .m_axi_wdata      (s1_axi_wdata                   ),//(axi_wdata[1*AXI_DW+:1*AXI_DW]),
        .m_axi_wstrb      (s1_axi_wstrb                   ),//(axi_wstrb[1*AXI_SW+:1*AXI_SW]),
        .m_axi_wlast      (s1_axi_wlast                   ),//(axi_wlast[1*1+:1*1]),
        .m_axi_wvalid     (s1_axi_wvalid                  ),//(axi_wvalid[1*1+:1*1]),
        .m_axi_wready     (s1_axi_wready                  ),//(axi_wready[1*1+:1*1]),
        //***********写回应通道
        .m_axi_bid        (s1_axi_bid                     ),//(axi_bid[1*8+:1*8]),
        .m_axi_bresp      (s1_axi_bresp                   ),//(axi_bresp[1*2+:1*2]),
        .m_axi_bvalid     (s1_axi_bvalid                  ),//(axi_bvalid[1*1+:1*1]),
        .m_axi_bready     (s1_axi_bready                  ),//(axi_bready[1*1+:1*1]),
        //**********读地址通道
        .m_axi_arid       (s1_axi_arid                    ),//(axi_arid[1*8+:1*8]),
        .m_axi_araddr     (s1_axi_araddr                  ),//(axi_araddr[1*AXI_AW+:1*AXI_AW]),
        .m_axi_arlen      (s1_axi_arlen                   ),//(axi_arlen[1*8+:1*8]),
        .m_axi_arsize     (s1_axi_arsize                  ),//(axi_arsize[1*3+:1*3]),
        .m_axi_arburst    (s1_axi_arburst                 ),//(axi_arburst[1*2+:1*2]),
        .m_axi_arlock     (s1_axi_arlock                  ),//(axi_arlock[1*1+:1*1]),
        .m_axi_arcache    (s1_axi_arcache                 ),//(axi_arcache[1*4+:1*4]),
        .m_axi_arprot     (s1_axi_arprot                  ),//(axi_arprot[1*3+:1*3]),
        .m_axi_arvalid    (s1_axi_arvalid                 ),//(axi_arvalid[1*1+:1*1]),
        .m_axi_arready    (s1_axi_arready                 ),//(axi_arready[1*1+:1*1]),
        //**********读数据通道
        .m_axi_rid        (s1_axi_rid                     ),//(axi_rid[1*8+:1*8]),
        .m_axi_rdata      (s1_axi_rdata                   ),//(axi_rdata[1*AXI_DW+:1*AXI_DW]),
        .m_axi_rresp      (s1_axi_rresp                   ),//(axi_rresp[1*2+:1*2]),
        .m_axi_rlast      (s1_axi_rlast                   ),//(axi_rlast[1*1+:1*1]),
        .m_axi_rvalid     (s1_axi_rvalid                  ),//(axi_rvalid[1*1+:1*1]),
        .m_axi_rready     (s1_axi_rready                  )//(axi_rready[1*1+:1*1])
    );
    //**********************************************************************************************
    assign o_scaler_wr_rst = user_wr_rst;
    assign o_scaler_wr_req = user_wr_req;
    assign o_scaler_wr_data = user_wr_data;
    assign o_scaler_wr_addr = user_wr_addr;
    assign o_scaler_rd_rst = user_rd_rst;
    assign o_scaler_rd_req = user_rd_req;
    assign o_scaler_rd_addr = user_rd_addr;
    assign user_rd_data = i_scaler_rd_data;
    assign user_rd_valid = i_scaler_rd_valid;
    //**********************************************************************************************
endmodule
