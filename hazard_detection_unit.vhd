library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hazard_detection_unit is
    Port (
        IF_ID_rs1       : in  std_logic_vector(4 downto 0);
        IF_ID_rs2       : in  std_logic_vector(4 downto 0);
        IF_ID_opcode    : in  std_logic_vector(6 downto 0);
        ID_EX_rd        : in  std_logic_vector(4 downto 0);
        ID_EX_mem_read  : in  std_logic;
        ID_EX_reg_write : in  std_logic;
        ID_EX_halt      : in  std_logic;
        ID_EX_pc_src    : in std_logic_vector(1 downto 0);
        EX_MEM_halt     : in  std_logic;
        MEM_WB_halt     : in  std_logic;
        ID_EX_branch    : in std_logic;
        branch_taken    : in  std_logic;
        stall_IF        : out std_logic;
        stall_IF_ID     : out std_logic;
        flush_IF_ID     : out std_logic;
        flush_EX_MEM    : out std_logic;
        flush_ID_EX     : out std_logic
    );
end hazard_detection_unit;

architecture Behavioral of hazard_detection_unit is

    --PC source encodings
    constant PC_SRC_SEQ  : std_logic_vector(1 downto 0) := "00";
    constant PC_SRC_BR   : std_logic_vector(1 downto 0) := "01";
    constant PC_SRC_JAL  : std_logic_vector(1 downto 0) := "10";
    constant PC_SRC_JALR : std_logic_vector(1 downto 0) := "11";

    --Opcode definitions
    constant OPCODE_BRANCH  : std_logic_vector(6 downto 0) := "1100011";
    constant OPCODE_JAL     : std_logic_vector(6 downto 0) := "1101111";
    constant OPCODE_JALR    : std_logic_vector(6 downto 0) := "1100111";
    constant OPCODE_LOAD    : std_logic_vector(6 downto 0) := "0000011";
    constant OPCODE_STORE   : std_logic_vector(6 downto 0) := "0100011";
    constant OPCODE_OP_IMM  : std_logic_vector(6 downto 0) := "0010011";
    constant OPCODE_OP      : std_logic_vector(6 downto 0) := "0110011";
    constant OPCODE_LUI     : std_logic_vector(6 downto 0) := "0110111";
    constant OPCODE_AUIPC   : std_logic_vector(6 downto 0) := "0010111";
    constant REG_ZERO       : std_logic_vector(4 downto 0) := "00000";
    
    --Internal signals
    signal uses_rs1         : std_logic;
    signal uses_rs2         : std_logic;
    signal load_use_hazard  : std_logic;
    signal control_hazard   : std_logic;
    signal is_jump          : std_logic; 

begin
    --logic: load-use occurs when a load is in the execute stage but the next inst in ID stage needs the data 
    -- Determine which registers the decode instruction needs (uses_rs1 and uses_rs2)
    uses_rs1 <= '1' when (IF_ID_opcode = OPCODE_OP or 
                          IF_ID_opcode = OPCODE_OP_IMM or 
                          IF_ID_opcode = OPCODE_LOAD or 
                          IF_ID_opcode = OPCODE_STORE or 
                          IF_ID_opcode = OPCODE_BRANCH or 
                          IF_ID_opcode = OPCODE_JALR) else '0';
    
    -- determine second reg decode inst needs
    uses_rs2 <= '1' when (IF_ID_opcode = OPCODE_OP or 
                          IF_ID_opcode = OPCODE_STORE or 
                          IF_ID_opcode = OPCODE_BRANCH) else '0';
    
    
    --now that we know the source regs, we check for a load-use hazard
    --a hazard occurs when: 1. theres a load in execute stage
    --2. load writes to a real register that is not x0 cause that aint a real reg
    --3. the inst in decode reads from that register
load_use_hazard <= '1' when (
    ID_EX_mem_read = '1' and
    ID_EX_rd /= REG_ZERO and
    (
        (uses_rs1 = '1' and ID_EX_rd = IF_ID_rs1) or
        (uses_rs2 = '1' and ID_EX_rd = IF_ID_rs2)
    )
) else '0';
--detect jump
is_jump <= '1' when (ID_EX_pc_src = PC_SRC_JAL or ID_EX_pc_src = PC_SRC_JALR) else '0';

--detect control hazards if a branch or jump is taken
control_hazard <= branch_taken or is_jump;

-- Output Control Signals
stall_IF    <= load_use_hazard; --STALL fetch stage on a load-use hazard
stall_IF_ID <= load_use_hazard; --STALL IF/ID reg on load-use hazard
flush_IF_ID <= control_hazard;  --flush IF/ID reg on a control hazard
flush_ID_EX <= load_use_hazard or control_hazard; --flush ID/EX on a load/use or a control hazard. 
flush_EX_MEM <= '0';


end Behavioral;