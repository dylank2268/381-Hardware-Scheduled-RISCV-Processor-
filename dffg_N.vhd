--Dylan Kramer
--Generic DFFG 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dffg_N is
  generic(
    N : integer := 1   -- width of the register
  );
  port(
    i_CLK : in  std_logic;
    i_RST : in  std_logic;
    i_WE  : in  std_logic;                            -- write enable
    i_D   : in  std_logic_vector(N-1 downto 0);       -- data in
    o_Q   : out std_logic_vector(N-1 downto 0)        -- data out
  );
end entity dffg_N;

architecture rtl of dffg_N is
  signal s_Q : std_logic_vector(N-1 downto 0);
begin

  process(i_CLK, i_RST)
  begin
    if i_RST = '1' then
      s_Q <= (others => '0');
    elsif rising_edge(i_CLK) then
      if i_WE = '1' then
        s_Q <= i_D;
      end if;
    end if;
  end process;

  o_Q <= s_Q;

end architecture rtl;
