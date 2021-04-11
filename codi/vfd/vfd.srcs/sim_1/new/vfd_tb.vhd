-------------------------------------------------------------------------------
-- Testbench : Variable Frequency Control of a 3-Phase Induction Motor
-------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity vfd_tb is
end vfd_tb;

architecture Behavioral of vfd_tb is

    component vfd is
        port (  clk, reset, down, up, enable_factor: in std_logic;
                s : out std_logic_vector (1 to 6)
                );
    end component;

    signal clk_tb, reset_tb, down_tb, up_tb : std_logic := '0';
    signal s_tb : std_logic_vector (1 to 6);
    signal proof : std_logic;

begin

uut: vfd
    port map (  clk => clk_tb,
                reset => reset_tb,
                down => down_tb,
                up => up_tb,
                enable_factor => '0',
                s => s_tb
                );

clk_tb <= not clk_tb after 5ns; --half_period

stimulus : process begin
    wait for 10ms;
    for i in 1 to 60 loop
        up_tb <= '1'; wait for 10ns;
        up_tb <= '0'; wait for 5ms;
    end loop;
    wait;
end process;

marca_zona_conduccio : process (s_tb) begin
    if ((s_tb(1) = '1' or s_tb(3) = '1' or s_tb(5) = '1') and (s_tb(4) = '1' or s_tb(6) = '1' or s_tb(2) = '1')) then
        proof <= '1';
    else
        proof <= '0';
    end if;
end process;

assert_short_circuit :
    assert (    not((s_tb(1) = '1' and s_tb(4) = '1') or
                    (s_tb(3) = '1' and s_tb(6) = '1') or
                    (s_tb(5) = '1' and s_tb(2) = '1')
                    )
                ) 
    report "SHORT-CIRCUIT" 
    severity failure;

end Behavioral;