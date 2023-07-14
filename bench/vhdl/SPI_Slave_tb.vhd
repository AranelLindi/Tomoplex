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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_Slave_tb is
    --  Port ( );
end SPI_Slave_tb;

architecture SPI_Slave_tb_arch of SPI_Slave_tb is
    constant DATA_WIDTH : Positive := 8;

    component SPI_Slave
        GENERIC (
            DATA_WIDTH : NATURAL
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            scl : IN STD_LOGIC;
            cs_n : IN STD_LOGIC;
            mosi : IN STD_LOGIC;
            miso : OUT STD_LOGIC;
            din : IN STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
            din_valid : IN STD_LOGIC;
            din_rdy : OUT STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
            dout_valid : OUT STD_LOGIC
        );
    end component;

    signal clk: STD_LOGIC;
    signal rst: STD_LOGIC;
    signal scl: STD_LOGIC;
    signal cs_n: STD_LOGIC;
    signal mosi: STD_LOGIC;
    signal miso: STD_LOGIC;
    signal din: STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    signal din_valid: STD_LOGIC;
    signal din_rdy: STD_LOGIC;
    signal dout: STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    signal dout_valid: STD_LOGIC ;

    constant clock_period: time := 10 ns;
    constant spi_clock_period: time := 100 ns;
    signal stop_the_clock: boolean;
    signal stop_the_clock_spi: boolean;
    
    procedure write2Slave(constant data : in std_logic_vector((DATA_WIDTH-1) downto 0); signal mosi : out std_logic; signal cs_n : out std_logic) is 
    begin
        wait until rising_edge(scl);
        cs_n <= '0';
    
        for i in (DATA_WIDTH-1) downto 0 loop
            --wait until falling_edge(scl);
            mosi <= data(i);
            wait for spi_clock_period;
            -- not sure if this will work correctly!
        end loop;
        cs_n <= '1';
        mosi <= '0';
    end procedure write2Slave;
    
    procedure readfromSlave(constant data : in std_logic_vector((DATA_WIDTH-1) downto 0); signal din : out std_logic_vector((DATA_WIDTH-1) downto 0); signal din_valid : out std_logic; signal cs_n : out std_logic) is
    begin
        wait until rising_edge(clk);        
        din <= data;
        din_valid <= '1';        
        cs_n <= '0', '1' after (DATA_WIDTH-1) * spi_clock_period;
        wait for clock_period;
        din <= (others => '0');
        din_valid <= '0';       
    end procedure readfromSlave;
begin
    -- Insert values for generic parameters !!
    uut: SPI_Slave generic map ( DATA_WIDTH =>  DATA_WIDTH)
        port map ( clk        => clk,
                 rst        => rst,
                 scl        => scl,
                 cs_n       => cs_n,
                 mosi       => mosi,
                 miso       => miso,
                 din        => din,
                 din_valid  => din_valid,
                 din_rdy    => din_rdy,
                 dout       => dout,
                 dout_valid => dout_valid );

    stimulus: process
    begin
        -- Put initialisation code here
        mosi <= '0';
        cs_n <= '0';
        din <= (others => '0');
        din_valid <= '0';
        rst <= '1';
        wait for spi_clock_period;
        rst <= '0';
        cs_n <= '1';
        wait for spi_clock_period;
        
        -- Put test bench stimulus code here
        --wait until rising_edge(scl);
        write2Slave("11111111", mosi, cs_n);
        
        wait for 10 * spi_clock_period;
        
        readfromSlave("11110000", din, din_valid, cs_n);
        
        wait for 10 * spi_clock_period;
        

        stop_the_clock <= true;
        stop_the_clock_spi <= true;
        wait;
    end process;

    clocking: process
    begin
        while not stop_the_clock loop
            CLK <= '0', '1' after clock_period / 2;
            wait for clock_period;
        end loop;
        wait;
    end process;

    spi_clocking: process
    begin
        while not stop_the_clock_spi loop
            scl <= '0', '1' after spi_clock_period / 2;
            wait for spi_clock_period;
        end loop;
        wait;
    end process;
end SPI_Slave_tb_arch;
