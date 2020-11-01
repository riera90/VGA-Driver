library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity main is
    Port (
        rst	  : in  std_logic;
        clk	  : in  std_logic;
        Hsync : out std_logic;
        Vsync : out std_logic;
        vgaR  : out std_logic_vector(3 downto 1);
        vgaG  : out std_logic_vector(3 downto 1);
        vgaB  : out std_logic_vector(3 downto 2);
        btn   : in  std_logic_vector(3 downto 0)
    );
end main;

architecture rtl of main is
    signal von : std_logic;
    signal hc  : std_logic_vector(9 downto 0);
    signal vc  : std_logic_vector(9 downto 0);

begin

    vgaDriver : entity work.vgaDriver(rtl) port map(
        rst   => rst,
        clk   => clk,
        Hsync => Hsync,
        Vsync => Vsync,
        von   => von,
        hc    => hc,
        vc    => vc
    );

    vgaPainter : entity work.vgaPainter(rtl) port map(
        rst   => rst,
        clk   => clk,
        von   => von,
        hc    => hc,
        vc    => vc,
        vgaR  => vgaR,
        vgaG  => vgaG,
        vgaB  => vgaB,
        btn   => btn
    );

end rtl;

