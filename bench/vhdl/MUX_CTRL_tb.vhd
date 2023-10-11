----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/11/2023 10:50:15 AM
-- Design Name: 
-- Module Name: MUX_CTRL_tb - MUX_CTRL_tb_arch
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

entity MUX_CTRL_tb is
    --  Port ( );
end MUX_CTRL_tb;

architecture MUX_CTRL_tb_arch of MUX_CTRL_tb is
    component MUX_CTRL
        GENERIC (
            Quarz_Taktfrequenz : Integer;
            SPI_Taktfrequenz : integer;
            DATA_WIDTH : integer
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            scl : out std_logic;
            miso : in std_logic;
            mosi : out std_logic;
            ss : out std_logic;
            sample : out std_logic;
            reg : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            mux : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
    end component;

    signal clk: STD_LOGIC;
    signal rst: STD_LOGIC;
    signal scl: std_logic;
    signal miso: std_logic;
    signal mosi: std_logic;
    signal ss: std_logic;
    signal sample: std_logic;
    signal reg: STD_LOGIC_VECTOR (15 DOWNTO 0);
    signal mux: STD_LOGIC_VECTOR (15 DOWNTO 0);


    constant clock_period : time := 10 ns;
begin

    -- Insert values for generic parameters !!
    uut: MUX_CTRL generic map ( Quarz_Taktfrequenz => 100_000_000,
                    SPI_Taktfrequenz   => 50_000_000,
                    DATA_WIDTH         => 16)
        port map ( clk                => clk,
                 rst                => rst,
                 scl                => scl,
                 miso               => miso,
                 mosi               => mosi,
                 ss                 => ss,
                 sample             => sample,
                 reg                => reg,
                 mux                => mux );

    stimulus: process
    begin
        -- Put initialisation code here
        rst <= '1';
        reg <= (others => '0');
        miso <= '0';
        wait for 5 * clock_period;
        rst <= '0';
        
        wait for 5 * clock_period;
        
        -- Put test bench stimulus code here
        
        wait until rising_edge(clk);
        reg <= std_logic_vector(to_unsigned(2, reg'length));
        
        wait for 100 * clock_period;
        
        reg <= std_logic_vector(to_unsigned(255, reg'length));
        wait for 2 * clock_period;
        reg <= std_logic_vector(to_unsigned(0, reg'length));
        
        wait;
    end process;

    clocking: process
    begin
        clk <= '0', '1' after clock_period / 2;
        wait for clock_period;
    end process;

end MUX_CTRL_tb_arch;
