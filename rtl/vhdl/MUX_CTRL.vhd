----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Chair of Computer Science VIII
-- Engineer: Stefan Lindörfer, BSc
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: MUX_CTRL - MUX_CTRL_arch
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

ENTITY MUX_CTRL IS
    GENERIC (
        -- Number of used MUX.
        MUX_LEN : NATURAL
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Reset (Synchronous reset).
        rst : IN STD_LOGIC;

        -- TODO: This is not final yet!!
        reg : IN STD_LOGIC_VECTOR ((MUX_LEN - 1) DOWNTO 0);
        mux : OUT STD_LOGIC_VECTOR ((MUX_LEN - 1) DOWNTO 0));
END MUX_CTRL;

ARCHITECTURE MUX_CTRL_arch OF MUX_CTRL IS

BEGIN
END MUX_CTRL_arch;