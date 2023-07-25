----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/12/2023 12:16:16 PM
-- Design Name: 
-- Module Name: SPI_Slave_tb - SPI_Slave_tb_arch
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
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity SPI_Slave_tb is
end;

architecture bench of SPI_Slave_tb is
    constant DATA_WIDTH : positive := 8;

    component SPI_Slave
        generic (
            DATA_WIDTH : in positive
        );
        Port ( clk    : in  STD_LOGIC;
             SSn    : in  STD_LOGIC;
             SCLK   : in  STD_LOGIC;
             MOSI   : in  STD_LOGIC;
             MISO   : out STD_LOGIC;
             Dout : out  STD_LOGIC_VECTOR (DATA_WIDTh-1 downto 0);
             Din  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
             newDataFlag : out std_logic
             );
    end component;

    signal clk: STD_LOGIC;
    signal SSn: STD_LOGIC;
    signal SCLK: STD_LOGIC;
    signal MOSI: STD_LOGIC;
    signal MISO: STD_LOGIC;
    signal Dout: STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
    signal Din: STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
    signal newDataFlag : std_logic;

    constant clock_period: time := 10 ns;
    constant SCLK_period: time := 1 us;

    procedure send2Slave(constant data: in std_logic_vector(DATA_WIDTH-1 downto 0); signal SSn: out std_logic; signal mosi: out std_logic) is
    begin
        wait until falling_edge(SCLK);
        SSn <= '0';

        for i in DATA_WIDTH-1 downto 0 loop
            MOSI <= data(i);
            wait for SCLK_period;
        end loop;

        SSn <= '1';
    end procedure;

    procedure send2Master(constant data: in std_logic_vector(DATA_WIDTH-1 downto 0); signal SSn: out std_logic; signal Din : out std_logic_vector(DATA_WIDTH-1 downto 0)) is
    begin
        wait until falling_edge(SCLK);
        SSn <= '0';

        Din <= data;
        wait for data'length * SCLK_period;

        SSn <= '1';
    end procedure;
begin

    uut: SPI_Slave
        generic map (DATA_WIDTH => DATA_WIDTH)
        port map ( clk  => clk,
                 SSn  => SSn,
                 SCLK => SCLK,
                 MOSI => MOSI,
                 MISO => MISO,
                 Dout => Dout,
                 Din  => Din,
                 newDataFlag => newDataFlag );

    stimulus: process
    begin

        -- Put initialisation code here
        SSn <= '1';
        MOSI <= '0';
        wait for 2 us;

        -- Put test bench stimulus code here
        send2Slave("11110000", SSn, MOSI);
        wait for (DATA_WIDTH + 1) * SCLK_period;

        --Din <= "1011001110111101";
        send2Master("10101010", SSn, Din);
        wait for (DATA_WIDTH +1) * SCLK_period;
        wait;
    end process;

    clocking: process
    begin
        clk <= '0', '1' after clock_period / 2;
        wait for clock_period;
    end process;

    SCLK_clocking: process
    begin
        SCLK <= '0', '1' after SCLK_period / 2;
        wait for SCLK_period;
    end process;
end;