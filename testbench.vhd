-- ETROC2 readout testbench 256 flat array version
-- jamieson olsen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.etroc2_package.all;

entity testbench is
end testbench;

architecture testbench_arch of testbench is

component etroc2 is
port(
    clock: in std_logic;
    reset: in std_logic;
    d: in pixel_data_array_256_type;
    q: out pixel_data_type
  );
end component;

signal clock: std_logic := '0';
signal reset: std_logic := '1';
signal d: pixel_data_array_256_type;
signal bcid: std_logic_vector(7 downto 0) := X"00";














begin

clock <= not clock after 12.5ns; -- 40MHz BX

reset <= '1', '0' after 47ns;

bcid_proc: process(clock) -- free running bunch crossing ID counter
begin
    if rising_edge(clock) then
        bcid <= std_logic_vector( unsigned(bcid) + 1 );
    end if;
end process bcid_proc;




main: process

-- some helper procedures

procedure clr_all is
begin
    InitLoopR: for R in 15 downto 0 loop
        InitLoopC: for C in 15 downto 0 loop
            d(16*R+C).valid <= '0';
            d(16*R+C).toa <= (others=>'0');
            d(16*R+C).tot <= (others=>'0');
            d(16*R+C).cal <= (others=>'0');
            d(16*R+C).row <= std_logic_vector(to_unsigned(R,4));
            d(16*R+C).col <= std_logic_vector(to_unsigned(C,4));
            d(16*R+C).bcid <= (others=>'0');
        end loop InitLoopC;
    end loop InitLoopR;
end procedure;

procedure set_pixel (constant row,col,toa,tot,cal: in integer) is
begin
    d(16*row+col).valid <= '1';
    d(16*row+col).tot   <= std_logic_vector(to_unsigned(tot,9));
    d(16*row+col).toa   <= std_logic_vector(to_unsigned(toa,10));
    d(16*row+col).cal   <= std_logic_vector(to_unsigned(cal,10));
    d(16*row+col).bcid  <= bcid;
end procedure;

procedure clr_pixel (constant row,col: in integer) is
begin
    d(16*row+col).valid <= '0';
    d(16*row+col).toa   <= (others=>'0');
    d(16*row+col).tot   <= (others=>'0');
    d(16*row+col).cal   <= (others=>'0');
    d(16*row+col).bcid  <= (others=>'0');
end procedure;

begin

clr_all;

wait for 500ns;

wait until falling_edge(clock);
set_pixel(4, 3, 122, 45, 98);
set_pixel(12, 4, 74, 5, 12);
set_pixel(9, 9, 41, 12, 49);
set_pixel(1, 14, 23, 92, 98);

wait until falling_edge(clock);
clr_all;


wait for 1000ns;  -- whole bunch of hits here, 24 = 10% occupancy

wait until falling_edge(clock);
set_pixel(6, 11, 0, 0, 0);
set_pixel(15, 0, 0, 0, 0);
set_pixel(12, 15, 0, 0, 0);
set_pixel(15, 15, 0, 0, 0);
set_pixel(11, 0, 0, 0, 0);
set_pixel(1, 7, 0, 0, 0);
set_pixel(2, 7, 0, 0, 0);
set_pixel(3, 7, 0, 0, 0);
set_pixel(4, 7, 0, 0, 0);
set_pixel(5, 7, 0, 0, 0);
set_pixel(6, 7, 0, 0, 0);
set_pixel(7, 7, 0, 0, 0);
set_pixel(8, 7, 0, 0, 0);
set_pixel(9, 7, 0, 0, 0);
set_pixel(10, 7, 0, 0, 0);
set_pixel(11, 7, 0, 0, 0);
set_pixel(12, 7, 0, 0, 0);
set_pixel(13, 7, 0, 0, 0);
set_pixel(14, 7, 0, 0, 0);
set_pixel(15, 7, 0, 0, 0);
set_pixel(4, 8, 0, 0, 0);
set_pixel(12, 12, 0, 0, 0);
set_pixel(9, 3, 0, 0, 0);
set_pixel(12, 1, 0, 0, 0);

wait until falling_edge(clock);
clr_all;










wait for 1000ns;  

-- another torture test, try back to back to back L1accepts!

wait until falling_edge(clock);
set_pixel(6, 1, 106, 107, 108);
set_pixel(6, 2, 109, 110, 111);
set_pixel(6, 3, 112, 113, 114);
set_pixel(6, 4, 115, 116, 117);
set_pixel(6, 5, 118, 118, 120);
set_pixel(9, 1, 121, 122, 123);

wait until falling_edge(clock);
clr_all;
set_pixel(8, 5, 206, 207, 208);
set_pixel(8, 6, 209, 210, 211);
set_pixel(8, 7, 212, 213, 214);
set_pixel(8, 8, 215, 216, 217);

wait until falling_edge(clock);
clr_all;
set_pixel(2, 12, 0, 0, 0);
set_pixel(3, 11, 0, 0, 0);
set_pixel(7, 5, 0, 0, 0);
set_pixel(14, 13, 0, 0, 0);
set_pixel(13, 13, 0, 0, 0);
set_pixel(2, 5, 0, 0, 0);
set_pixel(4, 11, 0, 0, 0);

wait until falling_edge(clock);
clr_all;














wait;
end process main;





DUT: etroc2
port map( clock => clock, reset => reset, d => d );

end testbench_arch;
