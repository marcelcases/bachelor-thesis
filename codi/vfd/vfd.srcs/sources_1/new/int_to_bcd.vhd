-------------------------------------------------------------------------------
-- Component : Unsigned Integer to Binary Coded Decimal (BCD)
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;

entity int_to_bcd is
    port (  int_in : in integer range 0 to 60;
            bcd_out : out std_logic_vector (7 downto 0)
            );
end int_to_bcd;

architecture Behavioral of int_to_bcd is begin

with int_in select
    bcd_out <=
        X"01" when 1,
        X"02" when 2,
        X"03" when 3,
        X"04" when 4,
        X"05" when 5,
        X"06" when 6,
        X"07" when 7,
        X"08" when 8,
        X"09" when 9,
        X"10" when 10,
        X"11" when 11,
        X"12" when 12,
        X"13" when 13,
        X"14" when 14,
        X"15" when 15,
        X"16" when 16,
        X"17" when 17,
        X"18" when 18,
        X"19" when 19,
        X"20" when 20,
        X"21" when 21,
        X"22" when 22,
        X"23" when 23,
        X"24" when 24,
        X"25" when 25,
        X"26" when 26,
        X"27" when 27,
        X"28" when 28,
        X"29" when 29,
        X"30" when 30,
        X"31" when 31,
        X"32" when 32,
        X"33" when 33,
        X"34" when 34,
        X"35" when 35,
        X"36" when 36,
        X"37" when 37,
        X"38" when 38,
        X"39" when 39,
        X"40" when 40,
        X"41" when 41,
        X"42" when 42,
        X"43" when 43,
        X"44" when 44,
        X"45" when 45,
        X"46" when 46,
        X"47" when 47,
        X"48" when 48,
        X"49" when 49,
        X"50" when 50,
        X"51" when 51,
        X"52" when 52,
        X"53" when 53,
        X"54" when 54,
        X"55" when 55,
        X"56" when 56,
        X"57" when 57,
        X"58" when 58,
        X"59" when 59,
        X"60" when 60,
        X"FF" when others; -- null

end Behavioral;
