----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Chair of Computer Science VIII
-- Engineer: Stefan Lindörfer, BSc
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: ADC2FIFO - ADC2FIFO_arch
-- Project Name: Tomoplex
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY ADC2FIFO IS
    GENERIC (
        -- Length of the value delivered by ADC.
        ADC_BITLEN : NATURAL;

        -- Length of a data word via SPI.
        SPI_DATAWIDTH : NATURAL
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Reset (Synchronous reset).
        rst : IN STD_LOGIC;

        -- Analog-digital-converter output value.
        adc_val : IN STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);

        -- Valid data on adc_val.
        adc_en : IN STD_LOGIC;

        -- Send command: All FIFO entries are sent via SPI to master.
        send : IN STD_LOGIC;


        -- TODO: Here is a signal missing which indicates whether the SPI slave is ready to send another data word.
        -- If necessary try to AND the 'send' signal with the 'ready' signal of the SPI slave and keep 'send' HIGH as long as the FIFO is not empty (could also be a bad idea)

        -- FIFO data output to SPI slave.
        dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0));
END ADC2FIFO;

ARCHITECTURE ADC2FIFO_arch OF ADC2FIFO IS

BEGIN
END ADC2FIFO_arch;