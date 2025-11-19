-- Dylan Kramer and Michael Berg
-- Testbench for Pipeline Registers
-- Tests: Data propagation through all stages, continuous insertion, individual stall/flush
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_pipeline_regs is
end tb_pipeline_regs;

architecture behavior of tb_pipeline_regs is
  
  -- Component declarations
  component IF_ID_reg is
    port(
      i_CLK         : in  std_logic;
      i_RST         : in  std_logic;
      i_pc          : in  std_logic_vector(31 downto 0);
      i_pc_plus4    : in  std_logic_vector(31 downto 0);
      i_instruction : in  std_logic_vector(31 downto 0);
      o_pc          : out std_logic_vector(31 downto 0);
      o_pc_plus4    : out std_logic_vector(31 downto 0);
      o_instruction : out std_logic_vector(31 downto 0)
    );
  end component;
  
  component ID_EX_reg is
    port(
      i_CLK         : in  std_logic;
      i_RST         : in  std_logic;
      i_alu_op      : in  std_logic_vector(3 downto 0);
      i_alu_src     : in  std_logic;
      i_mem_write   : in  std_logic;
      i_mem_read    : in  std_logic;
      i_reg_write   : in  std_logic;
      i_wb_sel      : in  std_logic_vector(1 downto 0);
      i_branch      : in  std_logic;
      i_jump        : in  std_logic;
      i_ld_byte     : in  std_logic;
      i_ld_half     : in  std_logic;
      i_ld_unsigned : in  std_logic;
      i_halt        : in  std_logic;
      i_rs1_val     : in  std_logic_vector(31 downto 0);
      i_rs2_val     : in  std_logic_vector(31 downto 0);
      i_imm         : in  std_logic_vector(31 downto 0);
      i_pc          : in  std_logic_vector(31 downto 0);
      i_pc_plus4    : in  std_logic_vector(31 downto 0);
      i_rs1_addr    : in  std_logic_vector(4 downto 0);
      i_rs2_addr    : in  std_logic_vector(4 downto 0);
      i_rd_addr     : in  std_logic_vector(4 downto 0);
      o_alu_op      : out std_logic_vector(3 downto 0);
      o_alu_src     : out std_logic;
      o_mem_write   : out std_logic;
      o_mem_read    : out std_logic;
      o_reg_write   : out std_logic;
      o_wb_sel      : out std_logic_vector(1 downto 0);
      o_branch      : out std_logic;
      o_jump        : out std_logic;
      o_ld_byte     : out std_logic;
      o_ld_half     : out std_logic;
      o_ld_unsigned : out std_logic;
      o_halt        : out std_logic;
      o_rs1_val     : out std_logic_vector(31 downto 0);
      o_rs2_val     : out std_logic_vector(31 downto 0);
      o_imm         : out std_logic_vector(31 downto 0);
      o_pc          : out std_logic_vector(31 downto 0);
      o_pc_plus4    : out std_logic_vector(31 downto 0);
      o_rs1_addr    : out std_logic_vector(4 downto 0);
      o_rs2_addr    : out std_logic_vector(4 downto 0);
      o_rd_addr     : out std_logic_vector(4 downto 0)
    );
  end component;
  
  component EX_MEM_reg is
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
  end component;
  
  component MEM_WB_reg is
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
      o_reg_write   : out std_logic;
      o_wb_sel      : out std_logic_vector(1 downto 0);
      o_halt        : out std_logic;
      o_alu_result  : out std_logic_vector(31 downto 0);
      o_mem_data    : out std_logic_vector(31 downto 0);
      o_pc_plus4    : out std_logic_vector(31 downto 0);
      o_rd_addr     : out std_logic_vector(4 downto 0)
    );
  end component;
  
  -- Clock and reset signals
  signal s_CLK : std_logic := '0';
  signal s_RST_IFID : std_logic := '0';
  signal s_RST_IDEX : std_logic := '0';
  signal s_RST_EXMEM : std_logic := '0';
  signal s_RST_MEMWB : std_logic := '0';
  
  -- IF/ID signals
  signal s_ifid_i_pc          : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_i_instruction : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_o_pc          : std_logic_vector(31 downto 0);
  signal s_ifid_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_ifid_o_instruction : std_logic_vector(31 downto 0);
  
  -- ID/EX signals
  signal s_idex_i_alu_op      : std_logic_vector(3 downto 0) := (others => '0');
  signal s_idex_i_alu_src     : std_logic := '0';
  signal s_idex_i_mem_write   : std_logic := '0';
  signal s_idex_i_mem_read    : std_logic := '0';
  signal s_idex_i_reg_write   : std_logic := '0';
  signal s_idex_i_wb_sel      : std_logic_vector(1 downto 0) := (others => '0');
  signal s_idex_i_branch      : std_logic := '0';
  signal s_idex_i_jump        : std_logic := '0';
  signal s_idex_i_ld_byte     : std_logic := '0';
  signal s_idex_i_ld_half     : std_logic := '0';
  signal s_idex_i_ld_unsigned : std_logic := '0';
  signal s_idex_i_halt        : std_logic := '0';
  signal s_idex_i_rs1_val     : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_rs2_val     : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_imm         : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_pc          : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_rs1_addr    : std_logic_vector(4 downto 0) := (others => '0');
  signal s_idex_i_rs2_addr    : std_logic_vector(4 downto 0) := (others => '0');
  signal s_idex_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_idex_o_alu_op      : std_logic_vector(3 downto 0);
  signal s_idex_o_alu_src     : std_logic;
  signal s_idex_o_mem_write   : std_logic;
  signal s_idex_o_mem_read    : std_logic;
  signal s_idex_o_reg_write   : std_logic;
  signal s_idex_o_wb_sel      : std_logic_vector(1 downto 0);
  signal s_idex_o_branch      : std_logic;
  signal s_idex_o_jump        : std_logic;
  signal s_idex_o_ld_byte     : std_logic;
  signal s_idex_o_ld_half     : std_logic;
  signal s_idex_o_ld_unsigned : std_logic;
  signal s_idex_o_halt        : std_logic;
  signal s_idex_o_rs1_val     : std_logic_vector(31 downto 0);
  signal s_idex_o_rs2_val     : std_logic_vector(31 downto 0);
  signal s_idex_o_imm         : std_logic_vector(31 downto 0);
  signal s_idex_o_pc          : std_logic_vector(31 downto 0);
  signal s_idex_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_idex_o_rs1_addr    : std_logic_vector(4 downto 0);
  signal s_idex_o_rs2_addr    : std_logic_vector(4 downto 0);
  signal s_idex_o_rd_addr     : std_logic_vector(4 downto 0);
  
  -- EX/MEM signals
  signal s_exmem_i_mem_write   : std_logic := '0';
  signal s_exmem_i_mem_read    : std_logic := '0';
  signal s_exmem_i_reg_write   : std_logic := '0';
  signal s_exmem_i_wb_sel      : std_logic_vector(1 downto 0) := (others => '0');
  signal s_exmem_i_ld_byte     : std_logic := '0';
  signal s_exmem_i_ld_half     : std_logic := '0';
  signal s_exmem_i_ld_unsigned : std_logic := '0';
  signal s_exmem_i_halt        : std_logic := '0';
  signal s_exmem_i_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_exmem_i_rs2_val     : std_logic_vector(31 downto 0) := (others => '0');
  signal s_exmem_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_exmem_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_exmem_i_overflow    : std_logic := '0';
  signal s_exmem_o_mem_write   : std_logic;
  signal s_exmem_o_mem_read    : std_logic;
  signal s_exmem_o_reg_write   : std_logic;
  signal s_exmem_o_wb_sel      : std_logic_vector(1 downto 0);
  signal s_exmem_o_ld_byte     : std_logic;
  signal s_exmem_o_ld_half     : std_logic;
  signal s_exmem_o_ld_unsigned : std_logic;
  signal s_exmem_o_halt        : std_logic;
  signal s_exmem_o_alu_result  : std_logic_vector(31 downto 0);
  signal s_exmem_o_rs2_val     : std_logic_vector(31 downto 0);
  signal s_exmem_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_exmem_o_rd_addr     : std_logic_vector(4 downto 0);
  signal s_exmem_o_overflow    : std_logic;
  
  -- MEM/WB signals
  signal s_memwb_i_reg_write   : std_logic := '0';
  signal s_memwb_i_wb_sel      : std_logic_vector(1 downto 0) := (others => '0');
  signal s_memwb_i_halt        : std_logic := '0';
  signal s_memwb_i_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_memwb_i_mem_data    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_memwb_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_memwb_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_memwb_o_reg_write   : std_logic;
  signal s_memwb_o_wb_sel      : std_logic_vector(1 downto 0);
  signal s_memwb_o_halt        : std_logic;
  signal s_memwb_o_alu_result  : std_logic_vector(31 downto 0);
  signal s_memwb_o_mem_data    : std_logic_vector(31 downto 0);
  signal s_memwb_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_memwb_o_rd_addr     : std_logic_vector(4 downto 0);
  
  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  
begin

  -- Instantiate IF/ID register
  IFID: IF_ID_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_IFID,
      i_pc          => s_ifid_i_pc,
      i_pc_plus4    => s_ifid_i_pc_plus4,
      i_instruction => s_ifid_i_instruction,
      o_pc          => s_ifid_o_pc,
      o_pc_plus4    => s_ifid_o_pc_plus4,
      o_instruction => s_ifid_o_instruction
    );
  
  -- Instantiate ID/EX register
  IDEX: ID_EX_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_IDEX,
      i_alu_op      => s_idex_i_alu_op,
      i_alu_src     => s_idex_i_alu_src,
      i_mem_write   => s_idex_i_mem_write,
      i_mem_read    => s_idex_i_mem_read,
      i_reg_write   => s_idex_i_reg_write,
      i_wb_sel      => s_idex_i_wb_sel,
      i_branch      => s_idex_i_branch,
      i_jump        => s_idex_i_jump,
      i_ld_byte     => s_idex_i_ld_byte,
      i_ld_half     => s_idex_i_ld_half,
      i_ld_unsigned => s_idex_i_ld_unsigned,
      i_halt        => s_idex_i_halt,
      i_rs1_val     => s_idex_i_rs1_val,
      i_rs2_val     => s_idex_i_rs2_val,
      i_imm         => s_idex_i_imm,
      i_pc          => s_idex_i_pc,
      i_pc_plus4    => s_idex_i_pc_plus4,
      i_rs1_addr    => s_idex_i_rs1_addr,
      i_rs2_addr    => s_idex_i_rs2_addr,
      i_rd_addr     => s_idex_i_rd_addr,
      o_alu_op      => s_idex_o_alu_op,
      o_alu_src     => s_idex_o_alu_src,
      o_mem_write   => s_idex_o_mem_write,
      o_mem_read    => s_idex_o_mem_read,
      o_reg_write   => s_idex_o_reg_write,
      o_wb_sel      => s_idex_o_wb_sel,
      o_branch      => s_idex_o_branch,
      o_jump        => s_idex_o_jump,
      o_ld_byte     => s_idex_o_ld_byte,
      o_ld_half     => s_idex_o_ld_half,
      o_ld_unsigned => s_idex_o_ld_unsigned,
      o_halt        => s_idex_o_halt,
      o_rs1_val     => s_idex_o_rs1_val,
      o_rs2_val     => s_idex_o_rs2_val,
      o_imm         => s_idex_o_imm,
      o_pc          => s_idex_o_pc,
      o_pc_plus4    => s_idex_o_pc_plus4,
      o_rs1_addr    => s_idex_o_rs1_addr,
      o_rs2_addr    => s_idex_o_rs2_addr,
      o_rd_addr     => s_idex_o_rd_addr
    );
  
  -- Instantiate EX/MEM register
  EXMEM: EX_MEM_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_EXMEM,
      i_mem_write   => s_exmem_i_mem_write,
      i_mem_read    => s_exmem_i_mem_read,
      i_reg_write   => s_exmem_i_reg_write,
      i_wb_sel      => s_exmem_i_wb_sel,
      i_ld_byte     => s_exmem_i_ld_byte,
      i_ld_half     => s_exmem_i_ld_half,
      i_ld_unsigned => s_exmem_i_ld_unsigned,
      i_halt        => s_exmem_i_halt,
      i_alu_result  => s_exmem_i_alu_result,
      i_rs2_val     => s_exmem_i_rs2_val,
      i_pc_plus4    => s_exmem_i_pc_plus4,
      i_rd_addr     => s_exmem_i_rd_addr,
      i_overflow    => s_exmem_i_overflow,
      o_mem_write   => s_exmem_o_mem_write,
      o_mem_read    => s_exmem_o_mem_read,
      o_reg_write   => s_exmem_o_reg_write,
      o_wb_sel      => s_exmem_o_wb_sel,
      o_ld_byte     => s_exmem_o_ld_byte,
      o_ld_half     => s_exmem_o_ld_half,
      o_ld_unsigned => s_exmem_o_ld_unsigned,
      o_halt        => s_exmem_o_halt,
      o_alu_result  => s_exmem_o_alu_result,
      o_rs2_val     => s_exmem_o_rs2_val,
      o_pc_plus4    => s_exmem_o_pc_plus4,
      o_rd_addr     => s_exmem_o_rd_addr,
      o_overflow    => s_exmem_o_overflow
    );
  
  -- Instantiate MEM/WB register
  MEMWB: MEM_WB_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_MEMWB,
      i_reg_write   => s_memwb_i_reg_write,
      i_wb_sel      => s_memwb_i_wb_sel,
      i_halt        => s_memwb_i_halt,
      i_alu_result  => s_memwb_i_alu_result,
      i_mem_data    => s_memwb_i_mem_data,
      i_pc_plus4    => s_memwb_i_pc_plus4,
      i_rd_addr     => s_memwb_i_rd_addr,
      o_reg_write   => s_memwb_o_reg_write,
      o_wb_sel      => s_memwb_o_wb_sel,
      o_halt        => s_memwb_o_halt,
      o_alu_result  => s_memwb_o_alu_result,
      o_mem_data    => s_memwb_o_mem_data,
      o_pc_plus4    => s_memwb_o_pc_plus4,
      o_rd_addr     => s_memwb_o_rd_addr
    );
  
  -- Clock generation
  CLK_PROCESS: process
  begin
    s_CLK <= '0';
    wait for CLK_PERIOD/2;
    s_CLK <= '1';
    wait for CLK_PERIOD/2;
  end process;
  
  -- Test stimulus
  TEST_PROCESS: process
  begin
    -- TEST 1: Initial reset and basic propagation through pipeline
    -- Reset all registers
    s_RST_IFID <= '1';
    s_RST_IDEX <= '1';
    s_RST_EXMEM <= '1';
    s_RST_MEMWB <= '1';
    wait for CLK_PERIOD;
    
    s_RST_IFID <= '0';
    s_RST_IDEX <= '0';
    s_RST_EXMEM <= '0';
    s_RST_MEMWB <= '0';
    wait for CLK_PERIOD;
    
    -- Insert marker value 0xDEADBEEF into IF/ID at cycle 0
    s_ifid_i_pc <= x"DEADBEEF";
    s_ifid_i_pc_plus4 <= x"DEADBEF3";
    s_ifid_i_instruction <= x"DEADB000";
    
    -- Also set up ID/EX inputs with marker
    s_idex_i_reg_write <= '1';
    s_idex_i_rd_addr <= "10101";
    s_idex_i_rs1_val <= x"11111111";
    
    wait for CLK_PERIOD; -- Cycle 1: Data in IF/ID
    
    -- Feed IF/ID output to ID/EX input
    s_idex_i_pc <= s_ifid_o_pc;
    s_idex_i_pc_plus4 <= s_ifid_o_pc_plus4;
    
    -- Insert new value into IF/ID (continuous insertion)
    s_ifid_i_pc <= x"CAFEBABE";
    s_ifid_i_pc_plus4 <= x"CAFEBAC2";
    s_ifid_i_instruction <= x"CAFEB000";
    
    wait for CLK_PERIOD; -- Cycle 2: Original data in ID/EX
    
    -- Feed ID/EX output to EX/MEM input
    s_exmem_i_reg_write <= s_idex_o_reg_write;
    s_exmem_i_rd_addr <= s_idex_o_rd_addr;
    s_exmem_i_pc_plus4 <= s_idex_o_pc_plus4;
    s_exmem_i_alu_result <= x"DEADBEEF"; -- Use PC as marker
    
    -- Feed IF/ID to ID/EX (second value)
    s_idex_i_pc <= s_ifid_o_pc;
    s_idex_i_pc_plus4 <= s_ifid_o_pc_plus4;
    
    -- Insert third value into IF/ID
    s_ifid_i_pc <= x"BAADF00D";
    s_ifid_i_pc_plus4 <= x"BAADF011";
    
    wait for CLK_PERIOD; -- Cycle 3: Original data in EX/MEM
    
    -- Feed EX/MEM output to MEM/WB input
    s_memwb_i_reg_write <= s_exmem_o_reg_write;
    s_memwb_i_rd_addr <= s_exmem_o_rd_addr;
    s_memwb_i_pc_plus4 <= s_exmem_o_pc_plus4;
    s_memwb_i_alu_result <= s_exmem_o_alu_result;
    s_memwb_i_mem_data <= x"12345678";
    
    -- Continue feeding pipeline
    s_exmem_i_pc_plus4 <= s_idex_o_pc_plus4;
    s_exmem_i_alu_result <= s_idex_o_pc; -- Use PC as marker
    s_idex_i_pc <= s_ifid_o_pc;
    s_idex_i_pc_plus4 <= s_ifid_o_pc_plus4;
    
    wait for CLK_PERIOD; -- Cycle 4: Original data in MEM/WB
    
    -- TEST 2: Continuous insertion - verify all 3 values in pipeline
    -- At this point we should have:
    -- MEM/WB: DEADBEEF (cycle 4)
    -- EX/MEM: CAFEBABE (cycle 3)
    -- ID/EX: BAADF00D (cycle 2)
    
    -- TEST 3: Flush individual stages
    -- Feed more data
    s_memwb_i_alu_result <= s_exmem_o_alu_result;
    s_exmem_i_alu_result <= s_idex_o_pc;
    s_idex_i_pc <= s_ifid_o_pc;
    s_ifid_i_pc <= x"AAAAAAAA";
    
    wait for CLK_PERIOD;
    
    -- TEST 3a: Flush only ID/EX stage
    s_RST_IDEX <= '1';
    wait for CLK_PERIOD;
    s_RST_IDEX <= '0';
    
    -- TEST 3b: Flush only EX/MEM stage
    -- Setup known data
    s_exmem_i_alu_result <= x"FEEDFACE";
    s_exmem_i_reg_write <= '1';
    wait for CLK_PERIOD;
    
    s_RST_EXMEM <= '1';
    wait for CLK_PERIOD;
    s_RST_EXMEM <= '0';
    
    -- TEST 3c: Flush only MEM/WB stage
    s_memwb_i_alu_result <= x"FACADE00";
    s_memwb_i_reg_write <= '1';
    wait for CLK_PERIOD;
    
    s_RST_MEMWB <= '1';
    wait for CLK_PERIOD;
    s_RST_MEMWB <= '0';
    
    -- TEST 3d: Flush only IF/ID stage
    s_ifid_i_pc <= x"ABCD1234";
    wait for CLK_PERIOD;
    
    s_RST_IFID <= '1';
    wait for CLK_PERIOD;
    s_RST_IFID <= '0';
    
    -- TEST 4: Simultaneous flush of multiple stages
    -- Setup data in all stages
    s_ifid_i_pc <= x"11111111";
    s_idex_i_rs1_val <= x"22222222";
    s_exmem_i_alu_result <= x"33333333";
    s_memwb_i_alu_result <= x"44444444";
    
    wait for CLK_PERIOD;
    
    -- Flush IF/ID and EX/MEM simultaneously
    s_RST_IFID <= '1';
    s_RST_EXMEM <= '1';
    wait for CLK_PERIOD;
    s_RST_IFID <= '0';
    s_RST_EXMEM <= '0';
    
    -- TEST 5: Data integrity through normal operation after flush
    -- Reset all
    s_RST_IFID <= '1';
    s_RST_IDEX <= '1';
    s_RST_EXMEM <= '1';
    s_RST_MEMWB <= '1';
    wait for CLK_PERIOD;
    
    s_RST_IFID <= '0';
    s_RST_IDEX <= '0';
    s_RST_EXMEM <= '0';
    s_RST_MEMWB <= '0';
    
    -- Insert sequential values
    for i in 1 to 8 loop
      s_ifid_i_pc <= std_logic_vector(to_unsigned(i * 100, 32));
      s_ifid_i_pc_plus4 <= std_logic_vector(to_unsigned(i * 100 + 4, 32));
      
      -- Feed pipeline
      if i >= 2 then
        s_idex_i_pc <= s_ifid_o_pc;
        s_idex_i_pc_plus4 <= s_ifid_o_pc_plus4;
      end if;
      
      if i >= 3 then
        s_exmem_i_pc_plus4 <= s_idex_o_pc_plus4;
        s_exmem_i_alu_result <= s_idex_o_pc;
      end if;
      
      if i >= 4 then
        s_memwb_i_pc_plus4 <= s_exmem_o_pc_plus4;
        s_memwb_i_alu_result <= s_exmem_o_alu_result;
      end if;
      
      wait for CLK_PERIOD;
    end loop;
    
    wait for CLK_PERIOD * 2;
    
    wait;
  end process;

end behavior;