----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/12/2023 12:11:33 PM
-- Design Name: 
-- Module Name: SPI_Master - Behavioral
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

entity SPI_Master is
    Generic ( Quarz_Taktfrequenz : integer;  -- Hertz 
            SPI_Taktfrequenz   : integer;  -- Hertz / zur Berechnung des Reload-Werts für Taktteiler
            DATA_WIDTH             : integer        -- Anzahl der zu übertragenden Bits
           );
    Port ( TX_Data  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- Sendedaten
         RX_Data  : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- Empfangsdaten
         MOSI     : out STD_LOGIC;
         MISO     : in  STD_LOGIC;
         SCLK     : out STD_LOGIC;
         SS       : out STD_LOGIC;
         TX_Start : in  STD_LOGIC;
         TX_Done  : out STD_LOGIC;
         clk      : in  STD_LOGIC
        );
end SPI_Master;

architecture Behavioral of SPI_Master is
    signal   delay       : integer range 0 to (Quarz_Taktfrequenz/(2*SPI_Taktfrequenz));
    constant clock_delay : integer := (Quarz_Taktfrequenz/(2*SPI_Taktfrequenz))-1;

    type   spitx_states is (spi_stx,spi_txactive,spi_etx);
    signal spitxstate    : spitx_states := spi_stx;

    signal spiclk    : std_logic;
    signal spiclklast: std_logic;

    signal bitcounter    : integer range 0 to DATA_WIDTH; -- wenn bitcounter = Laenge --> alle Bits uebertragen
    signal tx_reg        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal rx_reg        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
begin
    -- Drive outputs.
    SCLK    <= spiclk;
    MOSI    <= tx_reg(tx_reg'left);
    RX_Data <= rx_reg;

    ------ Verwaltung --------
    process begin
        wait until rising_edge(CLK);
        if delay > 0 then
            delay <= delay-1;
        else
            delay <= clock_delay;
        end if;

        spiclklast <= spiclk;

        case spitxstate is
            when spi_stx =>
                SS          <= '1'; -- slave select disabled
                TX_Done     <= '0';
                bitcounter  <= DATA_WIDTH;
                spiclk      <= '0'; -- SPI-Modus 0
                if TX_Start = '1' then
                    spitxstate <= spi_txactive;
                    SS         <= '0';
                    delay      <= clock_delay;
                end if;

            when spi_txactive =>  -- Daten aus tx_reg uebertragen
                if delay = 0 then -- shift
                    spiclk <= not spiclk;

                    if bitcounter = 0 then -- alle Bits uebertragen -> deselektieren
                        spiclk     <= '0';  -- SPI-Modus 0
                        spitxstate <= spi_etx;
                    end if;

                    if spiclk = '1' then    -- SPI-Modus 0
                        bitcounter <= bitcounter-1;
                    end if;
                end if;

            when spi_etx =>
                SS      <= '1'; -- disable Slave Select 
                TX_Done <= '1';

                if TX_Start = '0' then -- Handshake: warten, bis Start-Flag geloescht
                    spitxstate <= spi_stx;
                end if;
        end case;
    end process;

    ---- Empfangsschieberegister -----
    process begin
        wait until rising_edge(CLK);

        if (spiclk='1' and  spiclklast='0') then -- SPI-Modus 0
            rx_reg <= rx_reg(rx_reg'left-1 downto 0) & MISO;
        end if;
    end process;

    ---- Sendeschieberegister -------
    process begin
        wait until rising_edge(CLK);
        if spitxstate = spi_stx then   -- Zurücksetzen, wenn SS inaktiv
            tx_reg <= TX_Data;
        end if;

        if (spiclk='0' and  spiclklast='1') then -- SPI-Modus 0
            tx_reg <= tx_reg(tx_reg'left-1 downto 0) & tx_reg(0);
        end if;
    end process;
end Behavioral;