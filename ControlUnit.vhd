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
        imm12      : in  std_logic_vector(11 downto 0); --Added to fix ecall
        ALUSrc     : out std_logic;
        ALUControl : out std_logic_vector(1 downto 0);
        ImmType    : out std_logic_vector(2 downto 0);
        ResultSrc  : out std_logic_vector(1 downto 0);
        MemWrite   : out std_logic;
        RegWrite   : out std_logic;
        ALU_op     : out std_logic_vector(3 downto 0);
        CheckOverflow : out std_logic;
        Halt       : out std_logic;
        --Load/Store control signals
        MemRead    : out std_logic;
        LdByte     : out std_logic;
        LdHalf     : out std_logic;
        LdUnsigned : out std_logic;
        --Needed for AUIPC
        ASel       : out std_logic_vector(1 downto 0);
        Branch     : out std_logic;
        PCSrc      : out std_logic_vector(1 downto 0)
        );
end ControlUnit;

architecture Behavioral of ControlUnit is
    --WFI constant (helps us find wait commands)
     constant IMM12_WFI : std_logic_vector(11 downto 0) :=
        std_logic_vector(to_unsigned(16#105#, 12));  -- 0x105

        -- PC Source encodings (match your PCFetch constants)
    constant PC_SRC_SEQ  : std_logic_vector(1 downto 0) := "00"; -- sequential (PC+4)
    constant PC_SRC_BR   : std_logic_vector(1 downto 0) := "01"; -- branch target
    constant PC_SRC_JAL  : std_logic_vector(1 downto 0) := "10"; -- JAL target
    constant PC_SRC_JALR : std_logic_vector(1 downto 0) := "11"; -- JALR target
begin
    
    process(opcode, funct3, funct7, imm12)
    begin
        -- defaults
        ALUSrc     <= '0';
        ALUControl <= "00";
        ImmType    <= "000"; --Default R-type
        ResultSrc  <= "00";
        MemWrite   <= '0';
        RegWrite   <= '0';
        ALU_op     <= "0000"; --Do add by default
        CheckOverflow <= '0';
        Halt       <= '0';
        MemRead    <= '0';
        LdByte     <= '0';
        LdHalf     <= '0';
        LdUnsigned <= '0';
        ASel       <= "00";
        Branch     <= '0';
        PCSrc      <= PC_SRC_SEQ;

        -- I type functions
        if opcode = "0010011" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "001";          

            if funct3 = "000" then        -- addi
                ALUControl <= "00";
                ALU_op     <= "0000";
                CheckOverflow <= '1';  -- NEW: ADDI checks overflow
            elsif funct3 = "111" then     -- andi
                ALUControl <= "10";
                ALU_op     <= "0010";
                CheckOverflow <= '0';  -- NEW: No overflow for logical ops
            elsif funct3 = "100" then     -- xori
                ALUControl <= "10";
                ALU_op     <= "0100";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "110" then     -- ori
                ALUControl <= "10";
                ALU_op     <= "0011";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "010" then     -- slti
                ALUControl <= "01";
                ALU_op     <= "0110";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "011" then     -- sltiu
                ALUControl <= "01";
                ALU_op     <= "1011";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "001" then  -- slli
                ALUControl <= "11";
                ALU_op     <= "0111";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "101" then     -- srli/srai
                ALUControl <= "11";
                CheckOverflow <= '0';  -- NEW: No overflow
                if funct7 = "0100000" then
                    ALU_op <= "1001";     -- srai
                else
                    ALU_op <= "1000";     -- srli
                end if;
            end if;

        -- R type instructions
        elsif opcode = "0110011" then
            ALUSrc     <= '0';
            RegWrite   <= '1';
            ImmType    <= "000";

            if funct3 = "000" then        -- add/sub
                ALUControl <= "00";
                CheckOverflow <= '1';  -- NEW: ADD/SUB check overflow
                if funct7 = "0100000" then
                    ALU_op <= "0001";     -- sub
                else
                    ALU_op <= "0000";     -- add
                end if;
            elsif funct3 = "111" then     -- and
                ALUControl <= "10";
                ALU_op     <= "0010";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "100" then     -- xor
                ALUControl <= "10";
                ALU_op     <= "0100";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "110" then     -- or
                ALUControl <= "10";
                ALU_op     <= "0011";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "010" then     -- slt
                ALUControl <= "01";
                ALU_op     <= "0110";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "001" then     -- sll
                ALUControl <= "11";
                ALU_op     <= "0111";
                CheckOverflow <= '0';  -- NEW: No overflow
            elsif funct3 = "101" then     -- srl/sra
                ALUControl <= "11";
                CheckOverflow <= '0';  -- NEW: No overflow
                if funct7 = "0100000" then
                    ALU_op <= "0101";     -- sra
                else
                    ALU_op <= "1000";     -- srl
                end if;
            end if;

        -- lb, lh, lbu, lhu, lw 
        elsif opcode = "0000011" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ResultSrc  <= "01";           
            ImmType    <= "001";          
            ALUControl <= "00";
            ALU_op     <= "0000";
            MemRead    <= '1';
            CheckOverflow <= '0';  -- NEW: Loads don't check overflow
            
            case funct3 is
                when "000" =>  -- LB (sign-extend)
                    LdByte <= '1';
                    LdUnsigned <= '0';
                when "001" =>  -- LH (sign-extend)
                    LdHalf <= '1';
                    LdUnsigned <= '0';
                when "010" =>  -- LW
                    LdUnsigned <= '0';
                when "100" =>  -- LBU (zero-extend)
                    LdByte <= '1';
                    LdUnsigned <= '1';
                when "101" =>  -- LHU (zero-extend)
                    LdHalf <= '1';
                    LdUnsigned <= '1';
                when others =>
                    null;
            end case;

        -- sw 
        elsif opcode = "0100011" then
            ALUSrc     <= '1';
            MemWrite   <= '1';
            RegWrite   <= '0';
            ImmType    <= "010";         
            ALUControl <= "00";
            ALU_op     <= "0000";
            CheckOverflow <= '0';  -- NEW: Stores don't check overflow

        -- beq, bne, blt, bge, bltu, bgeu
        elsif opcode = "1100011" then
            ALUSrc     <= '0';
            RegWrite   <= '0';
            ImmType    <= "011";          
            ALUControl <= "00";
            ALU_op     <= "0001";  
            Branch     <= '1';       
            PCSrc      <= PC_SRC_BR;
            CheckOverflow <= '0';  -- NEW: Branches don't check overflow

        -- lui
        elsif opcode = "0110111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "100"; -- U-type immediate
            ASel       <= "10"; --Select ZERO into ALU
            ALUControl <= "00";
            ALU_op     <= "0000";
            CheckOverflow <= '0';  -- NEW: LUI doesn't check overflow

        -- auipc
        elsif opcode = "0010111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "100";         
            ALUControl <= "00";
            ALU_op     <= "0000";
            ASel       <= "01";
            CheckOverflow <= '0';  -- NEW: AUIPC doesn't check overflow

        -- jal
        elsif opcode = "1101111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "101";          
            ALUControl <= "00";
            PCSrc      <= PC_SRC_JAL;
            ResultSrc  <= "10";
            CheckOverflow <= '0';  -- NEW: JAL doesn't check overflow

        -- jalr
        elsif opcode = "1100111" then
            ALUSrc     <= '1';
            RegWrite   <= '1';
            ImmType    <= "001";          
            ALUControl <= "00";
            PCSrc      <= PC_SRC_JALR;
            ResultSrc  <= "10";
            CheckOverflow <= '0';  -- NEW: JALR doesn't check overflow
            
        --wfi and ECALL
         elsif opcode = "1110011" then
            --only halt on WFI, NOT ecall
            CheckOverflow <= '0';  -- NEW: System instructions don't check overflow
            if imm12 = IMM12_WFI then
                Halt <= '1';  -- WFI
            else
                -- goes to ecall
                -- keep defaults, do not halt
                null;
            end if;
        end if;
    end process;
end Behavioral;