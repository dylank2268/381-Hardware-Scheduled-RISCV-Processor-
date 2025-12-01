-- Pipeline Register: ID/EX
-- Stores control signals and data between Decode and Execute stages
library IEEE;
use IEEE.std_logic_1164.all;

entity ID_EX_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_alu_src     : in  std_logic;
    i_alu_ctrl    : in  std_logic_vector(3 downto 0);
    i_mem_write   : in  std_logic;
    i_mem_read    : in  std_logic;
    i_reg_write   : in  std_logic;
    i_wb_sel      : in  std_logic_vector(1 downto 0);
    i_ld_byte     : in  std_logic;
    i_ld_half     : in  std_logic;
    i_ld_unsigned : in  std_logic;
    i_a_sel       : in  std_logic_vector(1 downto 0);
    i_halt        : in  std_logic;
    i_branch      : in  std_logic;                  
    i_pc_src      : in  std_logic_vector(1 downto 0);
    i_pc          : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rs1_val     : in  std_logic_vector(31 downto 0);
    i_rs2_val     : in  std_logic_vector(31 downto 0);
    i_imm         : in  std_logic_vector(31 downto 0);
    i_immB        : in  std_logic_vector(31 downto 0); 
    i_immJ        : in  std_logic_vector(31 downto 0);
    i_shift_amt   : in  std_logic_vector(4 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_funct3      : in  std_logic_vector(2 downto 0);
    o_alu_src     : out std_logic;
    o_alu_ctrl    : out std_logic_vector(3 downto 0);
    o_mem_write   : out std_logic;
    o_mem_read    : out std_logic;
    o_reg_write   : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_ld_byte     : out std_logic;
    o_ld_half     : out std_logic;
    o_ld_unsigned : out std_logic;
    o_a_sel       : out std_logic_vector(1 downto 0);
    o_halt        : out std_logic;
    o_branch      : out std_logic;                      
    o_pc_src      : out std_logic_vector(1 downto 0);  
    o_pc          : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rs1_val     : out std_logic_vector(31 downto 0);
    o_rs2_val     : out std_logic_vector(31 downto 0);
    o_imm         : out std_logic_vector(31 downto 0);
    o_immB        : out std_logic_vector(31 downto 0);  
    o_immJ        : out std_logic_vector(31 downto 0);  
    o_shift_amt   : out std_logic_vector(4 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0);
    o_funct3      : out std_logic_vector(2 downto 0)
  );
end ID_EX_reg;

architecture structural of ID_EX_reg is
  
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
  ALU_SRC_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_alu_src, o_Q => o_alu_src);
             
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
  
  --Branch control signal
  BRANCH_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_branch, o_Q => o_branch);

  ALU_CTRL_REG: dffg_N
    generic map(N => 4)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_alu_ctrl, o_Q => o_alu_ctrl);
             
  WB_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_wb_sel, o_Q => o_wb_sel);
             
  A_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_a_sel, o_Q => o_a_sel);
             
  FUNCT3_REG: dffg_N
    generic map(N => 3)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_funct3, o_Q => o_funct3);
             
  SHIFT_AMT_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_shift_amt, o_Q => o_shift_amt);
             
  RD_ADDR_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rd_addr, o_Q => o_rd_addr);

  --PC source control signal
  PC_SRC_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_pc_src, o_Q => o_pc_src);

  --Data signals
  PC_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_pc, o_Q => o_pc);
             
  PC_PLUS4_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_pc_plus4, o_Q => o_pc_plus4);
             
  RS1_VAL_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rs1_val, o_Q => o_rs1_val);
             
  RS2_VAL_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rs2_val, o_Q => o_rs2_val);
             
  IMM_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_imm, o_Q => o_imm);

  --Branch immediates
  IMMB_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_immB, o_Q => o_immB);
             
  IMMJ_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_immJ, o_Q => o_immJ);

end structural;
