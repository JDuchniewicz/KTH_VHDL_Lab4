library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

entity Computer is -- TODO: inputs?
    port(clk   : in STD_LOGIC;
         reset : in STD_LOGIC;
         PIO   : out STD_LOGIC_VECTOR(7 downto 0));

end entity;

architecture behav of Computer is

    component fake_memory is
	    port(address	: in STD_LOGIC_VECTOR(7 downto 0);
            clock		: in STD_LOGIC := '1';
            data		: in STD_LOGIC_VECTOR(15 downto 0);
            wren		: in STD_LOGIC;
            q		    : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component CPU is
        generic (M : INTEGER := 8;
                 N : INTEGER := 16);
        port (clk     : IN STD_LOGIC;
              reset   : IN STD_LOGIC;
              Din     : IN STD_LOGIC_VECTOR(N - 1 downto 0);
              address : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
              Dout    : OUT STD_LOGIC_VECTOR(N - 1 downto 0);
              RW      : OUT STD_LOGIC);
    end component;

    component GPIO is
        generic(N : INTEGER);
        port(clk  : in STD_LOGIC;
             rst  : in STD_LOGIC;
             IE   : in STD_LOGIC;
             OE   : in STD_LOGIC;
             Din  : in STD_LOGIC_VECTOR(N - 1 downto 0);
             Dout : out STD_LOGIC_VECTOR(N - 1 downto 0));
    end component;

    --signal s_legal_address : STD_LOGIC_VECTOR(15 downto 0);
    --signal s_rden : STD_LOGIC;
    signal s_mem_wren : STD_LOGIC;
    --signal s_gpio_wren : STD_LOGIC;
    --signal s_gpio_rden : STD_LOGIC;

    signal s_Dout : STD_LOGIC_VECTOR(15 downto 0);
    signal s_Address : STD_LOGIC_VECTOR(15 downto 0); -- log the full address
    signal s_q : STD_LOGIC_VECTOR(15 downto 0);
    signal s_RW : STD_LOGIC;

begin

    mem : fake_memory port map(address => s_Address(7 downto 0),
                          clock => clk,
                          data => s_Dout,
                          wren => s_mem_wren,
                          q => s_q);

    cpu_1 : CPU port map(clk => clk,
                         reset => reset,
                         Din => s_q,
                         address => s_Address,
                         Dout => s_Dout,
                         RW => s_RW);

    gpios : GPIO generic map(N => 8)
                 port map(clk => clk,
                          rst => reset,
                          IE => '1',
                          OE => '1',
                          Din => s_Dout(7 downto 0),
                          Dout => PIO);

    process(clk, reset)
    begin
        if reset = '1' then

        elsif rising_edge(clk) then
            -- write the memory if address inside boundaries AND a write requested by CPU
            if s_Address >= X"0000" and s_Address <= X"00FF" and s_RW = '0' then
                s_mem_wren <= '1';
            else
                s_mem_wren <= '0';
            end if;

            --if s_Address = X"F000" then --output GPIO all the time, this seems to be broken in the lab manual
            --    s_gpio_wren <= '1';
            --    s_gpio_rden <= '1';
            --else
            --    s_gpio_wren <= '0'; -- TODO; wth? how to control them?
            --    s_gpio_rden <= '0';
            --end if;
        end if;
    end process;

end behav;
