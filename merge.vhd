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
-- signal q_reg : pixel_data_type;
signal a_lte_b, re_a, re_b, empty_a, empty_b : std_logic;

begin

-- manually pack input data into vectors

din_a <= a.valid & a.tot & a.toa & a.cal & a.row & a.col & a.ecnt;
din_b <= b.valid & b.tot & b.toa & b.cal & b.row & b.col & b.ecnt;

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

pix_a.valid <= dout_a(45);
pix_a.tot   <= dout_a(44 downto 36);
pix_a.toa   <= dout_a(35 downto 26);
pix_a.cal   <= dout_a(25 downto 16);
pix_a.row   <= dout_a(15 downto 12);
pix_a.col   <= dout_a(11 downto  3);
pix_a.bcid  <= dout_a( 2 downto  0);

pix_b.valid <= dout_b(45);
pix_b.tot   <= dout_b(44 downto 36);
pix_b.toa   <= dout_b(35 downto 26);
pix_b.cal   <= dout_b(25 downto 16);
pix_b.row   <= dout_b(15 downto 12);
pix_b.col   <= dout_b(11 downto  8);
pix_b.bcid  <= dout_b( 2 downto  0);

-- simple selection logic 

-- consider the event count fields and use a LUT to choose the old

a_older <= '1' when ( pix_a.ecnt <= pix_b.ecnt ) else '0';

re_a <= '1' when (empty_a='0' and empty_b='1') else -- FIFO A has something, FIFO B is empty
        '1' when (empty_a='0' and empty_b='0' and a_older='1') else -- both FIFOs have stuff, choose A because it is older
        '0';

re_b <= '1' when (empty_a='1' and empty_b='0') else -- FIFO A is empty, FIFO B has something
        '1' when (empty_a='0' and empty_b='0' and a_older='0') else -- both FIFOs have stuff, choose B because it is older
        '0';

-- combinatorial output version

q <= pix_a when (re_a='1' and re_b='0') else
     pix_b when (re_a='0' and re_b='1') else
     ('0',"000000000","0000000000","0000000000","0000","0000","000");


end merge_arch;

