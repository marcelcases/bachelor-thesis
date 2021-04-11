----------------------------------------------------------------------------------
-- Designer: @marcelcases
-- Create Date: 21.06.2018 19:46:45
-- Module Name: foc (top level)
-- Description: VHDL design for Field Oriented Control of an induction motor
-- Target Devices: Artix 7 - Basys 3
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity foc is
    generic (   int_min : integer := -1000;
                int_max : integer := 1000
--                slip : integer := 10 -- lliscament (degrees)
                );
    port (  clk, reset : in std_logic;
            i_a, i_b, i_c : in integer range int_min to int_max;
            theta : in integer range 0 to 359; -- rotor flux position
            v_d_ref, v_q_ref : in integer; -- torque reference and flux reference
            s : out std_logic_vector(1 to 6)
            );
end foc;

architecture behavioral of foc is

    component clarke
        port (  a, b : in integer;
                alpha, beta : out integer
                );
    end component;

    component park
        port (  clk, reset : in std_logic;
                alpha, beta : in integer;
                theta : in integer;
                d, q : out integer
                );
    end component;
    
    component invpark is
        port (  clk, reset : in std_logic;
                d, q : in integer;
                theta : in integer;
                alpha, beta : out integer
                );
    end component;

    component svpwm is
        port (  clk, reset : in std_logic;
                v_alpha, v_beta: in integer; 
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
    
    signal i_alpha, i_beta : integer range int_min to int_max := 0; -- Connection: Clarke tr. to Park tr.
    signal i_d, i_q : integer range int_min to int_max := int_min; -- Current flux (d) and Current torque (q) output

    signal v_alpha_ref, v_beta_ref : integer; -- Connection: InvPark to SVPWM

begin

inst_clarke : clarke
    port map (  a => i_a,
                b => i_b,
                alpha => i_alpha,
                beta => i_beta
                );

inst_park : park
    port map (  clk => clk,
                reset => reset,
                alpha => i_alpha,
                beta => i_beta,
                theta => theta,
                d => i_d,
                q => i_q
                );

inst_invpark : invpark
    port map (  clk => clk,
                reset => reset,
                d => v_d_ref,
                q => v_q_ref,
                theta => theta,
                alpha => v_alpha_ref,
                beta => v_beta_ref
                );

inst_svpwm : svpwm
    port map (  clk => clk,
                reset => reset,
                v_alpha => v_alpha_ref,
                v_beta => v_beta_ref,
                s => s
                );

stimulus: process begin
    wait;
end process;

end behavioral;
