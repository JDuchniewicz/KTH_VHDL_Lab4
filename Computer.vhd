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

    --component fake_memory is
	--    port(address	: in STD_LOGIC_VECTOR(7 downto 0);
    --        clock		: in STD_LOGIC := '1';
    --        data		: in STD_LOGIC_VECTOR(15 downto 0);
    --        wren		: in STD_LOGIC;
    --        q		    : out STD_LOGIC_VECTOR(15 downto 0));
    --end component;
    component memory is
        port (address : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
              clock   : IN STD_LOGIC;
              data    : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
              wren    : IN STD_LOGIC;
              q       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
    end component;

    component CPU is
        generic (M : INTEGER := 3;
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
    signal s_q_choice : STD_LOGIC_VECTOR(15 downto 0);
    signal r_q : STD_LOGIC_VECTOR(15 downto 0);
    signal s_PIO : STD_LOGIC_VECTOR(7 downto 0);
    signal s_RW : STD_LOGIC;
    signal s_ST_instr_served : STD_LOGIC;
    signal b_writeCycleDelay : INTEGER;

begin

    --mem : fake_memory port map(address => s_Address(7 downto 0),
    --                      clock => clk,
    --                      data => s_Dout,
    --                      wren => s_mem_wren,
    --                      q => s_q);
    mem : memory port map(address => s_Address(7 downto 0),
                          clock => clk,
                          data => s_Dout,
                          wren => s_mem_wren,
                          q => s_q);

    cpu_1 : CPU port map(clk => clk,
                         reset => reset,
                         Din => s_q_choice,
                         address => s_Address,
                         Dout => s_Dout,
                         RW => s_RW);

    gpios : GPIO generic map(N => 8)
                 port map(clk => clk,
                          rst => reset,
                          IE => '1',
                          OE => '1',
                          Din => s_PIO,
                          Dout => PIO);

    process(clk, reset)
    begin
        if reset = '1' then
            b_writeCycleDelay <= 0;
			r_q <= (others => '0');
        elsif rising_edge(clk) then
            -- don't read new value of q for 2 cycles (until it is safely secured in the memory)
            if s_ST_instr_served = '1' then
                b_writeCycleDelay <= 1;
                r_q <= s_q;
            elsif b_writeCycleDelay = 1 then
                b_writeCycleDelay <= 2;
                r_q <= r_q;
            elsif b_writeCycleDelay = 2 then
                b_writeCycleDelay <= 3;
                r_q <= r_q;
            elsif b_writeCycleDelay = 3 then
                b_writeCycleDelay <= 0;
                r_q <= r_q;
            else
                b_writeCycleDelay <= 0;
                r_q <= s_q;
            end if;
        end if;
    end process;

    process(s_Address, s_RW, reset, s_q, r_q, b_writeCycleDelay, s_Dout, s_ST_instr_served, s_PIO)
    begin
        if reset = '0' then
            s_PIO <= s_PIO;
			if s_RW = '0' then
                if s_Address >= X"0000" and s_Address <= X"00FF" then
                    s_mem_wren <= '1';
                elsif s_Address = X"F000" then
                    s_PIO <= s_Dout(7 downto 0);
                    s_mem_wren <= '0';
                else
                    s_mem_wren <= '0';
                end if;
                s_ST_instr_served <= '1';
				s_q_choice <= s_q;
            else
                s_mem_wren <= '0';
                if s_ST_instr_served = '1' or b_writeCycleDelay = 1 or b_writeCycleDelay = 2 or b_writeCycleDelay = 3 then
                    s_q_choice <= r_q;
                else
                    s_q_choice <= s_q;
                end if;

                s_ST_instr_served <= '0';
			end if;
        else
			s_q_choice <= (others => '0');
            s_mem_wren <= '0';
            s_ST_instr_served <= '0';
            s_PIO <= (others => '0');
        end if;
    end process;

end behav;
