library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity linedraw is
	port(clk_i: in std_logic;
	     reset_i: in boolean;
	     color_i: in std_logic_vector(3 downto 0);
	     x1_i: in integer;
	     y1_i: in integer;
	     x2_i: in integer;
	     y2_i: in integer;
	     req_i: in boolean;
	     rdy_o: out boolean;
	     ramaddr_o: out integer range 0 to 640*480-1;
	     ramdata_o: out std_logic_vector(15 downto 0);
	     ramdata_i: in std_logic_vector(15 downto 0);
	     ram_rdy_i: in boolean;
	     ram_we_o: out boolean);
end linedraw;

architecture rtl of linedraw is
signal ramaddr_s: integer := 0;
begin

ramaddr_o <= ramaddr_s / 4;

draw: process(reset_i, clk_i)
type state_t is (IDLE, XCH, XCH1, DRAW_READ, DRAW_WAIT, DRAW_WRITE);
variable state: state_t;
variable cur_x: integer := 0;
variable c1: boolean;
variable dx, t, x1, x2, x, y,y1, y2, dy: integer range 0 to 639 := 0;
variable incy: integer range -1 to 1 := 0;
variable e, horiz, diago: integer;
begin
	if (reset_i) then
		state := IDLE;
		rdy_o <= true;
		ram_we_o <= false;
	elsif (rising_edge(clk_i)) then
		case state is
			when IDLE =>
				ram_we_o <= false;
				if (req_i) then
					x1 := x1_i;
					x2 := x2_i;
					y1 := y1_i;
					y2 := y2_i;

					rdy_o <= false;
					state := XCH;
				else
					rdy_o <= true;
				end if;
			when XCH =>
				if (x2_i > x1_i) then
					dx := x2_i - x1_i;
				else
					dx := x1_i - x2_i;
				end if;

				if (y2_i > y1_i) then
					dy := y2_i - y1_i;
				else
					dy := y1_i - y2_i;
				end if;
				state := XCH1;
			when XCH1 =>
				if (dy > dx) then
					c1 := true;
					t := y2;
					y2 := x2;
					x2 := t;

					t := y1;
					y1 := x1;
					x1 := t;

					t := dx;
					dx := dy;
					dy := t;
				else
					c1 := false;
				end if;

				if (x1 > x2) then
					t := y2;
					y2 := y1;
					y1 := t;

					t := x1;
					x1 := x2;
					x2 := t;
				end if;

				horiz := dy * 2;
				diago := (dy - dx) * 2;
				e := dy * 2 - dx;

				if (y1 <= y2) then
					incy := 1;
				else
					incy := -1;
				end if;

				x := x1;
				y := y1;
				state := DRAW_READ;
			when DRAW_READ =>
				ram_we_o <= false;
				if (x = x2) then
					state := IDLE;
					rdy_o <= true;
				else

					if (c1) then
						ramaddr_s <= ((x * 640) + y);
					else
						ramaddr_s <= ((y * 640) + x);
					end if;
					state := DRAW_WAIT;
				end if;
			when DRAW_WAIT =>
				if (ram_rdy_i) then
					state := DRAW_WRITE;
				end if;
			when DRAW_WRITE =>
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

--				if (ramdata_i = color_i) then
--					ramdata_o <= '1' & ramdata_i(2 downto 0);
--				else
--					ramdata_o <= color_i;
--				end if;
				if (ram_rdy_i) then
					if (e > 0) then
						y := y + incy;
						e := e + diago;
					else
						e := e + horiz;
					end if;
					x := x + 1;
					state := DRAW_READ;
				end if;
		end case;
	end if;
end process;
end rtl;
