----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: ADC2FIFO - ADC2FIFO_arch
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ADC2FIFO is
    Generic (
        adc_bitlen : positive
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           adc_val : in STD_LOGIC_VECTOR ((adc_bitlen-1) downto 0);
           adc_en : in STD_LOGIC;
           send : in STD_LOGIC;
           miso : out STD_LOGIC);
end ADC2FIFO;

architecture ADC2FIFO_arch of ADC2FIFO is

begin


end ADC2FIFO_arch;
