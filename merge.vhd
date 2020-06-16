-- merge.vhd
-- merges two streams. inputs A and B feed into FIFOs. valid input data is written into the 
-- corresponding FIFO on each clock cycle.

-- Then, selection logic monitors the FIFO outputs and decides which is to be passed on to the output Q. 
-- If both FIFOs are empty, clear the output register.
-- If FIFO A has something and FIFO B does not, read from A and write it into the output register
-- If FIFO B has something and FIFO A does not, read from B and write it into the output register
-- If FIFO A and FIFO B both have something, read from the FIFO with the oldest timestamp (BCID).
--      note: if the BCID values are equal, read from A (slight bias here).
--
-- FIFO full conditions are not checked here
-- Busy output is set if one or both FIFOs have data.

library ieee;
use ieee.std_logic_1164.all;

use work.etroc2_package.all;

entity merge is
generic ( constant FIFO_DEPTH : positive := 4 );
port(
    clock: in  std_logic;
    reset: in  std_logic;
    a,b:   in  pixel_data_type;
    q:     out pixel_data_type
);
end merge;

architecture merge_arch of merge is

component FWFT_FIFO -- generic FIFO
generic( constant DATA_WIDTH  : positive := 8;
	     constant FIFO_DEPTH  : positive := 256 );
port( 
		CLK		: in  STD_LOGIC;
		RST		: in  STD_LOGIC;
		WriteEn	: in  STD_LOGIC;
		DataIn	: in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		ReadEn	: in  STD_LOGIC;
		DataOut	: out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		Empty	: out STD_LOGIC;
		Full	: out STD_LOGIC
	);
end component;

signal din_a, din_b, dout_a, dout_b : std_logic_vector(40 downto 0);
signal pix_a, pix_b: pixel_data_type;
signal a_lte_b, re_a, re_b, empty_a, empty_b : std_logic;

begin

-- manually pack input data into vectors

din_a <= a.valid & a.tot & a.toa & a.cal & a.row & a.col & a.enum;
din_b <= b.valid & b.tot & b.toa & b.cal & b.row & b.col & b.enum;

-- instantiate FIFOs

FIFO_A: FWFT_FIFO
generic map ( DATA_WIDTH => 41, FIFO_DEPTH => FIFO_DEPTH)
port map(
        CLK => clock,
		RST => reset,
		WriteEn	=> a.valid,
		DataIn  => din_a,
		ReadEn  => re_a,
		DataOut	=> dout_a,
		Empty	=> empty_a
	);

FIFO_B: FWFT_FIFO
generic map ( DATA_WIDTH => 41, FIFO_DEPTH => FIFO_DEPTH)
port map(
        CLK => clock,
		RST => reset,
		WriteEn	=> b.valid,
		DataIn  => din_b,
		ReadEn  => re_b,
		DataOut	=> dout_b,
		Empty	=> empty_b
	);

-- manually unpack FIFO outputs

pix_a.valid <= dout_a(40);
pix_a.tot   <= dout_a(39 downto 31);
pix_a.toa   <= dout_a(30 downto 21);
pix_a.cal   <= dout_a(20 downto 11);
pix_a.row   <= dout_a(10 downto 7 );
pix_a.col   <= dout_a(6 downto 3);
pix_a.enum  <= dout_a(2 downto 0);

pix_b.valid <= dout_b(40);
pix_b.tot   <= dout_b(39 downto 31);
pix_b.toa   <= dout_b(30 downto 21);
pix_b.cal   <= dout_b(20 downto 11);
pix_b.row   <= dout_b(10 downto 7);
pix_b.col   <= dout_b(6 downto 3);
pix_b.enum  <= dout_b(2 downto  0);

-- select logic consider the event number fields and use a LUT to choose the old

a_lte_b <= '1' when ( pix_a.enum <= pix_b.enum ) else '0';

re_a <= '1' when (empty_a='0' and empty_b='1') else -- FIFO A has something, FIFO B is empty
        '1' when (empty_a='0' and empty_b='0' and a_lte_b='1') else -- both FIFOs have stuff, choose A because it is older
        '0';

re_b <= '1' when (empty_a='1' and empty_b='0') else -- FIFO A is empty, FIFO B has something
        '1' when (empty_a='0' and empty_b='0' and a_lte_b='0') else -- both FIFOs have stuff, choose B because it is older
        '0';

-- combinatorial output version

q <= pix_a when (re_a='1' and re_b='0') else
     pix_b when (re_a='0' and re_b='1') else
     null_pixel_data;

end merge_arch;

