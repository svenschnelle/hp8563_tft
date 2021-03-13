library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_textio.all;
library std;
use std.textio.all;
entity dpram is
generic(
	arraysize: integer;
	wordsize: integer);
port (
	write_clock_i		: in std_logic;
	write_data_i		: in std_logic_vector(wordsize-1 downto 0);
	write_addr_i		: in integer range 0 to arraysize - 1;
	write_i			: in std_logic;

	read_clock_i		: in std_logic;
	read_addr_i		: in integer range 0 to arraysize - 1;
	read_data_o		: out std_logic_vector(wordsize - 1 downto 0)
);
end dpram;
architecture rtl of dpram is

type mem is array(0 TO arraysize - 1) of std_logic_vector(wordsize - 1 downto 0);

signal ram_block: MEM;

begin
process (write_clock_i)
begin
	if (rising_edge(write_clock_i)) then
		if (write_i = '1') then
                  ram_block(write_addr_i) <= write_data_i;
		end if;
	end if;
end process;

process (read_clock_i)
begin
	if (rising_edge(read_clock_i)) then
		read_data_o <= ram_block(read_addr_i);
	end if;
end process;
end rtl;
