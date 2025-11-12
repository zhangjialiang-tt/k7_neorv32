// ================================================================================
// NEORV32 OCD - RISC-V-Compatible Debug Transport Module (DTM)
// --------------------------------------------------------------------------------
// Compatible to RISC-V debug spec. versions 0.13 and 1.0.
// --------------------------------------------------------------------------------
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32
// Copyright (c) NEORV32 contributors.
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.
// Licensed under the BSD-3-Clause license, see LICENSE for details.
// SPDX-License-Identifier: BSD-3-Clause
// ================================================================================

module neorv32_debug_dtm
  import neorv32_package::*;
#(
  parameter logic [3:0]  IDCODE_VERSION = 4'h0,  // version
  parameter logic [15:0] IDCODE_PARTID  = 16'h0, // part number
  parameter logic [10:0] IDCODE_MANID   = 11'h0  // manufacturer id
)(
  // global control
  input  logic clk_i,      // global clock line
  input  logic rstn_i,     // global reset line, low-active
  // JTAG connection (TAP access)
  input  logic jtag_tck_i, // serial clock
  input  logic jtag_tdi_i, // serial data input
  output logic jtag_tdo_o, // serial data output
  input  logic jtag_tms_i, // mode select
  // debug module interface (DMI)
  output dmi_req_t dmi_req_o, // request
  input  dmi_rsp_t dmi_rsp_i  // response
);

  // TAP data registers
  localparam logic [4:0] ADDR_IDCODE = 5'b00001;
  localparam logic [4:0] ADDR_DTMCS  = 5'b10000;
  localparam logic [4:0] ADDR_DMI    = 5'b10001;
  localparam logic [4:0] ADDR_BYPASS = 5'b11111;

  localparam int SIZE_IDCODE = 32;
  localparam int SIZE_DTMCS  = 32;
  localparam int SIZE_DMI    = 7+32+2; // 7-bit address + 32-bit data + 2-bit operation/status
  localparam int SIZE_BYPASS = 1;

  // JTAG signal synchronizer
  logic [2:0] tck_ff;
  logic [1:0] tdi_ff, tms_ff;
  logic       tck_rise, tck_fall, tdi, tms;

  // TAP controller
  typedef enum logic [3:0] {
    LOGIC_RESET = 4'h0,
    DR_SCAN     = 4'h1,
    DR_CAPTURE  = 4'h2,
    DR_SHIFT    = 4'h3,
    DR_EXIT1    = 4'h4,
    DR_PAUSE    = 4'h5,
    DR_EXIT2    = 4'h6,
    DR_UPDATE   = 4'h7,
    RUN_IDLE    = 4'h8,
    IR_SCAN     = 4'h9,
    IR_CAPTURE  = 4'hA,
    IR_SHIFT    = 4'hB,
    IR_EXIT1    = 4'hC,
    IR_PAUSE    = 4'hD,
    IR_EXIT2    = 4'hE,
    IR_UPDATE   = 4'hF
  } state_t;

  state_t state, state2;

  // TAP registers
  logic [4:0] ireg;
  logic [SIZE_DMI-1:0] dreg; // max size (= dmi size)

  // misc
  logic update, dmihardreset, dmireset;

  // debug module interface controller
  dmi_req_t dmi;
  logic busy, err;

  // JTAG Input Synchronizer
  always_ff @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      tck_ff <= '0;
      tdi_ff <= '0;
      tms_ff <= '0;
    end else begin
      tck_ff <= {tck_ff[1:0], jtag_tck_i};
      tdi_ff <= {tdi_ff[0], jtag_tdi_i};
      tms_ff <= {tms_ff[0], jtag_tms_i};
    end
  end

  // JTAG clock edges
  assign tck_rise = (tck_ff[2:1] == 2'b01) ? 1'b1 : 1'b0;
  assign tck_fall = (tck_ff[2:1] == 2'b10) ? 1'b1 : 1'b0;

  // JTAG inputs
  assign tms = tms_ff[1];
  assign tdi = tdi_ff[1];

  // JTAG Tap Control FSM
  always_ff @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      state2 <= LOGIC_RESET;
      state  <= LOGIC_RESET;
    end else begin
      state2 <= state;
      if (tck_rise) begin // clock pulse (evaluate TMS on the rising edge of TCK)
        case (state) // JTAG state machine
          LOGIC_RESET: state <= (tms == 1'b0) ? RUN_IDLE   : LOGIC_RESET;
          RUN_IDLE:    state <= (tms == 1'b0) ? RUN_IDLE   : DR_SCAN;
          DR_SCAN:     state <= (tms == 1'b0) ? DR_CAPTURE : IR_SCAN;
          DR_CAPTURE:  state <= (tms == 1'b0) ? DR_SHIFT   : DR_EXIT1;
          DR_SHIFT:    state <= (tms == 1'b0) ? DR_SHIFT   : DR_EXIT1;
          DR_EXIT1:    state <= (tms == 1'b0) ? DR_PAUSE   : DR_UPDATE;
          DR_PAUSE:    state <= (tms == 1'b0) ? DR_PAUSE   : DR_EXIT2;
          DR_EXIT2:    state <= (tms == 1'b0) ? DR_SHIFT   : DR_UPDATE;
          DR_UPDATE:   state <= (tms == 1'b0) ? RUN_IDLE   : DR_SCAN;
          IR_SCAN:     state <= (tms == 1'b0) ? IR_CAPTURE : LOGIC_RESET;
          IR_CAPTURE:  state <= (tms == 1'b0) ? IR_SHIFT   : IR_EXIT1;
          IR_SHIFT:    state <= (tms == 1'b0) ? IR_SHIFT   : IR_EXIT1;
          IR_EXIT1:    state <= (tms == 1'b0) ? IR_PAUSE   : IR_UPDATE;
          IR_PAUSE:    state <= (tms == 1'b0) ? IR_PAUSE   : IR_EXIT2;
          IR_EXIT2:    state <= (tms == 1'b0) ? IR_SHIFT   : IR_UPDATE;
          IR_UPDATE:   state <= (tms == 1'b0) ? RUN_IDLE   : DR_SCAN;
          default:     state <= LOGIC_RESET;
        endcase
      end
    end
  end

  // DR_UPDATE edge detector
  assign update = ((state == DR_UPDATE) && (state2 != DR_UPDATE)) ? 1'b1 : 1'b0;

  // Tap Register Access
  always_ff @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      ireg       <= '0;
      dreg       <= '0;
      jtag_tdo_o <= '0;
    end else begin
      // instruction register input
      if ((state == LOGIC_RESET) || (state == IR_CAPTURE)) begin // capture phase
        ireg <= ADDR_IDCODE;
      end else if ((state == IR_SHIFT) && tck_rise) begin // access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
        ireg <= {tdi, ireg[4:1]};
      end

      // data register input
      if (state == DR_CAPTURE) begin // capture phase
        dreg <= '0;
        case (ireg) // make data MSB-aligned
          ADDR_IDCODE: dreg[$size(dreg)-1:$size(dreg)-SIZE_IDCODE] <= {IDCODE_VERSION, IDCODE_PARTID, IDCODE_MANID, 1'b1};
          ADDR_DTMCS:  dreg[$size(dreg)-1:$size(dreg)-SIZE_DTMCS]  <= 32'h00000071;
          ADDR_DMI:    dreg[$size(dreg)-1:$size(dreg)-SIZE_DMI]    <= {dmi.addr, dmi.data, err, err};
          default:     dreg[$size(dreg)-1:$size(dreg)-SIZE_BYPASS] <= '0;
        endcase
      end else if ((state == DR_SHIFT) && tck_rise) begin // access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
        dreg <= {tdi, dreg[$size(dreg)-1:1]};
      end

      // output
      if (tck_fall) begin // [JTAG-SYNC] update TDO on falling edge of TCK
        if (state == IR_SHIFT) begin
          jtag_tdo_o <= ireg[0];
        end else if (state == DR_SHIFT) begin
          case (ireg) // data is MSB-aligned so select the logical LSB as output
            ADDR_IDCODE: jtag_tdo_o <= dreg[$size(dreg)-SIZE_IDCODE];
            ADDR_DTMCS:  jtag_tdo_o <= dreg[$size(dreg)-SIZE_DTMCS];
            ADDR_DMI:    jtag_tdo_o <= dreg[$size(dreg)-SIZE_DMI];
            default:     jtag_tdo_o <= dreg[$size(dreg)-SIZE_BYPASS];
          endcase
        end
      end
    end
  end

  // reset control
  assign dmihardreset = (update && (ireg == ADDR_DTMCS) && dreg[17]) ? 1'b1 : 1'b0;
  assign dmireset     = (update && (ireg == ADDR_DTMCS) && dreg[16]) ? 1'b1 : 1'b0;

  // Debug Module Interface Controller
  always_ff @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      busy <= 1'b0;
      err  <= 1'b0;
      dmi  <= '{op: DMI_REQ_NOP, addr: '0, data: '0};
    end else begin
      // sticky error: access attempt while DMI is busy
      if (dmireset || dmihardreset) begin
        err <= 1'b0;
      end else if (update && (ireg == ADDR_DMI) && busy) begin
        err <= 1'b1;
      end

      // interface arbiter
      dmi.op <= DMI_REQ_NOP; // default
      if (!busy) begin // idle: waiting for new request
        if (update && (ireg == ADDR_DMI)) begin
          dmi.addr <= dreg[40:34];
          dmi.data <= dreg[33:2];
          dmi.op   <= dreg[1:0];
          busy     <= |dreg[1:0];
        end
      end else if (dmi_rsp_i.ack || dmihardreset) begin // busy: wait for access termination
        dmi.data <= dmi_rsp_i.data;
        busy     <= 1'b0;
      end
    end
  end

  // DMI output
  assign dmi_req_o = dmi;

endmodule