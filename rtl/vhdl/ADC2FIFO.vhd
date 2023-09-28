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
--use IEEE.NUMERIC_STD.ALL;

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
        SPI_DATAWIDTH : NATURAL
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

        -- Send command: All FIFO entries are sent via SPI to master.
        send : IN STD_LOGIC;


        -- TODO: Here is a signal missing which indicates whether the SPI slave is ready to send another data word.
        -- If necessary try to AND the 'send' signal with the 'ready' signal of the SPI slave and keep 'send' HIGH as long as the FIFO is not empty (could also be a bad idea)

        -- FIFO data output to SPI slave.
        dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
        
        spi_tx_ready : IN STD_LOGIC;
        
        spi_tx_ack : IN std_logic
        );
END ADC2FIFO;

ARCHITECTURE ADC2FIFO_arch OF ADC2FIFO IS
    -- FIFO related signals.
    signal s_fifo_almostempty : std_logic;
    signal s_fifo_almostfull : std_logic;
    signal s_fifo_do : std_logic_vector(ADC_BITLEN-1 downto 0);
    signal s_fifo_empty : std_logic := '1';
    signal s_fifo_full : std_logic := '0';
    signal s_fifo_rdcount : std_logic_vector(11 downto 0);
    signal s_fifo_rderr : std_logic;
    signal s_fifo_wrcount : std_logic_vector(11 downto 0);
    signal s_fifo_wrerr : std_logic;
    signal s_fifo_di : std_logic_vector(ADC_BITLEN-1 downto 0);
    signal s_fifo_rden : std_logic := '0';
    signal s_fifo_wren : std_logic := '0';
    
    type sendstates is (S_Idle, S_Send1, S_Send2);
    signal s_sendstate : sendstates := S_Idle;
BEGIN
    -- Read inputs.
    s_fifo_di(ADC_BITLEN-1 downto 0) <= adc_val;


    data_send : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
            else
                case s_sendstate is
                    when S_Idle =>
                        if send = '1' then
                            s_sendstate <= S_Send1;
                        else
                            s_sendstate <= S_Idle;
                        end if;
                    
                    when S_Send1 =>
                        if s_fifo_empty = '0' then
                            -- Fifo is not empty.
                            
                            -- Check if transmitter is ready to accept new data
                            
                            if deselect = '1' then
                                -- Device is selected by master to send data
                                s_fifo_rden <= '1';
                            else
                                s_fifo_rden <= '0';
                            end if;
                        else
                            -- Fifo is empty
                            s_sendstate <= S_Idle;
                        end if;
                                            
                    when S_Send2 =>
                        if s_fifo_empty = '1' then
                            -- Fifo is empty.
                            s_sendstate <= S_Idle;
                        else
                            -- Fifo is not empty.
                            s_sendstate <= S_Send1;
                        end if;
                        
                        s_fifo_rden <= '0';
                        
                        dout <= s_fifo_do;
                        
                end case;
            end if;
        end if;
    end process;
    
    
--    spi_send : process(clk)
--    begin
--        if rising_edge(clk) then
--            if rst = '1' then
--                -- Synchronous reset.
--            else
--                if send = '1' then
--                    -- Data shall be send.
                    
--                    if deselect = '1' then
--                        dout <= s_fifo_do;
--                        s_fifo_rden <= '1';
--                    else
--                        s_fifo_rden <= '0';
--                    end if;
--                else
--                    -- Data shall not be send.
--                end if;
--            end if;
--        end if;
--    end process;



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
      DI => s_fifo_di(ADC_BITLEN-1 downto 0),                     -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => clk,               -- 1-bit input read clock
      RDEN => s_fifo_rden,                 -- 1-bit input read enable
      RST => rst,                   -- 1-bit input reset
      WRCLK => adc_en,               -- 1-bit input write clock
      WREN => adc_en                  -- 1-bit input write enable
   );
   -- End of FIFO_DUALCLOCK_MACRO_inst instantiation
END ADC2FIFO_arch;