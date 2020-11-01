-- This module createsthe driving signals of the VGA protocol with 
-- a vertical refresh rate of 60Hz.  This is done by dividing the
-- system clock in half and using that for the pixel clock.  This in
-- turn drives the vertical sync when the horizontal sync has reached
-- its reset point.
-- the RGB values are feed by the VGA Painter


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;




entity vgaDriver is
    Port (
        rst   : in  std_logic;
        clk   : in  std_logic;
        Hsync : out std_logic;
        Vsync : out std_logic;
        von   : out std_logic;                    -- Tells whether or not its ok to display data
        hc    : out std_logic_vector(9 downto 0); -- horizontal counter
        vc    : out std_logic_vector(9 downto 0)  -- vertical counter
    );

end vgaDriver;

architecture rtl of vgaDriver is

    constant hpixels	: std_logic_vector(9 downto 0) := "1100100000";	-- Value of pixels in a horizontal line
    constant vlines		: std_logic_vector(9 downto 0) := "1000001001";	-- Number of horizontal lines in the display
    constant hbp		: std_logic_vector(9 downto 0) := "0010010000";	-- Horizontal back porch
    constant hfp		: std_logic_vector(9 downto 0) := "1100010000";	-- Horizontal front porch
    constant vbp		: std_logic_vector(9 downto 0) := "0000011111";	-- Vertical back porch
    constant vfp		: std_logic_vector(9 downto 0) := "0111111111";	-- Vertical front porch
    
    signal clkdiv		: std_logic;                                    -- Clock divider
    signal vcEnable		: std_logic;                                    -- Enable for the Vertical counter
    signal hcsig        : std_logic_vector(9 downto 0);                 -- horizontal counter
    signal vcsig        : std_logic_vector(9 downto 0);                 -- vertical counter
begin
    
    Hsync <= '1' when hcsig(9 downto 7) = "000" else '0';		 		-- Horizontal Sync Pulse
    Vsync <= '1' when vcsig(9 downto 1) = "000000000" else '0';			-- Vertical Sync Pulse
    von <= '1' when (((hcsig < hfp) and (hcsig > hbp)) or ((vcsig < vfp) and (vcsig > vbp))) else '0'; --video on
    hc <= hcsig;
    vc <= vcsig;

    -- Half clock divider 50MHz (inboard clk) -> 25MHz (vga clk)
    process(clk)
    begin
        if clk = '1' and clk'EVENT then
            clkdiv <= not clkdiv;
        end if;
    end process;

    -- Runs the horizontal counter
    process(clkdiv, rst)
    begin
        if rst = '1' then
            hcsig <= (others => '0');
        elsif clkdiv = '1' and clkdiv'EVENT then
            if hcsig = hpixels then -- The counter has reached the end
                -- reset the counter and enable the vertical counter
                hcsig <= (others => '0');
                vcEnable <= '1';
            else
                -- Increment the horizontal counter and dissable the vertical counter
                hcsig <= hcsig + 1;
                vcEnable <= '0';
            end if;
        end if;
    end process;


    -- Runs the verrtical counter
    process(clkdiv, rst)
    begin
        if rst = '1' then 
            vcsig <= "0000000000";
        elsif clkdiv = '1' and clkdiv'EVENT then
            if vcEnable = '1' then -- vc is enabled
                if vcsig = vlines then	
                    -- Reset when the number of lines is reached
                    vcsig <= "0000000000";
                else 
                    -- Increment the vertical counter
                    vcsig <= vcsig + 1;
                end if;
            end if;
        end if;
    end process;

end rtl;
