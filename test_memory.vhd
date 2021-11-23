library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

entity test is

end test;

architecture tb of test is
    component fake_memory
       port (clk : in STD_LOGIC;
             dummy : out STD_LOGIC);
    end component;
    signal clk : STD_ULOGIC := '0';
    signal t_dummy : STD_LOGIC;
begin
    mem : fake_memory port map(clk => clk,
                               dummy => t_dummy);

    clk <= not clk after 5 ns;
    d : process
    begin
        wait for 10 ns;
    end process;

end tb;
