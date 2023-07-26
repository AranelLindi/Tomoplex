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
USE IEEE.NUMERIC_STD.ALL;

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
        cs : IN STD_LOGIC; -- if not needed make it '0' !

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
            DATA_WIDTH : positive
        );
        PORT (
            clk    : in  STD_LOGIC;
            SSn    : in  STD_LOGIC;
            SCLK   : in  STD_LOGIC;
            MOSI   : in  STD_LOGIC;
            MISO   : out STD_LOGIC;
            Dout : out  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            Din  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            newDataFlag : out std_logic
    );
    END COMPONENT;

    -- Various signals (unrelated yet)
    SIGNAL s_register : STD_LOGIC_VECTOR((MUX_LEN - 1) DOWNTO 0);
    SIGNAL s_send : STD_LOGIC;
    SIGNAL s_record : STD_LOGIC;
    
    SIGNAL s_mux_switchpos : STD_LOGIC_VECTOR(7 downto 0);

    -- SPI related signals.
    SIGNAL s_miso : STD_LOGIC;

    SIGNAL s_din : STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
    SIGNAL s_dout : STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
    SIGNAL s_newDataFlag : STD_LOGIC;
    
    -- Command Decoder.
    Type CommandDecoderStates IS (S_Decode, S_Reset);
    Signal s_commanddecoderstate : CommandDecoderStates := S_Decode;
BEGIN
    -- SPI Receiver.
    spi_slave_inst : SPI_Slave
    GENERIC MAP(
        DATA_WIDTH => SPI_DATAWIDTH
    )
    PORT MAP(
        clk => clk,
        SSn => cs,
        SCLK => scl,
        MOSI => mosi,
        MISO => miso,
        Din => s_din,
        Dout => s_dout,
        newDataFlag => s_newDataFlag
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
    
    
    -- Command Decoder
    process(clk)
        variable i : integer range 0 to (2**SPI_DATAWIDTH)-1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
                s_send <= '0';
                s_record <= '0';
                s_mux_switchpos <= (others => '0'); -- 0 means: All Switches off (appropiate behaviour after global reset)
                s_commanddecoderstate <= S_Decode;
            else
                if s_newDataFlag = '1' then
                    -- new Data byte was received. Decode ->
                    i := to_integer(unsigned(s_dout));
                    
                    case s_commanddecoderstate is
                        when S_Decode =>
                            if i = 64 then
                                -- Record command
                                s_record <= '1';
                                s_commanddecoderstate <= S_Reset;
                            elsif i = 128 then
                                -- Send command
                                s_send <= '1';
                                s_commanddecoderstate <= S_Reset;
                            elsif (i >= 0 and i <= 16) or i = 255 then
                                -- MUX controller switch command
                                s_mux_switchpos <= std_logic_vector(to_unsigned(i, s_mux_switchpos'length));
                                s_commanddecoderstate <= S_Reset;
                            else
                                -- No valid command.
                                s_commanddecoderstate <= S_Decode;
                            end if;
                        
                        when S_Reset =>
                            -- All signals are reset here...
                            s_mux_switchpos <= std_logic_vector(to_unsigned(255, s_mux_switchpos'length)); -- 255 means: retains previous switch condition
                            s_send <= '0';
                            s_record <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;
END tomoplex_main_arch;