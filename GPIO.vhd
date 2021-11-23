library ieee;
use ieee.std_logic_1164.all;

entity GPIO is
    generic(N : INTEGER);
    port(clk  : in STD_LOGIC;
         rst  : in STD_LOGIC;
         IE   : in STD_LOGIC;
         OE   : in STD_LOGIC;
         Din  : in STD_LOGIC_VECTOR(N - 1 downto 0);
         Dout : out STD_LOGIC_VECTOR(N - 1 downto 0));
end entity;

architecture behav of GPIO is
   signal r_D : STD_LOGIC_VECTOR(N - 1 downto 0);
begin
    process (clk, rst)
    begin
        if rst = '1' then
            r_D <= (others => '0');
        elsif rising_edge(clk) then
            if IE = '1' then
                r_D <= Din;
            else
                r_D <= r_D;
            end if;

            if OE = '1' then
                Dout <= r_D;
            else
                Dout <= (others => 'Z');
            end if;
        else
            r_D <= r_D;
        end if;
    end process;
end behav;
