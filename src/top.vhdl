	library ieee;
	use ieee.std_logic_1164.all;
	use IEEE.numeric_std.all;

	entity top is
		port (clk: in std_logic;
		      -- lcd port
		      vsync_o: out std_logic;
		      hsync_o: out std_logic;
		      enable: out std_logic;
		      dclk: out std_logic;
		      r: out std_logic_vector(1 downto 0);
		      g: out std_logic_vector(1 downto 0);
		      b: out std_logic_vector(1 downto 0);
		      -- cpu
		      cpu_clk: in std_logic;
		      cpu_addr: in std_logic_vector(12 downto 0);
		      cpu_data: in std_logic_vector(15 downto 0);
		      cpu_wel: in std_logic;
		      cpu_weh: in std_logic;
		      -- sram
		      sram_addr: out std_logic_vector(19 downto 0);
		      sram_data: inout std_logic_vector(15 downto 0);
		      sram_oe: out std_logic;
		      sram_we: out std_logic;
		      sram_bhe: out std_logic;
		      sram_ble: out std_logic;
		      -- debug
		      led1: out std_logic);
	end top;

	architecture rtl of top is
	-- component DCM is
	-- 	port (CLKIN_IN: in std_logic;
	-- 	RST_IN: in std_logic;
	-- 	CLKDV_OUT: out std_logic;
	-- 	CLKFX_OUT: out std_logic;
	-- 	CLK2X_OUT: out std_logic;
	-- 	CLK0_OUT: out std_logic;
	-- 	LOCKED_OUT: out std_logic);
	-- end component;

	component dpram is
		generic(arraysize: integer;
			wordsize: integer);
		port (write_clock_i: in std_logic;
		      write_data_i: in std_logic_vector(wordsize-1 downto 0);
		      write_addr_i: in integer range 0 to arraysize - 1;
		      write_i: in std_logic;
		      read_clock_i: in std_logic;
		      read_addr_i: in integer range 0 to arraysize - 1;
		      read_data_o: out std_logic_vector(wordsize-1 downto 0)
	);
	end component;

	component testrom is
	port(read_clock_i: in std_logic;
		read_addr_i: in integer range 0 to 8191;
		read_data_o: out std_logic_vector(15 downto 0)
	     );
	end component;

	component vga is
		port (clk_i: in std_logic;
		      dclk_o: out std_logic;
		      reset_i: in boolean;
		      vsync_o: out std_logic;
		      hsync_o: out std_logic;
		      vblank_o: out boolean;
		      hblank_o: out boolean;
		      r_o: out std_logic_vector(1 downto 0);
		      g_o: out std_logic_vector(1 downto 0);
		      b_o: out std_logic_vector(1 downto 0);
		      ram_addr_o: out integer range 0 to 640*480;
		      ram_data_i: in std_logic_vector(15 downto 0));
	end component;

	component charmap is
		port (input: in std_logic_vector(11 downto 0);
		      output: out integer range 0 to 255);
	end component;

	component charcopy is
		port(clk_i: in std_logic;
		     reset_i: in boolean;
		     char_i: in integer;
		     color_i: in std_logic_vector(3 downto 0);
		     dstx_i: in integer;
		     dsty_i: in integer;
		     req_i: in boolean;
		     rdy_o: out boolean;
		     ramaddr_o: out integer range 0 to 640*480;
		     ramdata_o: out std_logic_vector(15 downto 0);
		     ramdata_i: in std_logic_vector(15 downto 0);
		     ram_we_o: out boolean;
		     ram_rdy_i: in boolean);
	end component;

	component linedraw is
		port(clk_i: in std_logic;
		     reset_i: in boolean;
		     color_i: in std_logic_vector(3 downto 0);
		     x1_i: in integer;
		     y1_i: in integer;
		     x2_i: in integer;
		     y2_i: in integer;
		     req_i: in boolean;
		     rdy_o: out boolean;
		     ramaddr_o: out integer range 0 to 640*480;
		     ramdata_o: out std_logic_vector(15 downto 0);
		     ramdata_i: in std_logic_vector(15 downto 0);
		     ram_rdy_i: in boolean;
		     ram_we_o: out boolean);
	end component;

	signal write_ram_addr_s: integer range 0 to 8191 := 0;
	signal read_addr_s: integer range 0 to 8191 := 0;
	signal read_data_s: std_logic_vector(15 downto 0);
	signal fb_write: std_logic;

	signal hblank_s: boolean;
	signal vblank_s: boolean;

	signal reset_s: boolean;
	signal font_data_s: std_logic_vector(15 downto 0);
	signal font_addr_s: std_logic_vector(11 downto 0);

	signal vga_ram_addr_s: integer := 0;
	signal vga_ram_data_s: std_logic_vector(15 downto 0);
	signal vga_display_clk_s: std_logic;

	signal render_addr_s: integer range 0 to 640*480 := 0;
	signal render_we_s: boolean;
	signal render_write_data_s: std_logic_vector(15 downto 0);

	signal charmap_output_s: integer range 0 to 255;
	signal charmap_input_s: std_logic_vector(11 downto 0);

	signal charcopy_color_s: std_logic_vector(3 downto 0) := x"7";
	signal charcopy_dstx_s: integer;
	signal charcopy_dsty_s: integer;
	signal charcopy_req_s: boolean;
	signal charcopy_rdy_s: boolean;
	signal charcopy_ram_addr_s: integer;
	signal charcopy_ramdata_out_s: std_logic_vector(15 downto 0);
	signal charcopy_ram_we_s: boolean;

	signal linedraw_color_s: std_logic_vector(3 downto 0) := x"f";
	signal linedraw_req_s: boolean;
	signal linedraw_rdy_s: boolean;
	signal linedraw_ram_addr_s: integer;
	signal linedraw_ramdata_out_s: std_logic_vector(15 downto 0);
	signal linedraw_ram_we_s: boolean;
	signal linedraw_ram_rdy_s: boolean;

	signal dstx_s: integer range 0 to 1023 := 512;
	signal dsty_s: integer range 0 to 1023 := 512;
	signal curx_s: integer range 0 to 1023 := 512;
	signal cury_s: integer range 0 to 1023 := 512;

	signal dstx_scaled_s: integer range 0 to 1023 := 0;
	signal dsty_scaled_s: integer range 0 to 1023 := 0;
	signal curx_scaled_s: integer range 0 to 1023 := 0;
	signal cury_scaled_s: integer range 0 to 1023 := 0;

	signal vblank_prev_s: boolean;

	signal rambank0_active_s: boolean;

	signal linedraw_active_s: boolean;
	signal charcopy_active_s: boolean;

	signal fbram_write_s: boolean;
	signal fbram_read_s: boolean;
	signal fbram_tmp_write_s: boolean;
	signal fbram_addr_s: integer := 0;-- range 0 to 640*480;
	signal fbram_read_data_s: std_logic_vector(15 downto 0);
	signal fbram_write_data_s: std_logic_vector(15 downto 0);
	signal fbram_tmp_write_data_s: std_logic_vector(15 downto 0);
	signal fbram_tmp_addr: integer;
	signal ram_rdy_s: boolean;
	signal plotx: integer;
	signal plotconfig_s: std_logic_vector(7 downto 0);
	signal dpaddr: integer range 0 to 8191 := 0;
	signal dpaddr_next: integer range 0 to 8191 := 0;
	constant XINIT: integer := 60;

	-- signal dcm_clkdv_s: std_logic;
	-- signal dcm_clkfx_s: std_logic;
	-- signal dcm_clk0_s: std_logic;
	-- signal dcm_locked_s: std_logic;
	-- signal dcm_reset_s: std_logic;

	type render_state_t is (IDLE, CLEAR_RAM, CLEAR_RAM2, FETCH, FETCH2, EXECUTE, CHARCOPY_WAIT, CHARCOPY_WAIT1, LINEDRAW_WAIT, LINEDRAW_WAIT1);

	begin
		-- dcmi: DCM port map(
		-- 	CLKIN_IN => clk50,
		-- 	RST_IN => dcm_reset_s,
		-- 	CLKDV_OUT => dcm_clkdv_s,
		-- 	CLKFX_OUT => dcm_clkfx_s,
		-- 	CLK2X_OUT => clk,
		-- 	CLK0_OUT => dcm_clk0_s,
		-- 	LOCKED_OUT => dcm_locked_s);

		ram0: dpram generic map(
			wordsize => 8,
			arraysize => 8192)
			port map(
				write_clock_i => cpu_clk,
				write_data_i => cpu_data(7 downto 0),
				write_addr_i => write_ram_addr_s,
				write_i => cpu_wel,
				read_clock_i => clk,
				read_addr_i => read_addr_s,
				read_data_o => read_data_s(7 downto 0));
		ram1: dpram generic map(
			wordsize => 8,
			arraysize => 8192)
			port map(
				write_clock_i => cpu_clk,
				write_data_i => cpu_data(15 downto 8),
				write_addr_i => write_ram_addr_s,
				write_i => cpu_weh,
				read_clock_i => clk,
				read_addr_i => read_addr_s,
				read_data_o => read_data_s(15 downto 8));

		charmapi: charmap port map(
			input => charmap_input_s,
			output => charmap_output_s);

		charcopyi: charcopy port map(
			clk_i => clk,
			reset_i => reset_s,
			char_i => charmap_output_s,
			color_i => charcopy_color_s,
			dstx_i => curx_scaled_s,
			dsty_i => cury_scaled_s,
			req_i => charcopy_req_s,
			rdy_o => charcopy_rdy_s,
			ramaddr_o => charcopy_ram_addr_s,
			ramdata_o => charcopy_ramdata_out_s,
			ramdata_i => sram_data(15 downto 0),
			ram_we_o => charcopy_ram_we_s,
			ram_rdy_i => ram_rdy_s);

		linedrawi: linedraw port map(
			clk_i => clk,
			reset_i => reset_s,
			color_i => linedraw_color_s,
			x1_i => curx_scaled_s,
			y1_i => cury_scaled_s,
			x2_i => dstx_scaled_s,
			y2_i => dsty_scaled_s,
			req_i => linedraw_req_s,
			rdy_o => linedraw_rdy_s,
			ramaddr_o => linedraw_ram_addr_s,
			ramdata_o => linedraw_ramdata_out_s,
			ramdata_i =>sram_data(15 downto 0),
			ram_rdy_i => ram_rdy_s,
			ram_we_o => linedraw_ram_we_s);

		vgai: vga port map(
			clk_i => clk,
			dclk_o => vga_display_clk_s,
			reset_i => reset_s,
			r_o => r,
			g_o => g,
			b_o => b,
			vsync_o => vsync_o,
			hsync_o => hsync_o,
			hblank_o => hblank_s,
			vblank_o => vblank_s,
			ram_addr_o => vga_ram_addr_s,
			ram_data_i => vga_ram_data_s);

--	dcm_reset_s <= '1' when reset_s else '0';
	curx_scaled_s <= ((curx_s * 105) / 128);
	dstx_scaled_s <= ((dstx_s * 105) / 128);
	cury_scaled_s <= (cury_s * 80) / 128;
	dsty_scaled_s <= (dsty_s * 80) / 128;


	write_ram_addr_s <= to_integer(unsigned(cpu_addr));

	fbram_tmp_addr <= charcopy_ram_addr_s when charcopy_active_s else
			  linedraw_ram_addr_s when linedraw_active_s else
			  render_addr_s;

	fbram_tmp_write_s <= true when charcopy_ram_we_s else
			     true when linedraw_ram_we_s else
			     render_we_s;

	fbram_tmp_write_data_s <= charcopy_ramdata_out_s when charcopy_active_s else
			      linedraw_ramdata_out_s when linedraw_active_s else
			      render_write_data_s;

	enable <= '0' when hblank_s else '1';

	dclk <= not vga_display_clk_s;
	sram_ble <= '0';
	sram_bhe <= '0';

	rammux: process(clk)
	variable cnt: integer range 0 to 1;
	begin
		if (rising_edge(clk)) then
			case cnt is
			when 0 =>
				if (rambank0_active_s) then
					sram_addr <= std_logic_vector(to_unsigned(vga_ram_addr_s, sram_addr'length));
				else
					sram_addr <= std_logic_vector(to_unsigned(307200/4 + vga_ram_addr_s, sram_addr'length));
				end if;
				sram_we <= '1';
				sram_oe <= '0';
				sram_data(15 downto 0) <= (others => 'Z');
				ram_rdy_s <= true;
				cnt := 1;
			when 1 =>

				if (rambank0_active_s) then
					sram_addr <= std_logic_vector(to_unsigned(307200/4 + fbram_tmp_addr, sram_addr'length));
				else
					sram_addr <= std_logic_vector(to_unsigned(fbram_tmp_addr, sram_addr'length));
				end if;
				if (fbram_tmp_write_s) then
					sram_we <= '0';
					sram_oe <= '1';
					sram_data <= fbram_tmp_write_data_s;
				else
					sram_we <= '1';
					sram_oe <= '0';
					sram_data <= (others => 'Z');
				end if;

				vga_ram_data_s <= sram_data;


				ram_rdy_s <= false;
				cnt := 0;
			end case;
		end if;
	end process;

	reset: process(clk)
	variable resetcnt: integer range 0 to 1024 := 0;
	begin
		if (rising_edge(clk)) then
			if (resetcnt < 1024) then
				led1 <= '0';
				resetcnt := resetcnt + 1;
				reset_s <= true;
			else
				led1 <= '1';
				reset_s <= false;
			end if;
		end if;
	end process;

render: process(reset_s, clk)

	variable state: render_state_t;
	variable visible: boolean;
	variable x: integer;
	variable y: integer;
	variable autoincx: boolean;
	begin
		if (reset_s) then
			rambank0_active_s <= false;
			state := CLEAR_RAM;
			dstx_s <= 512;
			dsty_s <= 0;
			curx_s <= 512;
			cury_s <= 0;
			autoincx := false;
		elsif (rising_edge(clk)) then
			read_addr_s <= dpaddr;

			case state is
				when IDLE =>
					dpaddr <= 0;
					curx_s <= 512;
					cury_s <= 0;
					dstx_s <= 512;
					dsty_s <= 0;
				when CLEAR_RAM =>
						if (render_addr_s = (640*480/4)-1) then
							state := FETCH;
							render_we_s <= false;
						else
							render_we_s <= true;
							render_write_data_s <= x"0000";
							render_addr_s <= render_addr_s + 1;
							state := CLEAR_RAM2;
						end if;
				when CLEAR_RAM2 =>
					state := CLEAR_RAM;
				when FETCH =>
					vblank_prev_s <= vblank_s;
					if (not vblank_prev_s and vblank_s) then
						rambank0_active_s <= not rambank0_active_s;
						render_addr_s <= 0;
						state := CLEAR_RAM;
						dpaddr <= 0;
					else
						read_addr_s <= dpaddr;
						dpaddr <= dpaddr + 1;
						state := FETCH2;
					end if;
				when FETCH2 =>
					state := EXECUTE;
				when EXECUTE =>
					state := FETCH;
					if (dpaddr < 8191) then
						y := 768-to_integer(unsigned(read_data_s(9 downto 0)));
						if (to_integer(unsigned(read_data_s(9 downto 0))) > 80) then
							x := to_integer(unsigned(read_data_s(9 downto 0))) - 80;
						else
							x := 0;
						end if;
						case read_data_s(15 downto 12) is
							when x"0" | x"1"  =>
								if (visible and read_data_s /= x"0000") then
									dsty_s <= y;
									visible := true;
									linedraw_active_s <= true;
									linedraw_req_s <= true;
									state := LINEDRAW_WAIT;
								else
									cury_s <= y;
									curx_s <= dstx_s;
								end if;
								visible := true;
							when x"2" =>
								autoincx := true;
								if (read_data_s = x"2402") then
									linedraw_color_s <= x"e";
								elsif (read_data_s = x"2405") then
									linedraw_color_s <= x"d";
								elsif (read_data_s = x"2403") then
								end if;

								dsty_s <= y;
								dstx_s <= dstx_s + 1;
								curx_s <= dstx_s;
								cury_s <= dsty_s;
								plotconfig_s <= read_data_s(7 downto 0);
								visible := true;

							when x"3" =>
								linedraw_color_s <= x"d";
								dstx_s <= dstx_s + 1;
								dsty_s <= y;
								curx_s <= dstx_s;
								cury_s <= dsty_s;
								plotconfig_s <= read_data_s(7 downto 0);
								visible := true;

							when x"4" => -- move x visible
								linedraw_color_s <= x"f";
								visible := true;
								dstx_s <= x;

							when x"5" => -- move x visible
								linedraw_color_s <= x"5";
								visible := true;
								dstx_s <= x;

							when x"6" => -- move x invisible?
								linedraw_color_s <= x"b";
								visible := false;
								dstx_s <= x;

							when x"7" => -- move x invisible
								visible := false;
								dstx_s <= x;

							when x"a" =>
								if (read_data_s(11 downto 0) /= x"000") then
									dpaddr <= to_integer(unsigned(read_data_s(11 downto 1)));
								end if;
								visible := false;
							when x"b" =>
								dpaddr <= 2048 + to_integer(unsigned(read_data_s(11 downto 1)));
								visible := false;
							when x"c" => -- char bright
								charcopy_color_s <= x"c";
								charcopy_req_s <= true;
								charmap_input_s <= read_data_s(11 downto 0);
								state := CHARCOPY_WAIT;
								charcopy_active_s <= true;

							when x"d" => -- char
								charcopy_color_s <= x"4";
								charcopy_req_s <= true;
								charmap_input_s <= read_data_s(11 downto 0);
								state := CHARCOPY_WAIT;
								charcopy_active_s <= true;

							when others =>
						end case;
					else
						state := IDLE;
					end if;
				when CHARCOPY_WAIT =>
					if (not charcopy_rdy_s) then
						state := CHARCOPY_WAIT1;
						charcopy_req_s <= false;
					end if;
				when CHARCOPY_WAIT1 =>
					if (charcopy_rdy_s) then
						charcopy_active_s <= false;
						state := FETCH;
						curx_s <= curx_s + 16;
					end if;
				when LINEDRAW_WAIT =>
					if (not linedraw_rdy_s) then
						state := LINEDRAW_WAIT1;
						linedraw_req_s <= false;
					end if;
				when LINEDRAW_WAIT1 =>
					if (linedraw_rdy_s) then
						linedraw_active_s <= false;
						state := FETCH;
						dstx_s <= dstx_s + 1;
						curx_s <= dstx_s;
						cury_s <= dsty_s;
					end if;
			end case;
		end if;
	end process;

end rtl;
