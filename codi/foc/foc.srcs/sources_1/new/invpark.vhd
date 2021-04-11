----------------------------------------------------------------------------------
-- Designer: @marcelcases
-- Create Date: 21.06.2018 19:46:45
-- Module Name: invpark
-- Description: The (d,q)->(alpha,beta) projection (inverse Park transformation)
-- Target Devices: Artix 7 - Basys 3
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity invpark is
    port (  clk, reset : in std_logic;
            d, q : in integer;
            theta : in integer;
            alpha, beta : out integer
            );
end invpark;

architecture behavioral of invpark is

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

alpha <= integer(real(d)*cos - real(q)*sin);
beta <= integer(real(d)*sin + real(q)*cos);

end behavioral;