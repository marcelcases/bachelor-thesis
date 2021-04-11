-------------------------------------------------------------------------------
-- Component : Sawtooth Signal Generation
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sawtooth_gen is
    port (  clk, reset : in std_logic;
            sawtooth : out integer
            );
end sawtooth_gen;

architecture Behavioral of sawtooth_gen is
    signal counter : integer range 0 to 2**15-1 := 0;
begin

process (clk) is begin
    if rising_edge(clk) then
        if reset = '1' then
            counter <= 0;
        elsif counter = 2**15-1 then --32767
            counter <= 0;
        else
            counter <= counter + 1;
        end if;
    end if;
end process;

sawtooth <= counter;

end Behavioral;
