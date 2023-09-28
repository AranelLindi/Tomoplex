----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/25/2023 01:45:51 PM
-- Design Name: 
-- Module Name: ADC2SPI_tb - ADC2SPI_tb_arch
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ADC2SPI_tb is
    --  Port ( );
end ADC2SPI_tb;

architecture ADC2SPI_tb_arch of ADC2SPI_tb is
    constant ADC_BITLEN : NATURAL := 8;
    constant MUX_LEN : NATURAL := 12; -- not needed in this TB
    constant SPI_DATAWIDTH : NATURAL := 8;

    component tomoplex_main is
        generic (
            ADC_BITLEN : NATURAL;
            MUX_LEN : NATURAL;
            SPI_DATAWIDTH : NATURAL
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            adc_val : in std_logic_vector((ADC_BITLEN-1) downto 0);
            adc_en : in std_logic;
            scl : in std_logic;
            mosi : in std_logic;
            miso : out std_logic;
            cs : in std_logic;
            mux : out std_logic_vector((MUX_LEN-1) downto 0)
        );
    end component;

    signal clk: STD_LOGIC;
    signal rst: STD_LOGIC;
    signal adc_val: STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);
    signal adc_en: STD_LOGIC;
    signal scl: STD_LOGIC;
    signal mosi: STD_LOGIC;
    signal miso: STD_LOGIC;
    signal cs: STD_LOGIC;
    signal mux: STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0) ;

    constant clock_period: time := 10 ns; -- 100 MHz
    constant spi_period : time := 25 us;
begin
    -- design under test.
    dut: tomoplex_main
        generic map (
            ADC_BITLEN => ADC_BITLEN,
            MUX_LEN => MUX_LEN,
            SPI_DATAWIDTH => SPI_DATAWIDTH
        )
        port map (
            clk => clk,
            rst => rst,
            adc_val => adc_val,
            adc_en => adc_en,
            scl => scl,
            mosi => mosi,
            miso => miso,
            cs => cs,
            mux => mux
        );

    -- Simulates communication with spi master.
    stimulus_spi: process
    begin

        -- Put initialisation code here
        rst <= '1', '0' after 1 * clock_period;
        mosi <= '0';
        cs <= '1';

        wait for 1 * spi_period;
        -- Put test bench stimulus code here
    
        cs <= '0';
        mosi <= '1';
        wait for spi_period;
        mosi <= '0';
        wait for 6 * spi_period;
        mosi <= '0';
        cs <= '1';
        wait for spi_period;
        cs <= '1';
        wait for 1 * spi_period;
        cs <= '1';
        wait;
    end process;
    
    -- Simulates communication with ADC.
    stimulus_adc : process
    begin
        -- Put initialisation code here
        adc_val <= (Others => '0');
        adc_en <= '0';
        
        -- Put test bench stimulus code here
        
        for i in 0 to 15 loop
            adc_val <= std_logic_vector(to_unsigned(i, adc_val'length));
            adc_en <= '1';
            wait for clock_period;
            adc_en <= '0';
            wait for clock_period;
        end loop;
        wait;
    end process;

    clocking: process
    begin
        clk <= '0', '1' after clock_period / 2;
        wait for clock_period;
    end process;
    
    spi_clocking: process
    begin
        scl <= '0', '1' after spi_period / 2;
        wait for spi_period;
    end process;
end ADC2SPI_tb_arch;