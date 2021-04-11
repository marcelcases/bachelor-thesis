-------------------------------------------------------------------------------
-- Component : LUT eoc
-------------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity eoc_lut is
    port (  clk : in std_logic;
            factor : in real;-- per reduir ampl. senyal sinus
            address : in std_logic_vector (9 downto 0);
            data_out : out std_logic_vector (15 downto 0)
            );
end eoc_lut;

architecture Behavioral of eoc_lut is

    type lut_type is array (2 to 50) of integer range 0 to 48800;
    constant lut : lut_type := (
    48800	,
    32533    ,
    24400    ,
    19520    ,
    16267    ,
    13943    ,
    12200    ,
    10844    ,
    9760    ,
    8873    ,
    8133    ,
    7508    ,
    6971    ,
    6507    ,
    6100    ,
    5741    ,
    5422    ,
    5137    ,
    4880    ,
    4648    ,
    4436    ,
    4243    ,
    4067    ,
    3904    ,
    3754    ,
    3615    ,
    3486    ,
    3366    ,
    3253    ,
    3148    ,
    3050    ,
    2958    ,
    2871    ,
    2789    ,
    2711    ,
    2638    ,
    2568    ,
    2503    ,
    2440    ,
    2380    ,
    2324    ,
    2270    ,
    2218    ,
    2169    ,
    2122    ,
    2077    ,
    2033    ,
    1992    ,
    1952    
    );

begin

process (clk) begin
    if(rising_edge(clk)) then
        data_out <= std_logic_vector(to_unsigned(integer(factor*real(rom(to_integer(unsigned(address))))), 16));
        --data_out <= std_logic_vector(to_unsigned(rom(to_integer(unsigned(address))), 16));
    end if;
end process;

end Behavioral;
