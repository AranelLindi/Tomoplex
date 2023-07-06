----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: MUX_CTRL - MUX_CTRL_arch
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

entity MUX_CTRL is
    Generic (
        mux_len : positive
    );
    Port ( clk : in STD_LOGIC;
         rst : in STD_LOGIC;
         reg : in STD_LOGIC_VECTOR ((mux_len-1) downto 0);
         mux : out STD_LOGIC_VECTOR ((mux_len-1) downto 0));
end MUX_CTRL;

architecture MUX_CTRL_arch of MUX_CTRL is

begin


end MUX_CTRL_arch;
