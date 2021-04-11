-------------------------------------------------------------------------------
-- Variable Frequency Drive (Scalar Control) of a 3-Phase Induction Motor
-- TFG Marcel Cases
-- March 2019
-- UPC & TalTech
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- Library for sin_gen process

entity vfd is
    generic (   max_freq : integer := 50 -- 3000rpm, nominal
                );
    port (  clk, -- W5 (internal)
--            reset, -- Ve de l'adaptador de tensió , PCB -> JB10
            reset,
            down, -- btnD
            up : in std_logic; -- btnU
            enable_factor : in std_logic; -- If 0 then factor always 100%
            reset_out, pwm_wave_ph1_out, pwm_wave_ph2_out, pwm_wave_ph3_out, sync : out std_logic;
            s : out std_logic_vector (1 to 6); -- Output to the inverter (power module's 6 switces)
            led : out std_logic_vector (15 downto 0); -- Enable LED indicator
--            sw : in std_logic_vector(7 downto 0) := (others => '0');
            cat : out std_logic_vector (7 downto 0); -- To 7-seg BCDs
            an : out std_logic_vector (3 downto 0)
            );
end vfd;

architecture Behavioral of vfd is

    component sin_rom is
        port (  clk : in std_logic;
                factor : in integer range 0 to 100;
                address : in std_logic_vector (9 downto 0);
                data_out : out std_logic_vector (15 downto 0)
                );
    end component;
    
    component clock_divider is
        port (  clk : in std_logic;
                reset : in std_logic;
                eoc : in integer;
                clk_div : out std_logic
                );
    end component;
    
    component phase_gen is
        port (  clk : in  std_logic;
                reset : in  std_logic;
                enable : in std_logic;
                pwm_in : in  std_logic;
                pwm_h : out  std_logic;
                pwm_l : out  std_logic
                );
    end component;
    
    component button_filter is
        port (  clk : in std_logic;
                reset : in std_logic;
                in_raw : in std_logic;
                out_filtered : out std_logic
                );
    end component;
    
    component edge_detection is
        port (  clk : in std_logic;
                reset : in std_logic;
                in_raw : in std_logic;
                out_filtered : out std_logic
                );
    end component;
    
    component decoder is
        port (  hex : in std_logic_vector (3 downto 0);
                cat : out std_logic_vector (7 downto 0)
                );
    end component;

    function int_to_bcd (int_in : integer) return std_logic_vector is
        variable tens, unit : integer := 0;
        variable bcd_out : std_logic_vector (7 downto 0);
    begin
        if (0 < int_in) and (int_in <= max_freq) then
            tens := int_in / 10;
            unit := int_in mod 10;
            bcd_out(7 downto 4) := std_logic_vector(to_unsigned(tens, 4)); -- tens
            bcd_out(3 downto 0) := std_logic_vector(to_unsigned(unit, 4)); -- units / reminder
            return bcd_out;
        end if;
        return X"FF"; -- null
    end int_to_bcd;

-- !!! Els reals no són sintetitzables !!!    
    function get_eoc (current_freq : integer) return integer is -- Linealització valor 'eoc'
    begin
        if (current_freq > 0) then -- current_freq will be > 0
            return 100*980/current_freq;
        end if;
        return 100*980;
--        return 1960; -- 50Hz
    end get_eoc;

    signal sawtooth_wave : std_logic_vector (15 downto 0); -- Signal of sawtooth gen process
    signal sawtooth_wave_int : integer range -2**15 to 2**15-1;
    signal address_ph1 : std_logic_vector (9 downto 0);-- := (others => '0'); -- (0 graus) Input signal to sin ROM
    signal address_ph2 : std_logic_vector (9 downto 0);-- := "1010101010"; -- (120 graus) Input signal to sin ROM
    signal address_ph3 : std_logic_vector (9 downto 0);-- := "0101010101"; -- (240 graus) Input signal to sin ROM
    signal factor : integer range 0 to 100; -- := 0;
    signal sin_wave_ph1, sin_wave_ph2, sin_wave_ph3 : std_logic_vector (15 downto 0);
    signal sin_wave_clk_div : std_logic;
    signal sawtooth_wave_clk_div : std_logic;
    signal eoc_clock_divider_sin_gen, eoc_clock_divider_sawtooth_gen : integer; -- := 97656; -- 1Hz
    signal pwm_wave_ph1, pwm_wave_ph2, pwm_wave_ph3 : std_logic;
    signal enable, enable_pulse : std_logic; -- Filtered signals
    signal down_pulse, up_pulse : std_logic; -- Filtered signals
    signal current_freq : integer range 0 to 60; -- := 0; -- Current freq. value
    signal current_freq_bcd : std_logic_vector (7 downto 0); -- Current freq. value translated to BCD
    signal current_freq_bcd_mux : std_logic_vector (3 downto 0); -- Current freq. value translated to BCD previous to decoder
    signal display_clk_div : std_logic; --1kHz
    signal current_display : integer range 0 to 3;

begin

reset_out <= reset;

inst_clock_divider_sawtooth_gen : clock_divider
    port map (  clk => clk,
                reset => reset,
                eoc => eoc_clock_divider_sawtooth_gen,
                clk_div => sawtooth_wave_clk_div
                );

eoc_clock_divider_sawtooth_gen <= eoc_clock_divider_sin_gen / 128;

proc_sawtooth_gen : process (clk) begin
    if rising_edge(clk) then
        if reset = '1' then
            sawtooth_wave_int <= -2**15;
        elsif (enable = '1') then
            if sawtooth_wave_int > 2**15-1 then --32767
                sawtooth_wave_int <= -2**15;
            elsif (sawtooth_wave_clk_div = '1') then
                sawtooth_wave_int <= sawtooth_wave_int + 64;--64;--2048;
            end if;
        end if;
    end if;
end process;

sawtooth_wave <= std_logic_vector(to_unsigned(sawtooth_wave_int, 16));

conc_factor :
    factor <= 2 * current_freq when enable_factor = '0' else 100;

inst_sin_rom_ph1 : sin_rom
    port map (  clk => clk,
                factor => factor, -- 100,
                address => address_ph1,
                data_out => sin_wave_ph1
                );

inst_sin_rom_ph2 : sin_rom
    port map (  clk => clk,
                factor => factor,
                address => address_ph2,
                data_out => sin_wave_ph2
                );

inst_sin_rom_ph3 : sin_rom
    port map (  clk => clk,
                factor => factor,
                address => address_ph3,
                data_out => sin_wave_ph3
                );

inst_clock_divider_sin_gen : clock_divider
    port map (  clk => clk,
                reset => reset,
                eoc => eoc_clock_divider_sin_gen, -- Means : freq. sawtooth_wave = (eoc + 1) * freq. sin_wave
                clk_div => sin_wave_clk_div
                );

func_get_eoc_clock_divider_sin_gen : -- gestió de 'eoc' per crear una frequencia determinada al sin
    eoc_clock_divider_sin_gen <= get_eoc(current_freq); -- f=50Hz -> eoc=1960

proc_sin_gen : process (clk) begin
    if rising_edge(clk) then
        if (reset = '1') or (enable_pulse = '1') then
            address_ph1 <= (others => '0'); -- (0 graus)
            address_ph2 <= "1010101010"; --682 (240 graus)
            address_ph3 <= "0101010101"; --341 (120 graus)
        elsif (enable = '1')  and (sin_wave_clk_div = '1') then
            address_ph1 <= address_ph1 + 1;
            address_ph2 <= address_ph2 + 1;
            address_ph3 <= address_ph3 + 1;
        end if;
    end if;     
end process;

sync <= '1' when address_ph1 >= "0111111111" else '0';

enable <= '1' when current_freq >= 1 else '0';

inst_edge_detection_enable : edge_detection
    port map (  clk => clk,
                reset => reset,
                in_raw => enable,
                out_filtered => enable_pulse
                );

proc_set_freq_up_down_counter : process (clk) begin
    if rising_edge(clk) then
        if (reset = '1') then
            current_freq <= 0;
        elsif (up_pulse = '1') and (current_freq < max_freq) then -- !!! canviar a up_pulse per sintesi Upper limit
            current_freq <= current_freq + 1;
        elsif (down_pulse = '1') and (current_freq > 0) then -- Lower limit
            current_freq <= current_freq - 1;
        end if;
    end if;    
end process;

conc_pwm_gen :
    pwm_wave_ph1 <= '1' when (to_integer(signed(sawtooth_wave)) < to_integer(signed(sin_wave_ph1))) and (enable = '1') else '0';
    pwm_wave_ph2 <= '1' when (to_integer(signed(sawtooth_wave)) < to_integer(signed(sin_wave_ph2))) and (enable = '1') else '0';
    pwm_wave_ph3 <= '1' when (to_integer(signed(sawtooth_wave)) < to_integer(signed(sin_wave_ph3))) and (enable = '1') else '0';
    pwm_wave_ph1_out <= pwm_wave_ph1;
    pwm_wave_ph2_out <= pwm_wave_ph2;
    pwm_wave_ph3_out <= pwm_wave_ph3;

inst_igbt_signals_leg1 : phase_gen
    port map (  clk => clk,
                reset => reset,
                enable => enable,
                pwm_in => pwm_wave_ph1,
                pwm_h => s(1),
                pwm_l => s(4)
                );

inst_igbt_signals_leg2 : phase_gen
    port map (  clk => clk,
                reset => reset,
                enable => enable,
                pwm_in => pwm_wave_ph2,
                pwm_h => s(3),
                pwm_l => s(6)
                );

inst_igbt_signals_leg3 : phase_gen
    port map (  clk => clk,
                reset => reset,
                enable => enable,
                pwm_in => pwm_wave_ph3,
                pwm_h => s(5),
                pwm_l => s(2)
                );


-- User interface and control --

inst_button_filter_down : button_filter
    port map (  clk => clk,
                reset => reset,
                in_raw => down,
                out_filtered => down_pulse
                );

inst_button_filter_up : button_filter
    port map (  clk => clk,
                reset => reset,
                in_raw => up,
                out_filtered => up_pulse
                );

--led <= (others => enable); --factor
proc_led_factor : process (clk) begin
    if rising_edge(clk) then
        if (factor <= 1) then
            led <= (others => '0');
        elsif (factor > 1) and (factor <= 6) then
            led <= "1000000000000000";
        elsif (factor > 6) and (factor <= 12) then
            led <= "1100000000000000";
        elsif (factor > 12) and (factor <= 18) then
            led <= "1110000000000000";
        elsif (factor > 18) and (factor <= 24) then
            led <= "1111000000000000";
        elsif (factor > 24) and (factor <= 30) then
            led <= "1111100000000000";
        elsif (factor > 30) and (factor <= 36) then
            led <= "1111110000000000";
        elsif (factor > 36) and (factor <= 42) then
            led <= "1111111000000000";
        elsif (factor > 42) and (factor <= 48) then
            led <= "1111111100000000";
        elsif (factor > 48) and (factor <= 60) then
            led <= "1111111110000000";
        elsif (factor > 60) and (factor <= 66) then
            led <= "1111111111000000";
        elsif (factor > 66) and (factor <= 72) then
            led <= "1111111111100000";
        elsif (factor > 72) and (factor <= 78) then
            led <= "1111111111110000";
        elsif (factor > 78) and (factor <= 84) then
            led <= "1111111111111000";
        elsif (factor > 84) and (factor <= 90) then
            led <= "1111111111111100";
        elsif (factor > 90) and (factor <= 98) then
            led <= "1111111111111110";
        else
            led <= (others => '1');
        end if;
    end if;    
end process;

current_freq_bcd <= int_to_bcd(current_freq);

with current_display select
    current_freq_bcd_mux <=
        current_freq_bcd(3 downto 0)      when 0,
        current_freq_bcd(7 downto 4)      when 1,
        "0000"                        when others;

inst_decoder_display_i : decoder
    port map (  hex => current_freq_bcd_mux,
                cat => cat
                );

inst_clock_divider_display : clock_divider
    port map (  clk => clk,
                reset => reset,
                eoc => 99999, -- 1kHz, enough for readable freq.
                clk_div => display_clk_div
                );

proc_display_mux : process (clk) begin
    if rising_edge(clk) then
        if reset = '1' then
            current_display <= 0;
        elsif display_clk_div = '1' then
            current_display <= current_display + 1;
        end if;
    end if;
end process;

gen_an_mux: for i in 0 to 3 generate
    an(i) <= '0' when current_display = i and i <= 1 and reset /= '1' else '1';
end generate;

end Behavioral;
