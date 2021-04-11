----------------------------------------------------------------------------------
-- Designer: @marcelcases
-- Create Date: 21.06.2018 19:46:45
-- Module Name: foc (testbench)
-- Description: VHDL design for Field Oriented Control of an induction motor
-- Target Devices: Artix 7 - Basys 3
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity foc_tb is
    generic (   int_min : integer := -1000;
                int_max : integer := 1000;
                slip : integer := 10 -- lliscament (degrees)
                );
end foc_tb;

architecture testbench of foc_tb is

    component foc is
        generic (   int_min : integer := int_min;
                    int_max : integer := int_max;
                    slip : integer := slip
                    );
        port (  clk, reset : in std_logic;
                i_a, i_b, i_c : in integer range int_min to int_max;
                theta : in integer range 0 to 359; -- rotor flux position   
                v_d_ref, v_q_ref : in integer; -- torque reference and flux reference
                s : out std_logic_vector(1 to 6)
                );
    end component;

    component trigonometry is
        port (  clk, reset : in std_logic;
                address : in integer range 0 to 359;
                sin, cos : out real range -1.0000 to 1.0000
                );
    end component;
    
    component clock_divider is
        port (  clk : in std_logic;
                reset : in std_logic;
                eoc : in integer;
                clk_div : out std_logic
                );
    end component;

    signal clk_tb : std_logic := '0'; -- font de la senyal (intern, w5)
    signal reset_tb : std_logic := '0'; -- posada a zero (pel reset) (boto)

    signal i_a_tb, i_b_tb, i_c_tb : integer range int_min to int_max := 0; -- lectura adc intensitats fase 'a', 'b', 'c'
    signal i_a_real_tb, i_b_real_tb, i_c_real_tb : real := 0.0000;
    signal theta_tb : integer range 0 to 359 := slip; -- rotor flux position
    signal theta_120_tb : integer range 0 to 359 := 119 + slip; -- rotor flux position + 120 degrees + slip
    signal theta_240_tb : integer range 0 to 359 := 239 + slip; -- rotor flux position + 240 degrees + slip
    signal clk_div_theta : std_logic;
    
    signal v_alpha_ref, v_beta_ref : integer; -- Connection: InvPark to SVPWM

    signal s_tb : std_logic_vector(1 to 6); -- Output to the inverter (power module's 6 switces)

begin

clk_tb <= not clk_tb after 5ns; --half_period

inst_clock_divider_theta : clock_divider
    port map (  clk => clk_tb,
                reset => reset_tb,
                eoc => 100,
                clk_div => clk_div_theta
                );

proc_counter_theta : process (clk_tb) begin
    if rising_edge(clk_tb) then
        if (theta_tb >= 359) then
            theta_tb <= 0;
        elsif (theta_120_tb >= 359) then
            theta_120_tb <= 0;
        elsif (theta_240_tb >= 359) then
            theta_240_tb <= 0;
        elsif (clk_div_theta = '1') then
            theta_tb <= theta_tb + 1;
            theta_120_tb <= theta_120_tb + 1;
            theta_240_tb <= theta_240_tb + 1;
        end if;
    end if;
end process;

inst_current_wave_gen_phase_a : trigonometry 
    port map (  clk => clk_tb,
                reset => reset_tb,
                address  => theta_tb,
                sin => i_a_real_tb
                );

inst_current_wave_gen_phase_b : trigonometry 
    port map (  clk => clk_tb,
                reset => reset_tb,
                address  => theta_240_tb,
                sin => i_b_real_tb
                );

inst_current_wave_gen_phase_c : trigonometry 
    port map (  clk => clk_tb,
                reset => reset_tb,
                address  => theta_120_tb,
                sin => i_c_real_tb
                );

i_a_tb <= integer(100.0*i_a_real_tb);
i_b_tb <= integer(100.0*i_b_real_tb);
i_c_tb <= integer(100.0*i_c_real_tb);

inst_foc : foc
    generic map (   int_min => int_min,
                    int_max => int_max,
                    slip => slip
                    )
    port map (  clk => clk_tb,
                reset => reset_tb,
                i_a => i_a_tb,
                i_b => i_b_tb,
                i_c => i_c_tb,
                theta => theta_tb,
                v_d_ref => 86,
                v_q_ref => 50,
                s => s_tb
                );

stimulus: process begin
    wait;
end process;

end testbench;
