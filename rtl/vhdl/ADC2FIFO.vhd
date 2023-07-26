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
        dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0));
END ADC2FIFO;

ARCHITECTURE ADC2FIFO_arch OF ADC2FIFO IS

BEGIN
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
      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
      DATA_WIDTH => 0,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
   port map (
      ALMOSTEMPTY => ALMOSTEMPTY,   -- 1-bit output almost empty
      ALMOSTFULL => ALMOSTFULL,     -- 1-bit output almost full
      DO => DO,                     -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => EMPTY,               -- 1-bit output empty
      FULL => FULL,                 -- 1-bit output full
      RDCOUNT => RDCOUNT,           -- Output read count, width determined by FIFO depth
      RDERR => RDERR,               -- 1-bit output read error
      WRCOUNT => WRCOUNT,           -- Output write count, width determined by FIFO depth
      WRERR => WRERR,               -- 1-bit output write error
      DI => DI,                     -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => RDCLK,               -- 1-bit input read clock
      RDEN => RDEN,                 -- 1-bit input read enable
      RST => RST,                   -- 1-bit input reset
      WRCLK => WRCLK,               -- 1-bit input write clock
      WREN => WREN                  -- 1-bit input write enable
   );
   -- End of FIFO_DUALCLOCK_MACRO_inst instantiation
END ADC2FIFO_arch;