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
        ADC_BITLEN : NATURAL := 8;
        
        -- SPI data width with the corresponding microcontroller.
        DATA_WIDTH_MCU : integer := 16;

        -- Length of a normal data word via SPI.
        SPI_DATAWIDTH_MCU : NATURAL := 8;
        
        -- Frequency of the used fpga clock.
        FPGA_FREQUENCY : Integer := 100_000_000; -- 100 MHz
        
        -- Frequency of the SPI master clock for mux controller communication.
        SPI_FREQUENCY_MUX : integer := 2_000_000; -- Intentionally unspecified !
        
        -- SPI data width with mux controller communication.
        DATA_WIDTH_MUX : integer := 8
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
        scl_mcu : IN STD_LOGIC;
        mosi_mcu : IN STD_LOGIC;
        miso_mcu : OUT STD_LOGIC := '0';
        cs_mcu : IN STD_LOGIC; -- if not needed make it '0' !
        
        debug : out std_logic_vector(2 downto 0);

        -- MUX control related signals.
        scl_mux : out std_logic;
        mosi_mux : out std_logic := '0';
        miso_mux : in std_logic;
        ss_mux : out std_logic
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
            sample_en : in std_logic;
            send : IN STD_LOGIC;
            fifo_size : out std_logic_vector(15 downto 0);
            fifo_elements : out std_logic_vector(15 downto 0);
            dout : OUT STD_LOGIC_VECTOR((SPI_DATAWIDTH - 1) DOWNTO 0);
            spi_tx_rdy : in std_Logic;
            debug : out std_logic_vector(2 downto 0);
            spi_tx_con : out std_logic
        );
    END COMPONENT;

    COMPONENT MUX_CTRL
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
            reg : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            mux : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT spi_slave
        generic (
            -- 32bit serial word length is default. 
            N: positive := 32;
            
            -- SPI mode selection (mode 0 is default). 
            CPOL : std_logic := '0';
            
            -- CPOL = clock polarity, CPHA = clock phase.
            CPHA: std_logic := '0';
            
            -- Prefetch lookahead cycles.
            PREFETCH : positive := 3
        );
        port (
            -- Internal interface clock (clocks di/do registers)        
            clk_i : in std_logic := 'X';
            
            -- SPI bus slave select line.
            spi_ssel_i : in std_logic := 'X';
            
            -- SPI bus SCK clock (clocks the shift register core).
            spi_sck_i : in std_logic := 'X';
            
            -- SPI bus MOSI input.
            spi_mosi_i : in std_logic := 'X';
            
            -- SPI bus MISO output.
            spi_miso_o : out std_logic := 'X';
            
            -- Preload lookahead data request line.
            di_req_o : out std_logic;
            
            -- Parallel load data in (clocked in on rising edge of clk_i).
            di_i : in std_logic_vector(N-1 downto 0) := (others => 'X');
            
            -- User data write enable.
            wren_i : in std_logic := 'X';
            
            -- Write acknowledgement.
            wr_ack_o : out std_logic;
            
            -- do_o data valid strobe, valid during one clk_i rising edge.
            do_valid_o : out std_logic;
            
            -- Parallel output (clocked out on falling clk_i).
            do_o : out std_logic_vector(N-1 downto 0);
            
            
            --- debug ports: can be removed for the application circuit ---
            -- Internal transfer drive.
            do_transfer_o : out std_logic;
            
            -- Internal state of the wren_i pulse stretcher. 
            wren_o : out std_logic;
            
            -- Internal rx bit. 
            rx_bit_next_o : out std_logic;
            
            -- Internal state register. 
            state_dbg_o : out std_logic_vector(3 downto 0);
            
            -- Internal shift register.
            sh_reg_dbg_o : out std_logic_vector(N-1 downto 0)
        );
    end component;

    -- Various signals (unrelated yet)
    SIGNAL s_register : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL s_send : STD_LOGIC;
    SIGNAL s_record : STD_LOGIC;
    
    SIGNAL s_mux_switchpos : STD_LOGIC_VECTOR(7 downto 0);

    -- SPI related signals (MCU communication).
    signal s_scl_mcu : std_logic;
    signal s_cs_mcu : std_logic;
    SIGNAL s_miso_mcu : STD_LOGIC := '0';
    SIGNAL s_mosi_mcu : STD_LOGIC;

    SIGNAL s_din : STD_LOGIC_VECTOR((SPI_DATAWIDTH_mcu - 1) DOWNTO 0);
    SIGNAL s_dout : STD_LOGIC_VECTOR((SPI_DATAWIDTH_mcu - 1) DOWNTO 0);
    SIGNAL s_rx_valid : STD_LOGIC;
    signal s_tx_rdy : std_logic;
    signal s_tx_con: std_logic; -- Shows if continuous transmitting is wanted.
    
    signal s_do : std_logic_vector((SPI_DATAWIDTH_mcu-1) downto 0) := (others => '0'); -- unconnected TODO
    signal s_di : std_logic_vector((SPI_DATAWIDTH_mcu-1) downto 0) := (others => '0'); -- unconnected TODO
        
    signal s_spi_send : std_logic_vector(SPI_DATAWIDTH_mcu-1 downto 0);
    
    -- SPI related signals (MUX communication).
    signal s_scl_mux : std_logic;
    signal s_miso_mux : std_logic;
    signal s_mosi_mux : std_logic;
    signal s_cs_mux : std_logic;
    
    signal s_mux : std_logic_vector(15 downto 0);
    
    -- Sample signal for ADC2FIFO.
    signal s_sample : std_logic;
    
    -- Fifo related registers.
    signal s_fifo_size : std_logic_vector(15 downto 0);
    signal s_fifo_elements : std_logic_vector(15 downto 0);
    
    -- Command Decoder.
    Type CommandDecoderStates IS (S_Decode, S_Reset);
    Signal s_commanddecoderstate : CommandDecoderStates := S_Decode;
BEGIN
    -- Debug:
    --miso <= ;
    --mux <= s_fifo_elements(11 downto 0);
    
    -- Drive outputs.
    miso_mcu <= s_miso_mcu;
        
    -- Read inputs.
    s_scl_mcu <= scl_mcu;
    s_cs_mcu <= cs_mcu;
    s_mosi_mcu <= mosi_mcu;


    -- SPI Receiver.
    spi_slave_inst : spi_slave
        generic map (
            N => SPI_DATAWIDTH_mcu,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 1 -- 3 is default value !
        )
        port map (
            clk_i => clk, -- done
            spi_ssel_i => s_cs_mcu, -- done
            spi_sck_i => s_scl_mcu, -- done
            spi_mosi_i => s_mosi_mcu, -- done
            spi_miso_o => s_miso_mcu, -- done 
            di_req_o => s_tx_rdy, -- TBD
            di_i => s_spi_send, -- done
            wren_i => s_tx_con,  -- TBD
            wr_ack_o => open, -- If needed define new signal for it
            do_valid_o => s_rx_valid,
            do_o => s_dout,
            do_transfer_o => open,
            wren_o => open,
            rx_bit_next_o => open,
            state_dbg_o => open,
            sh_reg_dbg_o => open
        );

    -- ADC2FIFO.
    adc2fifo_inst : ADC2FIFO
    GENERIC MAP(
        ADC_BITLEN => ADC_BITLEN,
        SPI_DATAWIDTH => SPI_DATAWIDTH_mcu
    )
    PORT MAP(
        clk => clk,
        rst => rst,
        adc_val => adc_val,
        adc_en => adc_en,
        sample_en => '1', -- TODO: Has to be changed as soon as MUX entity is integrated !
        send => s_send, -- TODO!
        fifo_size => s_fifo_size,
        fifo_elements => s_fifo_elements,
        dout => s_spi_send, -- SPI entity related
        spi_tx_rdy => s_tx_rdy, -- SPI entity related
        debug => debug,
        spi_tx_con => s_tx_con -- SPI entity related
        );

    -- MUX_CTRL
    mux_ctrl_inst : MUX_CTRL
    GENERIC MAP(
        Quarz_Taktfrequenz => FPGA_FREQUENCY,
        SPI_Taktfrequenz => SPI_FREQUENCY_mux,
        DATA_WIDTH => DATA_WIDTH_mux
    )
    PORT MAP(
        clk => clk,
        rst => rst,
        scl => s_scl_mux,
        miso => s_miso_mux,
        mosi => s_mosi_mux,
        ss => s_cs_mux,
        sample => s_sample,
        reg => s_register,
        mux => s_mux
    );
    
    
    -- Command Decoder
    process(clk)
        variable i : integer range 0 to (2**SPI_DATAWIDTH_MCU)-1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset.
                s_send <= '0';
                s_record <= '0';
                s_mux_switchpos <= (others => '0'); -- 0 means: All Switches off (appropiate behaviour after global reset)
                s_commanddecoderstate <= S_Decode;
            else
                if s_rx_valid = '1' then
                    --report "New Data was received via SPI!";
                    -- new Data byte was received. Decode ->
                    i := to_integer(unsigned(s_dout));
                    --report "The value of the data is " & integer'image(i);
                    
                    case s_commanddecoderstate is
                        when S_Decode =>
                            if i = 64 then
                                -- Record command
                                s_record <= '1';
                                s_commanddecoderstate <= S_Reset;
                            elsif i = 128 then
                                -- Send command
                                report "Send command received";
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