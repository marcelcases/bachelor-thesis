----------------------------------------------------------------------------------
-- Component : Clock Divider
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider is
    port (  clk : in std_logic;
            reset : in std_logic;
            eoc : in integer;
            clk_div : out std_logic
            );
end clock_divider;

architecture behavioral of clock_divider is
    signal counter: integer range 0 to 2147483647;
begin

process (clk) begin
    if rising_edge(clk) then
        clk_div <= '0';
        if reset = '1' then
            counter <= 0;
        elsif counter > eoc then
            counter <= 0;
            clk_div <= '1';
        else counter <= counter + 1;
        end if;
    end if;
end process;

end behavioral;