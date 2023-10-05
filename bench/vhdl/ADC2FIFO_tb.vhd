----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/05/2023 02:11:24 PM
-- Design Name: 
-- Module Name: ADC2FIFO_tb - ADC2FIFO_tb_arch
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

entity ADC2FIFO_tb is
    --  Port ( );
end ADC2FIFO_tb;

architecture ADC2FIFO_tb_arch of ADC2FIFO_tb is
    constant ADC_BITLEN : integer := 8;
    constant SPI_DATAWIDTH : integer := 8;

    component ADC2FIFO
        GENERIC (
            ADC_BITLEN : NATURAL;
            SPI_DATAWIDTH : NATURAL
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            adc_val : IN STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);
            adc_en : IN STD_LOGIC;
            send : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
            spi_tx_rdy : IN STD_LOGIC;
            spi_tx_con : OUT std_logic
        );
    end component;

    signal clk: STD_LOGIC;
    signal rst: STD_LOGIC;
    signal adc_val: STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);
    signal adc_en: STD_LOGIC;
    signal send: STD_LOGIC;
    signal dout: STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
    signal spi_tx_rdy: STD_LOGIC;
    signal spi_tx_con: std_logic ;

    constant clock_period: time := 10 ns;

begin
    dut: ADC2FIFO generic map ( ADC_BITLEN    => ADC_BITLEN,
                    SPI_DATAWIDTH => SPI_DATAWIDTH)
        port map ( clk           => clk,
                 rst           => rst,
                 adc_val       => adc_val,
                 adc_en        => adc_en,
                 send          => send,
                 dout          => dout,
                 spi_tx_rdy    => spi_tx_rdy,
                 spi_tx_con    => spi_tx_con );

    stimulus: process
    begin
        -- Put initialisation code here
        adc_val <= (others => '0');
        adc_en <= '0';
        send <= '0';
        spi_tx_rdy <= '0';
        
        rst <= '1';
        wait for 10 * clock_period;
        rst <= '0';

        -- Put test bench stimulus code here
        
        -- 1. Insert five values into FIFO:
        for i in 1 to 6 loop
            adc_val <= std_logic_vector(to_unsigned(i, adc_val'length));
            adc_en <= '1';
            wait for clock_period;
            adc_en <= '0';
            wait for clock_period;
        end loop;
        
        wait for 2 * clock_period;
        
        -- 2. Send 'send' signal:
        spi_tx_rdy <= '1'; -- Simulate that spi entity is ready to transmit data all the time.
        
        send <= '1';
        
        wait for 10 us; -- Wait enough time to give spi the opportunity to transmit the data from the fifo (and to make it visible at the simulation wave screen)
        wait;
    end process;

    clocking: process
    begin
        clk <= '0', '1' after clock_period / 2;
        wait for clock_period;
    end process;

end ADC2FIFO_tb_arch;