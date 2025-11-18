-- Pipeline Register: ID/EX
-- Stores control signals and data between Decode and Execute stages
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity ID_EX_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_flush       : in  std_logic; 
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
    i_check_overflow : in std_logic;
    i_pc          : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rs1_val     : in  std_logic_vector(31 downto 0);
    i_rs2_val     : in  std_logic_vector(31 downto 0);
    i_imm         : in  std_logic_vector(31 downto 0);
    i_immB        : in  std_logic_vector(31 downto 0);
    i_immJ        : in  std_logic_vector(31 downto 0);
    i_shift_amt   : in  std_logic_vector(4 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_rs1_addr    : in  std_logic_vector(4 downto 0); 
    i_rs2_addr    : in  std_logic_vector(4 downto 0); 
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
    o_check_overflow : out std_logic;
    o_pc          : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rs1_val     : out std_logic_vector(31 downto 0);
    o_rs2_val     : out std_logic_vector(31 downto 0);
    o_imm         : out std_logic_vector(31 downto 0);
    o_immB        : out std_logic_vector(31 downto 0);
    o_immJ        : out std_logic_vector(31 downto 0);
    o_shift_amt   : out std_logic_vector(4 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0);
    o_rs1_addr    : out std_logic_vector(4 downto 0);
    o_rs2_addr    : out std_logic_vector(4 downto 0);
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
  
  component mux2t1_N is
    generic(N : integer := 32);
    port(
      i_S  : in  std_logic;
      i_D0 : in  std_logic_vector(N-1 downto 0);
      i_D1 : in  std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
  end component;
  
  component mux2t1 is
    port(
      i_S  : in  std_logic;
      i_D0 : in  std_logic;
      i_D1 : in  std_logic;
      o_O  : out std_logic
    );
  end component;
  
  -- Muxed control signals (after flush logic)
  signal s_alu_src_mux     : std_logic;
  signal s_mem_write_mux   : std_logic;
  signal s_mem_read_mux    : std_logic;
  signal s_reg_write_mux   : std_logic;
  signal s_ld_byte_mux     : std_logic;
  signal s_ld_half_mux     : std_logic;
  signal s_ld_unsigned_mux : std_logic;
  signal s_halt_mux        : std_logic;
  signal s_branch_mux      : std_logic;
  signal s_check_overflow_mux : std_logic;
  signal s_alu_ctrl_mux    : std_logic_vector(3 downto 0);
  signal s_wb_sel_mux      : std_logic_vector(1 downto 0);
  signal s_a_sel_mux       : std_logic_vector(1 downto 0);
  signal s_pc_src_mux      : std_logic_vector(1 downto 0);
  
  --Constants for flush logic
  constant ZERO_2BIT : std_logic_vector(1 downto 0) := "00";
  constant ZERO_4BIT : std_logic_vector(3 downto 0) := "0000";
  
begin
  --MEM/WRITE mux
  MUX_MEM_WRITE: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_mem_write,  -- Normal
      i_D1 => '0',          -- Flush: no memory write
      o_O  => s_mem_write_mux
    );
  --MEM/READ mux
  MUX_MEM_READ: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_mem_read,   -- Normal
      i_D1 => '0',          -- Flush: no memory read
      o_O  => s_mem_read_mux
    );
  --REG/WRITE mux
  MUX_REG_WRITE: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_reg_write,  -- Normal
      i_D1 => '0',          -- Flush: no register write
      o_O  => s_reg_write_mux
    );
  --HALT mux
  MUX_HALT: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_halt,       -- Normal
      i_D1 => '0',          -- Flush: no halt
      o_O  => s_halt_mux
    );
  --BRANCH mux
  MUX_BRANCH: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_branch,     -- Normal
      i_D1 => '0',          -- Flush: no branch
      o_O  => s_branch_mux
    );
  --Flush MUX, we don't always need to check for overflow unless its an add or sub
  MUX_CHECK_OVERFLOW: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_check_overflow,  -- Normal
      i_D1 => '0',               -- Flush: no overflow checking
      o_O  => s_check_overflow_mux
    );
  
  --ALU source mux
  MUX_ALU_SRC: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_alu_src,
      i_D1 => '0',
      o_O  => s_alu_src_mux
    );
  --load byte mux
  MUX_LD_BYTE: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_ld_byte,
      i_D1 => '0',
      o_O  => s_ld_byte_mux
    );
  --load half mux
  MUX_LD_HALF: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_ld_half,
      i_D1 => '0',
      o_O  => s_ld_half_mux
    );
  --load unsigned mux
  MUX_LD_UNSIGNED: mux2t1
    port map(
      i_S  => i_flush,
      i_D0 => i_ld_unsigned,
      i_D1 => '0',
      o_O  => s_ld_unsigned_mux
    );
  --alu cutrl mux
  MUX_ALU_CTRL: mux2t1_N
    generic map(N => 4)
    port map(
      i_S  => i_flush,
      i_D0 => i_alu_ctrl,
      i_D1 => ZERO_4BIT,
      o_O  => s_alu_ctrl_mux
    );
  --WB sel mux
  MUX_WB_SEL: mux2t1_N
    generic map(N => 2)
    port map(
      i_S  => i_flush,
      i_D0 => i_wb_sel,
      i_D1 => ZERO_2BIT,
      o_O  => s_wb_sel_mux
    );
  --ALU A sel mux
  MUX_A_SEL: mux2t1_N
    generic map(N => 2)
    port map(
      i_S  => i_flush,
      i_D0 => i_a_sel,
      i_D1 => ZERO_2BIT,
      o_O  => s_a_sel_mux
    );
  --PC src mux
  MUX_PC_SRC: mux2t1_N
    generic map(N => 2)
    port map(
      i_S  => i_flush,
      i_D0 => i_pc_src,
      i_D1 => ZERO_2BIT,
      o_O  => s_pc_src_mux
    );
  
  --Registers to propagate data through pipeline
  ALU_SRC_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_alu_src_mux, o_Q => o_alu_src);
             
  MEM_WRITE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_mem_write_mux, o_Q => o_mem_write);
             
  MEM_READ_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_mem_read_mux, o_Q => o_mem_read);
             
  REG_WRITE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_reg_write_mux, o_Q => o_reg_write);
             
  LD_BYTE_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_ld_byte_mux, o_Q => o_ld_byte);
             
  LD_HALF_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_ld_half_mux, o_Q => o_ld_half);
             
  LD_UNSIGNED_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_ld_unsigned_mux, o_Q => o_ld_unsigned);
             
  HALT_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_halt_mux, o_Q => o_halt);
  
  BRANCH_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_branch_mux, o_Q => o_branch);

  CHECK_OVERFLOW_REG: dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_check_overflow_mux, o_Q => o_check_overflow);

  ALU_CTRL_REG: dffg_N
    generic map(N => 4)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_alu_ctrl_mux, o_Q => o_alu_ctrl);
             
  WB_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_wb_sel_mux, o_Q => o_wb_sel);
             
  A_SEL_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_a_sel_mux, o_Q => o_a_sel);

  PC_SRC_REG: dffg_N
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => s_pc_src_mux, o_Q => o_pc_src);
  
  
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

  -- RS1 and RS2 address registers for forwarding unit
  RS1_ADDR_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rs1_addr, o_Q => o_rs1_addr);
             
  RS2_ADDR_REG: dffg_N
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_rs2_addr, o_Q => o_rs2_addr);

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

  IMMB_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_immB, o_Q => o_immB);
             
  IMMJ_REG: dffg_N
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => '1',
             i_D => i_immJ, o_Q => o_immJ);

end structural;