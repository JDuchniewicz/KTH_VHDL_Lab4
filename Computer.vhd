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
    signal r_q : STD_LOGIC_VECTOR(15 downto 0);
    signal s_RW : STD_LOGIC;
    signal b_writeCycleDelay : INTEGER;

begin

    mem : fake_memory port map(address => s_Address(7 downto 0),
                          clock => clk,
                          data => s_Dout,
                          wren => s_mem_wren,
                          q => s_q);

    cpu_1 : CPU port map(clk => clk,
                         reset => reset,
                         Din => r_q,
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
            b_writeCycleDelay <= 0;
        elsif rising_edge(clk) then
            -- don't read new value of q for 2 cycles (until it is safely secured in the memory)
            if s_mem_wren = '1' then
                b_writeCycleDelay <= 1;
            elsif b_writeCycleDelay = 1 then
                b_writeCycleDelay <= 2;
            else
                b_writeCycleDelay <= 0;
            end if;
        end if;
    end process;

    process(s_Address, s_RW, reset, s_q, b_writeCycleDelay)
    begin
        if reset = '0' then
            if s_Address >= X"0000" and s_Address <= X"00FF" and s_RW = '0' then
                s_mem_wren <= '1';
                r_q <= r_q;
            else
                s_mem_wren <= '0';
                if b_writeCycleDelay > 0 and b_writeCycleDelay < 3 then -- a quite ugly hack to stall 2 cycles of reading by the CPU and keep the old value of instruction for ST instr
                    r_q <= r_q;
                else
                    r_q <= s_q;
                end if;
            end if;
        end if;
    end process;

end behav;
