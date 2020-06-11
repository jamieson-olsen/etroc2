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
generic(ROW,COL: integer range 0 to 15);
port(
    clock: in std_logic;
	reset: in std_logic;
	l1acc: in std_logic;
    din:   in tdc_data_type;
    dout:  out pixel_data_type
  );
end pixel;

architecture pixel_arch of pixel is

type memory_t is array((2**PIX_BUF_ADDR_WIDTH)-1 downto 0) of tdc_data_type;
signal memory : memory_t;
signal tdc_out_reg: tdc_data_type;
signal wptr, rptr: std_logic_vector(PIX_BUF_ADDR_WIDTH-1 downto 0) := (others=>'0');
signal enum_reg: std_logic_vector( (pixel_data_type.enum'length-1) downto 0) := (others=>'0');

begin


write_proc: process(clock) -- sync write into buffer
begin
	if rising_edge(clock) then

		if (reset='1') then

			wptr <= (others=>'0');
			rptr <= (others=>'0');

		else

			wptr <= std_logic_vector(unsigned(wptr) + 1);
			rptr <= std_logic_vector(unsigned(wptr) - L1ACC_OFFSET);
	
			if (unsigned(din.tot) > TOT_THRESHOLD) then
				memory( to_integer(unsigned(wptr)) ) <= din; -- store tdc data in circ buffer
			else
				memory( to_integer(unsigned(wptr)) ) <= null_tdc_data; -- write all zeros to circ buffer
			end if;
	
		end if;
	end if;
end process write_proc;

-- register the output
-- as pixel data leaves this module it is tagged with ROW, COL, and EventNumber information
-- note the event number simply increments with each L1Acc and is NOT the BCID. this number
-- helps the merge modules determine which TDC pixel value is OLDER

out_proc: process(clock) 
begin
	if rising_edge(clock) then
		if (reset='1') then
			enum_reg <= (others=>'0');
			tdc_out_reg <= null_tdc_data;
		else

			if (l1acc='1') then
				enum_reg <= std_logic_vector(unsigned(enum_reg)+1);
				tdc_out_reg <= memory( to_integer(unsigned(rptr)) );
			else
				tdc_out_reg <= null_tdc_data;
			end if;
		end if;
	end if;
end process out_proc;

dout.valid <= tdc_out_reg.valid;
dout.tot  <= tdc_out_reg.tot;
dout.toa  <= tdc_out_reg.toa;
dout.cal  <= tdc_out_reg.cal;
dout.row  <= std_logic_vector( to_unsigned(ROW,4) );
dout.col  <= std_logic_vector( to_unsigned(COL,4) );
dout.enum <= enum_reg;

end pixel_arch;
