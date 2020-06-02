-- pixel.vhd
-- this is just a circular buffer, the pointers are external to this module
-- here I keep it simple: the RAM is written on every clock (if din.tot < TOT_THRESH then zeros are written into RAM)
-- and the RAM is read on every clock.
--
-- jamieson olsen <jamieson@fnal.gov>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.etroc2_package.all;

entity pixel is
generic( TOT_THRESH : integer := 100 ; ADDR_WIDTH : integer := 8 );
port(
    clock: in std_logic;
    reset: in std_logic;
    din:   in tdc_type;
    waddr: in std_logic_vector(ADDR_WIDTH-1 downto 0);
    raddr: in std_logic_vector(ADDR_WIDTH-1 downto 0);
    dout:  out tdc_type
  );
end pixel;

architecture pixel_arch of pixel is

subtype data_t is std_logic_vector(31 downto 0);
type memory_t is array(0 to 2**ADDR_WIDTH-1) of data_t;
signal memory : memory_t := (others => X"00000000");
signal dout_i : std_logic_vector(31 downto 0);

begin

-- unpack






end pixel_arch;
