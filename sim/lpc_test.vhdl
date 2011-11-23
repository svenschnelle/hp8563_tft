------------------------------------------------------------------
-- Universal dongle board source code
--
-- Copyright (C) 2006 Artec Design <jyrit@artecdesign.ee>
--
-- This source code is free hardware; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This source code is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
--
--
-- The complete text of the GNU Lesser General Public License can be found in
-- the file 'lesser.txt'.
--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   17:35:11 10/09/2006
-- Design Name:   lpc_iow
-- Module Name:   C:/projects/USB_dongle/beh/lpc_byte_test.vhd
-- Project Name:  simulation
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: lpc_iow
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY top_tb IS
END top_tb;

ARCHITECTURE behavior OF top_tb IS

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT lpc
	PORT(
		lreset_n : IN std_logic;
		lclk : IN std_logic;
		lad_i : IN std_logic_vector(3 downto 0);
		lframe_n : IN std_logic;
		lpc_data_i : IN std_logic_vector(7 downto 0);
		lpc_ack : IN std_logic;
		lad_o : OUT std_logic_vector(3 downto 0);
		lad_oe : OUT std_logic;
		lpc_addr : OUT std_logic_vector(23 downto 0);
		lpc_val : OUT std_logic
		);
	END COMPONENT;

	component spi
		port(address: in std_logic_vector(23 downto 0);
		     data: out std_logic_vector(7 downto 0);
		     data_ready: out std_logic;
		     cycle_start: in std_logic;
		     resetn: in std_logic;
		     clk: in std_logic;
		     -- SPI signals
		     si: out std_logic;
		     so: in std_logic;
		     cs: out std_logic);
	end component;

	component s25fl032a
		generic(mem_file_name: string;
			userpreload: BOOLEAN);
		port(sck: in std_ulogic;
		     si: in std_ulogic;
		     csneg: in std_ulogic;
		     holdneg: in std_ulogic;
		     wneg: in std_ulogic;
		     so: out std_ulogic);
	end component;
	--Inputs
	SIGNAL lreset_n :  std_logic := '0';
	SIGNAL lclk :  std_logic := '0';

	--SIGNAL   lena_mem_r : std_logic:='1';  --enable lpc regular memory read cycles also (default is only LPC firmware read)
	--SIGNAL   lena_reads : std_logic:='1';  --enable read capabilities

	SIGNAL lframe_n :  std_logic := '1';
	SIGNAL lpc_ack :  std_logic := '0';
	SIGNAL lad_i :  std_logic_vector(3 downto 0) := (others=>'0');
	SIGNAL lpc_data_i :  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL lad_o :  std_logic_vector(3 downto 0);
	SIGNAL lad_oe :  std_logic;
	SIGNAL lpc_addr :  std_logic_vector(23 downto 0);
	SIGNAL lpc_data_o :  std_logic_vector(7 downto 0);
	SIGNAL lpc_val :  std_logic;
	signal cs: std_ulogic;
	signal si: std_ulogic;
	signal so: std_ulogic;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	lpc0: lpc port map(
		lreset_n => lreset_n,
		lclk => lclk,
		lad_i => lad_i,
		lad_o => lad_o,
		lad_oe => lad_oe,
		lframe_n => lframe_n,
		lpc_addr => lpc_addr,
		lpc_data_i => lpc_data_i,
		lpc_val => lpc_val,
		lpc_ack => lpc_ack
	);

	spi0: spi port map(
		resetn => lreset_n,
		clk => lclk,
		address => lpc_addr,
		data => lpc_data_i,
		data_ready => lpc_ack,
		cycle_start => lpc_val,
		si => si,
		so => so,
		cs => cs);

	spiflash: s25fl032a
		generic map(mem_file_name => "mem_contents",
			userpreload => TRUE)
		port map(
			si => si,
			so => so,
			csneg => cs,
			sck => lclk,
			holdneg => '1',
			wneg => '1');

 clocker : process is
  begin
    wait for 15 ns;
    lclk <=not (lclk);
  end process clocker;

  tb : PROCESS
	BEGIN

		-- Wait 100 ns for global reset to finish
		wait for 500 ns;
			lreset_n <='1';
		-- Place stimulus here
		wait until lclk='0'; --cycle 1
		wait until lclk='1';
		lad_i <= x"D";
		lframe_n <='0';
		wait until lclk='0'; --cycle 2
		wait until lclk='1';
		lad_i <= x"0";--			IDSEL
		lframe_n <='1';
		wait until lclk='0'; --cycle 3
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 0
		wait until lclk='0'; --cycle 4
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 1
		wait until lclk='0'; --cycle 5
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 2
		wait until lclk='0'; --cycle 6
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 3
		wait until lclk='0'; --cycle 7
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 4
		wait until lclk='0'; --cycle 8
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 5
		wait until lclk='0'; --cycle 9
		wait until lclk='1';
		lad_i <=x"0";			--address nibble 6
		wait until lclk='0'; --cycle 10
		wait until lclk='1';
		lad_i <=x"0";			-- msize
		wait until lclk='0'; --cycle 11
		wait until lclk='1';
		lad_i <= x"f";
		if lad_oe='0' then  --TAR 2
		else
			report "LPC error found on TAR cycle no 0xF on lad_o";
			lframe_n <='0';
		end if;
		wait until lclk='0'; --cycle 11
		wait until lclk='1';
		lad_i <= "ZZZZ";
      wait until lad_o=x"6";
      while(lad_o=x"6") loop
         wait until lclk='0'; --cycle 11
         wait until lclk='1';
      end loop;
		if (lad_o=x"0") and lad_oe='1' then --SYNC
		else
			report "LPC error found on SYNC cycle no 0x0 on lad_o";
			lframe_n <='0';
		end if;
		wait until lclk='0'; --cycle 12
		wait until lclk='1';
		if (lad_o=x"F") and lad_oe='1' then --TARL 1
		else
			report "LPC error found on TAR_L cycle no 0xF on lad_o";
			lframe_n <='0';
		end if;
		wait until lclk='0'; --cycle 13
		wait until lclk='1';
		lad_i <=x"F";			--TARL 2
		lframe_n <='1';
		wait; -- will wait forever
	END PROCESS;

END;
