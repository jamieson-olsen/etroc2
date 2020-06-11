-- etroc2_package.vhd
-- user-defined custom data types and constants

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package etroc2_package is

type tdc_data_type is record
    valid : std_logic;
    tot   : std_logic_vector(8 downto 0);
    toa   : std_logic_vector(9 downto 0);
    cal   : std_logic_vector(9 downto 0);
end record tdc_data_type;

constant null_tdc_data: tdc_data_type := ('0',"000000000","0000000000","0000000000");

type tdc_data_array_16_type is array (15 downto 0) of tdc_data_type;
type tdc_data_array_16_16_type is array (15 downto 0) of tdc_data_array_16_type;

type pixel_data_type is record -- 41 bits
    valid : std_logic;
    tot   : std_logic_vector(8 downto 0);
    toa   : std_logic_vector(9 downto 0);
    cal   : std_logic_vector(9 downto 0);
    row   : std_logic_vector(3 downto 0);
    col   : std_logic_vector(3 downto 0);
    enum  : std_logic_vector(2 downto 0); -- event number counter
end record pixel_data_type;

constant null_pixel_data: pixel_data_type := ('0',"000000000","0000000000","0000000000","0000","0000","000");

-- 1D pixel_data_arrays

type pixel_data_array_2_type   is array (  1 downto 0) of pixel_data_type;
type pixel_data_array_4_type   is array (  3 downto 0) of pixel_data_type;
type pixel_data_array_8_type   is array (  7 downto 0) of pixel_data_type;
type pixel_data_array_16_type  is array ( 15 downto 0) of pixel_data_type;

-- 2D pixel_data arrays, always index by ROW then COL

type pixel_data_array_2_16_type  is array ( 1 downto 0) of pixel_data_array_16_type;
type pixel_data_array_4_16_type  is array ( 3 downto 0) of pixel_data_array_16_type;
type pixel_data_array_8_16_type  is array ( 7 downto 0) of pixel_data_array_16_type;
type pixel_data_array_16_16_type is array (15 downto 0) of pixel_data_array_16_type;

constant TOT_THRESHOLD: integer := 10; -- TOT threshold in pixel cell
constant TOA_THRESHOLD: integer := 10; -- currently not used

constant L1ACC_OFFSET:  integer := 23;
constant PIX_BUF_ADDR_WIDTH: integer := 8; 

end etroc2_package;

