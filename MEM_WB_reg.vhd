-- Pipeline Register: MEM/WB
-- Stores control signals and data between Memory and Writeback stages
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity MEM_WB_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_reg_write   : in  std_logic;
    i_wb_sel      : in  std_logic_vector(1 downto 0);
    i_halt        : in  std_logic;
    i_alu_result  : in  std_logic_vector(31 downto 0);
    i_mem_data    : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_overflow    : in std_logic;
    i_check_overflow : in std_logic;
    o_reg_write   : out std_logic;
    o_overflow    : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_halt        : out std_logic;
    o_alu_result  : out std_logic_vector(31 downto 0);
    o_check_overflow : out std_logic;
    o_mem_data    : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0)
  );
end MEM_WB_reg;

architecture structural of MEM_WB_reg is
  
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
  
  component dffg is
    port(
      i_CLK : in  std_logic;
      i_RST : in  std_logic;
      i_WE  : in  std_logic;
      i_D   : in  std_logic;
      o_Q   : out std_logic
    );
  end component;
  
begin

  -- Control signals
  REG_WRITE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_reg_write, o_Q => o_reg_write);
             
  HALT_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_halt, o_Q => o_halt);

  OVERFLOW_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_overflow, o_Q => o_overflow);

   CHECK_OVERFLOW_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_check_overflow, o_Q => o_check_overflow);          


  WB_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_wb_sel, o_Q => o_wb_sel);
             
  RD_ADDR_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rd_addr, o_Q => o_rd_addr);

  -- Data signals
  ALU_RESULT_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_alu_result, o_Q => o_alu_result);
             
  MEM_DATA_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_mem_data, o_Q => o_mem_data);
             
  PC_PLUS4_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_pc_plus4, o_Q => o_pc_plus4);

end structural;