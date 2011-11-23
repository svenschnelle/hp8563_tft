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


library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;


entity lpc is
  port (
     --system signals
    lreset_n   : in  std_logic;
    lclk       : in  std_logic;
	--LPC bus from host
    lad_i      : in  std_logic_vector(3 downto 0);
    lad_o      : out std_logic_vector(3 downto 0);
    lad_oe     : out std_logic;
    lframe_n   : in  std_logic;
	--memory interface
    lpc_addr   : out std_logic_vector(23 downto 0); --shared address
    lpc_data_i : in  std_logic_vector(7 downto 0);
    lpc_val    : out std_logic;
    lpc_ack    : in  std_logic);
end lpc;

architecture rtl of lpc is
type state is (RESETs,STARTs,ADDRs,TARs,SYNCs,DATAs,LOCAL_TARs);  -- simple LCP states

signal CS : state;
signal r_lad   : std_logic_vector(3 downto 0);
signal r_addr  : std_logic_vector(27 downto 0);  --should consider saving max
                                                --adress 23 bits on flash
signal r_cnt   : std_logic_vector(2 downto 0);

constant START_FW_READ : std_logic_vector(3 downto 0):="1101";
constant START_LPC     : std_logic_vector(3 downto 0):="0000";
constant IDSEL_FW_BOOT : std_logic_vector(3 downto 0):="0000";  --0000 is boot device on ThinCan
constant MSIZE_FW_1B   : std_logic_vector(3 downto 0):="0000";  --0000 is 1 byte read
constant SYNC_OK       : std_logic_vector(3 downto 0):="0000";  --sync done
constant SYNC_WAIT     : std_logic_vector(3 downto 0):="0101";  --sync wait device holds the bus
constant SYNC_LWAIT    : std_logic_vector(3 downto 0):="0110";  --sync long wait expected device holds the bus
constant TAR_OK        : std_logic_vector(3 downto 0):="1111";  --accepted tar constant for master and slave

begin  -- rtl

--Pass the whole LPC address to the system
lpc_addr <= r_addr(23 downto 0);

-- purpose: LPC IO write/LPC MEM read/LPC FW read  handler
-- type   : sequential
-- inputs : lclk, lreset_n
-- outputs: 
LPC: process (lclk, lreset_n)
begin  -- process LPC
	if lreset_n = '0' then                -- asynchronous reset (active low)
		CS <= RESETs;
		lad_oe <= '0';
		lad_o <= x"0";
		lpc_val <='0';
		r_lad <= (others=>'0');
		r_addr <= (others=>'0');
		r_cnt <= (others=>'0');
	elsif lclk'event and lclk = '1' then
		case CS is
			 when RESETs =>
				lpc_val <='0';
				if lframe_n='0' then
					CS <= STARTs;
					r_lad <= lad_i;
				else
					CS <= RESETs;
				end if;
			when STARTs =>
				if lframe_n = '0' then
					r_lad <= lad_i;
					CS <= STARTs;
				elsif r_lad = START_FW_READ then
					CS <= ADDRs;
					r_cnt <= "000";
				else
					CS<= RESETs;
				end if;
			when ADDRs =>
				if r_cnt ="111" then
					r_cnt <= "000";
					lpc_val <='1';
					if lad_i = MSIZE_FW_1B then
						CS<=TARs;
					else
						--over byte fw read not supported
						CS<=RESETs;
					end if;
				else
					r_addr<= r_addr(23 downto 0) & lad_i;  --28 bit address is given
					r_cnt <= r_cnt + 1;
					CS<=ADDRs;
				end if;
			when DATAs =>
				if r_cnt ="001" then
					lad_o <= lpc_data_i(7 downto 4);
					r_cnt <= "000";
					CS <= LOCAL_TARs;
				else
					lad_o <= lpc_data_i(3 downto 0);
					r_cnt<=r_cnt + 1;
					CS <= DATAs;
				end if;
			when TARs =>
				lpc_val <='0';
				CS <= SYNCs;
				r_cnt <= "000";
				if r_cnt ="001" then
					if lpc_ack='0' then
						lad_o <= SYNC_LWAIT;
					end if;
					lad_oe <= '1';
				elsif lad_i = TAR_OK then
					r_cnt<=r_cnt + 1;
					lad_o <= TAR_OK;
					CS <= TARs;
				else
					CS <= RESETs;
				end if;
			when SYNCs =>
				if lpc_ack='1' then
					lad_o <= SYNC_OK;
					lpc_val <='0';
					CS <= DATAs;
					end if;
			when LOCAL_TARs =>
				if r_cnt ="000" then
					lad_o <= TAR_OK;
					r_cnt <= r_cnt + 1;
				else
					lad_oe <= '0';
					r_cnt <="000";
					CS <= RESETs;
				end if;
		end case;
	end if;
end process LPC;

end rtl;
