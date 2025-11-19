-- Dylan Kramer and Michael Berg
-- Testbench for Pipeline Registers
-- Made with the assistance of Claude 
-- Tests: Data propagation through all stages, continuous insertion, individual stall/flush
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity pipeline_regs_tb is
end pipeline_regs_tb;

architecture behavior of pipeline_regs_tb is
  
  -- Clock and reset signals
  signal s_CLK : std_logic := '0';
  signal s_RST_IFID : std_logic := '0';
  signal s_RST_IDEX : std_logic := '0';
  signal s_RST_EXMEM : std_logic := '0';
  signal s_RST_MEMWB : std_logic := '0';
  
  -- Stall and flush signals
  signal s_STALL_IFID : std_logic := '0';
  signal s_FLUSH_IFID : std_logic := '0';
  signal s_FLUSH_IDEX : std_logic := '0';
  signal s_FLUSH_EXMEM : std_logic := '0';
  
  -- IF/ID signals
  signal s_ifid_i_pc          : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_i_instruction : std_logic_vector(31 downto 0) := (others => '0');
  signal s_ifid_o_pc          : std_logic_vector(31 downto 0);
  signal s_ifid_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_ifid_o_instruction : std_logic_vector(31 downto 0);
  
  -- ID/EX signals (minimal set for testing)
  signal s_idex_i_reg_write   : std_logic := '0';
  signal s_idex_i_pc          : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_idex_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_idex_o_reg_write   : std_logic;
  signal s_idex_o_pc          : std_logic_vector(31 downto 0);
  signal s_idex_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_idex_o_rd_addr     : std_logic_vector(4 downto 0);
  
  -- EX/MEM signals
  signal s_exmem_i_reg_write   : std_logic := '0';
  signal s_exmem_i_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_exmem_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_exmem_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_exmem_o_reg_write   : std_logic;
  signal s_exmem_o_alu_result  : std_logic_vector(31 downto 0);
  signal s_exmem_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_exmem_o_rd_addr     : std_logic_vector(4 downto 0);
  
  -- MEM/WB signals
  signal s_memwb_i_reg_write   : std_logic := '0';
  signal s_memwb_i_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_memwb_i_pc_plus4    : std_logic_vector(31 downto 0) := (others => '0');
  signal s_memwb_i_rd_addr     : std_logic_vector(4 downto 0) := (others => '0');
  signal s_memwb_o_reg_write   : std_logic;
  signal s_memwb_o_alu_result  : std_logic_vector(31 downto 0);
  signal s_memwb_o_pc_plus4    : std_logic_vector(31 downto 0);
  signal s_memwb_o_rd_addr     : std_logic_vector(4 downto 0);
  
  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  
begin

  -- Instantiate IF/ID register using direct entity instantiation
  IFID: entity work.IF_ID_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_IFID,
      i_stall       => s_STALL_IFID,
      i_flush       => s_FLUSH_IFID,
      i_pc          => s_ifid_i_pc,
      i_pc_plus4    => s_ifid_i_pc_plus4,
      i_instruction => s_ifid_i_instruction,
      o_pc          => s_ifid_o_pc,
      o_pc_plus4    => s_ifid_o_pc_plus4,
      o_instruction => s_ifid_o_instruction
    );
  
  -- Instantiate ID/EX register with minimal signals
  IDEX: entity work.ID_EX_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_IDEX,
      i_flush       => s_FLUSH_IDEX,
      i_alu_src     => '0',
      i_alu_ctrl    => "0000",
      i_mem_write   => '0',
      i_mem_read    => '0',
      i_reg_write   => s_idex_i_reg_write,
      i_wb_sel      => "00",
      i_ld_byte     => '0',
      i_ld_half     => '0',
      i_ld_unsigned => '0',
      i_a_sel       => "00",
      i_halt        => '0',
      i_branch      => '0',
      i_pc_src      => "00",
      i_check_overflow => '0',
      i_pc          => s_idex_i_pc,
      i_pc_plus4    => s_idex_i_pc_plus4,
      i_rs1_val     => (others => '0'),
      i_rs2_val     => (others => '0'),
      i_imm         => (others => '0'),
      i_immB        => (others => '0'),
      i_immJ        => (others => '0'),
      i_shift_amt   => "00000",
      i_rd_addr     => s_idex_i_rd_addr,
      i_rs1_addr    => "00000",
      i_rs2_addr    => "00000",
      i_funct3      => "000",
      o_alu_src     => open,
      o_alu_ctrl    => open,
      o_mem_write   => open,
      o_mem_read    => open,
      o_reg_write   => s_idex_o_reg_write,
      o_wb_sel      => open,
      o_ld_byte     => open,
      o_ld_half     => open,
      o_ld_unsigned => open,
      o_a_sel       => open,
      o_halt        => open,
      o_branch      => open,
      o_pc_src      => open,
      o_check_overflow => open,
      o_pc          => s_idex_o_pc,
      o_pc_plus4    => s_idex_o_pc_plus4,
      o_rs1_val     => open,
      o_rs2_val     => open,
      o_imm         => open,
      o_immB        => open,
      o_immJ        => open,
      o_shift_amt   => open,
      o_rd_addr     => s_idex_o_rd_addr,
      o_rs1_addr    => open,
      o_rs2_addr    => open,
      o_funct3      => open
    );
  
  -- Instantiate EX/MEM register
  EXMEM: entity work.EX_MEM_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_EXMEM,
      i_flush       => s_FLUSH_EXMEM,
      i_mem_write   => '0',
      i_mem_read    => '0',
      i_reg_write   => s_exmem_i_reg_write,
      i_wb_sel      => "00",
      i_ld_byte     => '0',
      i_ld_half     => '0',
      i_ld_unsigned => '0',
      i_halt        => '0',
      i_alu_result  => s_exmem_i_alu_result,
      i_rs2_val     => (others => '0'),
      i_pc_plus4    => s_exmem_i_pc_plus4,
      i_rd_addr     => s_exmem_i_rd_addr,
      i_overflow    => '0',
      i_check_overflow => '0',
      o_mem_write   => open,
      o_mem_read    => open,
      o_reg_write   => s_exmem_o_reg_write,
      o_wb_sel      => open,
      o_ld_byte     => open,
      o_ld_half     => open,
      o_ld_unsigned => open,
      o_halt        => open,
      o_alu_result  => s_exmem_o_alu_result,
      o_rs2_val     => open,
      o_pc_plus4    => s_exmem_o_pc_plus4,
      o_rd_addr     => s_exmem_o_rd_addr,
      o_overflow    => open,
      o_check_overflow => open
    );
  
  -- Instantiate MEM/WB register
  MEMWB: entity work.MEM_WB_reg
    port map(
      i_CLK         => s_CLK,
      i_RST         => s_RST_MEMWB,
      i_reg_write   => s_memwb_i_reg_write,
      i_wb_sel      => "00",
      i_halt        => '0',
      i_alu_result  => s_memwb_i_alu_result,
      i_mem_data    => (others => '0'),
      i_pc_plus4    => s_memwb_i_pc_plus4,
      i_rd_addr     => s_memwb_i_rd_addr,
      i_overflow    => '0',
      i_check_overflow => '0',
      o_reg_write   => s_memwb_o_reg_write,
      o_wb_sel      => open,
      o_halt        => open,
      o_alu_result  => s_memwb_o_alu_result,
      o_mem_data    => open,
      o_pc_plus4    => s_memwb_o_pc_plus4,
      o_rd_addr     => s_memwb_o_rd_addr,
      o_overflow    => open,
      o_check_overflow => open
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
    s_idex_i_reg_write <= '1';
    s_idex_i_rd_addr <= "10101";
    
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
    s_exmem_i_alu_result <= x"DEADBEEF";
    
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
    
    -- Continue feeding pipeline
    s_exmem_i_pc_plus4 <= s_idex_o_pc_plus4;
    s_exmem_i_alu_result <= s_idex_o_pc;
    s_idex_i_pc <= s_ifid_o_pc;
    s_idex_i_pc_plus4 <= s_ifid_o_pc_plus4;
    
    wait for CLK_PERIOD; -- Cycle 4: Original data in MEM/WB
    
    -- TEST 2: Continuous insertion - all 3 values present
    s_memwb_i_alu_result <= s_exmem_o_alu_result;
    s_exmem_i_alu_result <= s_idex_o_pc;
    s_idex_i_pc <= s_ifid_o_pc;
    s_ifid_i_pc <= x"AAAAAAAA";
    
    wait for CLK_PERIOD;
    
    -- TEST 3a: Flush only ID/EX stage
    s_FLUSH_IDEX <= '1';
    wait for CLK_PERIOD;
    s_FLUSH_IDEX <= '0';
    
    -- TEST 3b: Flush only EX/MEM stage
    s_exmem_i_alu_result <= x"FEEDFACE";
    s_exmem_i_reg_write <= '1';
    wait for CLK_PERIOD;
    
    s_FLUSH_EXMEM <= '1';
    wait for CLK_PERIOD;
    s_FLUSH_EXMEM <= '0';
    
    -- TEST 3c: Flush only MEM/WB stage using reset
    s_memwb_i_alu_result <= x"FACADE00";
    s_memwb_i_reg_write <= '1';
    wait for CLK_PERIOD;
    
    s_RST_MEMWB <= '1';
    wait for CLK_PERIOD;
    s_RST_MEMWB <= '0';
    
    -- TEST 3d: Flush only IF/ID stage
    s_ifid_i_pc <= x"ABCD1234";
    wait for CLK_PERIOD;
    
    s_FLUSH_IFID <= '1';
    wait for CLK_PERIOD;
    s_FLUSH_IFID <= '0';
    
    -- TEST 4: Stall functionality
    s_ifid_i_pc <= x"5AA11001";
    s_ifid_i_pc_plus4 <= x"5AA11005";
    wait for CLK_PERIOD;
    
    -- Stall IF/ID for 2 cycles
    s_STALL_IFID <= '1';
    s_ifid_i_pc <= x"5AA11002";
    wait for CLK_PERIOD;
    
    s_ifid_i_pc <= x"5AA11003";
    wait for CLK_PERIOD;
    
    s_STALL_IFID <= '0';
    s_ifid_i_pc <= x"5AA11004";
    wait for CLK_PERIOD;
    
    -- TEST 5: Simultaneous flush
    s_ifid_i_pc <= x"11111111";
    s_exmem_i_alu_result <= x"33333333";
    s_memwb_i_alu_result <= x"44444444";
    
    wait for CLK_PERIOD;
    
    s_FLUSH_IFID <= '1';
    s_FLUSH_EXMEM <= '1';
    wait for CLK_PERIOD;
    s_FLUSH_IFID <= '0';
    s_FLUSH_EXMEM <= '0';
    
    -- TEST 6: Sequential operation
    s_RST_IFID <= '1';
    s_RST_IDEX <= '1';
    s_RST_EXMEM <= '1';
    s_RST_MEMWB <= '1';
    wait for CLK_PERIOD;
    
    s_RST_IFID <= '0';
    s_RST_IDEX <= '0';
    s_RST_EXMEM <= '0';
    s_RST_MEMWB <= '0';
    
    for i in 1 to 8 loop
      s_ifid_i_pc <= std_logic_vector(to_unsigned(i * 100, 32));
      s_ifid_i_pc_plus4 <= std_logic_vector(to_unsigned(i * 100 + 4, 32));
      
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