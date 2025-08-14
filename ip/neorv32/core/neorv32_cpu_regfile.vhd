-- ================================================================================ --
-- NEORV32 CPU - Data Register File                                                 --
-- -------------------------------------------------------------------------------- --
-- Data register file. 32 entries (= 1024 bit) for RV32I ISA (default), 16 entries  --
-- (= 512 bit) for RV32E ISA (when RISC-V "E" extension is enabled via "RVE_EN").   --
--                                                                                  --
-- By default the register file is coded to infer block RAM (for FPGAs), that does  --
-- not provide a dedicated hardware reset. For ASIC implementation or setups that   --
-- do require a dedicated hardware reset a flip-flop-based architecture can be      --
-- enabled via "RST_EN".                                                            --
--                                                                                  --
-- [NOTE] Read-during-write behavior of the register file's memory core is          --
--        irrelevant as read and write accesses are mutually exclusive and will     --
--        never happen at the same time.                                            --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cpu_regfile is
  generic (
    RST_EN : boolean; -- implement dedicated hardware reset ("ASIC style")
    RVE_EN : boolean; -- implement embedded RF extension
    RS3_EN : boolean  -- implement 3rd read port
  );
  port (
    -- global control --
    clk_i  : in  std_ulogic; -- global clock, rising edge
    rstn_i : in  std_ulogic; -- global reset, low-active, async
    ctrl_i : in  ctrl_bus_t; -- main control bus
    -- operands --
    rd_i   : in  std_ulogic_vector(XLEN-1 downto 0); -- destination operand rd
    rs1_o  : out std_ulogic_vector(XLEN-1 downto 0); -- source operand rs1
    rs2_o  : out std_ulogic_vector(XLEN-1 downto 0); -- source operand rs2
    rs3_o  : out std_ulogic_vector(XLEN-1 downto 0)  -- source operand rs3
  );
end neorv32_cpu_regfile;

architecture neorv32_cpu_regfile_rtl of neorv32_cpu_regfile is

  -- auto-configuration --
  constant addr_bits_c : natural := cond_sel_natural_f(RVE_EN, 4, 5); -- address width

  -- register file --
  type   reg_file_t is array ((2**addr_bits_c)-1 downto 0) of std_ulogic_vector(XLEN-1 downto 0);
  signal reg_file : reg_file_t;

  -- access --
  signal rf_we    : std_ulogic; -- write enable
  signal rd_zero  : std_ulogic; -- writing to x0?
  signal opa_addr : std_ulogic_vector(4 downto 0); -- rs1/rd address
  signal rs3_addr : std_ulogic_vector(4 downto 0); -- rs3 address

    -- local signals for connecting to the RAM
    signal ram_addr_a : std_ulogic_vector(addr_bits_c-1 downto 0);
    signal ram_addr_b : std_ulogic_vector(addr_bits_c-1 downto 0);
    signal ram_din_a  : std_ulogic_vector(XLEN-1 downto 0);
    signal ram_we_a   : std_ulogic;
    signal ram_dout_a : std_ulogic_vector(XLEN-1 downto 0);
    signal ram_dout_b : std_ulogic_vector(XLEN-1 downto 0);

  -- component declaration for the explicit BRAM IP
  component true_dual_port_ram is
    generic (
      DATA_WIDTH    : integer := 32;
      ADDR_WIDTH    : integer := 5;
      WRITE_MODE_1  : string  := "READ_FIRST";
      WRITE_MODE_2  : string  := "READ_FIRST";
      OUTPUT_REG_1  : string  := "TRUE";
      OUTPUT_REG_2  : string  := "TRUE";
      RAM_INIT_FILE : string  := ""
    );
    port (
      we1   : in  std_ulogic;
      we2   : in  std_ulogic;
      clka  : in  std_ulogic;
      clkb  : in  std_ulogic;
      din1  : in  std_ulogic_vector(DATA_WIDTH-1 downto 0);
      din2  : in  std_ulogic_vector(DATA_WIDTH-1 downto 0);
      addr1 : in  std_ulogic_vector(ADDR_WIDTH-1 downto 0);
      addr2 : in  std_ulogic_vector(ADDR_WIDTH-1 downto 0);
      dout1 : out std_ulogic_vector(DATA_WIDTH-1 downto 0);
      dout2 : out std_ulogic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

begin

  -- FPGA-Style Register File (BlockRAM, no hardware reset at all) --------------------------
  -- -------------------------------------------------------------------------------------------
  register_file_fpga:
  if not RST_EN generate

    -- True dual-port block RAM instantiation
    -- Port A: write-port (rd) and read-port (rs1)
    -- Port B: read-port (rs2)

    -- control logic to drive the RAM
    rd_zero  <= '1' when (ctrl_i.rf_rd = "00000") else '0';
    rf_we    <= (ctrl_i.rf_wb_en and (not rd_zero)) or ctrl_i.rf_zero_we; -- never write to x0 unless explicitly forced
    opa_addr <= "00000" when (ctrl_i.rf_zero_we = '1') else -- force rd = zero
                ctrl_i.rf_rd when (ctrl_i.rf_wb_en = '1') else -- rd
                ctrl_i.rf_rs1; -- rs1
    -- ram_we_a <= (ctrl_i.rf_wb_en and (not rd_zero)) or ctrl_i.rf_zero_we; -- never write to x0 unless explicitly forced

    -- Port A is used for writes (rd) and for rs1 reads
    ram_addr_a <= ctrl_i.rf_rd(addr_bits_c-1 downto 0) when (ctrl_i.rf_wb_en = '1') else
                  ctrl_i.rf_rs1(addr_bits_c-1 downto 0);
    ram_din_a  <= rd_i;

    -- Port B is used for rs2 reads
    ram_addr_b <= ctrl_i.rf_rs2(addr_bits_c-1 downto 0);

    -- Instantiate the true dual-port RAM
    bram_inst : true_dual_port_ram
      generic map (
        DATA_WIDTH    => XLEN,
        ADDR_WIDTH    => addr_bits_c,
        WRITE_MODE_1  => "READ_FIRST",
        WRITE_MODE_2  => "READ_FIRST",
        OUTPUT_REG_1  => "FALSE",
        OUTPUT_REG_2  => "FALSE",
        RAM_INIT_FILE => ""
      )
      port map (
        clka  => clk_i,
        addr1 => opa_addr,
        we1   => rf_we,
        din1  => rd_i,
        dout1 => rs1_o,--ram_dout_a,

        din2  => (others => '0'), -- Port B is read-only
        we2   => '0',             -- Port B is read-only
        clkb  => clk_i,
        addr2 => ram_addr_b,
        dout2 => rs2_o--ram_dout_b
      );

    -- Connect RAM outputs to module outputs
    -- Handle reading from address 0
    -- rs1_o <= ram_dout_a when (unsigned(ram_addr_a) /= 0) else (others => '0');
    -- rs2_o <= ram_dout_b when (unsigned(ram_addr_b) /= 0) else (others => '0');

  end generate; -- /register_file_fpga


  -- ASIC-Style Register File (individual FFs, full hardware reset) -------------------------
  -- -------------------------------------------------------------------------------------------
  register_file_asic:
  if RST_EN generate

    -- individual registers --
    reg_gen:
    for i in 1 to (2**addr_bits_c)-1 generate
      register_file: process(rstn_i, clk_i)
      begin
        if (rstn_i = '0') then
          reg_file(i) <= (others => '0'); -- full hardware reset
        elsif rising_edge(clk_i) then
          if (unsigned(ctrl_i.rf_rd(addr_bits_c-1 downto 0)) = to_unsigned(i, addr_bits_c)) and (ctrl_i.rf_wb_en = '1') then
            reg_file(i) <= rd_i;
          end if;
        end if;
      end process register_file;
    end generate;

    -- x0 is hardwired to zero --
    reg_file(0) <= (others => '0');

    -- synchronous read --
    rf_read: process(rstn_i, clk_i)
    begin
      if (rstn_i = '0') then
        rs1_o <= (others => '0');
        rs2_o <= (others => '0');
      elsif rising_edge(clk_i) then
        rs1_o <= reg_file(to_integer(unsigned(ctrl_i.rf_rs1(addr_bits_c-1 downto 0))));
        rs2_o <= reg_file(to_integer(unsigned(ctrl_i.rf_rs2(addr_bits_c-1 downto 0))));
      end if;
    end process rf_read;

  end generate; -- /register_file_asic


  -- Optional Third Read Port (rs3) ---------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  rs3_enabled:
  if RS3_EN generate
    rs3_read: process(clk_i)
    begin
      if rising_edge(clk_i) then
        rs3_o <= reg_file(to_integer(unsigned(rs3_addr(addr_bits_c-1 downto 0))));
      end if;
    end process rs3_read;
  end generate;

  rs3_disabled:
  if not RS3_EN generate
    rs3_o <= (others => '0');
  end generate;

  -- RISC-V rs3 operand --
  rs3_addr <= ctrl_i.ir_funct12(11 downto 7);


end neorv32_cpu_regfile_rtl;
