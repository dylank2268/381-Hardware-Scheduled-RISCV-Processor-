--Dylan Kramer
--Immediate generation module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_generator is
  port(
    i_instr : in  std_logic_vector(31 downto 0);
    i_kind  : in  std_logic_vector(2 downto 0); -- 000=R,001=I,010=S,011=SB,100=U,101=UJ
    o_imm   : out std_logic_vector(31 downto 0)
  );
end entity;

architecture simple of imm_generator is
  --raw inputs
  signal raw_i  : std_logic_vector(11 downto 0);
  signal raw_s  : std_logic_vector(11 downto 0);
  signal raw_sb : std_logic_vector(12 downto 0);
  signal raw_uj : std_logic_vector(20 downto 0);

  --expanded immediates
  signal imm_r  : std_logic_vector(31 downto 0);
  signal imm_i  : std_logic_vector(31 downto 0);
  signal imm_s  : std_logic_vector(31 downto 0);
  signal imm_sb : std_logic_vector(31 downto 0);
  signal imm_u  : std_logic_vector(31 downto 0);
  signal imm_uj : std_logic_vector(31 downto 0);
begin
  --R-type: 0 (NO immediate)
  imm_r <= (others => '0');

  -- I-type: sign-extend instr[31:20]
  raw_i  <= i_instr(31 downto 20);
  imm_i  <= std_logic_vector(resize(signed(raw_i), 32));

  -- S-type: sign-extend {instr[31:25], instr[11:7]}
  raw_s  <= i_instr(31 downto 25) & i_instr(11 downto 7);
  imm_s  <= std_logic_vector(resize(signed(raw_s), 32));

  -- SB-type (branch): sign-extend {instr[31], instr[7], instr[30:25], instr[11:8], 0}
  raw_sb <= i_instr(31) & i_instr(7) & i_instr(30 downto 25) & i_instr(11 downto 8) & '0';
  imm_sb <= std_logic_vector(resize(signed(raw_sb), 32));

  -- U-type: upper 20 bits with 12 trailing zeros (no sign-extend)
  imm_u  <= i_instr(31 downto 12) & (11 downto 0 => '0');

  -- UJ-type (jump): sign-extend {instr[31], instr[19:12], instr[20], instr[30:21], 0}
  raw_uj <= i_instr(31) & i_instr(19 downto 12) & i_instr(20) & i_instr(30 downto 21) & '0';
  imm_uj <= std_logic_vector(resize(signed(raw_uj), 32));

  --Selects what immediate to use
  with i_kind select
    o_imm <= imm_r   when "000",
             imm_i   when "001",
             imm_s   when "010",
             imm_sb  when "011",
             imm_u   when "100",
             imm_uj  when "101",
             (others => '0') when others;

end architecture;
