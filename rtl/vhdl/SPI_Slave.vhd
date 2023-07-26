----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Chair of Computer Science VIII
-- Engineer: Stefan Lindörfer, BSc
-- 
-- Create Date: 07/07/2023 01:50:56 PM
-- Design Name: 
-- Module Name: SPI_Slave - SPI_Slave_arch
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
-- TODO: Check if everything is complete and works as expected!
----------------------------------------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity SPI_Slave is
    generic(
        DATA_WIDTH : in positive
    );
    Port ( clk    : in  STD_LOGIC;
         SSn    : in  STD_LOGIC;
         SCLK   : in  STD_LOGIC;
         MOSI   : in  STD_LOGIC;
         MISO   : out STD_LOGIC;
         Dout : out  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
         Din  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
         newDataFlag : out std_logic);
end SPI_Slave;

architecture Behavioral of SPI_Slave is
    signal dSR     : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others=>'0');
    signal sclkSR  : STD_LOGIC_VECTOR (1 downto 0) := (others=>'0');
    signal ssSR    : STD_LOGIC_VECTOR (1 downto 0) := (others=>'0');

    signal misoLoc : std_logic;
begin
    sclkSR  <= sclkSR(0) & SCLK when rising_edge(clk); -- Eintakten der
    ssSR    <= ssSR(0) & SSn    when rising_edge(clk); -- asynchronen Signale

    -- Parallel-Eingänge --> MISO
    process begin
        wait until rising_edge(clk);

        if (ssSR="11") then                        -- solange deselektiert: immer Daten vom Din übernehmen
            dsr <= Din;
        elsif (sclkSR="01") then                   -- mit der steigenden SCLK-Flanke 
            dsr <= dsr(dsr'left-1 downto 0) & MOSI; -- wird MOSI eingetaktet
        end if;

        if (sclkSR="10") then
            misoLoc <= dsr(dsr'left);
        end if;
    end process;

    MISO <= misoLoc when SSn='0' else 'Z';
    --MISO <= dsr(dsr'left) when SSn='0' else 'Z';  -- Richtungsteuerung MISO direkt über SSn

    -- Parallel-Ausgänge übernehmen mit steigender SS-Flanke 
    process begin
        wait until rising_edge(clk);

        if (ssSR="01") then    -- steigende Flanke am SS: Device wird deselektiert
            Dout <= dsr;        -- Ausgangssignale an Dout ausgeben
            newDataFlag <= '1';
        else
            newDataFlag <= '0';
        end if;
    end process;
end Behavioral;
