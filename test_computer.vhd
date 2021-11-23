library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

entity test is

end test;

architecture computer_tb of test is

    component Computer is
        port(clk   : in STD_LOGIC;
             reset : in STD_LOGIC;
             PIO   : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    signal clk : STD_ULOGIC := '0';
    signal reset : STD_LOGIC := '1';
    signal s_PIO : STD_LOGIC_VECTOR(7 downto 0);
begin

    comp : Computer port map(clk => clk,
                             reset => reset,
                             PIO => s_PIO);

    clk <= not clk after 10 ns;

    process
    begin
        wait for 10 ns;
        reset <= '0';

        wait for 200 ns;

    end process;


end computer_tb;
