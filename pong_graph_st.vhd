library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity pong_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(4 downto 0);
        video_on: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end pong_graph_st;

architecture sq_ball_arch of pong_graph_st is
-- Signal used to control speed of ball and how
-- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

-- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

-- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;
    
-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.
    signal bar_x_l, bar_x_r: unsigned(9 downto 0);
    signal bar_y_t, bar_y_b: unsigned(9 downto 0);
    constant BAR_Y_SIZE: integer := 72;
    constant BAR_X_SIZE: integer := 10;

-- reg to track top boundary
    signal bar_y_reg, bar_y_next: unsigned(9 downto 0);

-- reg to track left boundary
    signal bar_x_reg, bar_x_next: unsigned(9 downto 0);

-- bar moving velocity when a button is pressed
-- the amount the bar is moved.
    constant BAR_V: integer:= 4;
    constant BAR_X: integer:= 3;

-- square ball -- ball left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant BALL_SIZE: integer := 8;
    signal ball_x_l1, ball_x_r1: unsigned(9 downto 0);
    signal ball_y_t1, ball_y_b1: unsigned(9 downto 0);

    signal ball_x_l2, ball_x_r2: unsigned(9 downto 0);
    signal ball_y_t2, ball_y_b2: unsigned(9 downto 0);

    signal ball_x_l3, ball_x_r3: unsigned(9 downto 0);
    signal ball_y_t3, ball_y_b3: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal ball_x_reg1, ball_x_next1: unsigned(9 downto 0);
    signal ball_y_reg1, ball_y_next1: unsigned(9 downto 0);

    signal ball_x_reg2, ball_x_next2: unsigned(9 downto 0);
    signal ball_y_reg2, ball_y_next2: unsigned(9 downto 0);

    signal ball_x_reg3, ball_x_next3: unsigned(9 downto 0);
    signal ball_y_reg3, ball_y_next3: unsigned(9 downto 0);

-- reg to track ball speed
    signal x_delta_reg1, x_delta_next1: unsigned(9 downto 0);
    signal y_delta_reg1, y_delta_next1: unsigned(9 downto 0);

    signal x_delta_reg2, x_delta_next2: unsigned(9 downto 0);
    signal y_delta_reg2, y_delta_next2: unsigned(9 downto 0);

    signal x_delta_reg3, x_delta_next3: unsigned(9 downto 0);
    signal y_delta_reg3, y_delta_next3: unsigned(9 downto 0);

-- ball movement can be pos or neg
    constant BALL_V_P1: unsigned(9 downto 0):= to_unsigned(1,10);
    constant BALL_V_N1: unsigned(9 downto 0):= unsigned(to_signed(-3,10));

    constant BALL_V_P2: unsigned(9 downto 0):= to_unsigned(2,10);
    constant BALL_V_N2: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

    constant BALL_V_P3: unsigned(9 downto 0):= to_unsigned(3,10);
    constant BALL_V_N3: unsigned(9 downto 0):= unsigned(to_signed(-3,10));

-- round ball image
    type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL_ROM: rom_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
    
    signal rom_addr1, rom_col1: unsigned(2 downto 0);
    signal rom_data1: std_logic_vector(7 downto 0);
    signal rom_bit1: std_logic;

    signal rom_addr2, rom_col2: unsigned(2 downto 0);
    signal rom_data2: std_logic_vector(7 downto 0);
    signal rom_bit2: std_logic;

    signal rom_addr3, rom_col3: unsigned(2 downto 0);
    signal rom_data3: std_logic_vector(7 downto 0);
    signal rom_bit3: std_logic;

-- object output signals -- new signal to indicate if
-- scan coord is within ball
    signal wall_on, bar_on, sq_ball_on1, rd_ball_on1, sq_ball_on2, rd_ball_on2, sq_ball_on3, rd_ball_on3: std_logic;
    signal wall_rgb, bar_rgb, ball_rgb: std_logic_vector(2 downto 0);
-- ====================================================

begin
    process (clk, reset)
    begin
        if (reset = '1') then
            bar_x_reg <= (others => '0');
            bar_y_reg <= (others => '0');

            ball_x_reg1 <= (others => '0');
            ball_y_reg1 <= (others => '0');
            x_delta_reg1 <= ("0000000100");
            y_delta_reg1 <= ("0000000100");

            ball_x_reg2 <= (others => '0');
            ball_y_reg2 <= (others => '0');
            x_delta_reg2 <= ("0000000100");
            y_delta_reg2 <= ("0000000100");

            ball_x_reg3 <= (others => '0');
            ball_y_reg3 <= (others => '0');
            x_delta_reg3 <= ("0000000100");
            y_delta_reg3 <= ("0000000100");

        elsif (clk'event and clk = '1') then
            bar_x_reg <= bar_x_next;
            bar_y_reg <= bar_y_next;
            
            ball_x_reg1 <= ball_x_next1;
            ball_y_reg1 <= ball_y_next1;
            x_delta_reg1 <= x_delta_next1;
            y_delta_reg1 <= y_delta_next1;

            ball_x_reg2 <= ball_x_next2;
            ball_y_reg2 <= ball_y_next2;
            x_delta_reg2 <= x_delta_next2;
            y_delta_reg2 <= y_delta_next2;

            ball_x_reg3 <= ball_x_next3;
            ball_y_reg3 <= ball_y_next3;
            x_delta_reg3 <= x_delta_next3;
            y_delta_reg3 <= y_delta_next3;
        end if;
    end process;

    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

    -- refr_tick: 1-clock tick asserted at start of v_sync,
    -- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else '0';

    -- wall left vertical stripe
    wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
    wall_rgb <= "001"; -- blue

    -- pixel within paddle
    bar_y_t <= bar_y_reg;
    bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
    bar_x_l <= bar_x_reg;
    bar_x_r <= bar_x_reg + BAR_X_SIZE - 1;
    bar_on <= '1' when (bar_x_l <= pix_x) and (pix_x <= bar_x_r) and (bar_y_t <= pix_y) and (pix_y <= bar_y_b) else '0';
    bar_rgb <= "010"; -- green

    -- Process bar movement requests
    process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
    begin
        bar_y_next <= bar_y_reg; -- no move
        if ( refr_tick = '1' ) then
        -- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and bar_y_b < (MAX_Y - 1 - BAR_V)) then
                bar_y_next <= bar_y_reg + BAR_V;
        -- if btn 0 pressed and bar not at top yet
            elsif ( btn(2) = '1' and bar_y_t > BAR_V) then
                bar_y_next <= bar_y_reg - BAR_V;
            end if;
        end if;
    end process;

    -- Process bar movement requests
    process( bar_x_reg, bar_x_r, bar_x_l, refr_tick, btn)
    begin
        bar_x_next <= bar_x_reg; -- no move
        if ( refr_tick = '1' ) then
        -- if btn 3 pressed and paddle not at right yet
            if ( btn(3) = '1' and bar_x_r < (MAX_X - 1 - BAR_X)) then
                bar_x_next <= bar_x_reg + BAR_X;
        -- if btn 2 pressed and bar not at left yet
            elsif ( btn(4) = '1' and bar_x_l > BAR_X) then
                bar_x_next <= bar_x_reg - BAR_X;
            end if;
        end if;
    end process;

-- set coordinates of square ball.
    ball_x_l1 <= ball_x_reg1;
    ball_y_t1 <= ball_y_reg1;
    ball_x_r1 <= ball_x_l1 + BALL_SIZE - 1;
    ball_y_b1 <= ball_y_t1 + BALL_SIZE - 1;

    ball_x_l2 <= ball_x_reg2;
    ball_y_t2 <= ball_y_reg2;
    ball_x_r2 <= ball_x_l2 + BALL_SIZE - 1;
    ball_y_b2 <= ball_y_t2 + BALL_SIZE - 1;

    ball_x_l3 <= ball_x_reg3;
    ball_y_t3 <= ball_y_reg3;
    ball_x_r3 <= ball_x_l3 + BALL_SIZE - 1;
    ball_y_b3 <= ball_y_t3 + BALL_SIZE - 1;

-- pixel within square ball
    sq_ball_on1 <= '1' when (ball_x_l1 <= pix_x) and (pix_x <= ball_x_r1) and (ball_y_t1 <= pix_y) and (pix_y <= ball_y_b1) else '0';
    sq_ball_on2 <= '1' when (ball_x_l2 <= pix_x) and (pix_x <= ball_x_r2) and (ball_y_t2 <= pix_y) and (pix_y <= ball_y_b2) else '0';
    sq_ball_on3 <= '1' when (ball_x_l3 <= pix_x) and (pix_x <= ball_x_r3) and (ball_y_t3 <= pix_y) and (pix_y <= ball_y_b3) else '0';

-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    rom_addr1 <= pix_y(2 downto 0) - ball_y_t1(2 downto 0);
    rom_addr2 <= pix_y(2 downto 0) - ball_y_t2(2 downto 0);
    rom_addr3 <= pix_y(2 downto 0) - ball_y_t3(2 downto 0);

-- ROM column
    rom_col1 <= pix_x(2 downto 0) - ball_x_l1(2 downto 0);
    rom_col2 <= pix_x(2 downto 0) - ball_x_l2(2 downto 0);
    rom_col3 <= pix_x(2 downto 0) - ball_x_l3(2 downto 0);

-- Get row data
    rom_data1 <= BALL_ROM(to_integer(rom_addr1));
    rom_data2 <= BALL_ROM(to_integer(rom_addr2));
    rom_data3 <= BALL_ROM(to_integer(rom_addr3));

-- Get column bit
    rom_bit1 <= rom_data1(to_integer(rom_col1));
    rom_bit2 <= rom_data2(to_integer(rom_col2));
    rom_bit3 <= rom_data3(to_integer(rom_col3));

-- Turn ball on only if within square and ROM bit is 1.
    rd_ball_on1 <= '1' when (sq_ball_on1 = '1') and (rom_bit1 = '1') else '0';
    rd_ball_on2 <= '1' when (sq_ball_on2 = '1') and (rom_bit2 = '1') else '0';
    rd_ball_on3 <= '1' when (sq_ball_on3 = '1') and (rom_bit3 = '1') else '0';

    ball_rgb <= "100"; -- red
-- Update the ball position 60 times per second.
    ball_x_next1 <= ball_x_reg1 + x_delta_reg1 when refr_tick = '1' else ball_x_reg1;
    ball_y_next1 <= ball_y_reg1 + y_delta_reg1 when refr_tick = '1' else ball_y_reg1;

    ball_x_next2 <= ball_x_reg2 + x_delta_reg2 when refr_tick = '1' else ball_x_reg2;
    ball_y_next2 <= ball_y_reg2 + y_delta_reg2 when refr_tick = '1' else ball_y_reg2;

    ball_x_next3 <= ball_x_reg3 + x_delta_reg3 when refr_tick = '1' else ball_x_reg3;
    ball_y_next3 <= ball_y_reg3 + y_delta_reg3 when refr_tick = '1' else ball_y_reg3;

-- Set the value of the next ball position according to the boundaries.
    process(x_delta_reg1, y_delta_reg1, ball_y_t1, ball_x_l1, ball_x_r1, ball_y_t1, ball_y_b1, bar_y_t, bar_y_b)
    begin
        x_delta_next1 <= x_delta_reg1;
        y_delta_next1 <= y_delta_reg1;
    -- ball reached top, make offset positive
        if ( ball_y_t1 < 1 ) then
            y_delta_next1 <= BALL_V_P1;
    -- reached bottom, make negative
        elsif (ball_y_b1 > (MAX_Y - 1)) then
            y_delta_next1 <= BALL_V_N1;
        -- reach wall, bounce back
        elsif (ball_x_l1 <= WALL_X_R ) then
            x_delta_next1 <= BALL_V_P1;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball_x_r1) and (ball_x_r1 <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball_y_b1) and (ball_y_t1 <= bar_y_b)) then
                x_delta_next1 <= BALL_V_N1;
            end if;
        end if;
    end process;

    process(x_delta_reg2, y_delta_reg2, ball_y_t2, ball_x_l2, ball_x_r2, ball_y_t2, ball_y_b2, bar_y_t, bar_y_b)
    begin
        x_delta_next2 <= x_delta_reg2;
        y_delta_next2 <= y_delta_reg2;
    -- ball reached top, make offset positive
        if ( ball_y_t2 < 1 ) then
            y_delta_next2 <= BALL_V_P2;
    -- reached bottom, make negative
        elsif (ball_y_b2 > (MAX_Y - 1)) then
            y_delta_next2 <= BALL_V_N2;
        -- reach wall, bounce back
        elsif (ball_x_l2 <= WALL_X_R ) then
            x_delta_next2 <= BALL_V_P2;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball_x_r2) and (ball_x_r2 <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball_y_b2) and (ball_y_t2 <= bar_y_b)) then
                x_delta_next2 <= BALL_V_N2;
            end if;
        end if;
    end process;

    process(x_delta_reg3, y_delta_reg3, ball_y_t3, ball_x_l3, ball_x_r3, ball_y_t3, ball_y_b3, bar_y_t, bar_y_b)
    begin
        x_delta_next3 <= x_delta_reg3;
        y_delta_next3 <= y_delta_reg3;
    -- ball reached top, make offset positive
        if ( ball_y_t3 < 1 ) then
            y_delta_next3 <= BALL_V_P3;
    -- reached bottom, make negative
        elsif (ball_y_b3 > (MAX_Y - 1)) then
            y_delta_next3 <= BALL_V_N3;
        -- reach wall, bounce back
        elsif (ball_x_l3 <= WALL_X_R ) then
            x_delta_next3 <= BALL_V_P3;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball_x_r3) and (ball_x_r3 <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball_y_b3) and (ball_y_t3 <= bar_y_b)) then
                x_delta_next3 <= BALL_V_N3;
            end if;
        end if;
    end process;

    process (video_on, wall_on, bar_on, rd_ball_on1, rd_ball_on2, rd_ball_on3, wall_rgb, bar_rgb, ball_rgb)
    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (bar_on = '1') then
                graph_rgb <= bar_rgb;
            elsif (rd_ball_on1 = '1') then
                graph_rgb <= ball_rgb;
            elsif (rd_ball_on2 = '1') then
                graph_rgb <= ball_rgb;
            elsif (rd_ball_on3 = '1') then
                graph_rgb <= ball_rgb;
            else
                graph_rgb <= "110"; -- yellow bkgnd
            end if;
        end if;
    end process;
end sq_ball_arch;

   
