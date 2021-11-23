library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.microcode_instructions.all;
use work.assembly_instructions.all;

entity fake_memory is
    port(address	: in STD_LOGIC_VECTOR(7 downto 0);
        clock		: in STD_LOGIC := '1';
        data		: in STD_LOGIC_VECTOR(15 downto 0);
        wren		: in STD_LOGIC;
        q		    : out STD_LOGIC_VECTOR(15 downto 0));
end fake_memory;

architecture fake of fake_memory is
     signal RAM:program(0 to 255):=(
          (LDI & R5 & B"1_0000_0000"),
          (ADD & R5 & R5 & R5 & Tail3),
          (ADD & R5 & R5 & R5 & Tail3),
          (ADD & R5 & R5 & R5 & Tail3),
          (ADD & R5 & R5 & R5 & Tail3),
          (LDI & R6 & '0' & X"20"),
          (LDI & R3 & B"0_0000_0011"),
          (ST & Tail3 & R6 & R3 & Tail3),
          (LDI & R1 & B"0_0000_0001"),
          (LDI & R0 & B"0_0000_1110"),
          (MOV & R2 & R0 & Tail3 & Tail3),
          (ADD & R2 & R2 & R1 & Tail3),
          (iSUB & R0 & R0 & R1 & Tail3),
          (BRZ & X"003"),
          (NOP & Tail3 & Tail3 & Tail3 & Tail3),
          (BRA & X"0FC"),
          (ST & Tail3 & R6 & R2 & Tail3),
          (ST & Tail3 & R5 & R2 & Tail3),
          (BRA & X"000"),
          others=>(NOP & R0 & R0 & R0 & Tail3));

begin
    process (clock, address, data, wren)
    begin
        if rising_edge(clock) then
            if wren = '1' then
                RAM(to_integer(unsigned(address))) <= data;
            end if;
        end if;
        q <= RAM(to_integer(unsigned(address)));
    end process;
end fake;
