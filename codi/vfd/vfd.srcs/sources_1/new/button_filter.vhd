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


entity button_filter is
    port (  clk : in std_logic;
            reset : in std_logic;
            in_raw : in std_logic;
            out_filtered : out std_logic
            );
end button_filter;


architecture behavioral of button_filter is
    signal counter: integer range 0 to 999999; -- 1. Clock Division
    signal clk_100Hz : std_logic;
    signal q : std_logic_vector (0 to 3); -- 2. Debouncing
    signal d, post_debouncing : std_logic;
    signal q1, q0 : std_logic; -- 3. Edge Detection
begin

-- 1. Clock divider
process (clk) begin
    if clk'event and clk = '1' then
        clk_100Hz <= '0';
        if reset = '1' then
            counter <= 0;
        elsif counter = 999999 then
            counter <= 0;
            clk_100Hz <= '1';
        else counter <= counter + 1;
        end if;
    end if;
end process;

-- 2. Debouncing
process (clk) begin
    if clk'event and clk = '1' then
        if reset = '1' then
            q <= (others => '0');
        elsif clk_100Hz = '1' then
            q(0) <= d;
            q(1 to 3) <= q(0 to 2);
        end if;
    end if;
end process;

d <= in_raw;
post_debouncing <= '1' when Q = "1111" else '0';

-- 3. Edge Detection
process (clk) begin
    if clk'event and clk = '1' then
        if reset = '1' then
            q0 <= '0';
            q1 <= '0';
        else
            q0 <= post_debouncing;
            q1 <= q0;
        end if;
    end if;
end process;

out_filtered <= q0 and not q1;

end behavioral;
