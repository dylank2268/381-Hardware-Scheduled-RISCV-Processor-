-- Pipeline Register: IF/ID
-- Stores instruction and PC information between Fetch and Decode stages
library IEEE;
use IEEE.std_logic_1164.all;

entity IF_ID_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    -- Inputs
    i_pc          : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_instruction : in  std_logic_vector(31 downto 0);
    -- Outputs
    o_pc          : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_instruction : out std_logic_vector(31 downto 0)
  );
end IF_ID_reg;

architecture structural of IF_ID_reg is
  
  component dffg_N is
    generic(N : integer := 32);
    port(
      i_CLK : in  std_logic;
      i_RST : in  std_logic;
      i_WE  : in  std_logic;
      i_D   : in  std_logic_vector(N-1 downto 0);
      o_Q   : out std_logic_vector(N-1 downto 0)
    );
  end component;
  
begin

  PC_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => '1',
      i_D   => i_pc,
      o_Q   => o_pc
    );
    
  PC_PLUS4_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => '1',
      i_D   => i_pc_plus4,
      o_Q   => o_pc_plus4
    );
    
  INST_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => '1',
      i_D   => i_instruction,
      o_Q   => o_instruction
    );

end structural;