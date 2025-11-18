--IF/ID Pipeline register 
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity IF_ID_reg is
  port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_stall       : in  std_logic;
    i_flush       : in  std_logic;
    i_pc          : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_instruction : in  std_logic_vector(31 downto 0);
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

  component mux2t1_N is
    generic(N : integer := 32);
    port(
      i_S  : in  std_logic;
      i_D0 : in  std_logic_vector(N-1 downto 0);
      i_D1 : in  std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
  end component;

  -- Internal signals
  signal s_write_enable : std_logic;
  signal s_pc_mux_out   : std_logic_vector(31 downto 0);
  signal s_pc4_mux_out  : std_logic_vector(31 downto 0);
  signal s_inst_mux_out : std_logic_vector(31 downto 0);
  
  -- NOP instruction (addi x0, x0, 0)
  constant NOP : std_logic_vector(31 downto 0) := x"00000013";
  constant ZERO : std_logic_vector(31 downto 0) := (others => '0');

begin

  --Write Enable Logic: Update register only if NOT stalled
  s_write_enable <= not i_stall;

  --Mux for PC: Select 0 on flush, otherwise pass input
  MUX_PC: mux2t1_N
    generic map(N => 32)
    port map(
      i_S  => i_flush,
      i_D0 => i_pc,       -- Normal: pass PC
      i_D1 => ZERO,       -- Flush: zero out
      o_O  => s_pc_mux_out
    );

  --Mux for PC+4: Select 0 on flush, otherwise pass input
  MUX_PC4: mux2t1_N
    generic map(N => 32)
    port map(
      i_S  => i_flush,
      i_D0 => i_pc_plus4, -- Normal: pass PC+4
      i_D1 => ZERO,       -- Flush: zero out
      o_O  => s_pc4_mux_out
    );

  --Mux for Instruction: Select NOP on flush, otherwise pass input
  MUX_INST: mux2t1_N
    generic map(N => 32)
    port map(
      i_S  => i_flush,
      i_D0 => i_instruction, -- Normal: pass instruction
      i_D1 => NOP,           -- Flush: insert NOP
      o_O  => s_inst_mux_out
    );

  --PC Register
  PC_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => s_write_enable,  -- Only update if not stalled
      i_D   => s_pc_mux_out,    -- Muxed input (0 on flush)
      o_Q   => o_pc
    );

  --PC+4 Register
  PC_PLUS4_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => s_write_enable,  -- Only update if not stalled
      i_D   => s_pc4_mux_out,   -- Muxed input (0 on flush)
      o_Q   => o_pc_plus4
    );

  --Instruction Register
  INST_REG: dffg_N
    generic map(N => 32)
    port map(
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => s_write_enable,  -- Only update if not stalled
      i_D   => s_inst_mux_out,  -- Muxed input (NOP on flush)
      o_Q   => o_instruction
    );

end structural;