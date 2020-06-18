-- format.vhd
-- monitor the output of the last merge module and prepend header and append trailer frames
-- din cannot be stopped.
-- within an event hits is contiguous with no gaps between hits.
-- there may or may not be gaps between events.
--
-- output format is 40 bits "constant word length"
--
-- header:  "00" & "10" X"555555" & BCID(11..0)
--   data:  "01" & Parity & ROW(3..0) & COL(3..0) & TOA(9..0) & TOT(8..0) & CAL(9..0)
-- trailer: "11" & "11" & X"555555555"


library ieee;
use ieee.std_logic_1164.all;

use work.etroc2_package.all;

entity format is
generic ( constant FIFO_DEPTH : positive := 4 );
port(
    clock: in  std_logic;
    reset: in  std_logic;
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
signal pix: pixel_data_type;
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

pix.valid <= fifo_dout(41);
pix.tot   <= fifo_dout(40 downto 32);
pix.toa   <= fifo_dout(31 downto 22);
pix.cal   <= fifo_dout(21 downto 12);
pix.row   <= fifo_dout(11 downto  8);
pix.col   <= fifo_dout( 7 downto  4);
pix.enum  <= fifo_dout( 3 downto  0);

fsm_proc: process(clock)
begin
    if rising_edge(clock) then

        if (reset='1') then

            state <= rst;
            enum_reg <= "0000";

        else

            enum_reg <= pix.enum;

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
                    elsif ( enum_reg /= pix.enum ) then -- hits from the next event are here
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

dout <= X"2555555" & bcid(11 downto 0) when (state=header) else -- note this BCID will be wrong, will fix...
        "10" & pix.valid & pix.row & pix.col & pix.toa & pix.tot & pix.cal when (state=dump) else
        X"F555555555"; -- trailer/idle word

end format_arch;

