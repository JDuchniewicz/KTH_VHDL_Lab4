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
    signal t_RAM : rf_type;
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
       init_signal_spy("/test/comp/mem/RAM","/t_RAM",1);
       wait;
    end process spy_process;

    process
        variable r2 : INTEGER := 15;
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        -- one instr takes 4 cycles
        wait for 60 ns;
        --TODO: write a testbench that will go over all the instructions and test if the program and simulation results are in accordance (for a several number of cycles)
        -- kickoff at mem address 0x0 -- LDI
        assert (t_address = "0000000000000001") report "I0 LDI does not work!" severity failure;
        assert (t_rf_mem(5) = x"FF00") report "R5 has wrong value!" severity failure;
        report "I0 LDI works OK";

        wait for 80 ns; -- ADD
        assert (t_address = "0000000000000010") report "I1 ADD does not work!" severity failure;
        assert (t_rf_mem(5) = x"FE00") report "R5 has wrong value!" severity failure;
        report "I1 ADD works OK";

        wait for 80 ns; -- ADD
        assert (t_address = "0000000000000011") report "I2 ADD does not work!" severity failure;
        assert (t_rf_mem(5) = x"FC00") report "R5 has wrong value!" severity failure;
        report "I2 ADD works OK";

        wait for 80 ns; -- ADD
        assert (t_address = "0000000000000100") report "I3 ADD does not work!" severity failure;
        assert (t_rf_mem(5) = x"F800") report "R5 has wrong value!" severity failure;
        report "I3 ADD works OK";

        wait for 80 ns; -- ADD
        assert (t_address = "0000000000000101") report "I4 ADD does not work!" severity failure;
        assert (t_rf_mem(5) = x"F000") report "R5 has wrong value!" severity failure;
        report "I4 ADD works OK";

        wait for 80 ns; -- LDI
        assert (t_address = "0000000000000110") report "I5 LDI does not work!" severity failure;
        assert (t_rf_mem(6) = x"0020") report "R6 has wrong value!" severity failure;
        report "I5 LDI works OK";

        wait for 80 ns; -- LDI
        assert (t_address = "0000000000000111") report "I6 LDI does not work!" severity failure;
        assert (t_rf_mem(3) = x"0003") report "R3 has wrong value!" severity failure;
        report "I6 LDI works OK";

        wait for 80 ns; -- ST instruction
        assert (t_address = "0000000000001000") report "I7 ST does not work!" severity failure;
        wait for 40 ns; -- it will be there only after 2 cycles
        assert (t_RAM(32) = x"0003") report "RAM at address 32 has wrong value!" severity failure;
        report "I7 ST works OK";

        wait for 40 ns; -- LDI instruction
        assert (t_address = "0000000000001001") report "I8 LDI does not work!" severity failure;
        assert (t_rf_mem(1) = x"0001") report "R1 has wrong value!" severity failure;
        report "I8 LDI works OK";

        wait for 80 ns; -- LDI instruction
        assert (t_address = "0000000000001010") report "I9 LDI does not work!" severity failure;
        assert (t_rf_mem(1) = x"0001") report "R1 has wrong value!" severity failure;
        report "I9 LDI works OK";

        wait for 80 ns; -- MOV instruction
        assert (t_address = "0000000000001011") report "IA MOV does not work!" severity failure;
        wait for 20 ns;
        assert (t_rf_mem(2) = t_rf_mem(0)) report "R2 has wrong value! not equal to R0" severity failure;
        assert (t_rf_mem(2) = x"000E") report "R2 has wrong value!" severity failure;
        report "IA MOV works OK";


        for i in 13 downto 0 loop
            report "ADD/SUB/BRZ/NOP i = " & integer'image(i);
            wait for 60 ns; -- ADD instruction
            assert (t_address = "0000000000001100") report "IB ADD does not work!" severity failure;
            assert (to_integer(signed(t_rf_mem(2))) = r2) report "R2 has wrong value!" severity failure;
            report "IB ADD works OK";

            wait for 80 ns; -- SUB instruction
            assert (t_address = "0000000000001101") report "IC SUB does not work!" severity failure;
            assert (to_integer(signed(t_rf_mem(0))) = i) report "R0 has wrong value!" severity failure;
            report "IC SUB works OK";

            wait for 80 ns; -- BRZ instruction (this is a loop which will be skipped only when the R0 is equal to 0)
            if i = 0 then
                assert (t_address = "0000000000010000") report "ID BRZ does not work!" severity failure;
                report "ID BRZ works OK";
                exit;
            end if;
            assert (t_address = "0000000000001110") report "ID BRZ does not work!" severity failure;
            report "ID BRZ works OK";

            wait for 80 ns; -- NOP
            assert (t_address = "0000000000001111") report "IE NOP does not work!" severity failure;
            report "IE NOP works OK";

            wait for 80 ns; -- BRA PC-4 (back to the ID BRZ)
            assert (t_address = "0000000000001011") report "IF BRA does not work!" severity failure;
            report "IF BRA works OK";
            r2 := r2 +1;

            wait for 20 ns;
        end loop;

        wait for 80 ns; -- ST
        assert (t_address = "0000000000010001") report "I10 ST does not work!" severity failure;
        wait for 40 ns; -- it will be there only after 2 cycles
        assert (t_RAM(32) = x"001C") report "RAM at address 32 has wrong value!" severity failure;
        report "I10 ST works OK";

        wait for 40 ns; -- ST
        assert (t_address = "0000000000010010") report "I11 ST does not work!" severity failure;
        wait for 40 ns; -- it will be there only after 2 cycles
        -- it writes to nonexistent memory (truncates and writes to 0x00)
        assert (t_RAM(32) = x"0000") report "RAM at address 32 has wrong value!" severity failure;
        report "I11 ST works OK";

        -- enable PIO and print R2 contents TODO: fix this

        wait for 40 ns; -- BRA
        assert (t_address = "0000000000010010") report "I12 BRA does not work!" severity failure;
        report "I12 BRA works OK";
        wait for 80 ns;
        wait for 3000 ns;
    end process;


end computer_tb;
