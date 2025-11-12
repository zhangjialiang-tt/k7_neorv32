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
#(
  parameter [3:0]  IDCODE_VERSION = 4'h0,  // version
  parameter [15:0] IDCODE_PARTID  = 16'h0, // part number
  parameter [10:0] IDCODE_MANID   = 11'h0  // manufacturer id
)(
  // global control
  input  wire clk_i,      // global clock line
  input  wire rstn_i,     // global reset line, low-active
  // JTAG connection (TAP access)
  input  wire jtag_tck_i, // serial clock
  input  wire jtag_tdi_i, // serial data input
  output reg  jtag_tdo_o, // serial data output
  input  wire jtag_tms_i, // mode select
  // debug module interface (DMI)
  output wire [40:0] dmi_req_o, // request: {addr[6:0], data[31:0], op[1:0]}
  input  wire [32:0] dmi_rsp_i  // response: {data[31:0], ack}
);

  // TAP data registers
  localparam [4:0] ADDR_IDCODE = 5'b00001;
  localparam [4:0] ADDR_DTMCS  = 5'b10000;
  localparam [4:0] ADDR_DMI    = 5'b10001;
  localparam [4:0] ADDR_BYPASS = 5'b11111;

  localparam SIZE_IDCODE = 32;
  localparam SIZE_DTMCS  = 32;
  localparam SIZE_DMI    = 7+32+2; // 7-bit address + 32-bit data + 2-bit operation/status
  localparam SIZE_BYPASS = 1;

  // JTAG signal synchronizer
  reg  [2:0] tck_ff;
  reg  [1:0] tdi_ff, tms_ff;
  wire       tck_rise, tck_fall, tdi, tms;

  // TAP controller
  reg  [3:0] state, state2;

  // TAP registers
  reg  [4:0] ireg;
  reg  [SIZE_DMI-1:0] dreg; // max size (= dmi size)

  // misc
  wire update, dmihardreset, dmireset;

  // debug module interface controller
  reg  [40:0] dmi; // {addr[6:0], data[31:0], op[1:0]}
  reg  busy, err;

  // DMI operation constants
  localparam [1:0] DMI_REQ_NOP = 2'b00;
  localparam [1:0] DMI_REQ_RD  = 2'b01;
  localparam [1:0] DMI_REQ_WR  = 2'b10;

  // JTAG Input Synchronizer
  always @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      tck_ff <= 3'b0;
      tdi_ff <= 2'b0;
      tms_ff <= 2'b0;
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
  always @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      state2 <= 4'h0; // LOGIC_RESET
      state  <= 4'h0; // LOGIC_RESET
    end else begin
      state2 <= state;
      if (tck_rise) begin // clock pulse (evaluate TMS on the rising edge of TCK)
        case (state) // JTAG state machine
          4'h0: state <= (tms == 1'b0) ? 4'h8 : 4'h0; // LOGIC_RESET -> RUN_IDLE / LOGIC_RESET
          4'h8: state <= (tms == 1'b0) ? 4'h8 : 4'h1; // RUN_IDLE    -> RUN_IDLE / DR_SCAN
          4'h1: state <= (tms == 1'b0) ? 4'h2 : 4'h9; // DR_SCAN     -> DR_CAPTURE / IR_SCAN
          4'h2: state <= (tms == 1'b0) ? 4'h3 : 4'h4; // DR_CAPTURE  -> DR_SHIFT / DR_EXIT1
          4'h3: state <= (tms == 1'b0) ? 4'h3 : 4'h4; // DR_SHIFT    -> DR_SHIFT / DR_EXIT1
          4'h4: state <= (tms == 1'b0) ? 4'h5 : 4'h7; // DR_EXIT1    -> DR_PAUSE / DR_UPDATE
          4'h5: state <= (tms == 1'b0) ? 4'h5 : 4'h6; // DR_PAUSE    -> DR_PAUSE / DR_EXIT2
          4'h6: state <= (tms == 1'b0) ? 4'h3 : 4'h7; // DR_EXIT2    -> DR_SHIFT / DR_UPDATE
          4'h7: state <= (tms == 1'b0) ? 4'h8 : 4'h1; // DR_UPDATE   -> RUN_IDLE / DR_SCAN
          4'h9: state <= (tms == 1'b0) ? 4'hA : 4'h0; // IR_SCAN     -> IR_CAPTURE / LOGIC_RESET
          4'hA: state <= (tms == 1'b0) ? 4'hB : 4'hC; // IR_CAPTURE  -> IR_SHIFT / IR_EXIT1
          4'hB: state <= (tms == 1'b0) ? 4'hB : 4'hC; // IR_SHIFT    -> IR_SHIFT / IR_EXIT1
          4'hC: state <= (tms == 1'b0) ? 4'hD : 4'hF; // IR_EXIT1    -> IR_PAUSE / IR_UPDATE
          4'hD: state <= (tms == 1'b0) ? 4'hD : 4'hE; // IR_PAUSE    -> IR_PAUSE / IR_EXIT2
          4'hE: state <= (tms == 1'b0) ? 4'hB : 4'hF; // IR_EXIT2    -> IR_SHIFT / IR_UPDATE
          4'hF: state <= (tms == 1'b0) ? 4'h8 : 4'h1; // IR_UPDATE   -> RUN_IDLE / DR_SCAN
          default:     state <= 4'h0; // LOGIC_RESET
        endcase
      end
    end
  end

  // DR_UPDATE edge detector
  assign update = ((state == 4'h7) && (state2 != 4'h7)) ? 1'b1 : 1'b0;

  // Tap Register Access
  always @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      ireg       <= 5'b0;
      dreg       <= {SIZE_DMI{1'b0}};
      jtag_tdo_o <= 1'b0;
    end else begin
      // instruction register input
      if ((state == 4'h0) || (state == 4'hA)) begin // capture phase
        ireg <= ADDR_IDCODE;
      end else if ((state == 4'hB) && tck_rise) begin // access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
        ireg <= {tdi, ireg[4:1]};
      end

      // data register input
      if (state == 4'h2) begin // capture phase
        dreg <= {SIZE_DMI{1'b0}};
        case (ireg) // make data MSB-aligned
          ADDR_IDCODE: dreg[SIZE_DMI-1:SIZE_DMI-SIZE_IDCODE] <= {IDCODE_VERSION, IDCODE_PARTID, IDCODE_MANID, 1'b1};
          ADDR_DTMCS:  dreg[SIZE_DMI-1:SIZE_DMI-SIZE_DTMCS]  <= 32'h00000071;
          ADDR_DMI:    dreg[SIZE_DMI-1:SIZE_DMI-SIZE_DMI]    <= {dmi[40:34], dmi[33:2], err, err};
          default:     dreg[SIZE_DMI-1:SIZE_DMI-SIZE_BYPASS] <= {SIZE_BYPASS{1'b0}};
        endcase
      end else if ((state == 4'h3) && tck_rise) begin // access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
        dreg <= {tdi, dreg[SIZE_DMI-1:1]};
      end

      // output
      if (tck_fall) begin // [JTAG-SYNC] update TDO on falling edge of TCK
        if (state == 4'hB) begin
          jtag_tdo_o <= ireg[0];
        end else if (state == 4'h3) begin
          case (ireg) // data is MSB-aligned so select the logical LSB as output
            ADDR_IDCODE: jtag_tdo_o <= dreg[SIZE_DMI-SIZE_IDCODE];
            ADDR_DTMCS:  jtag_tdo_o <= dreg[SIZE_DMI-SIZE_DTMCS];
            ADDR_DMI:    jtag_tdo_o <= dreg[SIZE_DMI-SIZE_DMI];
            default:     jtag_tdo_o <= dreg[SIZE_DMI-SIZE_BYPASS];
          endcase
        end
      end
    end
  end

  // reset control
  assign dmihardreset = (update && (ireg == ADDR_DTMCS) && dreg[17]) ? 1'b1 : 1'b0;
  assign dmireset     = (update && (ireg == ADDR_DTMCS) && dreg[16]) ? 1'b1 : 1'b0;

  // Debug Module Interface Controller
  always @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i) begin
      busy <= 1'b0;
      err  <= 1'b0;
      dmi  <= {7'b0, 32'b0, DMI_REQ_NOP}; // dmi_req_terminate_c equivalent
    end else begin
      // sticky error: access attempt while DMI is busy
      if (dmireset || dmihardreset) begin
        err <= 1'b0;
      end else if (update && (ireg == ADDR_DMI) && busy) begin
        err <= 1'b1;
      end

      // interface arbiter
      dmi[1:0] <= DMI_REQ_NOP; // default
      if (!busy) begin // idle: waiting for new request
        if (update && (ireg == ADDR_DMI)) begin
          dmi[40:34] <= dreg[40:34];
          dmi[33:2]  <= dreg[33:2];
          dmi[1:0]   <= dreg[1:0];
          busy       <= |dreg[1:0]; // or_reduce_f equivalent
        end
      end else if (dmi_rsp_i[32] || dmihardreset) begin // busy: wait for access termination
        dmi[33:2] <= dmi_rsp_i[31:0];
        busy       <= 1'b0;
      end
    end
  end

  // DMI output - unpack the concatenated signal
  assign dmi_req_o = dmi;

endmodule