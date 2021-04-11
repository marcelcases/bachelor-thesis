-------------------------------------------------------------------------------
-- Park transformation
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity park is
    port (  clk, reset : in std_logic;
            alpha, beta : in integer;
            theta : in integer;
            d, q : out integer
            );
end park;

architecture behavioral of park is

    component trigonometry is
        port (  clk, reset : in std_logic;
                address : in integer range 0 to 359;
                sin, cos : out real range -1.0000 to 1.0000
                );
    end component;

    signal sin, cos : real range -1.0000 to 1.0000;

begin

inst_trigonometry : trigonometry 
    port map (  clk => clk,
                reset => reset,
                address  => theta,
                sin => sin,
                cos => cos
                );

d <= integer(real(alpha)*cos + real(beta)*sin);
q <= integer(-real(alpha)*sin + real(beta)*cos);

end behavioral;
