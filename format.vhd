-- format.vhd
-- monitor the output of the last merge module and prepend header and append trailer frames
-- din cannot be stopped.
-- within an event hits is contiguous with no gaps between hits.
-- there may or may not be gaps between events.
--
-- output format is 40 bits:
--
-- header:  "01" & "00" X"000000" & BCID(11..0)
--   data:  "10" & V & TOT(8..0) & TOA(9..0) & CAL(9..0) & ROW(3..0) & COL(3..0)
-- trailer: "11" & "00" & X"000000000"
--   idle:  X"0000000000"

library ieee;
use ieee.std_logic_1164.all;

use work.etroc2_package.all;

entity format is
generic ( constant FIFO_DEPTH : positive := 4 );
port(
    clock: in  std_logic;
    reset: in  std_logic;
    l1acc: in  std_logic;
    enum:  in  std_logic_vector(3 downto 0);
    bcid:  in  std_logic_vector(11 downto 0);

    din:   in  pixel_data_type;
    dout:  out std_logic_vector(39 downto 0)
);
end format;

architecture format_arch of format is

component fwft_fifo -- generic fifo
generic( constant DATA_WIDTH  : positive := 8;
	     constant FIFO_DEPTH  : positive := 256 );
port( 
		clk		: in  std_logic;
		rst		: in  std_logic;
		writeen	: in  std_logic;
		datain	: in  std_logic_vector (data_width - 1 downto 0);
		readen	: in  std_logic;
		dataout	: out std_logic_vector (data_width - 1 downto 0);
		empty	: out std_logic;
		full	: out std_logic
	);
end component;

signal din_slv, fifo_dout: std_logic_vector(41 downto 0);
signal fifo_read, fifo_empty: std_logic;
signal enum_reg: std_logic_vector(3 downto 0);

type state_type is (rst, idle, header, dump, trailer0, trailer1);
signal state: state_type;

begin

din_slv <= din.valid & din.tot & din.toa & din.cal & din.row & din.col & din.enum;

fifo_read <= '0' when (state=header) else
             '0' when (state=trailer0) else
             '0' when (state=trailer0) else
             '1';

data_fifo_inst: fwft_fifo
generic map ( DATA_WIDTH => 42, FIFO_DEPTH => FIFO_DEPTH)
port map(
        clk => clock,
		rst => reset,
		writeen	=> din.valid,
		datain  => din_slv,
		readen  => fifo_read,
		dataout	=> fifo_dout,
		empty	=> fifo_empty
	);

fsm_proc: process(clock)
begin
    if rising_edge(clock) then

        if (reset='1') then

            state <= rst;
            enum_reg <= "0000";

        else

            enum_reg <= fifo_dout(3 downto 0);

            case state is 

                when rst => state <= idle;

                when idle =>
                    if (fifo_empty='0') then
                        state <= header;
                    else
                        state <= idle;
                    end if;

                when header =>
                    state <= dump;
        
                when dump =>
                    if (fifo_empty='1') then -- no more hits, no more events
                        state <= trailer0;
                    elsif ( enum_reg /= fifo_dout(3 downto 0) ) then -- hits from the next event are here
                        state <= trailer1;
                    end if;

                when trailer0 => -- no more events coming, send trailer, return to idle...
                    state <= idle;

                when trailer1 => -- there is another event ready, send trailer, send header, keep dumping
                    state <= header;

                when others => 
                    state <= rst;

            end case;
        end if;
    end if;
end process fsm_proc;

dout <= X"4000000000"                 when (state=header) else
        "10" & fifo_dout(41 downto 4) when (state=dump) else
        X"C000000000"                 when (state=trailer0 or state=trailer1) else
        (others=>'0');

end format_arch;

