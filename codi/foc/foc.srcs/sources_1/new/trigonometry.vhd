library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity trigonometry is
    port (  clk, reset : in std_logic;
            address : in integer range 0 to 359;
            sin, cos : out real range -1.0000 to 1.0000
            );
end trigonometry;

architecture behavioral of trigonometry is

    type rom_type is array (0 to 359) of real range -1.0000 to 1.0000;
    constant rom : rom_type := (
    0.0000	,
    0.0175    ,
    0.0349    ,
    0.0523    ,
    0.0698    ,
    0.0872    ,
    0.1045    ,
    0.1219    ,
    0.1392    ,
    0.1564    ,
    0.1736    ,
    0.1908    ,
    0.2079    ,
    0.2250    ,
    0.2419    ,
    0.2588    ,
    0.2756    ,
    0.2924    ,
    0.3090    ,
    0.3256    ,
    0.3420    ,
    0.3584    ,
    0.3746    ,
    0.3907    ,
    0.4067    ,
    0.4226    ,
    0.4384    ,
    0.4540    ,
    0.4695    ,
    0.4848    ,
    0.5000    ,
    0.5150    ,
    0.5299    ,
    0.5446    ,
    0.5592    ,
    0.5736    ,
    0.5878    ,
    0.6018    ,
    0.6157    ,
    0.6293    ,
    0.6428    ,
    0.6561    ,
    0.6691    ,
    0.6820    ,
    0.6947    ,
    0.7071    ,
    0.7193    ,
    0.7314    ,
    0.7431    ,
    0.7547    ,
    0.7660    ,
    0.7771    ,
    0.7880    ,
    0.7986    ,
    0.8090    ,
    0.8192    ,
    0.8290    ,
    0.8387    ,
    0.8480    ,
    0.8572    ,
    0.8660    ,
    0.8746    ,
    0.8829    ,
    0.8910    ,
    0.8988    ,
    0.9063    ,
    0.9135    ,
    0.9205    ,
    0.9272    ,
    0.9336    ,
    0.9397    ,
    0.9455    ,
    0.9511    ,
    0.9563    ,
    0.9613    ,
    0.9659    ,
    0.9703    ,
    0.9744    ,
    0.9781    ,
    0.9816    ,
    0.9848    ,
    0.9877    ,
    0.9903    ,
    0.9925    ,
    0.9945    ,
    0.9962    ,
    0.9976    ,
    0.9986    ,
    0.9994    ,
    0.9998    ,
    1.0000    ,
    0.9998    ,
    0.9994    ,
    0.9986    ,
    0.9976    ,
    0.9962    ,
    0.9945    ,
    0.9925    ,
    0.9903    ,
    0.9877    ,
    0.9848    ,
    0.9816    ,
    0.9781    ,
    0.9744    ,
    0.9703    ,
    0.9659    ,
    0.9613    ,
    0.9563    ,
    0.9511    ,
    0.9455    ,
    0.9397    ,
    0.9336    ,
    0.9272    ,
    0.9205    ,
    0.9135    ,
    0.9063    ,
    0.8988    ,
    0.8910    ,
    0.8829    ,
    0.8746    ,
    0.8660    ,
    0.8572    ,
    0.8480    ,
    0.8387    ,
    0.8290    ,
    0.8192    ,
    0.8090    ,
    0.7986    ,
    0.7880    ,
    0.7771    ,
    0.7660    ,
    0.7547    ,
    0.7431    ,
    0.7314    ,
    0.7193    ,
    0.7071    ,
    0.6947    ,
    0.6820    ,
    0.6691    ,
    0.6561    ,
    0.6428    ,
    0.6293    ,
    0.6157    ,
    0.6018    ,
    0.5878    ,
    0.5736    ,
    0.5592    ,
    0.5446    ,
    0.5299    ,
    0.5150    ,
    0.5000    ,
    0.4848    ,
    0.4695    ,
    0.4540    ,
    0.4384    ,
    0.4226    ,
    0.4067    ,
    0.3907    ,
    0.3746    ,
    0.3584    ,
    0.3420    ,
    0.3256    ,
    0.3090    ,
    0.2924    ,
    0.2756    ,
    0.2588    ,
    0.2419    ,
    0.2250    ,
    0.2079    ,
    0.1908    ,
    0.1736    ,
    0.1564    ,
    0.1392    ,
    0.1219    ,
    0.1045    ,
    0.0872    ,
    0.0698    ,
    0.0523    ,
    0.0349    ,
    0.0175    ,
    0.0000    ,
    -0.0175    ,
    -0.0349    ,
    -0.0523    ,
    -0.0698    ,
    -0.0872    ,
    -0.1045    ,
    -0.1219    ,
    -0.1392    ,
    -0.1564    ,
    -0.1736    ,
    -0.1908    ,
    -0.2079    ,
    -0.2250    ,
    -0.2419    ,
    -0.2588    ,
    -0.2756    ,
    -0.2924    ,
    -0.3090    ,
    -0.3256    ,
    -0.3420    ,
    -0.3584    ,
    -0.3746    ,
    -0.3907    ,
    -0.4067    ,
    -0.4226    ,
    -0.4384    ,
    -0.4540    ,
    -0.4695    ,
    -0.4848    ,
    -0.5000    ,
    -0.5150    ,
    -0.5299    ,
    -0.5446    ,
    -0.5592    ,
    -0.5736    ,
    -0.5878    ,
    -0.6018    ,
    -0.6157    ,
    -0.6293    ,
    -0.6428    ,
    -0.6561    ,
    -0.6691    ,
    -0.6820    ,
    -0.6947    ,
    -0.7071    ,
    -0.7193    ,
    -0.7314    ,
    -0.7431    ,
    -0.7547    ,
    -0.7660    ,
    -0.7771    ,
    -0.7880    ,
    -0.7986    ,
    -0.8090    ,
    -0.8192    ,
    -0.8290    ,
    -0.8387    ,
    -0.8480    ,
    -0.8572    ,
    -0.8660    ,
    -0.8746    ,
    -0.8829    ,
    -0.8910    ,
    -0.8988    ,
    -0.9063    ,
    -0.9135    ,
    -0.9205    ,
    -0.9272    ,
    -0.9336    ,
    -0.9397    ,
    -0.9455    ,
    -0.9511    ,
    -0.9563    ,
    -0.9613    ,
    -0.9659    ,
    -0.9703    ,
    -0.9744    ,
    -0.9781    ,
    -0.9816    ,
    -0.9848    ,
    -0.9877    ,
    -0.9903    ,
    -0.9925    ,
    -0.9945    ,
    -0.9962    ,
    -0.9976    ,
    -0.9986    ,
    -0.9994    ,
    -0.9998    ,
    -1.0000    ,
    -0.9998    ,
    -0.9994    ,
    -0.9986    ,
    -0.9976    ,
    -0.9962    ,
    -0.9945    ,
    -0.9925    ,
    -0.9903    ,
    -0.9877    ,
    -0.9848    ,
    -0.9816    ,
    -0.9781    ,
    -0.9744    ,
    -0.9703    ,
    -0.9659    ,
    -0.9613    ,
    -0.9563    ,
    -0.9511    ,
    -0.9455    ,
    -0.9397    ,
    -0.9336    ,
    -0.9272    ,
    -0.9205    ,
    -0.9135    ,
    -0.9063    ,
    -0.8988    ,
    -0.8910    ,
    -0.8829    ,
    -0.8746    ,
    -0.8660    ,
    -0.8572    ,
    -0.8480    ,
    -0.8387    ,
    -0.8290    ,
    -0.8192    ,
    -0.8090    ,
    -0.7986    ,
    -0.7880    ,
    -0.7771    ,
    -0.7660    ,
    -0.7547    ,
    -0.7431    ,
    -0.7314    ,
    -0.7193    ,
    -0.7071    ,
    -0.6947    ,
    -0.6820    ,
    -0.6691    ,
    -0.6561    ,
    -0.6428    ,
    -0.6293    ,
    -0.6157    ,
    -0.6018    ,
    -0.5878    ,
    -0.5736    ,
    -0.5592    ,
    -0.5446    ,
    -0.5299    ,
    -0.5150    ,
    -0.5000    ,
    -0.4848    ,
    -0.4695    ,
    -0.4540    ,
    -0.4384    ,
    -0.4226    ,
    -0.4067    ,
    -0.3907    ,
    -0.3746    ,
    -0.3584    ,
    -0.3420    ,
    -0.3256    ,
    -0.3090    ,
    -0.2924    ,
    -0.2756    ,
    -0.2588    ,
    -0.2419    ,
    -0.2250    ,
    -0.2079    ,
    -0.1908    ,
    -0.1736    ,
    -0.1564    ,
    -0.1392    ,
    -0.1219    ,
    -0.1045    ,
    -0.0872    ,
    -0.0698    ,
    -0.0523    ,
    -0.0349    ,
    -0.0175
    );

    signal address_90 : integer range 0 to 359 := 89;

begin

process (clk) begin
    if(rising_edge(clk)) then
        sin <= rom(address);
        cos <= rom(address_90);
    end if;
end process;

process (clk) begin
    if(rising_edge(clk)) then
        if (address >= 269) then
            address_90 <= address - 269;
        else
            address_90 <= address + 90;
        end if;
    end if;
end process;

end behavioral;
