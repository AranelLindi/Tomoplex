----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Chair of Computer Science VIII
-- Engineer: Stefan Lindörfer, BSc
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: tomoplex_main - tomoplex_main_arch
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

ENTITY tomoplex_main IS
    GENERIC (
        -- Length of the value delivered by the ADC.
        ADC_BITLEN : NATURAL;

        -- Number of used MUXs.
        MUX_LEN : NATURAL;

        -- Length of a normal data word via SPI.
        SPI_DATAWIDTH : NATURAL
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Reset (synchronous reset).
        rst : IN STD_LOGIC;

        -- Analog-digital-converter output.
        adc_val : IN STD_LOGIC_VECTOR ((ADC_BITLEN - 1) DOWNTO 0);

        -- Valid data on adc_val.
        adc_en : IN STD_LOGIC;

        -- SPI related signals.
        scl : IN STD_LOGIC;
        mosi : IN STD_LOGIC;
        miso : IN STD_LOGIC;

        -- MUX control related signals.
        mux : OUT STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0)
    );
END tomoplex_main;

ARCHITECTURE tomoplex_main_arch OF tomoplex_main IS    
    -- Component declarations.
    COMPONENT ADC2FIFO
        GENERIC (
            ADC_BITLEN : NATURAL;
            SPI_DATAWIDTH : NATURAL
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            adc_val : IN STD_LOGIC_VECTOR((ADC_BITLEN - 1) DOWNTO 0);
            adc_en : IN STD_LOGIC;
            send : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT MUX_CTRL
        GENERIC (
            MUX_LEN : NATURAL
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            reg : IN STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0);
            mux : OUT STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT SPI_Slave
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
    END COMPONENT;

    -- Various signals (unrelated yet)
    SIGNAL s_register : STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0);
    SIGNAL s_send : STD_LOGIC;

    -- SPI related signals.
    SIGNAL s_miso : STD_LOGIC;

    SIGNAL s_din : STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
    SIGNAL s_din_valid : STD_LOGIC;
    SIGNAL s_din_rdy : STD_LOGIC;
    SIGNAL s_dout : STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
    SIGNAL s_dout_valid : STD_LOGIC;
BEGIN
    -- SPI Receiver.
    spi_slave_inst : SPI_Slave
    GENERIC MAP(
        DATA_WIDTH => SPI_DATAWIDTH
    )
    PORT MAP(
        clk => clk,
        rst => rst,
        scl => scl,
        cs_n => '0', -- if needed, make as separate input
        mosi => mosi,
        miso => miso,
        din => s_din,
        din_valid => s_din_valid,
        din_rdy => s_din_rdy,
        dout => s_dout,
        dout_valid => s_dout_valid
    );

    -- ADC2FIFO.
    adc2fifo_inst : ADC2FIFO
    GENERIC MAP(
        ADC_BITLEN => ADC_BITLEN,
        SPI_DATAWIDTH => SPI_DATAWIDTH
    )
    PORT MAP(
        clk => scl,
        rst => rst,
        adc_val => adc_val,
        adc_en => adc_en,
        send => s_send, -- TODO!
        dout => s_dout);

    -- MUX_CTRL
    mux_ctrl_inst : MUX_CTRL
    GENERIC MAP(MUX_LEN => MUX_LEN)
    PORT MAP(
        clk => clk,
        rst => rst,
        reg => s_register,
        mux => mux
    );
END tomoplex_main_arch;