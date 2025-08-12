//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
//Date        : Tue Aug 12 18:57:54 2025
//Host        : beelink-ser6 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (DDR3_addr,
    DDR3_ba,
    DDR3_cas_n,
    DDR3_ck_n,
    DDR3_ck_p,
    DDR3_cke,
    DDR3_cs_n,
    DDR3_dm,
    DDR3_dq,
    DDR3_dqs_n,
    DDR3_dqs_p,
    DDR3_odt,
    DDR3_ras_n,
    DDR3_reset_n,
    DDR3_we_n,
    S00_AXI_0_araddr,
    S00_AXI_0_arburst,
    S00_AXI_0_arcache,
    S00_AXI_0_arid,
    S00_AXI_0_arlen,
    S00_AXI_0_arlock,
    S00_AXI_0_arprot,
    S00_AXI_0_arqos,
    S00_AXI_0_arready,
    S00_AXI_0_arregion,
    S00_AXI_0_arsize,
    S00_AXI_0_arvalid,
    S00_AXI_0_awaddr,
    S00_AXI_0_awburst,
    S00_AXI_0_awcache,
    S00_AXI_0_awid,
    S00_AXI_0_awlen,
    S00_AXI_0_awlock,
    S00_AXI_0_awprot,
    S00_AXI_0_awqos,
    S00_AXI_0_awready,
    S00_AXI_0_awregion,
    S00_AXI_0_awsize,
    S00_AXI_0_awvalid,
    S00_AXI_0_bid,
    S00_AXI_0_bready,
    S00_AXI_0_bresp,
    S00_AXI_0_bvalid,
    S00_AXI_0_rdata,
    S00_AXI_0_rid,
    S00_AXI_0_rlast,
    S00_AXI_0_rready,
    S00_AXI_0_rresp,
    S00_AXI_0_rvalid,
    S00_AXI_0_wdata,
    S00_AXI_0_wlast,
    S00_AXI_0_wready,
    S00_AXI_0_wstrb,
    S00_AXI_0_wvalid,
    S01_AXI_0_araddr,
    S01_AXI_0_arburst,
    S01_AXI_0_arcache,
    S01_AXI_0_arid,
    S01_AXI_0_arlen,
    S01_AXI_0_arlock,
    S01_AXI_0_arprot,
    S01_AXI_0_arqos,
    S01_AXI_0_arready,
    S01_AXI_0_arregion,
    S01_AXI_0_arsize,
    S01_AXI_0_arvalid,
    S01_AXI_0_awaddr,
    S01_AXI_0_awburst,
    S01_AXI_0_awcache,
    S01_AXI_0_awid,
    S01_AXI_0_awlen,
    S01_AXI_0_awlock,
    S01_AXI_0_awprot,
    S01_AXI_0_awqos,
    S01_AXI_0_awready,
    S01_AXI_0_awregion,
    S01_AXI_0_awsize,
    S01_AXI_0_awvalid,
    S01_AXI_0_bid,
    S01_AXI_0_bready,
    S01_AXI_0_bresp,
    S01_AXI_0_bvalid,
    S01_AXI_0_rdata,
    S01_AXI_0_rid,
    S01_AXI_0_rlast,
    S01_AXI_0_rready,
    S01_AXI_0_rresp,
    S01_AXI_0_rvalid,
    S01_AXI_0_wdata,
    S01_AXI_0_wlast,
    S01_AXI_0_wready,
    S01_AXI_0_wstrb,
    S01_AXI_0_wvalid,
    S02_AXI_0_araddr,
    S02_AXI_0_arburst,
    S02_AXI_0_arcache,
    S02_AXI_0_arid,
    S02_AXI_0_arlen,
    S02_AXI_0_arlock,
    S02_AXI_0_arprot,
    S02_AXI_0_arqos,
    S02_AXI_0_arready,
    S02_AXI_0_arregion,
    S02_AXI_0_arsize,
    S02_AXI_0_arvalid,
    S02_AXI_0_awaddr,
    S02_AXI_0_awburst,
    S02_AXI_0_awcache,
    S02_AXI_0_awid,
    S02_AXI_0_awlen,
    S02_AXI_0_awlock,
    S02_AXI_0_awprot,
    S02_AXI_0_awqos,
    S02_AXI_0_awready,
    S02_AXI_0_awregion,
    S02_AXI_0_awsize,
    S02_AXI_0_awvalid,
    S02_AXI_0_bid,
    S02_AXI_0_bready,
    S02_AXI_0_bresp,
    S02_AXI_0_bvalid,
    S02_AXI_0_rdata,
    S02_AXI_0_rid,
    S02_AXI_0_rlast,
    S02_AXI_0_rready,
    S02_AXI_0_rresp,
    S02_AXI_0_rvalid,
    S02_AXI_0_wdata,
    S02_AXI_0_wlast,
    S02_AXI_0_wready,
    S02_AXI_0_wstrb,
    S02_AXI_0_wvalid,
    S03_AXI_0_araddr,
    S03_AXI_0_arburst,
    S03_AXI_0_arcache,
    S03_AXI_0_arid,
    S03_AXI_0_arlen,
    S03_AXI_0_arlock,
    S03_AXI_0_arprot,
    S03_AXI_0_arqos,
    S03_AXI_0_arready,
    S03_AXI_0_arregion,
    S03_AXI_0_arsize,
    S03_AXI_0_arvalid,
    S03_AXI_0_awaddr,
    S03_AXI_0_awburst,
    S03_AXI_0_awcache,
    S03_AXI_0_awid,
    S03_AXI_0_awlen,
    S03_AXI_0_awlock,
    S03_AXI_0_awprot,
    S03_AXI_0_awqos,
    S03_AXI_0_awready,
    S03_AXI_0_awregion,
    S03_AXI_0_awsize,
    S03_AXI_0_awvalid,
    S03_AXI_0_bid,
    S03_AXI_0_bready,
    S03_AXI_0_bresp,
    S03_AXI_0_bvalid,
    S03_AXI_0_rdata,
    S03_AXI_0_rid,
    S03_AXI_0_rlast,
    S03_AXI_0_rready,
    S03_AXI_0_rresp,
    S03_AXI_0_rvalid,
    S03_AXI_0_wdata,
    S03_AXI_0_wlast,
    S03_AXI_0_wready,
    S03_AXI_0_wstrb,
    S03_AXI_0_wvalid,
    ddr_clk,
    ddr_init_done,
    ddr_sync_rst,
    sys_clk_i_0,
    sys_rst_0);
  output [14:0]DDR3_addr;
  output [2:0]DDR3_ba;
  output DDR3_cas_n;
  output [0:0]DDR3_ck_n;
  output [0:0]DDR3_ck_p;
  output [0:0]DDR3_cke;
  output [0:0]DDR3_cs_n;
  output [3:0]DDR3_dm;
  inout [31:0]DDR3_dq;
  inout [3:0]DDR3_dqs_n;
  inout [3:0]DDR3_dqs_p;
  output [0:0]DDR3_odt;
  output DDR3_ras_n;
  output DDR3_reset_n;
  output DDR3_we_n;
  input [31:0]S00_AXI_0_araddr;
  input [1:0]S00_AXI_0_arburst;
  input [3:0]S00_AXI_0_arcache;
  input [7:0]S00_AXI_0_arid;
  input [7:0]S00_AXI_0_arlen;
  input [0:0]S00_AXI_0_arlock;
  input [2:0]S00_AXI_0_arprot;
  input [3:0]S00_AXI_0_arqos;
  output S00_AXI_0_arready;
  input [3:0]S00_AXI_0_arregion;
  input [2:0]S00_AXI_0_arsize;
  input S00_AXI_0_arvalid;
  input [31:0]S00_AXI_0_awaddr;
  input [1:0]S00_AXI_0_awburst;
  input [3:0]S00_AXI_0_awcache;
  input [7:0]S00_AXI_0_awid;
  input [7:0]S00_AXI_0_awlen;
  input [0:0]S00_AXI_0_awlock;
  input [2:0]S00_AXI_0_awprot;
  input [3:0]S00_AXI_0_awqos;
  output S00_AXI_0_awready;
  input [3:0]S00_AXI_0_awregion;
  input [2:0]S00_AXI_0_awsize;
  input S00_AXI_0_awvalid;
  output [7:0]S00_AXI_0_bid;
  input S00_AXI_0_bready;
  output [1:0]S00_AXI_0_bresp;
  output S00_AXI_0_bvalid;
  output [255:0]S00_AXI_0_rdata;
  output [7:0]S00_AXI_0_rid;
  output S00_AXI_0_rlast;
  input S00_AXI_0_rready;
  output [1:0]S00_AXI_0_rresp;
  output S00_AXI_0_rvalid;
  input [255:0]S00_AXI_0_wdata;
  input S00_AXI_0_wlast;
  output S00_AXI_0_wready;
  input [31:0]S00_AXI_0_wstrb;
  input S00_AXI_0_wvalid;
  input [31:0]S01_AXI_0_araddr;
  input [1:0]S01_AXI_0_arburst;
  input [3:0]S01_AXI_0_arcache;
  input [7:0]S01_AXI_0_arid;
  input [7:0]S01_AXI_0_arlen;
  input [0:0]S01_AXI_0_arlock;
  input [2:0]S01_AXI_0_arprot;
  input [3:0]S01_AXI_0_arqos;
  output S01_AXI_0_arready;
  input [3:0]S01_AXI_0_arregion;
  input [2:0]S01_AXI_0_arsize;
  input S01_AXI_0_arvalid;
  input [31:0]S01_AXI_0_awaddr;
  input [1:0]S01_AXI_0_awburst;
  input [3:0]S01_AXI_0_awcache;
  input [7:0]S01_AXI_0_awid;
  input [7:0]S01_AXI_0_awlen;
  input [0:0]S01_AXI_0_awlock;
  input [2:0]S01_AXI_0_awprot;
  input [3:0]S01_AXI_0_awqos;
  output S01_AXI_0_awready;
  input [3:0]S01_AXI_0_awregion;
  input [2:0]S01_AXI_0_awsize;
  input S01_AXI_0_awvalid;
  output [7:0]S01_AXI_0_bid;
  input S01_AXI_0_bready;
  output [1:0]S01_AXI_0_bresp;
  output S01_AXI_0_bvalid;
  output [255:0]S01_AXI_0_rdata;
  output [7:0]S01_AXI_0_rid;
  output S01_AXI_0_rlast;
  input S01_AXI_0_rready;
  output [1:0]S01_AXI_0_rresp;
  output S01_AXI_0_rvalid;
  input [255:0]S01_AXI_0_wdata;
  input S01_AXI_0_wlast;
  output S01_AXI_0_wready;
  input [31:0]S01_AXI_0_wstrb;
  input S01_AXI_0_wvalid;
  input [31:0]S02_AXI_0_araddr;
  input [1:0]S02_AXI_0_arburst;
  input [3:0]S02_AXI_0_arcache;
  input [7:0]S02_AXI_0_arid;
  input [7:0]S02_AXI_0_arlen;
  input [0:0]S02_AXI_0_arlock;
  input [2:0]S02_AXI_0_arprot;
  input [3:0]S02_AXI_0_arqos;
  output S02_AXI_0_arready;
  input [3:0]S02_AXI_0_arregion;
  input [2:0]S02_AXI_0_arsize;
  input S02_AXI_0_arvalid;
  input [31:0]S02_AXI_0_awaddr;
  input [1:0]S02_AXI_0_awburst;
  input [3:0]S02_AXI_0_awcache;
  input [7:0]S02_AXI_0_awid;
  input [7:0]S02_AXI_0_awlen;
  input [0:0]S02_AXI_0_awlock;
  input [2:0]S02_AXI_0_awprot;
  input [3:0]S02_AXI_0_awqos;
  output S02_AXI_0_awready;
  input [3:0]S02_AXI_0_awregion;
  input [2:0]S02_AXI_0_awsize;
  input S02_AXI_0_awvalid;
  output [7:0]S02_AXI_0_bid;
  input S02_AXI_0_bready;
  output [1:0]S02_AXI_0_bresp;
  output S02_AXI_0_bvalid;
  output [255:0]S02_AXI_0_rdata;
  output [7:0]S02_AXI_0_rid;
  output S02_AXI_0_rlast;
  input S02_AXI_0_rready;
  output [1:0]S02_AXI_0_rresp;
  output S02_AXI_0_rvalid;
  input [255:0]S02_AXI_0_wdata;
  input S02_AXI_0_wlast;
  output S02_AXI_0_wready;
  input [31:0]S02_AXI_0_wstrb;
  input S02_AXI_0_wvalid;
  input [31:0]S03_AXI_0_araddr;
  input [1:0]S03_AXI_0_arburst;
  input [3:0]S03_AXI_0_arcache;
  input [7:0]S03_AXI_0_arid;
  input [7:0]S03_AXI_0_arlen;
  input [0:0]S03_AXI_0_arlock;
  input [2:0]S03_AXI_0_arprot;
  input [3:0]S03_AXI_0_arqos;
  output S03_AXI_0_arready;
  input [3:0]S03_AXI_0_arregion;
  input [2:0]S03_AXI_0_arsize;
  input S03_AXI_0_arvalid;
  input [31:0]S03_AXI_0_awaddr;
  input [1:0]S03_AXI_0_awburst;
  input [3:0]S03_AXI_0_awcache;
  input [7:0]S03_AXI_0_awid;
  input [7:0]S03_AXI_0_awlen;
  input [0:0]S03_AXI_0_awlock;
  input [2:0]S03_AXI_0_awprot;
  input [3:0]S03_AXI_0_awqos;
  output S03_AXI_0_awready;
  input [3:0]S03_AXI_0_awregion;
  input [2:0]S03_AXI_0_awsize;
  input S03_AXI_0_awvalid;
  output [7:0]S03_AXI_0_bid;
  input S03_AXI_0_bready;
  output [1:0]S03_AXI_0_bresp;
  output S03_AXI_0_bvalid;
  output [255:0]S03_AXI_0_rdata;
  output [7:0]S03_AXI_0_rid;
  output S03_AXI_0_rlast;
  input S03_AXI_0_rready;
  output [1:0]S03_AXI_0_rresp;
  output S03_AXI_0_rvalid;
  input [255:0]S03_AXI_0_wdata;
  input S03_AXI_0_wlast;
  output S03_AXI_0_wready;
  input [31:0]S03_AXI_0_wstrb;
  input S03_AXI_0_wvalid;
  output ddr_clk;
  output ddr_init_done;
  output ddr_sync_rst;
  input sys_clk_i_0;
  input sys_rst_0;

  wire [14:0]DDR3_addr;
  wire [2:0]DDR3_ba;
  wire DDR3_cas_n;
  wire [0:0]DDR3_ck_n;
  wire [0:0]DDR3_ck_p;
  wire [0:0]DDR3_cke;
  wire [0:0]DDR3_cs_n;
  wire [3:0]DDR3_dm;
  wire [31:0]DDR3_dq;
  wire [3:0]DDR3_dqs_n;
  wire [3:0]DDR3_dqs_p;
  wire [0:0]DDR3_odt;
  wire DDR3_ras_n;
  wire DDR3_reset_n;
  wire DDR3_we_n;
  wire [31:0]S00_AXI_0_araddr;
  wire [1:0]S00_AXI_0_arburst;
  wire [3:0]S00_AXI_0_arcache;
  wire [7:0]S00_AXI_0_arid;
  wire [7:0]S00_AXI_0_arlen;
  wire [0:0]S00_AXI_0_arlock;
  wire [2:0]S00_AXI_0_arprot;
  wire [3:0]S00_AXI_0_arqos;
  wire S00_AXI_0_arready;
  wire [3:0]S00_AXI_0_arregion;
  wire [2:0]S00_AXI_0_arsize;
  wire S00_AXI_0_arvalid;
  wire [31:0]S00_AXI_0_awaddr;
  wire [1:0]S00_AXI_0_awburst;
  wire [3:0]S00_AXI_0_awcache;
  wire [7:0]S00_AXI_0_awid;
  wire [7:0]S00_AXI_0_awlen;
  wire [0:0]S00_AXI_0_awlock;
  wire [2:0]S00_AXI_0_awprot;
  wire [3:0]S00_AXI_0_awqos;
  wire S00_AXI_0_awready;
  wire [3:0]S00_AXI_0_awregion;
  wire [2:0]S00_AXI_0_awsize;
  wire S00_AXI_0_awvalid;
  wire [7:0]S00_AXI_0_bid;
  wire S00_AXI_0_bready;
  wire [1:0]S00_AXI_0_bresp;
  wire S00_AXI_0_bvalid;
  wire [255:0]S00_AXI_0_rdata;
  wire [7:0]S00_AXI_0_rid;
  wire S00_AXI_0_rlast;
  wire S00_AXI_0_rready;
  wire [1:0]S00_AXI_0_rresp;
  wire S00_AXI_0_rvalid;
  wire [255:0]S00_AXI_0_wdata;
  wire S00_AXI_0_wlast;
  wire S00_AXI_0_wready;
  wire [31:0]S00_AXI_0_wstrb;
  wire S00_AXI_0_wvalid;
  wire [31:0]S01_AXI_0_araddr;
  wire [1:0]S01_AXI_0_arburst;
  wire [3:0]S01_AXI_0_arcache;
  wire [7:0]S01_AXI_0_arid;
  wire [7:0]S01_AXI_0_arlen;
  wire [0:0]S01_AXI_0_arlock;
  wire [2:0]S01_AXI_0_arprot;
  wire [3:0]S01_AXI_0_arqos;
  wire S01_AXI_0_arready;
  wire [3:0]S01_AXI_0_arregion;
  wire [2:0]S01_AXI_0_arsize;
  wire S01_AXI_0_arvalid;
  wire [31:0]S01_AXI_0_awaddr;
  wire [1:0]S01_AXI_0_awburst;
  wire [3:0]S01_AXI_0_awcache;
  wire [7:0]S01_AXI_0_awid;
  wire [7:0]S01_AXI_0_awlen;
  wire [0:0]S01_AXI_0_awlock;
  wire [2:0]S01_AXI_0_awprot;
  wire [3:0]S01_AXI_0_awqos;
  wire S01_AXI_0_awready;
  wire [3:0]S01_AXI_0_awregion;
  wire [2:0]S01_AXI_0_awsize;
  wire S01_AXI_0_awvalid;
  wire [7:0]S01_AXI_0_bid;
  wire S01_AXI_0_bready;
  wire [1:0]S01_AXI_0_bresp;
  wire S01_AXI_0_bvalid;
  wire [255:0]S01_AXI_0_rdata;
  wire [7:0]S01_AXI_0_rid;
  wire S01_AXI_0_rlast;
  wire S01_AXI_0_rready;
  wire [1:0]S01_AXI_0_rresp;
  wire S01_AXI_0_rvalid;
  wire [255:0]S01_AXI_0_wdata;
  wire S01_AXI_0_wlast;
  wire S01_AXI_0_wready;
  wire [31:0]S01_AXI_0_wstrb;
  wire S01_AXI_0_wvalid;
  wire [31:0]S02_AXI_0_araddr;
  wire [1:0]S02_AXI_0_arburst;
  wire [3:0]S02_AXI_0_arcache;
  wire [7:0]S02_AXI_0_arid;
  wire [7:0]S02_AXI_0_arlen;
  wire [0:0]S02_AXI_0_arlock;
  wire [2:0]S02_AXI_0_arprot;
  wire [3:0]S02_AXI_0_arqos;
  wire S02_AXI_0_arready;
  wire [3:0]S02_AXI_0_arregion;
  wire [2:0]S02_AXI_0_arsize;
  wire S02_AXI_0_arvalid;
  wire [31:0]S02_AXI_0_awaddr;
  wire [1:0]S02_AXI_0_awburst;
  wire [3:0]S02_AXI_0_awcache;
  wire [7:0]S02_AXI_0_awid;
  wire [7:0]S02_AXI_0_awlen;
  wire [0:0]S02_AXI_0_awlock;
  wire [2:0]S02_AXI_0_awprot;
  wire [3:0]S02_AXI_0_awqos;
  wire S02_AXI_0_awready;
  wire [3:0]S02_AXI_0_awregion;
  wire [2:0]S02_AXI_0_awsize;
  wire S02_AXI_0_awvalid;
  wire [7:0]S02_AXI_0_bid;
  wire S02_AXI_0_bready;
  wire [1:0]S02_AXI_0_bresp;
  wire S02_AXI_0_bvalid;
  wire [255:0]S02_AXI_0_rdata;
  wire [7:0]S02_AXI_0_rid;
  wire S02_AXI_0_rlast;
  wire S02_AXI_0_rready;
  wire [1:0]S02_AXI_0_rresp;
  wire S02_AXI_0_rvalid;
  wire [255:0]S02_AXI_0_wdata;
  wire S02_AXI_0_wlast;
  wire S02_AXI_0_wready;
  wire [31:0]S02_AXI_0_wstrb;
  wire S02_AXI_0_wvalid;
  wire [31:0]S03_AXI_0_araddr;
  wire [1:0]S03_AXI_0_arburst;
  wire [3:0]S03_AXI_0_arcache;
  wire [7:0]S03_AXI_0_arid;
  wire [7:0]S03_AXI_0_arlen;
  wire [0:0]S03_AXI_0_arlock;
  wire [2:0]S03_AXI_0_arprot;
  wire [3:0]S03_AXI_0_arqos;
  wire S03_AXI_0_arready;
  wire [3:0]S03_AXI_0_arregion;
  wire [2:0]S03_AXI_0_arsize;
  wire S03_AXI_0_arvalid;
  wire [31:0]S03_AXI_0_awaddr;
  wire [1:0]S03_AXI_0_awburst;
  wire [3:0]S03_AXI_0_awcache;
  wire [7:0]S03_AXI_0_awid;
  wire [7:0]S03_AXI_0_awlen;
  wire [0:0]S03_AXI_0_awlock;
  wire [2:0]S03_AXI_0_awprot;
  wire [3:0]S03_AXI_0_awqos;
  wire S03_AXI_0_awready;
  wire [3:0]S03_AXI_0_awregion;
  wire [2:0]S03_AXI_0_awsize;
  wire S03_AXI_0_awvalid;
  wire [7:0]S03_AXI_0_bid;
  wire S03_AXI_0_bready;
  wire [1:0]S03_AXI_0_bresp;
  wire S03_AXI_0_bvalid;
  wire [255:0]S03_AXI_0_rdata;
  wire [7:0]S03_AXI_0_rid;
  wire S03_AXI_0_rlast;
  wire S03_AXI_0_rready;
  wire [1:0]S03_AXI_0_rresp;
  wire S03_AXI_0_rvalid;
  wire [255:0]S03_AXI_0_wdata;
  wire S03_AXI_0_wlast;
  wire S03_AXI_0_wready;
  wire [31:0]S03_AXI_0_wstrb;
  wire S03_AXI_0_wvalid;
  wire ddr_clk;
  wire ddr_init_done;
  wire ddr_sync_rst;
  wire sys_clk_i_0;
  wire sys_rst_0;

  design_1 design_1_i
       (.DDR3_addr(DDR3_addr),
        .DDR3_ba(DDR3_ba),
        .DDR3_cas_n(DDR3_cas_n),
        .DDR3_ck_n(DDR3_ck_n),
        .DDR3_ck_p(DDR3_ck_p),
        .DDR3_cke(DDR3_cke),
        .DDR3_cs_n(DDR3_cs_n),
        .DDR3_dm(DDR3_dm),
        .DDR3_dq(DDR3_dq),
        .DDR3_dqs_n(DDR3_dqs_n),
        .DDR3_dqs_p(DDR3_dqs_p),
        .DDR3_odt(DDR3_odt),
        .DDR3_ras_n(DDR3_ras_n),
        .DDR3_reset_n(DDR3_reset_n),
        .DDR3_we_n(DDR3_we_n),
        .S00_AXI_0_araddr(S00_AXI_0_araddr),
        .S00_AXI_0_arburst(S00_AXI_0_arburst),
        .S00_AXI_0_arcache(S00_AXI_0_arcache),
        .S00_AXI_0_arid(S00_AXI_0_arid),
        .S00_AXI_0_arlen(S00_AXI_0_arlen),
        .S00_AXI_0_arlock(S00_AXI_0_arlock),
        .S00_AXI_0_arprot(S00_AXI_0_arprot),
        .S00_AXI_0_arqos(S00_AXI_0_arqos),
        .S00_AXI_0_arready(S00_AXI_0_arready),
        .S00_AXI_0_arregion(S00_AXI_0_arregion),
        .S00_AXI_0_arsize(S00_AXI_0_arsize),
        .S00_AXI_0_arvalid(S00_AXI_0_arvalid),
        .S00_AXI_0_awaddr(S00_AXI_0_awaddr),
        .S00_AXI_0_awburst(S00_AXI_0_awburst),
        .S00_AXI_0_awcache(S00_AXI_0_awcache),
        .S00_AXI_0_awid(S00_AXI_0_awid),
        .S00_AXI_0_awlen(S00_AXI_0_awlen),
        .S00_AXI_0_awlock(S00_AXI_0_awlock),
        .S00_AXI_0_awprot(S00_AXI_0_awprot),
        .S00_AXI_0_awqos(S00_AXI_0_awqos),
        .S00_AXI_0_awready(S00_AXI_0_awready),
        .S00_AXI_0_awregion(S00_AXI_0_awregion),
        .S00_AXI_0_awsize(S00_AXI_0_awsize),
        .S00_AXI_0_awvalid(S00_AXI_0_awvalid),
        .S00_AXI_0_bid(S00_AXI_0_bid),
        .S00_AXI_0_bready(S00_AXI_0_bready),
        .S00_AXI_0_bresp(S00_AXI_0_bresp),
        .S00_AXI_0_bvalid(S00_AXI_0_bvalid),
        .S00_AXI_0_rdata(S00_AXI_0_rdata),
        .S00_AXI_0_rid(S00_AXI_0_rid),
        .S00_AXI_0_rlast(S00_AXI_0_rlast),
        .S00_AXI_0_rready(S00_AXI_0_rready),
        .S00_AXI_0_rresp(S00_AXI_0_rresp),
        .S00_AXI_0_rvalid(S00_AXI_0_rvalid),
        .S00_AXI_0_wdata(S00_AXI_0_wdata),
        .S00_AXI_0_wlast(S00_AXI_0_wlast),
        .S00_AXI_0_wready(S00_AXI_0_wready),
        .S00_AXI_0_wstrb(S00_AXI_0_wstrb),
        .S00_AXI_0_wvalid(S00_AXI_0_wvalid),
        .S01_AXI_0_araddr(S01_AXI_0_araddr),
        .S01_AXI_0_arburst(S01_AXI_0_arburst),
        .S01_AXI_0_arcache(S01_AXI_0_arcache),
        .S01_AXI_0_arid(S01_AXI_0_arid),
        .S01_AXI_0_arlen(S01_AXI_0_arlen),
        .S01_AXI_0_arlock(S01_AXI_0_arlock),
        .S01_AXI_0_arprot(S01_AXI_0_arprot),
        .S01_AXI_0_arqos(S01_AXI_0_arqos),
        .S01_AXI_0_arready(S01_AXI_0_arready),
        .S01_AXI_0_arregion(S01_AXI_0_arregion),
        .S01_AXI_0_arsize(S01_AXI_0_arsize),
        .S01_AXI_0_arvalid(S01_AXI_0_arvalid),
        .S01_AXI_0_awaddr(S01_AXI_0_awaddr),
        .S01_AXI_0_awburst(S01_AXI_0_awburst),
        .S01_AXI_0_awcache(S01_AXI_0_awcache),
        .S01_AXI_0_awid(S01_AXI_0_awid),
        .S01_AXI_0_awlen(S01_AXI_0_awlen),
        .S01_AXI_0_awlock(S01_AXI_0_awlock),
        .S01_AXI_0_awprot(S01_AXI_0_awprot),
        .S01_AXI_0_awqos(S01_AXI_0_awqos),
        .S01_AXI_0_awready(S01_AXI_0_awready),
        .S01_AXI_0_awregion(S01_AXI_0_awregion),
        .S01_AXI_0_awsize(S01_AXI_0_awsize),
        .S01_AXI_0_awvalid(S01_AXI_0_awvalid),
        .S01_AXI_0_bid(S01_AXI_0_bid),
        .S01_AXI_0_bready(S01_AXI_0_bready),
        .S01_AXI_0_bresp(S01_AXI_0_bresp),
        .S01_AXI_0_bvalid(S01_AXI_0_bvalid),
        .S01_AXI_0_rdata(S01_AXI_0_rdata),
        .S01_AXI_0_rid(S01_AXI_0_rid),
        .S01_AXI_0_rlast(S01_AXI_0_rlast),
        .S01_AXI_0_rready(S01_AXI_0_rready),
        .S01_AXI_0_rresp(S01_AXI_0_rresp),
        .S01_AXI_0_rvalid(S01_AXI_0_rvalid),
        .S01_AXI_0_wdata(S01_AXI_0_wdata),
        .S01_AXI_0_wlast(S01_AXI_0_wlast),
        .S01_AXI_0_wready(S01_AXI_0_wready),
        .S01_AXI_0_wstrb(S01_AXI_0_wstrb),
        .S01_AXI_0_wvalid(S01_AXI_0_wvalid),
        .S02_AXI_0_araddr(S02_AXI_0_araddr),
        .S02_AXI_0_arburst(S02_AXI_0_arburst),
        .S02_AXI_0_arcache(S02_AXI_0_arcache),
        .S02_AXI_0_arid(S02_AXI_0_arid),
        .S02_AXI_0_arlen(S02_AXI_0_arlen),
        .S02_AXI_0_arlock(S02_AXI_0_arlock),
        .S02_AXI_0_arprot(S02_AXI_0_arprot),
        .S02_AXI_0_arqos(S02_AXI_0_arqos),
        .S02_AXI_0_arready(S02_AXI_0_arready),
        .S02_AXI_0_arregion(S02_AXI_0_arregion),
        .S02_AXI_0_arsize(S02_AXI_0_arsize),
        .S02_AXI_0_arvalid(S02_AXI_0_arvalid),
        .S02_AXI_0_awaddr(S02_AXI_0_awaddr),
        .S02_AXI_0_awburst(S02_AXI_0_awburst),
        .S02_AXI_0_awcache(S02_AXI_0_awcache),
        .S02_AXI_0_awid(S02_AXI_0_awid),
        .S02_AXI_0_awlen(S02_AXI_0_awlen),
        .S02_AXI_0_awlock(S02_AXI_0_awlock),
        .S02_AXI_0_awprot(S02_AXI_0_awprot),
        .S02_AXI_0_awqos(S02_AXI_0_awqos),
        .S02_AXI_0_awready(S02_AXI_0_awready),
        .S02_AXI_0_awregion(S02_AXI_0_awregion),
        .S02_AXI_0_awsize(S02_AXI_0_awsize),
        .S02_AXI_0_awvalid(S02_AXI_0_awvalid),
        .S02_AXI_0_bid(S02_AXI_0_bid),
        .S02_AXI_0_bready(S02_AXI_0_bready),
        .S02_AXI_0_bresp(S02_AXI_0_bresp),
        .S02_AXI_0_bvalid(S02_AXI_0_bvalid),
        .S02_AXI_0_rdata(S02_AXI_0_rdata),
        .S02_AXI_0_rid(S02_AXI_0_rid),
        .S02_AXI_0_rlast(S02_AXI_0_rlast),
        .S02_AXI_0_rready(S02_AXI_0_rready),
        .S02_AXI_0_rresp(S02_AXI_0_rresp),
        .S02_AXI_0_rvalid(S02_AXI_0_rvalid),
        .S02_AXI_0_wdata(S02_AXI_0_wdata),
        .S02_AXI_0_wlast(S02_AXI_0_wlast),
        .S02_AXI_0_wready(S02_AXI_0_wready),
        .S02_AXI_0_wstrb(S02_AXI_0_wstrb),
        .S02_AXI_0_wvalid(S02_AXI_0_wvalid),
        .S03_AXI_0_araddr(S03_AXI_0_araddr),
        .S03_AXI_0_arburst(S03_AXI_0_arburst),
        .S03_AXI_0_arcache(S03_AXI_0_arcache),
        .S03_AXI_0_arid(S03_AXI_0_arid),
        .S03_AXI_0_arlen(S03_AXI_0_arlen),
        .S03_AXI_0_arlock(S03_AXI_0_arlock),
        .S03_AXI_0_arprot(S03_AXI_0_arprot),
        .S03_AXI_0_arqos(S03_AXI_0_arqos),
        .S03_AXI_0_arready(S03_AXI_0_arready),
        .S03_AXI_0_arregion(S03_AXI_0_arregion),
        .S03_AXI_0_arsize(S03_AXI_0_arsize),
        .S03_AXI_0_arvalid(S03_AXI_0_arvalid),
        .S03_AXI_0_awaddr(S03_AXI_0_awaddr),
        .S03_AXI_0_awburst(S03_AXI_0_awburst),
        .S03_AXI_0_awcache(S03_AXI_0_awcache),
        .S03_AXI_0_awid(S03_AXI_0_awid),
        .S03_AXI_0_awlen(S03_AXI_0_awlen),
        .S03_AXI_0_awlock(S03_AXI_0_awlock),
        .S03_AXI_0_awprot(S03_AXI_0_awprot),
        .S03_AXI_0_awqos(S03_AXI_0_awqos),
        .S03_AXI_0_awready(S03_AXI_0_awready),
        .S03_AXI_0_awregion(S03_AXI_0_awregion),
        .S03_AXI_0_awsize(S03_AXI_0_awsize),
        .S03_AXI_0_awvalid(S03_AXI_0_awvalid),
        .S03_AXI_0_bid(S03_AXI_0_bid),
        .S03_AXI_0_bready(S03_AXI_0_bready),
        .S03_AXI_0_bresp(S03_AXI_0_bresp),
        .S03_AXI_0_bvalid(S03_AXI_0_bvalid),
        .S03_AXI_0_rdata(S03_AXI_0_rdata),
        .S03_AXI_0_rid(S03_AXI_0_rid),
        .S03_AXI_0_rlast(S03_AXI_0_rlast),
        .S03_AXI_0_rready(S03_AXI_0_rready),
        .S03_AXI_0_rresp(S03_AXI_0_rresp),
        .S03_AXI_0_rvalid(S03_AXI_0_rvalid),
        .S03_AXI_0_wdata(S03_AXI_0_wdata),
        .S03_AXI_0_wlast(S03_AXI_0_wlast),
        .S03_AXI_0_wready(S03_AXI_0_wready),
        .S03_AXI_0_wstrb(S03_AXI_0_wstrb),
        .S03_AXI_0_wvalid(S03_AXI_0_wvalid),
        .ddr_clk(ddr_clk),
        .ddr_init_done(ddr_init_done),
        .ddr_sync_rst(ddr_sync_rst),
        .sys_clk_i_0(sys_clk_i_0),
        .sys_rst_0(sys_rst_0));
endmodule
