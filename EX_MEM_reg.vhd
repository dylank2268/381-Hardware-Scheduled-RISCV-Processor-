-- Pipeline Register: EX/MEM
-- Stores control signals and ALU results between Execute and Memory stages
library IEEE;
use IEEE.std_logic_1164.all;

entity EX_MEM_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_mem_write   : in  std_logic;
    i_mem_read    : in  std_logic;
    i_reg_write   : in  std_logic;
    i_wb_sel      : in  std_logic_vector(1 downto 0);
    i_ld_byte     : in  std_logic;
    i_ld_half     : in  std_logic;
    i_ld_unsigned : in  std_logic;
    i_halt        : in  std_logic;
    i_alu_result  : in  std_logic_vector(31 downto 0);
    i_rs2_val     : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_overflow    : in  std_logic;
    o_mem_write   : out std_logic;
    o_mem_read    : out std_logic;
    o_reg_write   : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_ld_byte     : out std_logic;
    o_ld_half     : out std_logic;
    o_ld_unsigned : out std_logic;
    o_halt        : out std_logic;
    o_alu_result  : out std_logic_vector(31 downto 0);
    o_rs2_val     : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0);
    o_overflow    : out std_logic
  );
end EX_MEM_reg;

architecture structural of EX_MEM_reg is
  
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
  MEM_WRITE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_mem_write, o_Q => o_mem_write);
             
  MEM_READ_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_mem_read, o_Q => o_mem_read);
             
  REG_WRITE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_reg_write, o_Q => o_reg_write);
             
  LD_BYTE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_ld_byte, o_Q => o_ld_byte);
             
  LD_HALF_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_ld_half, o_Q => o_ld_half);
             
  LD_UNSIGNED_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_ld_unsigned, o_Q => o_ld_unsigned);
             
  HALT_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_halt, o_Q => o_halt);
             
  OVERFLOW_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_overflow, o_Q => o_overflow);

  WB_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_wb_sel, o_Q => o_wb_sel);
             
  RD_ADDR_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rd_addr, o_Q => o_rd_addr);

  --Data signals
  ALU_RESULT_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_alu_result, o_Q => o_alu_result);
             
  RS2_VAL_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rs2_val, o_Q => o_rs2_val);
             
  PC_PLUS4_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_pc_plus4, o_Q => o_pc_plus4);

end structural;
