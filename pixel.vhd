-- pixel.vhd
-- this is just a circular buffer, the read and write pointers are internal to this module
-- the RAM is written on every clock (if din.tot < TOT_THRESH then zeros are written into RAM)
-- and the RAM is read on every clock. the event counter is calculated here and increments with L1acc.
-- this is very simple scheme for generating the event counter bits and rollover comparison
-- errors can occur in the merge cells (e.g. is event 4 older or newer than 7?)
--
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.etroc2_package.all;

entity pixel is
generic(ROW,COL: integer range 0 to 3);
port(
    clock: in std_logic;
	l1acc: in std_logic;
    din:   in tdc_data_type;
    dout:  out pixel_data_type
  );
end pixel;

architecture pixel_arch of pixel is

type memory_t is array(0 to 2**PIX_BUF_ADDR_WIDTH-1) of pixel_data_type;
signal memory : memory_t;
signal temp: pixel_data_type;
signal wptr, rptr: integer range 0 to (2**PIX_BUF_ADDR_WIDTH-1);
signal enum_reg: std_logic_vector( (pixel_data_type.enum'length-1) downto 0) := (others=>'0');

begin

temp.valid <= din.valid;
temp.tot   <= din.tot;
temp.toa   <= din.toa;
temp.cal   <= din.cal;
temp.row   <= std_logic_vector( to_unsigned(ROW,4) );
temp.col   <= std_logic_vector( to_unsigned(COL,4) );
temp.enum  <= enum_reg;

write_proc: process(clock) -- sync write into buffer
begin
	if rising_edge(clock) then

		wptr <= wptr + 1;
		rptr <= wptr - L1ACC_OFFSET;

		if (unsigned(temp.tot) > TOT_THRESHOLD) then
			memory(wptr) <= temp; -- store tdc data in circ buffer
		else
			memory(wptr) <= null_pixel_data; -- write all zeros to circ buffer
		end if;

		if (l1acc='1') then
			enum_reg <= std_logic_vector(unsigned(enum_reg)+1); -- this event counter simply increments with l1acc
		end if;

	end if;
end process write_proc;

-- async read from buffer

dout <= memory(rptr) when (l1acc='1') else null_pixel_data;

end pixel_arch;
