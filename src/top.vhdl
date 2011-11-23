library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity top is
  port (lreset_n: in  std_logic;
        lclk: in  std_logic;
        lad: inout std_logic_vector(3 downto 0);
        lframe_n: in std_logic;
        spi_cs: out std_logic;
        spi_si: out std_logic;
        spi_so: in std_logic;
        spi_clk: out std_logic);
end top;

architecture rtl of top is
	signal lpc_data_in: std_logic_vector(7 downto 0);
	signal lpc_lad_in: std_logic_vector(3 downto 0);
	signal lpc_lad_out: std_logic_vector(3 downto 0);
	signal lpc_lad_oe: std_logic;
	signal lpc_val: std_logic;
	signal lpc_ack: std_logic;
	signal lpc_address: std_logic_vector(23 downto 0);

	component lpc
		port(
			lreset_n: in std_logic;
			lclk: in std_logic;
			lad_i: inout std_logic_vector(3 downto 0);
			lad_o: out std_logic_vector(3 downto 0);
			lad_oe: out std_logic;
			lframe_n: in std_logic;
			lpc_addr: out std_logic_vector(23 downto 0);
			lpc_data_i: in std_logic_vector(7 downto 0);
			lpc_val: out std_logic;
			lpc_ack: in std_logic);
	end component;
	
	component spi
		port(
			resetn: in std_logic;
			clk: in std_logic;
			address: in std_logic_vector(23 downto 0);
			data: out std_logic_vector(7 downto 0);
			data_ready: out std_logic;
			cycle_start: in std_logic;
			so: in std_logic;
			si: out std_logic;
			cs: out std_logic);
	end component;
begin
	lpc0: lpc port map(
		lreset_n => lreset_n,
		lclk => lclk,
		lad_i => lpc_lad_in,
		lad_o => lpc_lad_out,
		lad_oe => lpc_lad_oe,
		lframe_n => lframe_n,
		lpc_val => lpc_val,
		lpc_ack => lpc_ack,
		lpc_data_i => lpc_data_in,
		lpc_addr => lpc_address);
		
	spi0: spi port map(
		resetn => lreset_n,
		clk => lclk,
		address => lpc_address,
		data => lpc_data_in,
		cycle_start => lpc_val,
		data_ready => lpc_ack,
		si => spi_si,
		so => spi_so,
		cs => spi_cs);
		

lad <= lpc_lad_out when lpc_lad_oe = '1' else (others => 'Z');
lpc_lad_in <= lad;
spi_clk <= lclk;

end rtl;
