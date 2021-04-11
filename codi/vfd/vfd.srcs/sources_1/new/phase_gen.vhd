----------------------------------------------------------------------------------
-- Component : Phase Generation + dead time
-- Input <- PWM
-- Output -> PWM high and PWM low to the inverter
-------------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_gen is
    port (  clk : in  std_logic;
            reset : in  std_logic;
            enable : in std_logic;
            pwm_in : in  std_logic;
            pwm_h : out  std_logic;
            pwm_l : out  std_logic
            );
end phase_gen;

architecture Behavioral of phase_gen is
    type type_state_pwm is (f0,f1,f2,f3,f4);
    signal estat_pwm, estat_pwm_next : type_state_pwm;
    signal compt_dt, compt_dt_next :integer range 0 to 200; -- temp pel dead time (2us)
    signal compt_wdt, compt_wdt_next : integer range 0 to 10000000; -- temp del watchdog timer. Si pwm_in està 100ms sense commutar, passa a l'estat 0

begin

-- Màquina d'estats per a la generacio dels dos senyals (alt i baix) pwm:

pwm_sync: process (clk,reset) begin
if clk'event and clk = '1' then
	if reset = '1' then
		estat_pwm <= f0;
		compt_dt <= 0;
		compt_wdt <= 0;
	else
		estat_pwm <= estat_pwm_next;
		compt_dt <= compt_dt_next;
		compt_wdt <= compt_wdt_next;
	end if;
end if;
end process;

pwm_comb: process (pwm_in,estat_pwm,compt_dt,compt_wdt) begin
estat_pwm_next <= estat_pwm;
compt_dt_next <= compt_dt;
compt_wdt_next <= compt_wdt;
case estat_pwm is
	when f0 =>
		if pwm_in = '1' then
			compt_dt_next <= 0;
			compt_wdt_next <= 0;
			estat_pwm_next <= f2;
		end if;
	when f1 =>
		if compt_wdt = 10000000 then
			estat_pwm_next <= f0;
		elsif pwm_in = '1' then
			compt_dt_next <= 0;
			compt_wdt_next <= 0;
			estat_pwm_next <= f2;
		else
			compt_wdt_next <= compt_wdt + 1;
		end if;
	when f2 =>
		if compt_dt = 200 then
			estat_pwm_next <= f3;
		elsif pwm_in = '0' then
			estat_pwm_next <= f0;
		else
			compt_dt_next <= compt_dt + 1;
		end if;
		compt_wdt_next <= compt_wdt + 1;
	when f3 =>
		if compt_wdt = 10000000 then
			estat_pwm_next <= f0;
		elsif pwm_in = '0' then
			compt_dt_next <= 0;
			compt_wdt_next <= 0;
			estat_pwm_next <= f4;
		else 
			compt_wdt_next <= compt_wdt + 1;
		end if;
	when f4 =>
		if compt_dt = 200 then
			estat_pwm_next <= f1;
		elsif pwm_in = '1' then
			estat_pwm_next <= f0;
		else
			compt_dt_next <= compt_dt + 1;
		end if;
		compt_wdt_next <= compt_wdt + 1;
end case;
end process;

pwm_h <= '1' when estat_pwm = f3 and enable = '1' else '0';
pwm_l <= '1' when estat_pwm = f1 and enable = '1' else '0';

end Behavioral;
