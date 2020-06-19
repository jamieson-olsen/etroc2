-- ETROC2 readout testbench
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.etroc2_package.all;

entity testbench is
end testbench;

architecture testbench_arch of testbench is

component etroc2 is
port(
    clock: in  std_logic;
    reset: in  std_logic;
	l1acc: in  std_logic;
    bc0:   in  std_logic;
    tdc:   in  tdc_data_array_16_16_type;
    dout:  out std_logic_vector(39 downto 0)
  );
end component;

signal clock: std_logic := '0';
signal reset: std_logic := '1';
signal l1acc,bc0: std_logic := '0';
signal d: tdc_data_array_16_16_type;
signal bcid: integer := 0;

type int_array_16 is array (15 downto 0) of integer;
type int_array_16_16 is array(15 downto 0) of int_array_16;

begin

clock <= not clock after 12.5ns; -- 40MHz BX

reset <= '1', '0' after 47ns;

process
    file inputfile: text;
    variable v_line: line;
    variable v_bcid: integer := 0;
    variable v_l1acc: std_logic := '0';
    variable v_tdc: int_array_16_16;
    variable temp: std_logic_vector(31 downto 0) := X"00000000";
    
    procedure clr_all is
    begin
        InitLoopR: for R in 15 downto 0 loop
            InitLoopC: for C in 15 downto 0 loop
                d(R)(C).valid <= '0';
                d(R)(C).toa <= (others=>'0');
                d(R)(C).tot <= (others=>'0');
                d(R)(C).cal <= (others=>'0');
            end loop InitLoopC;
        end loop InitLoopR;
    end procedure;
--
--    procedure set_pixel (constant row,col,toa,tot,cal: in integer) is
--    begin
--        d(row)(col).valid <= '1';
--        d(row)(col).tot   <= std_logic_vector(to_unsigned(tot,9));
--        d(row)(col).toa   <= std_logic_vector(to_unsigned(toa,10));
--        d(row)(col).cal   <= std_logic_vector(to_unsigned(cal,10));
--    end procedure;
--
--    procedure clr_pixel (constant row,col: in integer) is
--    begin
--        d(row)(col).valid <= '0';
--        d(row)(col).toa   <= (others=>'0');
--        d(row)(col).tot   <= (others=>'0');
--        d(row)(col).cal   <= (others=>'0');
--    end procedure;

begin 

file_open(inputfile, "MCburst00.dat", read_mode);

-- each line looks like : BC L1A pix(0,0) pix(1,0).... pix(15,15)
-- where pix is an unsigned int with:
-- bit 31 = 0
-- bit 30 = 0
-- bit 29 = valid
-- bits 28..19 = toa(9..0)
-- bits 18..10 = tot(8..0)
-- bits 9..0 = cal(9..0)

clr_all;
wait for 10us; -- add some delay here to let the circular buffer fill up completely

wait until falling_edge(clock);
bc0 <= '1';
wait until falling_edge(clock);
bc0 <= '0';

while not endfile(inputfile) loop
    readline(inputfile, v_line);
   
    if v_line.all'length = 0 or v_line.all(1) = '#' then  -- Skip empty lines and single-line comments
        next;
    end if;
    read(v_line, v_bcid);
    read(v_line, v_l1acc);
    for R in 0 to 15 loop
        for C in 0 to 15 loop
            read(v_line, v_tdc(R)(C));
        end loop;
    end loop;

    wait until falling_edge(clock);
    l1acc <= v_l1acc;
    bcid <= v_bcid;
    for R in 0 to 15 loop
        for C in 0 to 15 loop
            temp := std_logic_vector( to_unsigned(v_tdc(R)(C),32) );
            d(R)(C).valid <= temp(29);
            d(R)(C).toa   <= temp(28 downto 19);
            d(R)(C).tot   <= temp(18 downto 10);
            d(R)(C).cal   <= temp(9 downto 0);
        end loop;
    end loop;

 end loop;
 
 file_close(inputfile);
     
 wait;
end process;

--clr_all;
--
--wait for 1000ns;
--
---- short event 1
--
--wait until falling_edge(clock);
--set_pixel(4, 3, 122, 45, 98);
--set_pixel(12, 4, 74, 15, 12);
--set_pixel(9, 9, 41, 12, 49);
--set_pixel(1, 14, 23, 92, 98);
--wait until falling_edge(clock);
--clr_all;
--wait for 25ns * L1ACC_OFFSET;
--l1acc <= '1';
--wait until falling_edge(clock);
--l1acc <= '0';
--
--wait for 600ns;  
--
---- a high occupancy event 2
--
--wait until falling_edge(clock);
--set_pixel(6, 11,  0, 21,  0);
--set_pixel(15, 0,  0, 22,  0);
--set_pixel(12, 15, 0, 23,  0);
--set_pixel(15, 15, 0, 18,  0);
--set_pixel(11, 0,  0, 43,  0);
--set_pixel(1, 7, 0, 16, 0);
--set_pixel(2, 7, 0, 78, 0);
--set_pixel(3, 7, 0, 12, 0);
--set_pixel(4, 7, 0, 32, 0);
--set_pixel(5, 7, 0, 23, 0);
--set_pixel(6, 7, 0, 75, 0);
--set_pixel(7, 7, 0, 76, 0);
--set_pixel(8, 7, 0, 77, 0);
--set_pixel(9, 7, 0, 90, 0);
--set_pixel(10, 7, 0, 13, 0);
--set_pixel(11, 7, 0, 14, 0);
--set_pixel(12, 7, 0, 15, 0);
--set_pixel(13, 7, 0, 19, 0);
--set_pixel(14, 7, 0, 19, 0);
--set_pixel(15, 7, 0, 23, 0);
--set_pixel(4, 8, 0, 21, 0);
--set_pixel(12, 12, 0, 56, 0);
--set_pixel(9, 3, 0, 11, 0);
--set_pixel(12, 1, 0, 47, 0);
--wait until falling_edge(clock);
--clr_all;
--wait for 25ns * L1ACC_OFFSET;
--l1acc <= '1';
--wait until falling_edge(clock);
--l1acc <= '0';
--
--wait for 600ns;  
--
---- now try back to back to back L1accepts, still busy with previous event...
---- events 3,4,5
--
--wait until falling_edge(clock);
--set_pixel(6, 1, 106, 107, 108);
--set_pixel(6, 2, 109, 110, 111);
--set_pixel(6, 3, 112, 113, 114);
--set_pixel(6, 4, 115, 116, 117);
--set_pixel(6, 5, 118, 118, 120);
--set_pixel(9, 1, 121, 122, 123);
--
--wait until falling_edge(clock);
--clr_all;
--set_pixel(8, 5, 206, 207, 208);
--set_pixel(8, 6, 209, 210, 211);
--set_pixel(8, 7, 212, 213, 214);
--set_pixel(8, 8, 215, 216, 217);
--
--wait until falling_edge(clock);
--clr_all;
--set_pixel(2,  12, 0, 61, 0);
--set_pixel(3,  11, 0, 62, 0);
--set_pixel(7,   5, 0, 63, 0);
--set_pixel(14, 13, 0, 64, 0);
--set_pixel(13, 13, 0, 65, 0);
--set_pixel(2,   5, 0, 66, 0);
--set_pixel(4,  11, 0, 67, 0);
--
--wait until falling_edge(clock);
--clr_all;
--wait for 25ns * (L1ACC_OFFSET -2) ;
--l1acc <= '1';
--wait until falling_edge(clock);
--wait until falling_edge(clock);
--wait until falling_edge(clock);
--l1acc <= '0';
--
--wait for 1000ns; -- enough time for the pixel circular buffer pointers to wrap around...
--
---- short event 6
--
--wait until falling_edge(clock);
--set_pixel(6, 8, 111, 25, 33);
--set_pixel(12, 3, 92, 15, 12);
--set_pixel(7, 7, 71, 62, 99);
--set_pixel(3, 11, 43, 69, 100);
--wait until falling_edge(clock);
--clr_all;
--wait for 25ns * L1ACC_OFFSET;
--l1acc <= '1';
--wait until falling_edge(clock);
--l1acc <= '0';
--
--wait;
--end process main;


DUT: etroc2
port map( clock => clock, reset => reset, l1acc => l1acc, bc0 => bc0, tdc => d );

end testbench_arch;
