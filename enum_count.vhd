-- enum_count.vhd
--
-- When both FIFOs in a given Merge Module contain hits the Merge Module considers the ENUM tag
-- and always chooses the OLDER of the two hits. Therefore it is critical that the ENUM tag
-- is properly selected and should not roll over, which could result in abiguity (e.g. is 2 older
-- than 7? or the other way around). 
--
-- This module generates the ENUM tag, which is appended to hits as they leave the pixel cells.
-- This module makes an *estimate* of how busy the merge network is based on how often the 
-- L1acc signal is observed.
--
-- If the sytem is idle ENUM is 0. If a L1ACC occurs while the network is busy then ENUM
-- increments. Once the network returns to idle ENUM is reset to zero. In this
-- way ENUM increases monotonically as the merge network aborbs and processes hits and 
-- we don't have to deal with any wrap around problems with ENUM.

-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.etroc2_package.all;

entity enum_count is
port(
    clock: in std_logic;
	reset: in std_logic;
	l1acc: in std_logic;
    enum:  out std_logic_vector(2 downto 0)
  );
end enum_count;

architecture enum_count_arch of enum_count is

signal enum_reg: std_logic_vector(2 downto 0) := (others=>'0');
signal timeout_reg: unsigned(7 downto 0);
type state_type is (rst,idle,busy);
signal state: state_type;

begin

fsm_proc: process(clock) -- sync write into buffer
begin
	if rising_edge(clock) then

		if (reset='1') then

			state <= rst;
            enum_reg <= (others=>'0');
            timeout_reg <= (others=>'0');

		else

            case state is 

                when rst =>
                    state <= idle;

                when idle =>
                    if (l1acc='1') then
                        state <= busy;
                        timeout_reg <= to_unsigned(BUSY_WINDOW,timeout_reg'length);
                        -- enum_reg <= std_logic_vector( unsigned(enum_reg) + 1);
                    else
                        state <= idle;
                        enum_reg <= (others=>'0');
                    end if;

                when busy =>
                    if (l1acc='1') then
                        state <= busy;
                        timeout_reg <= timeout_reg + BUSY_WINDOW;
                        enum_reg <= std_logic_vector( unsigned(enum_reg) + 1);
                    else
                        if (timeout_reg=0) then
                            state <= idle;
                            enum_reg <= (others=>'0');
                        else
                            timeout_reg <= (timeout_reg - 1);
                            state <= busy;
                        end if;
                    end if;

                when others =>
                    state <= rst;

            end case;
		
		end if;
	end if;
end process fsm_proc;

enum <= enum_reg;

end enum_count_arch;
