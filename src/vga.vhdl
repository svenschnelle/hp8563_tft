library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga is
	port (clk_i: in std_logic;
	      dclk_o: out std_logic;
	      reset_i: in boolean;
	      vsync_o: out std_logic;
	      hsync_o: out std_logic;
	      vblank_o: out boolean;
	      r_o: out std_logic_vector(2 downto 0);
	      g_o: out std_logic_vector(2 downto 0);
	      b_o: out std_logic_vector(2 downto 0);
	      hblank_o: out boolean;
	      ram_addr_o: out integer range 0 to 640*480;
	      ram_data_i: in std_logic_vector(15 downto 0));
end vga;

architecture rtl of vga is

signal ram_addr_s: integer := 0;
signal ram_addr_delayed_s: integer := 0;
signal display_addr_s: integer := 0;
signal hsync_s: boolean;
signal hsync_prev_s: boolean;
signal vsync_s: boolean;
signal hblank_s: boolean;
signal vblank_s: boolean;
signal display_clk_s: std_logic;
signal color_s: std_logic_vector(8 downto 0);
type color_type is array (0 to 15) of std_logic_vector(8 downto 0);

constant colors : color_type := (
	-- R      G       B
	"000" & "000" & "000", -- 0
	"000" & "000" & "100", -- 1
	"100" & "000" & "000", -- 2
	"100" & "000" & "100", -- 3
	"000" & "111" & "000", -- 4
	"000" & "100" & "100", -- 5
	"100" & "100" & "000", -- 6
	"110" & "110" & "110", -- 7
	"000" & "000" & "000", -- 8
	"000" & "000" & "111", -- 9
	"111" & "000" & "000", -- 10
	"111" & "000" & "111", -- 11
	"111" & "100" & "100", -- 12
	"000" & "111" & "111", -- 13
	"111" & "111" & "000", -- 14
	"111" & "111" & "111"  -- 15
	);

begin

hsync_o <= '0' when hsync_s else '1';
vsync_o <= '0' when vsync_s else '1';
hblank_o <= hblank_s;
vblank_o <= vblank_s;
dclk_o <= display_clk_s;
ram_addr_o <= ram_addr_s/4;

b_o <= (others => '0') when hblank_s or vblank_s else color_s(2 downto 0);
g_o <= (others => '0') when hblank_s or vblank_s else color_s(5 downto 3);
r_o <= (others => '0') when hblank_s or vblank_s else color_s(8 downto 6);

process(reset_i, clk_i)
variable clkdiv: integer;
begin
	if (reset_i) then
		display_clk_s <= '0';
		clkdiv := 0;
	elsif (rising_edge(clk_i)) then
		display_clk_s <= not display_clk_s;
	end if;
end process;

color_s <= colors(to_integer(unsigned(ram_data_i(3 downto 0)))) when ram_addr_delayed_s mod 4 = 3 else
	   colors(to_integer(unsigned(ram_data_i(7 downto 4)))) when ram_addr_delayed_s mod 4 = 2 else
	   colors(to_integer(unsigned(ram_data_i(11 downto 8)))) when ram_addr_delayed_s mod 4 = 1 else
	   colors(to_integer(unsigned(ram_data_i(15 downto 12)))) when ram_addr_delayed_s mod 4 = 0 else
	   (others => '0');

hsynccnt: process(reset_i, display_clk_s)
variable hcnt: integer range 0 to 820;
begin
	if (reset_i) then
		hcnt := 0;
		hsync_s <= false;
		hblank_s <= false;
	elsif (rising_edge(display_clk_s)) then
		hblank_s <= hcnt > 639;
		hsync_s <= hcnt > 690 and hcnt < 750;

		if (hcnt < 800) then
			hcnt := hcnt + 1;
		else
			hcnt := 0;
		end if;

		if (not hblank_s and not vblank_s and ram_addr_s < 640*480-1) then
			ram_addr_s <= ram_addr_s + 1;
		elsif (vblank_s) then
			ram_addr_s <= 0;
		end if;
		ram_addr_delayed_s <= ram_addr_s;
	end if;
end process;

vsynccnt: process(reset_i, display_clk_s)
variable vcnt: integer range 0 to 525;
begin
	if (reset_i) then
		vcnt := 0;
		vblank_s <= false;
		vsync_s <= false;
	elsif (rising_edge(display_clk_s)) then
		hsync_prev_s <= hsync_s;
		if (not hsync_prev_s and hsync_s) then
			if (vcnt < 525) then
				vcnt := vcnt + 1;
			else
				vcnt := 0;
			end if;
		end if;
		vblank_s <= vcnt > 479;
		vsync_s <= vcnt > 490 and vcnt < 500;
	end if;
end process;

end rtl;
