library ieee;
use ieee.std_logic_1164.all;

entity data_avl_delay is
    generic
    (
        DW            : integer := 1;           --data width
        DELAY_NUM     : integer := 1            --
    );
    port
    (
        i_clk               : in std_logic;
        i_rst_n             : in std_logic;
        i_pixel_vld         : in std_logic;
        --data input
        i_data              : in std_logic_vector(DW - 1 downto 0);
        --data output
        o_data              : out std_logic_vector(DW - 1 downto 0)
    );
end entity;

architecture rtl of data_avl_delay is

type data_delay_type is array (integer range <>) of std_logic_vector(i_data'range);
signal data_reg             : data_delay_type(DELAY_NUM - 1 downto 0);
    
begin
    
		process(i_clk, i_rst_n)
		begin
				if(i_rst_n = '0')then
						data_reg(0) <= (others => '0');
				elsif(rising_edge(i_clk))then
						if(i_pixel_vld = '1')then
								data_reg(0) <= i_data;
						end if;
				end if;
		end process;
    
		delay_gen : if(DELAY_NUM > 1)generate
				data_gen : for i in 1 to (DELAY_NUM - 1) generate
						process(i_clk, i_rst_n)
						begin
								if(i_rst_n = '0')then
										data_reg(i) <= (others => '0');
								elsif(rising_edge(i_clk))then
										if(i_pixel_vld = '1')then
												data_reg(i) <= data_reg(i - 1);
										end if;
								end if;
						end process;
				end generate;
		end generate;
    
    o_data <= data_reg(DELAY_NUM - 1);
    
end rtl;
