library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity game_over_display is
    port(
        clk, reset: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        life_cnt: in std_logic_vector(1 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end game_over_display;

architecture arch of game_over_display is
    signal pix_x, pix_y: unsigned(9 downto 0);

    constant LETTER_SIZE: unsigned := to_unsigned(32, 10);
    constant LETTER_RGB: std_logic_vector := "110";

    type letter_type is array (0 to 31) of std_logic_vector(31 downto 0);

    constant G_ROM: letter_type:= (
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "00000000000000000000000000000011",
        "11111111111111111100000000000011",
        "11111111111111111100000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111"
    );

    constant G_X_L1: unsigned := to_unsigned(220, 10);
    constant G_X_R1: unsigned := G_X_L1 + LETTER_SIZE - 1;
    constant G_Y_T1: unsigned := to_unsigned(150, 10);
    constant G_Y_B1: unsigned := G_Y_T1 + LETTER_SIZE - 1;

    signal G_rom_addr1, G_rom_col1: unsigned(4 downto 0);
    signal G_rom_data1: std_logic_vector(31 downto 0);
    signal G_rom_bit1: std_logic;

    signal sq_G_on1: std_logic;
    signal G_G_on1: std_logic;

    constant A_ROM: letter_type:= (
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011",
        "11000000000000000000000000000011"
    );

    constant A_X_L1: unsigned := to_unsigned(260, 10);
    constant A_X_R1: unsigned := A_X_L1 + LETTER_SIZE - 1;
    constant A_Y_T1: unsigned := to_unsigned(150, 10);
    constant A_Y_B1: unsigned := A_Y_T1 + LETTER_SIZE - 1;

    signal A_rom_addr1, A_rom_col1: unsigned(4 downto 0);
    signal A_rom_data1: std_logic_vector(31 downto 0);
    signal A_rom_bit1: std_logic;

    signal sq_A_on1: std_logic;
    signal A_A_on1: std_logic;
    
begin
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

    sq_G_on1 <= '1' when (G_X_L1 <= pix_x) and (pix_x <= G_X_R1) and (G_Y_T1 <= pix_y) and (pix_y <= G_Y_B1) else '0';
    G_rom_addr1 <= pix_y(4 downto 0) - G_Y_T1(4 downto 0);
    G_rom_col1 <= pix_x(4 downto 0) - G_X_L1(4 downto 0);
    G_rom_data1 <= G_ROM(to_integer(G_rom_addr1));
    G_rom_bit1 <= G_rom_data1(to_integer(G_rom_col1));
    G_G_on1 <= '1' when (sq_G_on1 = '1') and (G_rom_bit1 = '1') else '0';

    sq_A_on1 <= '1' when (A_X_L1 <= pix_x) and (pix_x <= A_X_R1) and (A_Y_T1 <= pix_y) and (pix_y <= A_Y_B1) else '0';
    A_rom_addr1 <= pix_y(4 downto 0) - A_Y_T1(4 downto 0);
    A_rom_col1 <= pix_x(4 downto 0) - A_X_L1(4 downto 0);
    A_rom_data1 <= A_ROM(to_integer(A_rom_addr1));
    A_rom_bit1 <= A_rom_data1(to_integer(A_rom_col1));
    A_A_on1 <= '1' when (sq_A_on1 = '1') and (A_rom_bit1 = '1') else '0';

    graph_rgb <= LETTER_RGB when ((G_G_on1 = '1') or (A_A_on1 = '1')) else "000";
end arch;














