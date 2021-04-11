----------------------------------------------------------------------------------
-- Designer: @marcelcases
-- Create Date: 21.06.2018 19:46:45
-- Module Name: clarke
-- Description: The (a,b,c)->(alpha,beta) projection (Clarke transformation)
-- Target Devices: Artix 7 - Basys 3
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clarke is
    port (  a, b: in integer;
            alpha, beta : out integer
            );
end clarke;

architecture behavioral of clarke is begin

alpha <= a;
beta <= integer(0.5774*real(a) + 1.1547*real(b));

end behavioral;