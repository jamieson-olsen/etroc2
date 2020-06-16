-- etroc2.vhd
-- ETROC2 top level, 16 x 16 array of pixel modules followed by tiers of merge modules
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.etroc2_package.all;

entity etroc2 is
port(
    clock: in  std_logic;
    reset: in  std_logic;
	l1acc: in  std_logic;
    d:     in  tdc_data_array_16_16_type;
    q:     out pixel_data_type
  );
end etroc2;

architecture etroc2_arch of etroc2 is

component pixel is
generic(ROW,COL: integer range 0 to 15);
port(
    clock: in std_logic;
	reset: in std_logic;
	l1acc: in std_logic;
    enum:  in std_logic_vector(3 downto 0);
    din:   in tdc_data_type;
    dout:  out pixel_data_type
  );
end component;

component merge is
generic ( constant FIFO_DEPTH : positive := 4 );
port(
    clock: in  std_logic;
    reset: in  std_logic;
    a,b:   in  pixel_data_type;
	q:     out pixel_data_type
);
end component;

component enum_count is
port(
    clock: in  std_logic;
	reset: in  std_logic;
	l1acc: in  std_logic;
    val:   in  std_logic;
    enum:  out std_logic_vector(3 downto 0 )
  );
end component;

signal pix_dout: pixel_data_array_16_16_type;
signal t2d: pixel_data_array_8_16_type;
signal t3d: pixel_data_array_4_16_type;
signal t4d: pixel_data_array_2_16_type;
signal t5d: pixel_data_array_16_type;
signal t6d: pixel_data_array_8_type;
signal t7d: pixel_data_array_4_type;
signal t8d: pixel_data_array_2_type;
signal q_reg, t8q: pixel_data_type;
signal bcid: std_logic_vector(11 downto 0) := (others=>'0');
signal enum: std_logic_vector(3 downto 0);

begin

enum_inst: enum_count
port map(
    clock => clock,
	reset => reset,
	l1acc => l1acc,
    val   => t8q.valid,
    enum  => enum
  );

-- 16x16 pixel array

Pix_Row_Gen: for R in 15 downto 0 generate
	Pix_Col_Gen: for C in 15 downto 0 generate
		pixel_inst: pixel 
		generic map(ROW=>R, COL=>C)
		port map(
    		clock => clock,
			reset => reset,
			l1acc => l1acc,
            enum  => enum,
    		din   => d(R)(C),
    		dout  => pix_dout(R)(C)
  		);
	end generate Pix_Col_Gen;
end generate Pix_Row_Gen;

-- 1st tier merge cells 8Rx16C

T1_R_gen: for R in 7 downto 0 generate
	T1_C_gen: for C in 15 downto 0 generate
	    merge_inst: merge 
	        generic map( FIFO_DEPTH => 4 )
	        port map( clock => clock, reset => reset, a => pix_dout(2*R)(C), b => pix_dout((2*R)+1)(C), q => t2d(R)(C) );
	end generate T1_C_gen;
end generate T1_R_gen;

-- 2nd tier merge cells 4Rx16C

T2_R_gen: for R in 3 downto 0 generate
	T2_C_gen: for C in 15 downto 0 generate
	    merge_inst: merge 
	        generic map( FIFO_DEPTH => 8 )
	        port map( clock => clock, reset => reset, a => t2d(2*R)(C), b => t2d((2*R)+1)(C), q => t3d(R)(C) );
	end generate T2_C_gen;
end generate T2_R_gen;

-- 3rd tier merge cells 2Rx16C

T3_R_gen: for R in 1 downto 0 generate
	T3_C_gen: for C in 15 downto 0 generate
	    merge_inst: merge 
	        generic map( FIFO_DEPTH => 16 )
	        port map( clock => clock, reset => reset, a => t3d(2*R)(C), b => t3d((2*R)+1)(C), q => t4d(R)(C) );
	end generate T3_C_gen;
end generate T3_R_gen;

-- 4th tier merge cells 16C

T4_gen: for C in 15 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 32 )
        port map( clock => clock, reset => reset, a => t4d(0)(C), b => t4d(1)(C), q => t5d(C) );
end generate T4_gen;

-- 5th tier merge cells 8C

T5_gen: for C in 7 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 64 )
        port map( clock => clock, reset => reset, a => t5d(2*C), b => t5d((2*C)+1), q => t6d(C) );
end generate T5_gen;

-- 6th tier merge cells 4C

T6_gen: for C in 3 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 128 )
        port map( clock => clock, reset => reset, a => t6d(2*C), b => t6d((2*C)+1), q => t7d(C) );
end generate T6_gen;

-- 7th tier merge cells 2C

T7_gen: for C in 1 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 256 )
        port map( clock => clock, reset => reset, a => t7d(2*C), b => t7d((2*C)+1), q => t8d(C) );
end generate T7_gen;

-- 8th (and last tier) merge cell

T8_merge_inst: merge 
    generic map( FIFO_DEPTH => 512 )
    port map( clock => clock, reset => reset, a => t8d(0), b => t8d(1), q => t8q );

outproc: process(clock)
begin
    if rising_edge(clock) then
        q_reg <= t8q;
		if (reset='1') then
			bcid <= (others=>'0');
		else
			bcid <= std_logic_vector( unsigned(bcid) + 1 );
		end if;
    end if;           
end process outproc;

q <= q_reg;

end etroc2_arch;
