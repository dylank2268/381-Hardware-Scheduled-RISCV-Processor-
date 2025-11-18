--PCFetch unit for HW-Scheduled pipeline
--Now includes logic for halts and stalls to support forwarding and hazard detection
--Dylan Kramer
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PCFetch is
  generic(G_RESET_VECTOR : unsigned(31 downto 0) := x"00400000" );
  port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    i_halt      : in  std_logic;
    i_stall     : in  std_logic;
    i_pc_src    : in  std_logic_vector(1 downto 0);
    i_br_taken  : in  std_logic;
    i_ex_pc     : in  std_logic_vector(31 downto 0);
    i_rs1_val   : in  std_logic_vector(31 downto 0);
    i_immI      : in  std_logic_vector(31 downto 0);
    i_immB      : in  std_logic_vector(31 downto 0);
    i_immJ      : in  std_logic_vector(31 downto 0);
    o_pc        : out std_logic_vector(31 downto 0);
    o_pc_plus4  : out std_logic_vector(31 downto 0);
    o_imem_addr : out std_logic_vector(31 downto 0)
  );
end entity PCFetch;

architecture mixed of PCFetch is

  --Internal PC signals as unsigned for easy arithmetic
  signal s_pc_reg    : unsigned(31 downto 0);
  signal s_pc_next   : unsigned(31 downto 0);
  signal s_pc_plus4  : unsigned(31 downto 0);
  signal s_br_tgt    : unsigned(31 downto 0);
  signal s_jal_tgt   : unsigned(31 downto 0);
  signal s_jalr_tgt  : unsigned(31 downto 0);

  --Encodings for i_pc_src
  constant PC_SRC_SEQ  : std_logic_vector(1 downto 0) := "00";
  constant PC_SRC_BR   : std_logic_vector(1 downto 0) := "01";
  constant PC_SRC_JAL  : std_logic_vector(1 downto 0) := "10";
  constant PC_SRC_JALR : std_logic_vector(1 downto 0) := "11";

begin
  
  --PC + 4 (for sequential execution from current fetch PC)
  s_pc_plus4 <= s_pc_reg + to_unsigned(4, 32);

  --Branch target: EX_PC + B-imm (use PC from EX stage)
  s_br_tgt   <= unsigned(i_ex_pc) + unsigned(i_immB);

  --JAL target: EX_PC + J-imm (use PC from EX stage)
  s_jal_tgt  <= unsigned(i_ex_pc) + unsigned(i_immJ);

  --JALR target: rs1 + I-imm
  s_jalr_tgt <= unsigned(i_rs1_val) + unsigned(i_immI);

  --decides next PC
  s_pc_next <= s_br_tgt  when (i_pc_src = PC_SRC_BR and i_br_taken = '1') else
             s_jal_tgt   when (i_pc_src = PC_SRC_JAL) else
             s_jalr_tgt  when (i_pc_src = PC_SRC_JALR) else
             s_pc_plus4;

  --PC reg (process was the best way to do this... our DFFG didn't have a RESET vector)
  process(i_clk, i_rst)
  begin
  if i_rst = '1' then
    s_pc_reg <= G_RESET_VECTOR;
  elsif rising_edge(i_clk) then
    if (i_halt = '0' and i_stall = '0') then
      s_pc_reg <= s_pc_next;
    end if;
  end if;
  end process;

  --output mappings
  o_pc        <= std_logic_vector(s_pc_reg);
  o_pc_plus4  <= std_logic_vector(s_pc_plus4);
  o_imem_addr <= std_logic_vector(s_pc_reg);

end architecture mixed;