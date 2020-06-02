-- etroc2_package.vhd
-- user-defined custom data types and constants

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package etroc2_package is

type tdc_type is record
    valid : std_logic;
    tot   : std_logic_vector(8 downto 0);
    toa   : std_logic_vector(9 downto 0);
    cal   : std_logic_vector(9 downto 0);
end record tdc_type;

type pixel_data_type is record -- 41 bits
    valid : std_logic;
    tot   : std_logic_vector(8 downto 0);
    toa   : std_logic_vector(9 downto 0);
    cal   : std_logic_vector(9 downto 0);
    row   : std_logic_vector(3 downto 0);
    col   : std_logic_vector(3 downto 0);
    ecnt  : std_logic_vector(2 downto 0); -- event counter
end record pixel_data_type;

type pixel_data_array_256_type is array (255 downto 0) of pixel_data_type;
type pixel_data_array_128_type is array (127 downto 0) of pixel_data_type;
type pixel_data_array_64_type  is array ( 63 downto 0) of pixel_data_type;
type pixel_data_array_32_type  is array ( 31 downto 0) of pixel_data_type;
type pixel_data_array_16_type  is array ( 15 downto 0) of pixel_data_type;
type pixel_data_array_8_type   is array (  7 downto 0) of pixel_data_type;
type pixel_data_array_4_type   is array (  3 downto 0) of pixel_data_type;
type pixel_data_array_2_type   is array (  1 downto 0) of pixel_data_type;

type pixel_data_array_16x16_type is array (15 downto 0) of pixel_data_array_16_type;

end etroc2_package;

