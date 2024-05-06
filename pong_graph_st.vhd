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
        hit_cnt: out std_logic_vector(2 downto 0);
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

-- triangle moving velocity when a button is pressed
-- the amount the triangle is moved.
    constant TR_V: integer:= 3;
    constant TR_X: integer:= 3;

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
    constant BALL_V_N1: unsigned(9 downto 0):= unsigned(to_signed(-1,10));

    constant BALL_V_P2: unsigned(9 downto 0):= to_unsigned(2,10);
    constant BALL_V_N2: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

    constant BALL_V_P3: unsigned(9 downto 0):= to_unsigned(3,10);
    constant BALL_V_N3: unsigned(9 downto 0):= unsigned(to_signed(-3,10));

-- firing missile
    constant MISSILE_SIZE_Y: integer := 16;
    constant MISSILE_SIZE_X: integer := 8;
    signal missile_x_l, missile_x_r: unsigned(9 downto 0);
    signal missile_y_t, missile_y_b: unsigned(9 downto 0);

    signal missile_fire_reg, missile_fire_next: std_logic;

    constant MISSILE_V: integer := 2;

-- reg to track left and top boundary
    signal missile_x_reg, missile_x_next: unsigned(9 downto 0);
    signal missile_y_reg, missile_y_next: unsigned(9 downto 0);

-- reg to track middle button press
    type btn_state is (idle, button_in, button_out);
    signal btn_state_reg, btn_state_next: btn_state;

-- Triangle
    constant TR_SIZE: integer := 32;
    signal tr_x_l, tr_x_r: unsigned(9 downto 0);
    signal tr_y_t, tr_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal tr_x_reg, tr_x_next: unsigned(9 downto 0);
    signal tr_y_reg, tr_y_next: unsigned(9 downto 0);

-- round ball image
    type ball_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL_ROM: ball_rom_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");
        
    type tr_rom_type is array(0 to 31) of std_logic_vector(0 to 31);
    constant TR_ROM: tr_rom_type:= (
        "00000000000000001000000000000000",
        "00000000000000011100000000000000",
        "00000000000000111110000000000000",
        "00000000000001111111000000000000",
        "00000000000011111111100000000000",
        "00000000000111111111110000000000",
        "00000000001111111111111000000000",
        "00000000011111111111111100000000",
        "00000000111111111111111110000000",
        "00000001111111111111111111000000",
        "00000011111111111111111111100000",
        "00000111111111111111111111110000",
        "00001111111111111111111111111000",
        "00011111111111111111111111111100",
        "00111111111111111111111111111110",
        "01111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111",
        "11111111111111111111111111111111");
    
    signal rom_addr1, rom_col1: unsigned(2 downto 0);
    signal rom_data1: std_logic_vector(7 downto 0);
    signal rom_bit1: std_logic;

    signal rom_addr2, rom_col2: unsigned(2 downto 0);
    signal rom_data2: std_logic_vector(7 downto 0);
    signal rom_bit2: std_logic;

    signal rom_addr3, rom_col3: unsigned(2 downto 0);
    signal rom_data3: std_logic_vector(7 downto 0);
    signal rom_bit3: std_logic;

    signal tr_rom_addr, tr_rom_col: unsigned(5 downto 0);
    signal tr_rom_data: std_logic_vector(31 downto 0);
    signal tr_rom_bit: std_logic;


-- object output signals -- new signal to indicate if
-- scan coord is within ball
    signal wall_on: std_logic;
    signal sq_ball_on1, rd_ball_on1, sq_ball_on2, rd_ball_on2, sq_ball_on3, rd_ball_on3: std_logic;
    signal sq_tr_on, tr_tr_on: std_logic;
    signal missile_on: std_logic;
    signal wall_rgb, ball_rgb, tr_rgb, missile_rgb: std_logic_vector(2 downto 0);

    signal hit_log1, hit_log2, hit_log3: boolean;
    signal hit_cnt_reg, hit_cnt_next: unsigned (2 downto 0);
-- ====================================================

begin
    process (clk, reset)
    begin
        if (reset = '1') then
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

            tr_x_reg <= ("0011111100");
            tr_y_reg <= ("0011111100");

            missile_x_reg <= ("0011111100");
            missile_y_reg <= ("0011111100");
            missile_fire_reg <= '0';

            hit_cnt_reg <= (others => '0');

            btn_state_reg <= idle;

        elsif (clk'event and clk = '1') then
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

            tr_x_reg <= tr_x_next;
            tr_y_reg <= tr_y_next;

            missile_x_reg <= missile_x_next;
            missile_y_reg <= missile_y_next;
            
            missile_fire_reg <= missile_fire_next;

            hit_cnt_reg <= hit_cnt_next;

            btn_state_reg <= btn_state_next;
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

    -- Process triangle movement requests
    process( tr_y_reg, tr_y_b, tr_y_t, refr_tick, btn)
    begin
        tr_y_next <= tr_y_reg; -- no move
        if ( refr_tick = '1' ) then
        -- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and tr_y_b < (MAX_Y - 1 - TR_V)) then
                tr_y_next <= tr_y_reg + TR_V;
        -- if btn 0 pressed and bar not at top yet
            elsif ( btn(2) = '1' and tr_y_t > TR_V) then
                tr_y_next <= tr_y_reg - TR_V;
            end if;
        end if;
    end process;

    -- Process triangle movement requests
    process( tr_x_reg, tr_x_r, tr_x_l, refr_tick, btn)
    begin
        tr_x_next <= tr_x_reg; -- no move
        if ( refr_tick = '1' ) then
        -- if btn 3 pressed and paddle not at right yet
            if ( btn(3) = '1' and tr_x_r < (MAX_X - 1 - TR_X)) then
                tr_x_next <= tr_x_reg + TR_X;
        -- if btn 2 pressed and bar not at left yet
            elsif ( btn(4) = '1' and tr_x_l > TR_X) then
                tr_x_next <= tr_x_reg - TR_X;
            end if;
        end if;
    end process;

    -- Process for middle button
    process(btn_state_reg, btn_state_next, btn, missile_fire_next, missile_y_t)
    begin
        btn_state_next <= btn_state_reg;
        missile_fire_next <= missile_fire_reg;
        case btn_state_reg is
            when idle =>
                if (btn(0) = '1') then
                    btn_state_next <= button_in;
                end if;

                if (missile_y_t < 1) then
                    missile_fire_next <= '0';
                end if;
            
            when button_in =>
                missile_fire_next <= '0';
                if (btn(0) = '0') then
                    btn_state_next <= button_out;
                end if;

            when button_out =>
                missile_fire_next <= '1';
                btn_state_next <= idle;
        end case;
    end process;

    -- Process for missile
    process(missile_x_reg, missile_y_reg, missile_x_next, missile_y_next, missile_y_t, missile_fire_reg, missile_fire_next, tr_x_l, tr_y_t, refr_tick)
    begin
        if (refr_tick = '1') then
            if (missile_fire_reg = '1') then
                missile_x_next <= missile_x_reg;
                missile_y_next <= missile_y_reg - MISSILE_V;
            else
                missile_x_next <= tr_x_l + TR_SIZE/2;
                missile_y_next <= tr_y_t;
            end if;
        else
            missile_x_next <= missile_x_reg;
            missile_y_next <= missile_y_reg;
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

-- set coordinates of triangle.
    tr_x_l <= tr_x_reg;
    tr_y_t <= tr_y_reg;
    tr_x_r <= tr_x_l + TR_SIZE - 1;
    tr_y_b <= tr_y_t + TR_SIZE - 1;

-- pixel within missile.
    missile_x_l <= missile_x_reg;
    missile_y_t <= missile_y_reg;
    missile_x_r <= missile_x_l + MISSILE_SIZE_X - 1;
    missile_y_b <= missile_y_t + MISSILE_SIZE_Y - 1;
    missile_on <= '1' when (missile_x_l <= pix_x) and (pix_x <= missile_x_r) and (missile_y_t <= pix_y) and (pix_y <= missile_y_b) and (missile_fire_reg = '1') else '0';
    missile_rgb <= "100"; --white

-- pixel within square ball
    sq_ball_on1 <= '1' when (ball_x_l1 <= pix_x) and (pix_x <= ball_x_r1) and (ball_y_t1 <= pix_y) and (pix_y <= ball_y_b1) else '0';
    sq_ball_on2 <= '1' when (ball_x_l2 <= pix_x) and (pix_x <= ball_x_r2) and (ball_y_t2 <= pix_y) and (pix_y <= ball_y_b2) else '0';
    sq_ball_on3 <= '1' when (ball_x_l3 <= pix_x) and (pix_x <= ball_x_r3) and (ball_y_t3 <= pix_y) and (pix_y <= ball_y_b3) else '0';
    
-- pixel within square triangle
    sq_tr_on <= '1' when (tr_x_l <= pix_x) and (pix_x <= tr_x_r) and (tr_y_t <= pix_y) and (pix_y <= tr_y_b) else '0';

-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    rom_addr1 <= pix_y(2 downto 0) - ball_y_t1(2 downto 0);
    rom_addr2 <= pix_y(2 downto 0) - ball_y_t2(2 downto 0);
    rom_addr3 <= pix_y(2 downto 0) - ball_y_t3(2 downto 0);

    tr_rom_addr <= pix_y(5 downto 0) - tr_y_t(5 downto 0);

-- ROM column
    rom_col1 <= pix_x(2 downto 0) - ball_x_l1(2 downto 0);
    rom_col2 <= pix_x(2 downto 0) - ball_x_l2(2 downto 0);
    rom_col3 <= pix_x(2 downto 0) - ball_x_l3(2 downto 0);

    tr_rom_col <= pix_x(5 downto 0) - tr_x_l(5 downto 0);

-- Get row data
    rom_data1 <= BALL_ROM(to_integer(rom_addr1));
    rom_data2 <= BALL_ROM(to_integer(rom_addr2));
    rom_data3 <= BALL_ROM(to_integer(rom_addr3));

    tr_rom_data <= TR_ROM(to_integer(tr_rom_addr));

-- Get column bit
    rom_bit1 <= rom_data1(to_integer(rom_col1));
    rom_bit2 <= rom_data2(to_integer(rom_col2));
    rom_bit3 <= rom_data3(to_integer(rom_col3));

    tr_rom_bit <= tr_rom_data(to_integer(tr_rom_col));

-- Turn ball on only if within square and ROM bit is 1.
    rd_ball_on1 <= '1' when (sq_ball_on1 = '1') and (rom_bit1 = '1') else '0';
    rd_ball_on2 <= '1' when (sq_ball_on2 = '1') and (rom_bit2 = '1') else '0';
    rd_ball_on3 <= '1' when (sq_ball_on3 = '1') and (rom_bit3 = '1') else '0';

    tr_tr_on <= '1' when (sq_tr_on = '1') and (tr_rom_bit = '1') else '0';

    ball_rgb <= "100"; -- red
    tr_rgb <= "011"; -- cyan
-- Update the ball position 60 times per second.
    ball_x_next1 <= ball_x_reg1 + x_delta_reg1 when refr_tick = '1' else ball_x_reg1;
    ball_y_next1 <= ball_y_reg1 + y_delta_reg1 when refr_tick = '1' else ball_y_reg1;

    ball_x_next2 <= ball_x_reg2 + x_delta_reg2 when refr_tick = '1' else ball_x_reg2;
    ball_y_next2 <= ball_y_reg2 + y_delta_reg2 when refr_tick = '1' else ball_y_reg2;

    ball_x_next3 <= ball_x_reg3 + x_delta_reg3 when refr_tick = '1' else ball_x_reg3;
    ball_y_next3 <= ball_y_reg3 + y_delta_reg3 when refr_tick = '1' else ball_y_reg3;

-- Set the value of the next ball position according to the boundaries.
    process(x_delta_reg1, y_delta_reg1, ball_y_t1, ball_x_l1, ball_x_r1, ball_y_t1, ball_y_b1, tr_y_t, tr_y_b, tr_x_l, tr_x_r)
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
        elsif ((tr_x_l <= ball_x_r1) and (ball_x_r1 <= tr_x_r)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((tr_y_t <= ball_y_b1) and (ball_y_t1 <= tr_y_b)) then
                x_delta_next1 <= BALL_V_N1;
            end if;
        end if;
    end process;

    process(x_delta_reg2, y_delta_reg2, ball_y_t2, ball_x_l2, ball_x_r2, ball_y_t2, ball_y_b2, tr_y_t, tr_y_b, tr_x_l, tr_x_r)
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
        elsif ((tr_x_l <= ball_x_r2) and (ball_x_r2 <= tr_x_r)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((tr_y_t <= ball_y_b2) and (ball_y_t2 <= tr_y_b)) then
                x_delta_next2 <= BALL_V_N2;
            end if;
        end if;
    end process;

    process(x_delta_reg3, y_delta_reg3, ball_y_t3, ball_x_l3, ball_x_r3, ball_y_t3, ball_y_b3, tr_y_t, tr_y_b, tr_x_l, tr_x_r)
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
        elsif ((tr_x_l <= ball_x_r3) and (ball_x_r3 <= tr_x_r)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((tr_y_t <= ball_y_b3) and (ball_y_t3 <= tr_y_b)) then
                x_delta_next3 <= BALL_V_N3;
            end if;
        end if;
    end process;

    process (video_on, wall_on, rd_ball_on1, rd_ball_on2, rd_ball_on3, tr_tr_on, wall_rgb, ball_rgb, tr_rgb)
    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (tr_tr_on = '1') then
                graph_rgb <= tr_rgb;
            elsif (missile_on = '1') then
                graph_rgb <= missile_rgb;
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

    hit_log1 <= (tr_x_l < ball_x_r1) and 
                (ball_x_r1 < tr_x_l + BALL_V_P1) and 
                (x_delta_reg1 = BALL_V_N1) and 
                (tr_y_t < ball_y_b1) and 
                (ball_y_t1 < tr_y_b) and 
                (refr_tick = '1');

    hit_log2 <= (tr_X_L < ball_x_r2) and 
                (ball_x_r2 < tr_X_L + BALL_V_P2) and 
                (x_delta_reg2 = BALL_V_N2) and 
                (tr_y_t < ball_y_b2) and 
                (ball_y_t2 < tr_y_b) and 
                (refr_tick = '1');

    hit_log3 <= (tr_X_L < ball_x_r3) and 
                (ball_x_r3 < tr_X_L + BALL_V_P3) and 
                (x_delta_reg3 = BALL_V_N3) and 
                (tr_y_t < ball_y_b3) and 
                (ball_y_t3 < tr_y_b) and 
                (refr_tick = '1');

    hit_cnt_next <= hit_cnt_reg+1 when (hit_log1 or hit_log2 or hit_log3)
                    else hit_cnt_reg;
                            
    -- output logic
    hit_cnt <= std_logic_vector(hit_cnt_reg);
end sq_ball_arch;

   
