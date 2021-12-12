library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library modelsim_lib;
use modelsim_lib.util.all;          -- defines the spy_signal procedure
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

    signal t_address : STD_LOGIC_VECTOR(15 downto 0);
    signal t_Dout : STD_LOGIC_VECTOR(15 downto 0);
    type rf_type is array(0 to 2**8 - 1) of std_logic_vector(15 downto 0);
    signal t_rf_mem:rf_type;
begin

    comp : Computer port map(clk => clk,
                             reset => reset,
                             PIO => s_PIO);

    clk <= not clk after 10 ns;

    spy_process: -- Spy process connects signals inside the hierarchy to signals in the test_bench (simulator dependent - only works in Modelsim)
    process
    begin
       init_signal_spy("/test/comp/cpu_1/address","/t_address",1);
       init_signal_spy("/test/comp/cpu_1/Dout","/t_Dout",1);
       init_signal_spy("/test/comp/cpu_1/Datapath1/RF_1/mem","/t_rf_mem",1);
       wait;
    end process spy_process;

    process
    begin
        wait for 20 ns;
        reset <= '0';
        -- one instr takes 4 cycles
        wait for 70 ns;
        --TODO: write a testbench that will go over all the instructions and test if the program and simulation results are in accordance (for a several number of cycles)
        -- kickoff at mem address 0x0
        assert (t_address = "0000000000000001") report "I1 does not work!" severity failure;
        assert (t_rf_mem(5) = x"FF00") report "R5 has wrong value!" severity failure;
        report "I1 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000010") report "I2 does not work!" severity failure;
        assert (t_rf_mem(5) = x"FE00") report "R5 has wrong value!" severity failure;
        report "I2 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000011") report "I3 does not work!" severity failure;
        assert (t_rf_mem(5) = x"FC00") report "R5 has wrong value!" severity failure;
        report "I3 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000100") report "I4 does not work!" severity failure;
        assert (t_rf_mem(5) = x"F800") report "R5 has wrong value!" severity failure;
        report "I4 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000101") report "I5 does not work!" severity failure;
        assert (t_rf_mem(5) = x"F000") report "R5 has wrong value!" severity failure;
        report "I5 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000110") report "I6 does not work!" severity failure;
        assert (t_rf_mem(6) = x"0020") report "R6 has wrong value!" severity failure;
        report "I6 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000000111") report "I7 does not work!" severity failure;
        assert (t_rf_mem(6) = x"0003") report "R3 has wrong value!" severity failure;
        report "I7 works OK";

        wait for 40 ns;
        assert (t_address = "0000000000001000") report "I8 does not work!" severity failure;
        assert (t_rf_mem(6) = x"0003") report "R3 has wrong value!" severity failure;
        report "I7 works OK";
    end process;


end computer_tb;
