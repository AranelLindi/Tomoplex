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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY SPI_Slave IS
    GENERIC (
        -- Size of transfer word in bits, must be power of two (why?)
        DATA_WIDTH : NATURAL
    );
    PORT (
        -- System signals.
        clk : IN STD_LOGIC;

        -- Reset (Synchronous reset).
        rst : IN STD_LOGIC;

        -- SPI slave signals.
        scl : IN STD_LOGIC;
        cs_n : IN STD_LOGIC;
        mosi : IN STD_LOGIC;
        miso : OUT STD_LOGIC;

        -- Interna interface signals.
        -- Data for transmission to spi master.
        din : IN STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        -- Valid data on din.
        din_valid : IN STD_LOGIC;
        -- Ready to accept new data.
        din_rdy : OUT STD_LOGIC;
        -- Received data from SPI master.
        dout : OUT STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
        -- Received data is valid.
        dout_valid : OUT STD_LOGIC
    );
END SPI_Slave;

ARCHITECTURE SPI_Slave_arch OF SPI_Slave IS
    CONSTANT c_bit_cnt_width : NATURAL := NATURAL(ceil(log2(REAL(DATA_WIDTH))));

    SIGNAL s_scl_meta : STD_LOGIC;
    SIGNAL s_cs_n_meta : STD_LOGIC;
    SIGNAL s_mosi_meta : STD_LOGIC;
    SIGNAL s_scl_reg : STD_LOGIC;
    SIGNAL s_cs_n_reg : STD_LOGIC;
    SIGNAL s_mosi_reg : STD_LOGIC;
    SIGNAL s_spi_clk_reg : STD_LOGIC;
    SIGNAL s_spi_clk_redge_en : STD_LOGIC;
    SIGNAL s_spi_clk_fedge_en : STD_LOGIC;
    SIGNAL s_bit_cnt : unsigned((c_bit_cnt_width - 1) DOWNTO 0);
    SIGNAL s_bit_cnt_max : STD_LOGIC;
    SIGNAL s_last_bit_en : STD_LOGIC;
    SIGNAL s_load_data_en : STD_LOGIC;
    SIGNAL s_data_shreg : STD_LOGIC_VECTOR((DATA_WIDTH - 1) DOWNTO 0);
    SIGNAL s_slave_ready : STD_LOGIC;
    SIGNAL s_shreg_busy : STD_LOGIC;
    SIGNAL s_rx_data_vld : STD_LOGIC;
BEGIN
    -- Drive output signals.    
    din_rdy <= s_slave_ready;
    dout <= s_data_shreg;
    dout_valid <= s_rx_data_vld;

    -- Received data from master are valid when falling edge of SPI clock is
    -- detected and the last bit of received byte is detected.
    s_rx_data_vld <= s_spi_clk_fedge_en AND s_last_bit_en;

    -- Falling edge is detect when sclk_reg=0 and spi_clk_reg=1.
    s_spi_clk_fedge_en <= NOT s_scl_reg AND s_spi_clk_reg;
    -- Rising edge is detect when sclk_reg=1 and spi_clk_reg=0.
    s_spi_clk_redge_en <= s_scl_reg AND NOT s_spi_clk_reg;

    -- The SPI slave is ready for accept new input data when cs_n_reg is assert and
    -- shift register not busy or when received data are valid.
    s_slave_ready <= (s_cs_n_reg AND NOT s_shreg_busy) OR s_rx_data_vld;

    -- The new input data is loaded into the shift register when the SPI slave
    -- is ready and input data are valid.
    s_load_data_en <= s_slave_ready AND din_valid;

    -- The flag of maximal value of the bit counter.
    s_bit_cnt_max <= '1' WHEN (s_bit_cnt = DATA_WIDTH - 1) ELSE
        '0';
    -- -------------------------------------------------------------------------
    --  INPUT SYNCHRONIZATION REGISTERS
    -- -------------------------------------------------------------------------
    -- Synchronization registers to eliminate possible metastability.
    sync_ffs_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            s_scl_meta <= scl;
            s_cs_n_meta <= cs_n;
            s_mosi_meta <= mosi;

            s_scl_reg <= s_scl_meta;
            s_cs_n_reg <= s_cs_n_meta;
            s_mosi_reg <= s_mosi_meta;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  SPI CLOCK REGISTER
    -- -------------------------------------------------------------------------
    -- The SPI clock register is necessary for clock edge detection.
    spi_clk_reg_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (RST = '1') THEN
                s_spi_clk_reg <= '0';
            ELSE
                s_spi_clk_reg <= s_scl_reg;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  RECEIVED BITS COUNTER
    -- -------------------------------------------------------------------------
    -- The counter counts received bits from the master. Counter is enabled when
    -- falling edge of SPI clock is detected and not asserted cs_n_reg.
    bit_cnt_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (RST = '1') THEN
                s_bit_cnt <= (OTHERS => '0');
            ELSIF (s_spi_clk_fedge_en = '1' AND s_cs_n_reg = '0') THEN
                IF (s_bit_cnt_max = '1') THEN
                    s_bit_cnt <= (OTHERS => '0');
                ELSE
                    s_bit_cnt <= s_bit_cnt + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  LAST BIT FLAG REGISTER
    -- -------------------------------------------------------------------------
    -- The flag of last bit of received byte is only registered the flag of
    -- maximal value of the bit counter.
    last_bit_en_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (RST = '1') THEN
                s_last_bit_en <= '0';
            ELSE
                s_last_bit_en <= s_bit_cnt_max;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  SHIFT REGISTER BUSY FLAG REGISTER
    -- -------------------------------------------------------------------------
    -- Data shift register is busy until it sends all input data to SPI master.
    shreg_busy_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (RST = '1') THEN
                s_shreg_busy <= '0';
            ELSE
                IF (din_valid = '1' AND (s_cs_n_reg = '1' OR s_rx_data_vld = '1')) THEN
                    s_shreg_busy <= '1';
                ELSIF (s_rx_data_vld = '1') THEN
                    s_shreg_busy <= '0';
                ELSE
                    s_shreg_busy <= s_shreg_busy;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  DATA SHIFT REGISTER
    -- -------------------------------------------------------------------------
    -- The shift register holds data for sending to master, capture and store
    -- incoming data from master.
    data_shreg_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (s_load_data_en = '1') THEN
                s_data_shreg <= din;
            ELSIF (s_spi_clk_redge_en = '1' AND s_cs_n_reg = '0') THEN
                s_data_shreg <= s_data_shreg(DATA_WIDTH - 2 DOWNTO 0) & s_mosi_reg;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------------------------
    --  MISO REGISTER
    -- -------------------------------------------------------------------------
    -- The output MISO register ensures that the bits are transmit to the master
    -- when is not assert cs_n_reg and falling edge of SPI clock is detected.
    miso_p : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            IF (s_load_data_en = '1') THEN
                miso <= din(DATA_WIDTH - 1);
            ELSIF (s_spi_clk_fedge_en = '1' AND s_cs_n_reg = '0') THEN
                miso <= s_data_shreg(DATA_WIDTH - 1);
            END IF;
        END IF;
    END PROCESS;
END SPI_Slave_arch;