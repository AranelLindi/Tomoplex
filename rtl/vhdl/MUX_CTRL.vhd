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
        MUX_LEN : NATURAL; -- TOOD: Not sure if this is really needed!
        
        -- Used FPGA clock frequency.
        Quarz_Taktfrequenz : Integer; -- NEW
        
        -- SPI clock frequency.
        SPI_Taktfrequenz : integer; -- NEW
        
        -- SPI word width.
        DATA_WIDTH : integer -- NEW
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Reset (Synchronous reset).
        rst : IN STD_LOGIC;
        
        -- SPI clock.
        scl : out std_logic; -- NEW
        
        -- SPI Master In Slave Out.
        miso : in std_logic; -- NEW
        
        -- SPI Master Out Slave In.
        mosi : out std_logic; -- NEW
        
        -- SPI slave select.
        ss : out std_logic; -- NEW
        
        -- High if ADC samples shall stored into FIFO.
        sample : out std_logic; -- NEW

        -- TODO: This is not final yet!!
        reg : IN STD_LOGIC_VECTOR ((MUX_LEN - 1) DOWNTO 0); -- TODO: Probably better so set a fixed length! -- NEW
        mux : OUT STD_LOGIC_VECTOR ((MUX_LEN - 1) DOWNTO 0)); -- TODO: Probably better to set a fixed length! -- NEW
END MUX_CTRL;

ARCHITECTURE MUX_CTRL_arch OF MUX_CTRL IS
    component SPI_Master is
        generic (
            Quarz_Taktfrequenz : integer; -- Hertz
            SPI_Taktfrequenz : integer; -- Hertz / to calculate the reload value of clock divider
            DATA_WIDTH : integer -- Number of transmitted bits per data word
        );
        port (
            TX_Data : in std_logic_vector(DATA_WIDTH-1 downto 0); -- Transmit data
            RX_Data : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Received data
            MOSI : out std_logic;
            MISO : in std_logic;
            SCLK : out std_logic;
            SS : out Std_logic;
            TX_Start : in std_logic;
            TX_Done : out std_logic;
            clk : in std_logic
        );
    end component;
    
    signal s_txdata : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s_rxdata : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s_mosi : std_logic;
    signal s_miso : std_logic;
    signal s_scl : std_logic;
    signal s_ss : std_logic;
    signal s_tx_start : std_logic;
    signal s_tx_done : std_logic;
    
    
BEGIN
    -- Read inputs.
    s_miso <= miso;
    
    -- Drive outputs.
    mosi <= s_mosi;
    SCL <= s_scl;
    ss <= s_ss;
    sample <= s_sample;


    spimaster : SPI_Master -- Might be that the SPI Master also need a reset input
        generic (
            Quarz_Taktfrequenz => Quarz_Taktfrequenz,
            SPI_Taktfrequenz => SPI_Taktfrequenz,
            DATA_WIDTH => DATA_WIDTH,
        )
        port (
            TX_Data => s_txdata,
            RX_Data => s_rxdata,
            MOSI => s_mosi,
            MISO => s_miso,
            SCLK => s_scl,
            SS => s_ss;
            TX_Start => s_tx_start,
            TX_Done => s_tx_done,
            clk => clk
        );
        
    -- Reading responses from the MUX controller.
    process(clk)
        variable i : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
                i := 0;
            else
                case to_integer(unsigned(s_rxdata)) is
                    -- TODO: Create all necessary cases here (e.g. "when 1 => ...")
                    when others => null;
                end case;
            end if;
        end if;
    end process;
        
    -- Configuration for the MUX controller.
    process(clk)
        variable i : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
                i := -1; -- default value: configurations remains unchanged
                s_txdata <= (others => '0');
                s_tx_start <= '0';
                s_sample <= '0';
            else
                if s_tx_done = '1' then -- TODO: Using s_tx_done her implies that it is assigned to HIGH as long as the spi master has nothing new to sent! If its just set to high for one clock cycle it might cause problems
                    case to_integer(unsigned(reg)) is
                        when -1 => 
                            i := -1; -- TODO: -1 means: configuration remains untouched. Can be set as desired
                            s_sample <= '1';
                        when 0 => -- TODO: A special case is needed for deactivate sampling! Should be a state that is not touched by the MUX control interval to exlude confusion
                            s_sample <= '0'; 
                        when others => 
                            i := to_integer(unsigned(reg));
                            s_sample <= '1';
                    end case;
                    
                    -- Transmit new settings to MUX controller:
                    s_txdata <= std_logic_vector(to_unsigned(i, s_txdata'length));
                    s_tx_start <= '1';
                    
                    -- Update value to register:
                    mux <= 
                else
                    s_txdata <= (others => '0'); -- For the case that erros occur (e.g. only zeros are sent) then its probably this line !
                    s_tx_start <= '0';
                end if;
            end if;
        end if;
    end process;
END MUX_CTRL_arch;