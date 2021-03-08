library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity charcopy is
	port(clk_i: in std_logic;
	     reset_i: in boolean;
	     char_i: in integer;
	     color_i: in std_logic_vector(3 downto 0);
	     dstx_i: in integer;
	     dsty_i: in integer;
	     req_i: in boolean;
	     rdy_o: out boolean;
	     ramaddr_o: out integer range 0 to 640*480-1;
	     ramdata_i: in std_logic_vector(15 downto 0);
	     ramdata_o: out std_logic_vector(15 downto 0);
	     ram_rdy_i: in boolean;
	     ram_we_o: out boolean);
end charcopy;

architecture rtl of charcopy is

component fontrom is
	port(clk_i  : in std_logic;
	     addr_i : in integer;
	     data_o : out std_logic_vector(0 downto 0));
end component;

signal font_addr_s: integer := 0;
signal font_data_s: std_logic_vector(0 downto 0);
signal cur_y: integer := 0;
signal ramaddr_s: integer := 0;
begin
	fontromi: fontrom port map(
		clk_i => clk_i,
		addr_i => font_addr_s,
		data_o => font_data_s
	);


ramaddr_o <= ramaddr_s / 4;

copy: process(reset_i, clk_i)
type state_t is (IDLE, READ, UPDATE_READ, UPDATE_WAIT, UPDATE_WRITE);
variable state: state_t;
variable charstart: integer;
variable cur_x: integer := 0;

begin
	if (reset_i) then
		state := IDLE;
		cur_x := 0;
		cur_y <= 0;
		state := IDLE;
		rdy_o <= true;
		ram_we_o <= false;
	elsif (rising_edge(clk_i)) then

		case state is
			when IDLE =>
				ram_we_o <= false;
				if (req_i) then
					rdy_o <= false;
					state := READ;
					cur_x := 0;
					cur_y <= 0;
					charstart := ((char_i - 32) * 14 * 12);
					font_addr_s <= charstart;
				else
					rdy_o <= true;
				end if;
			when READ =>
				font_addr_s <= font_addr_s + 1;
				ram_we_o <= false;

				if (font_data_s(0) = '1') then
					state := UPDATE_READ;
				else
					if (cur_x = 13) then
						cur_x := 0;
						if (cur_y = 11) then
							state := IDLE;
						else
							cur_y <= cur_y + 1;
							state := READ;
						end if;
					else
						cur_x := cur_x + 1;
						state := READ;
					end if;
				end if;
			when UPDATE_READ =>
				ramaddr_s <= ((dsty_i + cur_y + 3) * 640 + dstx_i + cur_x + 8);
				state := UPDATE_WAIT;
			when UPDATE_WAIT =>
				if (ram_rdy_i) then
					state := UPDATE_WRITE;
				end if;
			when UPDATE_WRITE =>
				ram_we_o <= true;
				case (ramaddr_s mod 4) is
					when 3 =>
						ramdata_o(3 downto 0) <= color_i or ramdata_i(3 downto 0);
						ramdata_o(15 downto 4) <= ramdata_i(15 downto 4);
					when 2 =>
						ramdata_o(3 downto 0) <= ramdata_i(3 downto 0);
						ramdata_o(7 downto 4) <= color_i or ramdata_i(7 downto 4);
						ramdata_o(15 downto 8) <= ramdata_i(15 downto 8);
					when 1 =>
						ramdata_o(7 downto 0) <= ramdata_i(7 downto 0);
						ramdata_o(11 downto 8) <= color_i or ramdata_i(11 downto 8);
						ramdata_o(15 downto 12) <= ramdata_i(15 downto 12);
					when 0 =>
						ramdata_o(11 downto 0) <= ramdata_i(11 downto 0);
						ramdata_o(15 downto 12) <= color_i or ramdata_i(15 downto 12);
					when others =>
				end case;
				if (ram_rdy_i) then
					if (cur_x = 13) then
						cur_x := 0;
						if (cur_y = 11) then
							state := IDLE;
						else
							cur_y <= cur_y + 1;
							state := READ;
						end if;
					else
						cur_x := cur_x + 1;
						state := READ;
					end if;
				end if;
		end case;
	end if;
end process;
end rtl;
