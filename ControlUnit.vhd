--Control Unit
--Michael Berg
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.RISCV_types.all;

entity ControlUnit is
    port(
        opcode     : in  std_logic_vector(6 downto 0);
        funct3     : in  std_logic_vector(2 downto 0);
        funct7     : in  std_logic_vector(6 downto 0);
        imm12      : in  std_logic_vector(11 downto 0);
        ALUSrc     : out std_logic;
        ALUControl : out std_logic_vector(1 downto 0);
        ImmType    : out std_logic_vector(2 downto 0);
        ResultSrc  : out std_logic_vector(1 downto 0);
        MemWrite   : out std_logic;
        RegWrite   : out std_logic;
        ALU_op     : out std_logic_vector(3 downto 0);
        CheckOverflow : out std_logic;
        Halt       : out std_logic;
        MemRead    : out std_logic;
        LdByte     : out std_logic;
        LdHalf     : out std_logic;
        LdUnsigned : out std_logic;
        ASel       : out std_logic_vector(1 downto 0);
        Branch     : out std_logic;
        PCSrc      : out std_logic_vector(1 downto 0)
        );
end ControlUnit;

architecture Behavioral of ControlUnit is
    --Opcodes
    constant OP_I_TYPE   : std_logic_vector(6 downto 0) := "0010011";
    constant OP_R_TYPE   : std_logic_vector(6 downto 0) := "0110011";
    constant OP_LOAD     : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE    : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH   : std_logic_vector(6 downto 0) := "1100011";
    constant OP_LUI      : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC    : std_logic_vector(6 downto 0) := "0010111";
    constant OP_JAL      : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR     : std_logic_vector(6 downto 0) := "1100111";
    constant OP_SYSTEM   : std_logic_vector(6 downto 0) := "1110011";
    
    --WFI constant
    constant IMM12_WFI : std_logic_vector(11 downto 0) := "000100000101";  -- 0x105
    
    --PC Source encodings
    constant PC_SRC_SEQ  : std_logic_vector(1 downto 0) := "00";
    constant PC_SRC_BR   : std_logic_vector(1 downto 0) := "01";
    constant PC_SRC_JAL  : std_logic_vector(1 downto 0) := "10";
    constant PC_SRC_JALR : std_logic_vector(1 downto 0) := "11";
    
    --Instruction type detection signals
    signal is_i_type   : std_logic;
    signal is_r_type   : std_logic;
    signal is_load     : std_logic;
    signal is_store    : std_logic;
    signal is_branch   : std_logic;
    signal is_lui      : std_logic;
    signal is_auipc    : std_logic;
    signal is_jal      : std_logic;
    signal is_jalr     : std_logic;
    signal is_wfi      : std_logic;
    
begin
    -- Decode instruction types based on op
    is_i_type <= '1' when opcode = OP_I_TYPE else '0';
    is_r_type <= '1' when opcode = OP_R_TYPE else '0';
    is_load   <= '1' when opcode = OP_LOAD   else '0';
    is_store  <= '1' when opcode = OP_STORE  else '0';
    is_branch <= '1' when opcode = OP_BRANCH else '0';
    is_lui    <= '1' when opcode = OP_LUI    else '0';
    is_auipc  <= '1' when opcode = OP_AUIPC  else '0';
    is_jal    <= '1' when opcode = OP_JAL    else '0';
    is_jalr   <= '1' when opcode = OP_JALR   else '0';
    is_wfi    <= '1' when (opcode = OP_SYSTEM and imm12 = IMM12_WFI) else '0';
    

    -- ALUSrc: Select immediate (1) or register (0) as second ALU input
    ALUSrc <= '1' when (is_i_type = '1' or is_load = '1' or is_store = '1' or
                        is_lui = '1' or is_auipc = '1' or is_jal = '1' or is_jalr = '1') else
              '0';
    

    -- RegWrite: Enable writing to register file
    RegWrite <= '1' when (is_i_type = '1' or is_r_type = '1' or is_load = '1' or
                          is_lui = '1' or is_auipc = '1' or is_jal = '1' or is_jalr = '1') else
                '0';
    

    -- ImmType: Select immediate format
    ImmType <= "001" when (is_i_type = '1' or is_load = '1' or is_jalr = '1') else  -- I-type
               "010" when is_store = '1'  else  -- S-type
               "011" when is_branch = '1' else  -- B-type
               "100" when (is_lui = '1' or is_auipc = '1') else  -- U-type
               "101" when is_jal = '1'    else  -- J-type
               "000";  -- Default R-type
    

    -- ResultSrc: Select what to write back to register
    ResultSrc <= "01" when is_load = '1' else  -- Memory data
                 "10" when (is_jal = '1' or is_jalr = '1') else  -- PC+4
                 "00";  -- ALU result
    

    -- Memory signals
    MemWrite <= '1' when is_store = '1' else '0';
    MemRead  <= '1' when is_load = '1'  else '0';
    

    -- Load type controls
    LdByte <= '1' when (is_load = '1' and (funct3 = "000" or funct3 = "100")) else '0';  -- LB/LBU
    LdHalf <= '1' when (is_load = '1' and (funct3 = "001" or funct3 = "101")) else '0';  -- LH/LHU
    LdUnsigned <= '1' when (is_load = '1' and (funct3 = "100" or funct3 = "101")) else '0';  -- LBU/LHU
    

    -- ALU A input select
    ASel <= "10" when is_lui = '1'   else  -- Zero
            "01" when is_auipc = '1' else  -- PC
            "00";  -- rs1
    
    -- Branch and PC controls
    Branch <= '1' when is_branch = '1' else '0';
    
    PCSrc <= PC_SRC_BR   when is_branch = '1' else
             PC_SRC_JAL  when is_jal = '1'    else
             PC_SRC_JALR when is_jalr = '1'   else
             PC_SRC_SEQ;
    
    -- Halt (wfi inst)
    Halt <= '1' when is_wfi = '1' else '0';
    
    -- ALUControl: High-level ALU operation type
    ALUControl <= "01" when ((is_i_type = '1' or is_r_type = '1') and 
                             (funct3 = "010" or funct3 = "011")) else  -- SLT/SLTU/SLTI/SLTIU
                  "10" when ((is_i_type = '1' or is_r_type = '1') and 
                             (funct3 = "111" or funct3 = "100" or funct3 = "110")) else  -- Logical ops
                  "11" when ((is_i_type = '1' or is_r_type = '1') and 
                             (funct3 = "001" or funct3 = "101")) else  -- Shift ops
                  "00";  -- Default: Add/Sub
    
    -- ALU_op: Specific ALU operation
    ALU_op <= "0001" when (is_r_type = '1' and funct3 = "000" and funct7 = "0100000") else  -- SUB
              "0001" when is_branch = '1' else  -- Branch comparison (subtract)
              "0010" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "111") else  -- AND/ANDI
              "0100" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "100") else  -- XOR/XORI
              "0011" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "110") else  -- OR/ORI
              "0110" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "010") else  -- SLT/SLTI
              "1011" when (is_i_type = '1' and funct3 = "011") else  -- SLTIU
              "0111" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "001") else  -- SLL/SLLI
              "1001" when (is_i_type = '1' and funct3 = "101" and funct7 = "0100000") else  -- SRAI
              "0101" when (is_r_type = '1' and funct3 = "101" and funct7 = "0100000") else  -- SRA
              "1000" when ((is_i_type = '1' or is_r_type = '1') and funct3 = "101") else  -- SRL/SRLI
              "0000";  -- Default: ADD
    
    -- CheckOverflow: Only for ADD/ADDI/SUB
    CheckOverflow <= '1' when ((is_i_type = '1' or is_r_type = '1') and funct3 = "000") else '0';

end Behavioral;