----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Chair of Computer Science VIII
-- Engineer: Stefan Lindörfer, BSc
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: ADC2FIFO - ADC2FIFO_arch
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

ENTITY ADC2FIFO IS
    GENERIC (
        -- Length of the value delivered by ADC.
        ADC_BITLEN : NATURAL;

        -- Length of a data word via SPI.
        SPI_DATAWIDTH : NATURAL := 8
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Reset (Synchronous reset).
        rst : IN STD_LOGIC;

        -- Analog-digital-converter output value.
        adc_val : IN STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);

        -- Valid data on adc_val.
        adc_en : IN STD_LOGIC;

        -- HIGH if ADC values shall be stored into fifo.
        sample_en : IN STD_LOGIC;

        -- Send command: All FIFO entries are sent via SPI to master.
        send : IN STD_LOGIC;

        -- Returns the constant size of the FIFO.
        fifo_size : out std_logic_vector(15 downto 0);

        -- Elements contained in the FIFO.
        fifo_elements : out std_logic_vector(15 downto 0);


        -- TODO: Here is a signal missing which indicates whether the SPI slave is ready to send another data word.
        -- If necessary try to AND the 'send' signal with the 'ready' signal of the SPI slave and keep 'send' HIGH as long as the FIFO is not empty (could also be a bad idea)

        -- FIFO data output to SPI slave.
        dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);

        spi_tx_rdy : IN STD_LOGIC; -- former: slave_select

        debug : out std_logic_vector(2 downto 0);

        spi_tx_con : OUT std_logic -- former: deselect (IN)
    );
END ADC2FIFO;

ARCHITECTURE ADC2FIFO_arch OF ADC2FIFO IS
    -- Constants.
    constant c_fifo_size : INTEGER := 4097; -- p. 57 UG473 (table 2-7)

    -- FIFO related signals.
    signal s_fifo_almostempty : std_logic;
    signal s_fifo_almostfull : std_logic;
    signal s_fifo_do : std_logic_vector(ADC_BITLEN-1 downto 0);
    signal s_fifo_empty : std_logic := '1';
    signal s_fifo_full : std_logic;
    signal s_fifo_rdcount : std_logic_vector(11 downto 0);
    signal s_fifo_rderr : std_logic;
    signal s_fifo_wrcount : std_logic_vector(11 downto 0);
    signal s_fifo_wrerr : std_logic;
    signal s_fifo_di : std_logic_vector(ADC_BITLEN-1 downto 0);
    signal s_fifo_rden : std_logic := '0';
    signal s_fifo_wren : std_logic := '0';

    signal s_send : std_logic;
    signal s_tx_rdy : std_logic;
    signal s_tx_con : std_logic;

    signal s_dout : std_logic_vector(SPI_DATAWIDTH-1 downto 0);

    signal s_adc_val : std_logic_vector(ADC_BITLEN-1 downto 0);
    signal s_adc_en : std_logic;
    signal s_sample_en : std_logic;

    type sendstates is (S_Idle, S_Tx1, S_Tx2);
    signal s_sendstate : sendstates := S_Idle;

    signal s_rdcounter : integer range 0 to c_fifo_size;
    signal s_wrcounter : integer range 0 to c_fifo_size;
    signal s_size : unsigned(15 downto 0) := (others => '0'); -- 2 Bytes is completely sufficient to represent all possible FIFO depths constants (see below)
BEGIN
    -- Read inputs.
    s_send <= send;
    s_tx_rdy <= spi_tx_rdy;
    s_fifo_di(ADC_BITLEN-1 downto 0) <= adc_val;

    -- Drive outputs.
    dout <= s_dout;
    spi_tx_con <= s_tx_con;

    fifo_size <= std_logic_vector(to_unsigned(c_fifo_size, fifo_size'length));
    fifo_elements <= std_logic_vector(s_size); -- TODO: HIER WEITERMACHEN ! LÖSUNG FINDEN FÜR UNTERSCHIEDLICHE VEKTORLÄNGEN !


    -- Reads data out of the fifo.
    sending: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
                s_dout <= (others => '0');
                s_fifo_rden <= '0';
                s_rdcounter <= 0;
                s_tx_con <= '0';
                s_sendstate <= S_Idle;
            else
                case s_sendstate is
                    when S_Idle =>
                        debug <= "001";

                        s_tx_con <= '0'; -- This has to be here to be able to insert user-defined tokens into the SPI stream!
                        if s_send = '1' and s_fifo_empty = '0' then
                            s_sendstate <= S_Tx1;
                        end if;

                    when S_Tx1 =>
                        debug <= "010";
                        if s_tx_rdy = '1' then
                            if s_fifo_empty = '0' then
                                -- Fifo is not empty.
                                s_dout <= s_fifo_do;
                                s_fifo_rden <= '1';

                                s_tx_con <= '1';

                                s_sendstate <= S_Tx2;
                            else
                                -- Fifo is empty.

                                -- Send token instead!
                                s_dout <= (others => '1'); -- this can be configured as desired ! But it should be unique to seperate it from ADC data samples !
                                s_tx_con <= '1';

                                s_sendstate <= S_Idle;
                            end if;
                        else
                            s_sendstate <= S_Tx1;
                        end if;

                    when S_Tx2 =>
                        debug <= "100";
                        s_fifo_rden <= '0';
                        s_tx_con <= '0';

                        IF s_size > 0 THEN -- s_size contains available elements to read
                            IF s_rdcounter = (c_fifo_size - 1) THEN
                                s_rdcounter <= 0; -- wrap
                            ELSE
                                s_rdcounter <= s_rdcounter + 1;
                            END IF;
                        END IF;

                        s_sendstate <= S_Tx1;
                end case;
            end if;
        end if;
    end process;

    -- Samples ADC inputs.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_adc_val <= (others => '0');
                s_adc_en <= '0';
                s_sample_en <= '0';
            else
                s_adc_val <= adc_val;
                s_adc_en <= adc_en and s_sample_en; -- Data shall only be stored if requested (by MUX for example)
                s_sample_en <= sample_en;
            end if;
        end if;
    end process;

    -- Writes words from ADC to FIFO.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_fifo_wren <= '0';
                s_wrcounter <= 0;
            else
                if s_adc_en = '1' then
                    s_fifo_wren <= '1';

                    IF s_size /= c_fifo_size - 1 THEN -- prevents that value of rdcounter is bigger than wrcounter altough fifo is empty
                        IF s_wrcounter = (c_fifo_size - 1) THEN
                            s_wrcounter <= 0; -- wrap
                        ELSE
                            s_wrcounter <= s_wrcounter + 1;
                        END IF;
                    END IF;
                else
                    s_fifo_wren <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Calculates FIFOs free space.
    size_calc : PROCESS (s_rdcounter, s_wrcounter)
    BEGIN
        IF s_wrcounter >= s_rdcounter THEN
            s_size <= to_unsigned(s_wrcounter - s_rdcounter, s_size'length);
        ELSE -- s_wrcounter < s_rdcounter
            s_size <= to_unsigned(c_fifo_size + s_wrcounter - s_rdcounter, s_size'length);
        END IF;
    END PROCESS size_calc;


    -- FIFO_DUALCLOCK_MACRO: Dual-Clock First-In, First-Out (FIFO) RAM Buffer
    --                       Virtex-7
    -- Xilinx HDL Language Template, version 2022.1

    -- Note -  This Unimacro model assumes the port directions to be "downto". 
    --         Simulation of this model with "to" in the port directions could lead to erroneous results.

    -----------------------------------------------------------------
    -- DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width --
    -- ===========|===========|============|=======================--
    --   37-72    |  "36Kb"   |     512    |         9-bit         --
    --   19-36    |  "36Kb"   |    1024    |        10-bit         --
    --   19-36    |  "18Kb"   |     512    |         9-bit         --
    --   10-18    |  "36Kb"   |    2048    |        11-bit         --
    --   10-18    |  "18Kb"   |    1024    |        10-bit         --
    --    5-9     |  "36Kb"   |    4096    |        12-bit         --
    --    5-9     |  "18Kb"   |    2048    |        11-bit         --
    --    1-4     |  "36Kb"   |    8192    |        13-bit         --
    --    1-4     |  "18Kb"   |    4096    |        12-bit         --
    -----------------------------------------------------------------

    FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
        generic map (
            DEVICE => "7SERIES",            -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET => X"06FF",  -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0100", -- Sets the almost empty threshold
            DATA_WIDTH => ADC_BITLEN,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE => "36Kb",            -- Target BRAM, "18Kb" or "36Kb" 
            FIRST_WORD_FALL_THROUGH => TRUE) -- Sets the FIFO FWFT to TRUE or FALSE
        port map (
            ALMOSTEMPTY => s_fifo_almostempty,   -- 1-bit output almost empty
            ALMOSTFULL => s_fifo_almostfull,     -- 1-bit output almost full
            DO => s_fifo_do,                     -- Output data, width defined by DATA_WIDTH parameter
            EMPTY => s_fifo_empty,               -- 1-bit output empty
            FULL => s_fifo_full,                 -- 1-bit output full
            RDCOUNT => s_fifo_rdcount,           -- Output read count, width determined by FIFO depth
            RDERR => s_fifo_wrerr,               -- 1-bit output read error
            WRCOUNT => s_fifo_wrcount,           -- Output write count, width determined by FIFO depth
            WRERR => s_fifo_wrerr,               -- 1-bit output write error
            DI => s_adc_val, --s_fifo_di(ADC_BITLEN-1 downto 0),                     -- Input data, width defined by DATA_WIDTH parameter
            RDCLK => clk,               -- 1-bit input read clock
            RDEN => s_fifo_rden,                 -- 1-bit input read enable
            RST => rst,                   -- 1-bit input reset
            WRCLK => clk,               -- 1-bit input write clock
            WREN => s_fifo_wren                  -- 1-bit input write enable
        );
        -- End of FIFO_DUALCLOCK_MACRO_inst instantiation
END ADC2FIFO_arch;