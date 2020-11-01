----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:37:30 10/25/2020 
-- Design Name: 
-- Module Name:    vgaPainter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity vgaPainter is
    Port (
        rst  : in  std_logic;
        clk  : in  std_logic;
        von  : in std_logic;                     -- Tells whether or not its ok to display data
        hc   : in  std_logic_vector(9 downto 0); -- horizontal counter
        vc   : in  std_logic_vector(9 downto 0); -- vertical counter
        vgaR : out std_logic_vector(3 downto 1);
        vgaG : out std_logic_vector(3 downto 1);
        vgaB : out std_logic_vector(3 downto 2);
        btn  : in  std_logic_vector(3 downto 0);
        sw   : in  std_logic_vector(1 downto 0)
    );
end vgaPainter;

architecture rtl of vgaPainter is
    type box_color_type is record 
        R : std_logic_vector(3 downto 1); 
        G : std_logic_vector(3 downto 1);
        B : std_logic_vector(3 downto 2);
    end record;
        
    type plane_point_type is record
        x : std_logic_vector(9 downto 0);
        y : std_logic_vector(9 downto 0);
    end record;

    type box_type is record
        p1    : plane_point_type;
        p2    : plane_point_type;
        color : box_color_type;
    end record;

    type image_5x5_type is array (24 downto 0) of std_logic_vector(7 downto 0); -- RRRGGGBB

    type image_5x5_box_type is record
        img  : image_5x5_type;
        loc  : plane_point_type; -- upper left corner of image
        scale: std_logic_vector(7 downto 0);
    end record;

    procedure moveUp(signal box : inout box_type) is
    begin
        box.p1.y <= box.p1.y - 1;
        box.p2.y <= box.p2.y - 1;
    end procedure;

    procedure moveDown(signal box : inout box_type) is
    begin
        box.p1.y <= box.p1.y + 1;
        box.p2.y <= box.p2.y + 1;
    end procedure;

    procedure moveRight(signal box : inout box_type) is
    begin
        box.p1.x <= box.p1.x - 1;
        box.p2.x <= box.p2.x - 1;
    end procedure;

    procedure moveLeft(signal box : inout box_type) is
    begin
        box.p1.x <= box.p1.x + 1;
        box.p2.x <= box.p2.x + 1;
    end procedure;

    procedure moveNot(signal box : inout box_type) is
    begin
        box.p1.x <= box.p1.x;
        box.p2.x <= box.p2.x;
        box.p1.y <= box.p1.y;
        box.p2.y <= box.p2.y;
    end procedure;

    signal mc     : std_logic_vector(17 downto 0); -- The movement counter
    signal btnP   : std_logic_vector(3 downto 0);  -- up, down, left, right movement pulses
    signal btnS   : std_logic_vector(3 downto 0);  -- up, down, left, right set register (latch)

    signal img5x5imageBasePointer: std_logic_vector(4 downto 0); -- image base pointer
    signal img5x5imagePointer    : std_logic_vector(4 downto 0); -- image pointer for line
    signal img5x5hCounter        : std_logic_vector(4 downto 0); -- image counter for line
    signal img5x5hScaleCounter   : std_logic_vector(7 downto 0); -- image horizontal scale counter
    signal img5x5vScaleCounter   : std_logic_vector(7 downto 0); -- image vertical scale counter
    signal img5x5Box             : image_5x5_box_type; 
    
    
begin

    --Handles the buttons
    process(clk, rst)
    begin
        if rst = '1' then
            mc <= (others => '0');
            btnS <= (others => '0');
            btnP <= (others => '0');
        elsif clk = '1' and clk'EVENT then
            btnP <= btn and not btnS;
            btnS <= btn;
            if mc(17)='1' then -- Reset when the limit is reached
                mc <= (others => '0');
                btnS <= (others => '0');
            else
                mc <= mc + 1; -- Increment the counter
            end if;
        end if;
    end process;

--    --Handles the movement
--    process(clk, rst)
--    begin
--        if rst = '1' then
--            
--        elsif clk = '1' and clk'EVENT then
--            if sw(1)='0' then
--                if sw(0)='0' then
--                    case btnP(3 downto 0) is
--                        when "1000" => moveLeft(box1);
--                        when "0100" => moveRight(box1);
--                        when "0010" => moveUp(box1);
--                        when "0001" => moveDown(box1);
--                        when "1010" => moveLeft(box1);  moveUp(box1);
--                        when "1001" => moveLeft(box1);  moveDown(box1);
--                        when "0110" => moveRight(box1); moveUp(box1);
--                        when "0101" => moveRight(box1); moveDown(box1);
--                        when others => moveNot(box1);
--                    end case;
--                else
--                    case btnP(3 downto 0) is
--                        when "1000" => moveLeft(box2);
--                        when "0100" => moveRight(box2);
--                        when "0010" => moveUp(box2);
--                        when "0001" => moveDown(box2);
--                        when "1010" => moveLeft(box2);  moveUp(box2);
--                        when "1001" => moveLeft(box2);  moveDown(box2);
--                        when "0110" => moveRight(box2); moveUp(box2);
--                        when "0101" => moveRight(box2); moveDown(box2);
--                        when others => moveNot(box2);
--                    end case;
--                end if;
--            else
--                case btnP(3 downto 0) is
--                    when "1000" => moveLeft(box1);                   moveLeft(box2);
--                    when "0100" => moveRight(box1);                  moveRight(box2);
--                    when "0010" => moveUp(box1);                     moveUp(box2);
--                    when "0001" => moveDown(box1);                   moveDown(box2);
--                    when "1010" => moveLeft(box1);  moveUp(box1);    moveLeft(box2);  moveUp(box2);
--                    when "1001" => moveLeft(box1);  moveDown(box1);  moveLeft(box2);  moveDown(box2);
--                    when "0110" => moveRight(box1); moveUp(box1);    moveRight(box2); moveUp(box2);
--                    when "0101" => moveRight(box1); moveDown(box1);  moveRight(box2); moveDown(box2);
--                    when others => moveNot(box1);                    moveNot(box2);
--                end case;
--            end if;
--        end if;
--    end process;


    -- the painter
    process(clk, rst)
        variable index : integer range 0 to 1000;
    begin
        if rst = '1' then
            vgaR                  <= (others => '0');
            vgaG                  <= (others => '0');
            vgaB                  <= (others => '0');
            img5x5imageBasePointer<= (others => '0');
            img5x5imagePointer    <= (others => '0');
            img5x5hCounter        <= (others => '0');
            img5x5hScaleCounter   <= (others => '0');
            img5x5vScaleCounter   <= (others => '0');
            img5x5Box <= (
                loc => (
                    x => "0011000000",
                    y => "0001000000"
                ),
                scale => "00010010",
                img => (
                    "11111100", "11100000", "11100000", "11100000", "11111111", 
                    "00011100", "00000000", "00000000", "00000000", "11111111", 
                    "00011100", "11100000", "00011100", "00000011", "11111111", 
                    "00011100", "00000000", "00000000", "00000000", "11111111", 
                    "00011111", "00000011", "00000011", "00000011", "00000011"
                )
            );
        elsif clk = '1' and clk'EVENT then
            vgaR      <= (others => '0');
            vgaG      <= (others => '0');
            vgaB      <= (others => '0');
            if hc = "0000000000" then -- start of new line
                img5x5imagePointer <= img5x5imageBasePointer;
                img5x5hScaleCounter <= (others => '0');
                img5x5hCounter <= (others => '0');
                -- add 1 to vertical scale counter
                img5x5vScaleCounter <= img5x5vScaleCounter + 1;
            end if;
            if vc = "0000000000" then -- start of new screen
                img5x5imageBasePointer <= (others => '0');
                img5x5vScaleCounter <= (others => '0');
            end if;
            
            if von='1' then
                if img5x5Box.loc.x < hc and img5x5Box.loc.y < vc then--and img5x5hCounter < "110"  and img5x5imageBasePointer < "11001" then
                    
                    -- horizonal scale counter
                    if img5x5hScaleCounter = img5x5Box.scale then
                        -- reset the horizontal scale counter
                        img5x5hScaleCounter <= (others => '0');
                        -- go to next pixel in the line
                        img5x5imagePointer <= img5x5imagePointer + 1;
                        -- add one to line pixel counter
                        img5x5hCounter <= img5x5hCounter + 1;
                    else
                        -- keep adding to horizontal scale counter until box scale is reached
                        img5x5hScaleCounter <= img5x5hScaleCounter + 1;
                    end if;


                    -- vertical scale counter
                    if img5x5vScaleCounter = img5x5Box.scale then
                        -- reset the vertical scale counter
                        img5x5hScaleCounter <= (others => '0');
                        -- goto next line (add 5 to the image base pointer)
                        img5x5imageBasePointer <= img5x5imageBasePointer + 5;
                    end if;

                    index := CONV_INTEGER(img5x5imagePointer);
                    
                    vgaR <= (others => '1');--img5x5Box.img(index)(6 downto 4);
                    vgaG <= img5x5Box.img(index)(3 downto 1);
                    vgaB <= img5x5Box.img(index)(1 downto 0);
                    
                end if;                
            end if;
        end if;
    end process;


end rtl;

