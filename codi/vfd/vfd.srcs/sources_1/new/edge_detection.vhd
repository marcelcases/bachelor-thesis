----------------------------------------------------------------------------------
-- Component: Button Filter =
--      Clock Divider
--      + Debouncing
--      + Edge Detection
-- @marcelcases
-- 21.11.2018
-------------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity edge_detection is
    port (  clk : in std_logic;
            reset : in std_logic;
            in_raw : in std_logic;
            out_filtered : out std_logic
            );
end edge_detection;


architecture behavioral of edge_detection is
    signal q1, q0 : std_logic;
begin

process (clk) begin
    if clk'event and clk = '1' then
        if reset = '1' then
            q0 <= '0';
            q1 <= '0';
        else
            q0 <= in_raw;
            q1 <= q0;
        end if;
    end if;
end process;

out_filtered <= q0 and not q1;

end behavioral;
