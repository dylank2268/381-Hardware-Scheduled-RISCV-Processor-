--Dylan kramer
--Forwarding unit for HW-Scheduled RISCV Processor
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity forwarding_unit is
  port(
    ID_EX_rs1       : in  std_logic_vector(4 downto 0);
    ID_EX_rs2       : in  std_logic_vector(4 downto 0);
    EX_MEM_rd       : in  std_logic_vector(4 downto 0);
    EX_MEM_reg_write: in  std_logic;
    MEM_WB_rd       : in  std_logic_vector(4 downto 0);
    MEM_WB_reg_write: in  std_logic;
    forward_A       : out std_logic_vector(1 downto 0);
    forward_B       : out std_logic_vector(1 downto 0)
  );
end forwarding_unit;

architecture behavioral of forwarding_unit is
  
  --Helper signals for readability
  signal ex_hazard_rs1  : std_logic;
  signal ex_hazard_rs2  : std_logic;
  signal mem_hazard_rs1 : std_logic;
  signal mem_hazard_rs2 : std_logic;
  
begin

  --EX hazard detection (forward from EX/MEM stage)
  --meant to detect when inst in MEM stage produces data needed in ex stage
  --logic: inst will write to reg file,not write to x0, and we check that dest matches src reg
  ex_hazard_rs1 <= '1' when (EX_MEM_reg_write = '1' and EX_MEM_rd /= "00000" and EX_MEM_rd = ID_EX_rs1) else '0';
  ex_hazard_rs2 <= '1' when (EX_MEM_reg_write = '1' and EX_MEM_rd /= "00000" and EX_MEM_rd = ID_EX_rs2) else '0';
  
  --MEM hazard detection (forward from MEM/WB stage)
  --meant to detect when inst in WB stage produces data needed in ex stage
  --logic: check rs1 to see if MEM/WB writes to reg we need
  --then, inst will write to reg file, not write to x0, and we make sure theres not an EX hazard 
  mem_hazard_rs1 <= '1' when (MEM_WB_reg_write = '1' and MEM_WB_rd /= "00000" and 
                              MEM_WB_rd = ID_EX_rs1 and ex_hazard_rs1 = '0') else '0';
  mem_hazard_rs2 <= '1' when (MEM_WB_reg_write = '1' and MEM_WB_rd /= "00000" and 
                              MEM_WB_rd = ID_EX_rs2 and ex_hazard_rs2 = '0') else '0';
  
  --Forward selection for rs1
  forward_A <= "01" when ex_hazard_rs1  = '1' else
               "10" when mem_hazard_rs1 = '1' else
               "00";
  --forward selection for rs2
  forward_B <= "01" when ex_hazard_rs2  = '1' else
               "10" when mem_hazard_rs2 = '1' else
               "00";

end behavioral;