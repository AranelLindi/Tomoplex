----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/06/2023 07:34:59 PM
-- Design Name: 
-- Module Name: tomoplex_main - tomoplex_main_arch
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

entity tomoplex_main is
    Generic (
        adc_bitlen : positive;
        mux_len : positive;
        spi_datawidth : positive
    );
    Port ( clk : in STD_LOGIC;
         rst : in STD_LOGIC;
         adc_val : in STD_LOGIC_VECTOR ((adc_bitlen-1) downto 0);
         adc_en : in STD_LOGIC;
         scl : in STD_LOGIC;
         mosi : in STD_LOGIC;
         miso : in STD_LOGIC;
         mux : out STD_LOGIC_VECTOR((mux_len-1) downto 0)
         );
end tomoplex_main;

architecture tomoplex_main_arch of tomoplex_main is
    constant c_command : std_logic_vector((spi_datawidth-1) downto 0) := ""; -- TODO
    signal s_register : std_logic_vector((mux_len-1) downto 0);
    signal s_send : std_logic;

    component ADC2FIFO
        Generic (
            adc_bitlen : positive
        );
        Port (
            clk : in std_logic;
            rst : in std_logic;
            adc_val : in std_logic_vector((adc_bitlen-1) downto 0);
            adc_en : in std_logic;
            send : in std_logic;
            miso : out std_logic
        );
    end component;
    
    component MUX_CTRL
        generic (
            mux_len : positive
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            reg : in std_logic_vector((mux_len-1) downto 0);
            mux : out std_logic_vector((mux_len-1) downto 0)
        );
    end component;
    
    
    -- SPI slave related signals.
    signal s_shift_reg : std_logic_vector((spi_datawidth-1) downto 0);
begin
    -- SPI slave.
    process(scl)
    begin
        if rising_edge(scl) then
            if rst = '1' then
                -- Synchronous reset.
                s_shift_reg <= (others => '0');
            else
                s_shift_reg <= s_shift_reg((spi_datawidth-2) downto 0) & mosi;
            end if;
        end if;
    end process;
    
    process(scl)
    begin
        if rising_edge(scl) then
            if rst = '1' then
                -- Synchronous reset.
                s_send <= '0';
            else
                if s_shift_reg = c_command then
                    s_send <= '1';
                else
                    s_send <= '0';
                end if;
            end if;
        end if;
    end process;



    adc2fifo_inst: ADC2FIFO
        generic map ( adc_bitlen => adc_bitlen)
        port map (clk => scl,
                    rst => rst,
                    adc_val => adc_val,
                    adc_en => adc_en,
                    send => s_send, -- TODO!
                    miso => miso);

    mux_ctrl_inst: MUX_CTRL
        generic map (mux_len => mux_len)
        port map (
            clk => clk,
            rst => rst,
            reg => s_register,
            mux => mux
        );
end tomoplex_main_arch;
