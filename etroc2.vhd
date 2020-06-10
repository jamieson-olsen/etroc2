-- etroc2.vhd
-- ETROC2 top level, model this as a 256 1D array (logically same as 16x16 2D array just simpler to code)
-- jamieson olsen <jamieson@fnal.gov>
-- not done yet, need to add pixel modules in here and include L1acc...

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
    d:     in  pixel_data_array_256_type;
    q:     out pixel_data_type
  );
end etroc2;

architecture etroc2_arch of etroc2 is

component pixel is
generic(ROW,COL: integer range 0 to 3);
port(
    clock: in std_logic;
	l1acc: in std_logic;
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

signal t2d: pixel_data_array_128_type;
signal t3d: pixel_data_array_64_type;
signal t4d: pixel_data_array_32_type;
signal t5d: pixel_data_array_16_type;
signal t6d: pixel_data_array_8_type;
signal t7d: pixel_data_array_4_type;
signal t8d: pixel_data_array_2_type;

signal q_reg, t8q: pixel_data_type;

begin

T1_gen: for i in 127 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 4 )
        port map( clock => clock, reset => reset, a => d(2*i), b => d((2*i)+1), q => t2d(i) );
end generate T1_gen;

T2_gen: for i in 63 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 8 )
        port map( clock => clock, reset => reset, a => t2d(2*i), b => t2d((2*i)+1), q => t3d(i) );
end generate T2_gen;

T3_gen: for i in 31 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 16 )
        port map( clock => clock, reset => reset, a => t3d(2*i), b => t3d((2*i)+1), q => t4d(i) );
end generate T3_gen;

T4_gen: for i in 15 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 16 )
        port map( clock => clock, reset => reset, a => t4d(2*i), b => t4d((2*i)+1), q => t5d(i) );
end generate T4_gen;

T5_gen: for i in 7 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 16 )
        port map( clock => clock, reset => reset, a => t5d(2*i), b => t5d((2*i)+1), q => t6d(i) );
end generate T5_gen;

T6_gen: for i in 3 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 16 )
        port map( clock => clock, reset => reset, a => t6d(2*i), b => t6d((2*i)+1), q => t7d(i) );
end generate T6_gen;

T7_gen: for i in 1 downto 0 generate
    merge_inst: merge 
        generic map( FIFO_DEPTH => 16 )
        port map( clock => clock, reset => reset, a => t7d(2*i), b => t7d((2*i)+1), q => t8d(i) );
end generate T7_gen;

T8_merge_inst: merge 
    generic map( FIFO_DEPTH => 16 )
    port map( clock => clock, reset => reset, a => t8d(0), b => t8d(1), q => t8q );

outproc: process(clock)
begin
    if rising_edge(clock) then
        q_reg <= t8q;
    end if;           
end process outproc;

q <= q_reg;

end etroc2_arch;
