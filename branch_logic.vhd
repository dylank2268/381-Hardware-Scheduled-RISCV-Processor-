
--Dylan Kramer and Michael Berg
--Branch logic unit
--Compares rs1 and rs2 values and generates branch taken signal
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity branch_logic is
  port(
    i_rs1     : in  std_logic_vector(31 downto 0);
    i_rs2     : in  std_logic_vector(31 downto 0);
    i_funct3  : in  std_logic_vector(2 downto 0);
    i_branch  : in  std_logic;  --from control unit (1 for branch instructions)
    o_br_taken: out std_logic
  );
end branch_logic;

architecture behavioral of branch_logic is
  signal s_eq   : std_logic; --equals
  signal s_lt   : std_logic;  -- signed less than
  signal s_ltu  : std_logic;  -- unsigned less than
  signal s_cond : std_logic;
begin
  
  --Equality comparison
  s_eq <= '1' when (i_rs1 = i_rs2) else '0';
  
  --Signed less than
  s_lt <= '1' when (signed(i_rs1) < signed(i_rs2)) else '0';
  
  --Unsigned less than
  s_ltu <= '1' when (unsigned(i_rs1) < unsigned(i_rs2)) else '0';
  
  --Branch condition evaluation based on funct3
  with i_funct3 select s_cond <=
    s_eq           when "000",  -- BEQ
    not s_eq       when "001",  -- BNE
    s_lt           when "100",  -- BLT
    not s_lt       when "101",  -- BGE
    s_ltu          when "110",  -- BLTU
    not s_ltu      when "111",  -- BGEU
    '0'            when others;
  
  --Output: branch taken only if this is a branch instruction AND condition is true
  o_br_taken <= i_branch and s_cond;
  
end behavioral;