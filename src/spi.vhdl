library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity spi is
	port(address: in std_logic_vector(23 downto 0);
		data: out std_logic_vector(7 downto 0);
		data_ready: out std_logic;
		cycle_start: in std_logic;
		resetn: in std_logic;
		clk: in std_logic;
		si: out std_logic;
		so: in std_logic;
		cs: out std_logic);
begin
end spi;

architecture rtl of spi is
	type spi_state is (IDLEs, COMMANDs, ADDRESSs, DATAs);
	signal state: spi_state;
	signal shift_in: std_ulogic;
	constant READ_COMMAND: std_logic_vector(7 downto 0) := x"03";
begin

spi_process: process(clk, resetn, address, cycle_start)
	variable bitcnt: integer;

begin
	if resetn = '0' then
		state <= IDLEs;
		si <= '0';
		cs <= '1';
		data_ready <= '0';
		bitcnt := 0;
		shift_in <= '0';
	elsif clk'event and clk = '0' then
		case state is
			when IDLEs =>
				data_ready <= '0';
				cs <= '1';
				if cycle_start = '1' then
					state <= COMMANDs;
					bitcnt := 7;
				end if;
			when COMMANDs =>
				cs <= '0';
				si <= READ_COMMAND(bitcnt);
				if bitcnt = 0 then
					state <= ADDRESSs;
					bitcnt := 23;
				else
					bitcnt := bitcnt - 1;
				end if;
			when ADDRESSs =>
				si <= address(bitcnt);
				if bitcnt = 0 then
					state <= DATAs;
					bitcnt := 8;
				else
					bitcnt := bitcnt - 1;
				end if;
			when DATAs =>
				if bitcnt = 0 then
					state <= IDLEs;
					cs <= '1';
					data_ready <= '1';
					shift_in <= '0';
				else
					bitcnt := bitcnt - 1;
					shift_in <= '1';
				end if;
		end case;
	end if;
end process;

spi_shift_in: process(clk, resetn, shift_in, so)
	variable shiftcnt: natural;
begin
		if resetn = '0' then
			shiftcnt := 0;
		elsif shift_in = '1' and shiftcnt < 8 then
			if clk'event and clk = '0' then
				data(7-shiftcnt) <= so;
				shiftcnt := shiftcnt + 1;
			end if;
		else
			shiftcnt := 0;
		end if;
end process;

end rtl;
