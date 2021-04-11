----------------------------------------------------------------------------------
-- Designer: @marcelcases
-- Create Date: 21.06.2018 19:46:45
-- Module Name: park
-- Description: Space Vector Pulse Width Modulation
-- Target Devices: Artix 7 - Basys 3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity svpwm is
    port (  clk, reset : in std_logic;
            v_alpha, v_beta: in integer; 
            s : out std_logic_vector(1 to 6)
            );
end svpwm;

architecture behavioral of svpwm is
    signal s_buff : std_logic_vector(1 to 6); -- buffer for switches
    signal sector : integer range 0 to 7 := 0;
    signal vector, pwm_h, pwm_l : std_logic_vector(2 downto 0) := "000";
    type sector_type is (s0, s1, s2, s3, s4, s5, s6, s7);
        signal state, next_state : sector_type;

begin

output_decode : process (state) begin
    case state is
        when s0 =>
            pwm_h <= "000";
            pwm_l <= "000";
        when s1 =>
            pwm_h <= "010";
            pwm_l <= "110";
        when s2 =>
            pwm_h <= "100";
            pwm_l <= "101";
        when s3 =>
            pwm_h <= "100";
            pwm_l <= "110";
        when s4 =>
            pwm_h <= "001";
            pwm_l <= "011";
        when s5 =>
            pwm_h <= "010";
            pwm_l <= "011";
        when s6 =>
            pwm_h <= "001";
            pwm_l <= "101";
        when s7 =>
            pwm_h <= "111";
            pwm_l <= "111";
    end case;
end process;

next_state_decode : with sector select
    next_state <=
        s0 when 0,
        s1 when 1,
        s2 when 2,
        s3 when 3,
        s4 when 4,
        s5 when 5,
        s6 when 6,
        s7 when 7;

state_decode : process (clk) begin
	if rising_edge(clk) then
		if reset = '1' then
			state <= s0;
		else
			state <= next_state;
		end if;
	end if;
end process;

sector_determination : process (clk) begin
    if rising_edge(clk) then
        if (reset = '1') then
            sector <= 0;
        elsif (v_beta >= 0) then
            if (v_alpha >= 50) then
                sector <= 3;
            elsif (v_alpha <= -50) then
                sector <= 5;
            else
                sector <= 1;
            end if;
        else
            if (v_alpha >= 50) then
                sector <= 2;
            elsif (v_alpha <= -50) then
                sector <= 4;
            else
                sector <= 6;
            end if;
        end if;
    end if;
end process;

proc_pwm_switching : process begin
    vector <= pwm_h; wait for 5us;
    vector <= pwm_l; wait for 5us;
end process;

s_buff(1) <= vector(0);
s_buff(3) <= vector(1);
s_buff(5) <= vector(2);
s_buff(4) <= not(s_buff(1));
s_buff(6) <= not(s_buff(3));
s_buff(2) <= not(s_buff(5));
s <= s_buff;

end behavioral;
