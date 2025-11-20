--Dylan Kramer and Michael Berg
--Top level implementation of a single-cycle RISC-V processor
library IEEE;
use IEEE.std_logic_1164.all;
library work;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0) := (others=> '0'); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- TODO: this signal indicates an overflow exception would have been initiated

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment

--PC Path signals
signal s_Curr_PC : std_logic_vector(N-1 downto 0) := x"00000000";
signal s_PCPlus4 : std_logic_vector(N-1 downto 0);
signal PCSrc : std_logic_vector(1 downto 0);


--Decode fields
signal s_opcode  : std_logic_vector(6 downto 0);
signal s_funct3  : std_logic_vector(2 downto 0);
signal s_funct7  : std_logic_vector(6 downto 0);
signal s_rs1     : std_logic_vector(4 downto 0);
signal s_rs2     : std_logic_vector(4 downto 0);
signal s_rd      : std_logic_vector(4 downto 0);

--Register signals
signal s_rs1_val : std_logic_vector(N-1 downto 0) := (others=>'0');
signal s_rs2_val : std_logic_vector(N-1 downto 0) := (others=>'0');

--Immediate signals
signal s_ImmKind : std_logic_vector(2 downto 0); --Selects what instruction type for control unit
signal s_immI : std_logic_vector(N-1 downto 0) := (others => '0');
signal s_immB : std_logic_vector(31 downto 0) := (others => '0');
signal s_immJ : std_logic_vector(31 downto 0) := (others => '0');

--ALU signals
signal s_ALUSrcSel : std_logic := '0'; --0: rs2, 1: immI
signal s_ALUInB : std_logic_vector(N-1 downto 0); --second ALU input
signal s_ALURes : std_logic_vector(N-1 downto 0); --ALU Result signal
signal s_ALUCtrl : std_logic_vector(3 downto 0) := (others=>'0');
signal s_ALUOvfl : std_logic;
signal s_ALU2BitControl : std_logic_vector(1 downto 0);
signal s_ALUShiftAmt : std_logic_vector(4 downto 0);
signal s_ALUZero : std_logic := '0'; --Zero flag signal
signal s_CheckOverflow : std_logic;

--Writeback signals
signal s_WBSel : std_logic_vector(1 downto 0) := "00";  -- 00=ALU, 01=Load, 10=PC+4, 11=unused
signal s_WBData : std_logic_vector(31 downto 0);

--Load/Store control signals
signal s_MemRead : std_logic;
signal s_MemWrite : std_logic;
signal s_LdByte : std_logic;
signal s_LdHalf : std_logic;
signal s_LdUnsigned : std_logic;


--Load/Store unit signals
signal s_LoadedData : std_logic_vector(31 downto 0);
signal s_RegWrLoad : std_logic;
signal s_RegWr_Final : std_logic;

--Signals for AUIPC logic
signal s_ALUInA : std_logic_vector(31 downto 0);
signal s_ASel   : std_logic_vector(1 downto 0); -- 00=RS1, 01=PC, 10=ZERO

--Signals for branch logic
signal s_Branch : std_logic; --From control unit
signal s_BranchTaken : std_logic; --From branch logic 
signal s_ShiftAmt_ID    : std_logic_vector(4 downto 0);

--IF/ID pipeline signals
signal s_IF_ID_pc : std_logic_vector(31 downto 0);
signal s_IF_IDPC_Plus4 : std_logic_vector(31 downto 0);
signal s_IF_ID_Inst : std_logic_vector(31 downto 0);

--decode stage signals
signal s_ID_RegWr : std_logic;
signal s_ID_Halt  : std_logic;

--ID/EX pipeline signals
-- Control outputs from ID/EX register
signal s_ID_EX_ALU_SRC     : std_logic;
signal s_ID_EX_ALU_CTRL    : std_logic_vector(3 downto 0);
signal s_ID_EX_MEM_WRITE   : std_logic;
signal s_ID_EX_MEM_READ    : std_logic;
signal s_ID_EX_REG_WRITE   : std_logic;
signal s_ID_EX_WB_SEL      : std_logic_vector(1 downto 0);
signal s_ID_EX_LD_BYTE     : std_logic;
signal s_ID_EX_LD_HALF     : std_logic;
signal s_ID_EX_LD_UNSIGNED : std_logic;
signal s_ID_EX_ASEL       : std_logic_vector(1 downto 0);
signal s_ID_EX_HALT        : std_logic;
signal s_ID_EX_BRANCH     : std_logic;
signal s_ID_EX_PC_SRC     : std_logic_vector(1 downto 0);
signal s_ID_EX_CHECK_OVERFLOW : std_logic;

-- Data outputs from ID/EX register
signal s_ID_EX_PC          : std_logic_vector(31 downto 0);
signal s_ID_EX_PC_PLUS4    : std_logic_vector(31 downto 0);
signal s_ID_EX_RS1_VAL     : std_logic_vector(31 downto 0);
signal s_ID_EX_RS2_VAL     : std_logic_vector(31 downto 0);
signal s_ID_EX_IMMI         : std_logic_vector(31 downto 0);
signal s_ID_EX_IMMB       : std_logic_vector(31 downto 0);
signal s_ID_EX_IMMJ       : std_logic_vector(31 downto 0);
signal s_ID_EX_SHIFT_AMT   : std_logic_vector(4 downto 0);
signal s_ID_EX_RD_ADDR     : std_logic_vector(4 downto 0);
signal s_ID_EX_RS1_ADDR    : std_logic_vector(4 downto 0);
signal s_ID_EX_RS2_ADDR    : std_logic_vector(4 downto 0);signal s_ID_EX_FUNCT3      : std_logic_vector(2 downto 0);

--Execute stage shift calculation signal
signal s_ShiftAmt_EX       : std_logic_vector(4 downto 0);

--EX/MEM pipeline signals
-- Control outputs from EX/MEM register
signal s_EX_MEM_MEM_WRITE   : std_logic;
signal s_EX_MEM_MEM_READ    : std_logic;
signal s_EX_MEM_REG_WRITE   : std_logic;
signal s_EX_MEM_WB_SEL      : std_logic_vector(1 downto 0);
signal s_EX_MEM_LD_BYTE     : std_logic;
signal s_EX_MEM_LD_HALF     : std_logic;
signal s_EX_MEM_LD_UNSIGNED : std_logic;
signal s_EX_MEM_HALT        : std_logic;
signal s_EX_MEM_CHECK_OVERFLOW : std_logic;
-- Data outputs from EX/MEM register
signal s_EX_MEM_ALU_RESULT  : std_logic_vector(31 downto 0);
signal s_EX_MEM_RS2_VAL     : std_logic_vector(31 downto 0);
signal s_EX_MEM_PC_PLUS4    : std_logic_vector(31 downto 0);
signal s_EX_MEM_RD_ADDR     : std_logic_vector(4 downto 0);
signal s_EX_MEM_OVERFLOW    : std_logic;
 
--MEM/WB signals
-- Control outputs from MEM/WB register
signal s_MEM_WB_REG_WRITE   : std_logic;
signal s_MEM_WB_WB_SEL      : std_logic_vector(1 downto 0);
signal s_MEM_WB_HALT        : std_logic;
signal s_MEM_WB_CHECK_OVERFLOW : std_logic;
-- Data outputs from MEM/WB register
signal s_MEM_WB_ALU_RESULT  : std_logic_vector(31 downto 0);
signal s_MEM_WB_MEM_DATA    : std_logic_vector(31 downto 0);
signal s_MEM_WB_PC_PLUS4    : std_logic_vector(31 downto 0);
signal s_MEM_WB_RD_ADDR     : std_logic_vector(4 downto 0);
signal s_MEM_WB_OVERFLOW    : std_logic;

--Hazard detection signals
signal s_STALL_IF : std_logic;
signal s_STALL_IF_ID : std_logic;
signal s_FLUSH_IF_ID : std_logic;
signal s_FLUSH_ID_EX : std_logic;
signal s_FLUSH_EX_MEM : std_logic;

--Forwarding signals
signal s_ForwardA : std_logic_vector(1 downto 0);
signal s_ForwardB : std_logic_vector(1 downto 0);
signal s_ALUInA_Forwarded : std_logic_vector(31 downto 0);
signal s_ALUInB_Forwarded : std_logic_vector(31 downto 0);  

--Control unit instantiation
  component ControlUnit is
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
end component;

--ALU unit instantiation
  component ALUUnit is
    port (
      A         : in  std_logic_vector(31 downto 0);
      B         : in  std_logic_vector(31 downto 0);
      shift_amt : in  std_logic_vector(4 downto 0);
      ALU_op    : in  std_logic_vector(3 downto 0);  -- matches your fixed encodings
      F         : out std_logic_vector(31 downto 0);
      Zero      : out std_logic;
      Overflow  : out std_logic
    );
end component;


--reg file instantiation
  component reg is
    generic(N : integer := DATA_WIDTH);
    port(
      RS1     : in  std_logic_vector(4 downto 0);
      RS2     : in  std_logic_vector(4 downto 0);
      DATA_IN : in  std_logic_vector(N-1 downto 0);
      W_SEL   : in  std_logic_vector(4 downto 0);
      WE      : in  std_logic;
      RST     : in  std_logic;
      CLK     : in  std_logic;
      RS1_OUT : out std_logic_vector(N-1 downto 0);
      RS2_OUT : out std_logic_vector(N-1 downto 0)
    );
end component;
--N-bit 2t1 mux instantiation
  component mux2t1_N is
    generic(N : integer := 32);
    port(
      i_S  : in  std_logic;
      i_D0 : in  std_logic_vector(N-1 downto 0);
      i_D1 : in  std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
end component;
--Immediate generator instantiation
  component imm_generator is
    port(
      i_instr : in  std_logic_vector(31 downto 0);
      i_kind  : in  std_logic_vector(2 downto 0);  -- 000=R,001=I,010=S,011=SB,100=U,101=UJ
      o_imm   : out std_logic_vector(31 downto 0)
    );
end component;
--PC Fetch component instantiation
  component PCFetch is
    generic (G_RESET_VECTOR : unsigned(31 downto 0) := x"00000000");
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
  end component;

  --Load and store unit instantiation
component load_store_unit is
    port (
      i_addr        : in  std_logic_vector(31 downto 0);
      i_rs2_wdata   : in  std_logic_vector(31 downto 0);
      i_mem_read    : in  std_logic;
      i_mem_write   : in  std_logic;
      i_ld_byte     : in  std_logic;
      i_ld_half     : in  std_logic;
      i_ld_unsigned : in  std_logic;
      i_mem_rdata   : in  std_logic_vector(31 downto 0);
      o_mem_addr    : out std_logic_vector(31 downto 0);
      o_mem_wdata   : out std_logic_vector(31 downto 0);
      o_mem_we      : out std_logic;
      o_load_data   : out std_logic_vector(31 downto 0)
    );
  end component;

  --Branch logic unit
  component branch_logic is 
    port(
    i_rs1     : in  std_logic_vector(31 downto 0);
    i_rs2     : in  std_logic_vector(31 downto 0);
    i_funct3  : in  std_logic_vector(2 downto 0);
    i_branch  : in  std_logic;
    o_br_taken: out std_logic
    );
  end component;
--4t1 mux instantiation
component mux4t1_N is
  generic (N : integer := 32);
  port(
    i_S  : in  std_logic_vector(1 downto 0);
    i_D0 : in  std_logic_vector(N-1 downto 0);
    i_D1 : in  std_logic_vector(N-1 downto 0);
    i_D2 : in  std_logic_vector(N-1 downto 0);
    i_D3 : in  std_logic_vector(N-1 downto 0);
    o_O  : out std_logic_vector(N-1 downto 0)
  );
end component;
--IF/ID pipeline
component IF_ID_reg is
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
  end component;
  --ID/EX pipeline
  component ID_EX_reg is
      port(
    i_CLK         : in  std_logic;
    i_RST         : in  std_logic;
    i_flush       : in  std_logic; 
    i_alu_src     : in  std_logic;
    i_alu_ctrl    : in  std_logic_vector(3 downto 0);
    i_mem_write   : in  std_logic;
    i_mem_read    : in  std_logic;
    i_reg_write   : in  std_logic;
    i_wb_sel      : in  std_logic_vector(1 downto 0);
    i_ld_byte     : in  std_logic;
    i_ld_half     : in  std_logic;
    i_ld_unsigned : in  std_logic;
    i_a_sel       : in  std_logic_vector(1 downto 0);
    i_halt        : in  std_logic;
    i_branch      : in  std_logic;
    i_pc_src      : in  std_logic_vector(1 downto 0);
    i_check_overflow : in std_logic; --Only want to check overflow for certain insts
    i_pc          : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rs1_val     : in  std_logic_vector(31 downto 0);
    i_rs2_val     : in  std_logic_vector(31 downto 0);
    i_imm         : in  std_logic_vector(31 downto 0);
    i_immB        : in  std_logic_vector(31 downto 0);
    i_immJ        : in  std_logic_vector(31 downto 0);
    i_shift_amt   : in  std_logic_vector(4 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_rs1_addr    : in  std_logic_vector(4 downto 0); 
    i_rs2_addr    : in  std_logic_vector(4 downto 0); 
    i_funct3      : in  std_logic_vector(2 downto 0);
    o_alu_src     : out std_logic;
    o_alu_ctrl    : out std_logic_vector(3 downto 0);
    o_mem_write   : out std_logic;
    o_mem_read    : out std_logic;
    o_reg_write   : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_ld_byte     : out std_logic;
    o_ld_half     : out std_logic;
    o_ld_unsigned : out std_logic;
    o_a_sel       : out std_logic_vector(1 downto 0);
    o_halt        : out std_logic;
    o_branch      : out std_logic;
    o_pc_src      : out std_logic_vector(1 downto 0);
    o_check_overflow : out std_logic;
    o_pc          : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rs1_val     : out std_logic_vector(31 downto 0);
    o_rs2_val     : out std_logic_vector(31 downto 0);
    o_imm         : out std_logic_vector(31 downto 0);
    o_immB        : out std_logic_vector(31 downto 0);
    o_immJ        : out std_logic_vector(31 downto 0);
    o_shift_amt   : out std_logic_vector(4 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0);
    o_rs1_addr    : out std_logic_vector(4 downto 0);
    o_rs2_addr    : out std_logic_vector(4 downto 0);
    o_funct3      : out std_logic_vector(2 downto 0)
  );
  end component;
  --EX/MEM pipeline reg
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
    i_flush       : in std_logic; 
    i_alu_result  : in  std_logic_vector(31 downto 0);
    i_rs2_val     : in  std_logic_vector(31 downto 0);
    i_pc_plus4    : in  std_logic_vector(31 downto 0);
    i_rd_addr     : in  std_logic_vector(4 downto 0);
    i_overflow    : in  std_logic;
    i_check_overflow : in std_logic;
    o_mem_write   : out std_logic;
    o_mem_read    : out std_logic;
    o_reg_write   : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_ld_byte     : out std_logic;
    o_ld_half     : out std_logic;
    o_ld_unsigned : out std_logic;
    o_halt        : out std_logic;
    o_alu_result  : out std_logic_vector(31 downto 0);
    o_check_overflow : out std_logic;
    o_rs2_val     : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0);
    o_overflow    : out std_logic
  );
  end component;
  --MEM/WB REG
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
    i_overflow    : in std_logic;
    i_check_overflow : in std_logic;
    o_reg_write   : out std_logic;
    o_overflow    : out std_logic;
    o_wb_sel      : out std_logic_vector(1 downto 0);
    o_halt        : out std_logic;
    o_alu_result  : out std_logic_vector(31 downto 0);
    o_check_overflow : out std_logic;
    o_mem_data    : out std_logic_vector(31 downto 0);
    o_pc_plus4    : out std_logic_vector(31 downto 0);
    o_rd_addr     : out std_logic_vector(4 downto 0)
  );
  end component;
  component hazard_detection_unit is
    Port(
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
    end component;

    component forwarding_unit is
      port(
        ID_EX_rs1       : in  std_logic_vector(4 downto 0);
        ID_EX_rs2       : in  std_logic_vector(4 downto 0);
        EX_MEM_rd       : in  std_logic_vector(4 downto 0);
        EX_MEM_reg_write: in  std_logic;
        MEM_WB_rd       : in  std_logic_vector(4 downto 0);
        MEM_WB_reg_write: in  std_logic;
        forward_A       : out std_logic_vector(1 downto 0);  -- 00=no forward, 01=from EX/MEM, 10=from MEM/WB
        forward_B       : out std_logic_vector(1 downto 0)
        );
    end component;

begin

  -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0',
      iInstAddr when others;


  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)
  -- TODO: Ensure that s_Ovfl is connected to the overflow output of your ALU

  -- TODO: Implement the rest of your processor below this comment! 

  --PC fetch unit
 PCU: PCFetch
  generic map(G_RESET_VECTOR => x"00400000")
  port map(
    i_clk       => iCLK,
    i_rst       => iRST,
    i_halt      => s_Halt,
    i_pc_src    => s_ID_EX_PC_SRC, 
    i_br_taken  => s_BranchTaken,    
    i_stall     => s_STALL_IF,
    i_ex_pc     => s_ID_EX_PC,        
    i_rs1_val   => s_ALUInA_Forwarded,    --Need forwarded ALUA so JALR works 
    i_immI      => s_ID_EX_IMMI,      
    i_immB      => s_ID_EX_IMMB,       
    i_immJ      => s_ID_EX_IMMJ,       
    o_pc        => s_Curr_PC,
    o_pc_plus4  => s_PCPlus4,
    o_imem_addr => s_NextInstAddr
  );
    --IF/ID pipeline register
  IF_ID_PIPE: IF_ID_reg
   port map(
    i_CLK  => iCLK,
    i_RST  => iRST,
    i_stall => s_STALL_IF_ID,
    i_flush => s_FLUSH_IF_ID,
    i_pc   => s_Curr_PC,
    i_pc_plus4 => s_PCPlus4,
    i_instruction => s_Inst,
    o_pc          => s_IF_ID_pc,
    o_pc_plus4    => s_IF_IDPC_PLUS4,
    o_instruction => s_IF_ID_INST
  );


  -----------------------
  --STAGE 2 DECODE
  ----------------------
    -- Decode instruction fields
  s_opcode <= s_IF_ID_Inst(6 downto 0);
  s_rd     <= s_IF_ID_Inst(11 downto 7);
  s_funct3 <= s_IF_ID_Inst(14 downto 12);
  s_rs1    <= s_IF_ID_Inst(19 downto 15);
  s_rs2    <= s_IF_ID_Inst(24 downto 20);
  s_funct7 <= s_IF_ID_Inst(31 downto 25);


  s_ShiftAmt_ID <= s_IF_ID_Inst(24 downto 20);  -- Always use immediate field for ID stage

  --Hazard detection unit
  HAZARD_DETECT: hazard_detection_unit
  port map(
    IF_ID_rs1       => s_rs1,      
    IF_ID_rs2       => s_rs2,
    IF_ID_opcode    => s_opcode,
    ID_EX_rd        => s_ID_EX_RD_ADDR,
    ID_EX_mem_read  => s_ID_EX_MEM_READ,
    ID_EX_reg_write => s_ID_EX_REG_WRITE,
    ID_EX_halt      => s_ID_EX_HALT,
    ID_EX_pc_src    => s_ID_EX_PC_SRC,
    EX_MEM_halt     => s_EX_MEM_HALT,
    MEM_WB_halt     => s_MEM_WB_HALT,
    branch_taken    => s_BranchTaken,
    ID_EX_branch    => s_ID_EX_BRANCH, 
    stall_IF        => s_STALL_IF,
    stall_IF_ID     => s_STALL_IF_ID,
    flush_IF_ID     => s_FLUSH_IF_ID,
    flush_EX_MEM    => s_FLUSH_EX_MEM,
    flush_ID_EX     => s_FLUSH_ID_EX
  );

--Control unit
  U_CTRL: ControlUnit
    port map(
      opcode     => s_opcode,
      funct3     => s_funct3,
      funct7     => s_funct7,
      imm12      => s_IF_ID_Inst(31 downto 20), --Propagted instruction imm
      ALUSrc     => s_ALUSrcSel,
      ALUControl => open,
      ImmType    => s_ImmKind, 
      ResultSrc  => s_WBSel,
      MemWrite   => s_MemWrite,    
      RegWrite   => s_ID_RegWr,
      ALU_op     => s_ALUCtrl,
      CheckOverflow => s_CheckOverflow,
      Halt       => s_ID_Halt,
      MemRead    => s_MemRead,
      LdByte     => s_LdByte,
      LdHalf     => s_LdHalf,
      LdUnsigned => s_LdUnsigned,
      ASel       => s_ASel,
      Branch     => s_Branch,
      PCSrc      => PCSrc
    );


--Reg file logic
REGFILE: reg
   generic map(N => 32)
   port map(
	  RS1 => s_rs1,
	  RS2 => s_rs2,
	  DATA_IN => s_RegWrData, --From WB Mux
	  W_SEL => s_RegWrAddr, --RD 
	  WE => s_RegWr,
	  RST => iRST,
	  CLK => iCLK,
	  RS1_OUT => s_rs1_val,
	  RS2_OUT => s_rs2_val
    );
	-- Immediate Generation
  IMM_GEN: imm_generator
    port map(
      i_instr => s_IF_ID_Inst,
      i_kind  => s_ImmKind,
      o_imm   => s_immI
    );

  -- Generate B-type immediate (for branches)
  s_immB <= std_logic_vector(resize(signed(s_IF_ID_Inst(31) & s_IF_ID_Inst(7) & 
            s_IF_ID_Inst(30 downto 25) & s_IF_ID_Inst(11 downto 8) & '0'), 32));

  -- Generate J-type immediate (for JAL)
  s_immJ <= std_logic_vector(resize(signed(s_IF_ID_Inst(31) & s_IF_ID_Inst(19 downto 12) & 
            s_IF_ID_Inst(20) & s_IF_ID_Inst(30 downto 21) & '0'), 32));


  -------------------
  --ID/EX pipeline
  -------------------
    -- ID/EX Pipeline Register
  ID_EX_PIPE: ID_EX_reg
    port map(
      i_CLK         => iCLK,
      i_RST         => iRST,
      i_flush      => s_FLUSH_ID_EX,
      i_alu_src     => s_ALUSrcSel,
      i_alu_ctrl    => s_ALUCtrl,
      i_mem_write   => s_MemWrite,
      i_mem_read    => s_MemRead,
      i_reg_write   => s_ID_RegWr,
      i_wb_sel      => s_WBSel,
      i_ld_byte     => s_LdByte,
      i_ld_half     => s_LdHalf,
      i_ld_unsigned => s_LdUnsigned,
      i_a_sel       => s_ASel,
      i_halt        => s_ID_Halt,
      i_check_overflow => s_CheckOverflow,
      i_pc          => s_IF_ID_PC,
      i_pc_plus4    => s_IF_IDPC_Plus4,
      i_rs1_val     => s_rs1_val, --From reg 
      i_rs2_val     => s_rs2_val, --from reg
      i_imm         => s_immI,
      i_immB        => s_immB,
      i_immJ        => s_immJ,
      i_shift_amt   => s_ShiftAmt_ID,
      i_rd_addr     => s_rd,
      i_rs1_addr    => s_rs1,
      i_rs2_addr    => s_rs2,
      i_funct3      => s_funct3,
      i_branch      => s_Branch, --FOR BRANCH SIGNAL
      i_pc_src      => PCSrc,
      o_alu_src     => s_ID_EX_ALU_SRC,
      o_alu_ctrl    => s_ID_EX_ALU_CTRL,
      o_mem_write   => s_ID_EX_MEM_WRITE,
      o_mem_read    => s_ID_EX_MEM_READ,
      o_reg_write   => s_ID_EX_REG_WRITE,
      o_check_overflow => s_ID_EX_CHECK_OVERFLOW,
      o_wb_sel      => S_ID_EX_WB_SEL,
      o_ld_byte     => s_ID_EX_LD_BYTE,
      o_ld_half     => s_ID_EX_LD_HALF,
      o_ld_unsigned => s_ID_EX_LD_UNSIGNED,
      o_a_sel       => s_ID_EX_ASEL,
      o_halt        => s_ID_EX_HALT,
      o_pc          => s_ID_EX_PC,
      o_pc_plus4    => s_ID_EX_PC_PLUS4,
      o_rs1_val     => s_ID_EX_RS1_VAL,
      o_rs2_val     => s_ID_EX_RS2_VAL,
      o_imm         => s_ID_EX_IMMI,
      o_immB        => s_ID_EX_IMMB,
      o_immJ        => s_ID_EX_IMMJ,
      o_branch      => s_ID_EX_BRANCH,
      o_pc_src      => s_ID_EX_PC_SRC,
      o_shift_amt   => s_ID_EX_SHIFT_AMT,
      o_rs1_addr    => s_ID_EX_RS1_ADDR,
      o_rs2_addr    => s_ID_EX_RS2_ADDR,
      o_rd_addr     => s_ID_EX_RD_ADDR,
      o_funct3      => s_ID_EX_FUNCT3
    );
  -------------------
  --EXECUTE STAGE
  -------------------

  s_ShiftAmt_EX <= s_ALUInB_Forwarded(4 downto 0) when (s_ID_EX_ALU_SRC = '0') else
                 s_ID_EX_SHIFT_AMT;

   FORWARD_UNIT: forwarding_unit
  port map(
    ID_EX_rs1        => s_ID_EX_RS1_ADDR,  -- Need to also store rs1/rs2 in ID/EX!
    ID_EX_rs2        => s_ID_EX_RS2_ADDR,
    EX_MEM_rd        => s_EX_MEM_RD_ADDR,
    EX_MEM_reg_write => s_EX_MEM_REG_WRITE,
    MEM_WB_rd        => s_MEM_WB_RD_ADDR,
    MEM_WB_reg_write => s_MEM_WB_REG_WRITE,
    forward_A        => s_ForwardA,
    forward_B        => s_ForwardB
  );

    -- Forwarding mux for ALU input A (after ASel mux)
  MUX_FORWARD_A: mux4t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ForwardA,
    i_D0 => s_ID_EX_RS1_VAL,    -- No forwarding
    i_D1 => s_EX_MEM_ALU_RESULT,-- Forward from EX/MEM
    i_D2 => s_WBData,          -- Forward from MEM/WB
    i_D3 => (others => '0'),
    o_O  => s_ALUInA_Forwarded
  );

  -- Forwarding mux for ALU input B (after ALUSrc mux)
  MUX_FORWARD_B: mux4t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ForwardB,
    i_D0 => s_ID_EX_RS2_VAL,   -- No forwarding
    i_D1 => s_EX_MEM_ALU_RESULT, -- Forward from EX/MEM
    i_D2 => s_WBData,       -- Forward from MEM/WB
    i_D3 => (others => '0'),
    o_O  => s_ALUInB_Forwarded
  );

   BRANCH_UNIT: branch_logic
  port map(
    i_rs1      => s_ALUInA_Forwarded, -- From register file (decode stage)
    i_rs2      => s_ALUInB_Forwarded, -- From register file (decode stage)
    i_funct3   => s_ID_EX_FUNCT3,   -- From instruction decode
    i_branch   => s_ID_EX_BRANCH,   -- From control unit
    o_br_taken => s_BranchTaken     -- Branch decision in decode stage
  );


    --ALU A select
  with s_ID_EX_ASEL select
    s_ALUInA <= s_ALUInA_Forwarded when "00",
                s_ID_EX_PC         when "01",
                (others => '0')    when "10",
                s_ALUInA_Forwarded       when others;


--ALU operand B-select MUX. This calculates branch address before going into the ALU
MUX_ALU_B: mux2t1_N
  generic map(N => 32)
  port map(
    i_S  => s_ID_EX_ALU_SRC,  -- control: 0 = rs2, 1 = immI
    i_D0 => s_ALUInB_Forwarded,-- rs2 value (R-type)
    i_D1 => s_ID_EX_IMMI,      -- immediate (I-type)
    o_O  => s_ALUInB      -- goes into ALU.B
  );


--ALU logic
ALU0: ALUUnit
  port map(
    A         => s_ALUInA,
    B         => s_ALUInB, --select between rs1 and PC
    shift_amt => s_ShiftAmt_EX,
    ALU_op    => s_ID_EX_ALU_CTRL,    
    F         => s_ALURes, --ALU Result
    Zero      => s_ALUZero,
    Overflow  => s_ALUOvfl);


    ---------------
    --EX/MEM PIPELINE
    ---------------
   EX_MEM_PIPE: EX_MEM_reg
    port map(
      i_CLK         => iCLK,
      i_RST         => iRST,
      i_mem_write   => s_ID_EX_MEM_WRITE,
      i_mem_read    => s_ID_EX_MEM_READ,
      i_reg_write   => s_ID_EX_REG_WRITE,
      i_wb_sel      => s_ID_EX_WB_SEL,
      i_ld_byte     => s_ID_EX_LD_BYTE,
      i_ld_half     => s_ID_EX_LD_HALF,
      i_ld_unsigned => s_ID_EX_LD_UNSIGNED,
      i_halt        => s_ID_EX_HALT,
      i_flush       => s_FLUSH_EX_MEM,
      i_check_overflow => s_ID_EX_CHECK_OVERFLOW,
      i_alu_result  => s_ALURes,
      i_rs2_val     => s_ALUInB_Forwarded,
      i_pc_plus4    => s_ID_EX_PC_PLUS4,
      i_rd_addr     => s_ID_EX_RD_ADDR,
      i_overflow    => s_ALUOvfl, --Propagating the OVFL signal to the end
      o_mem_write   => s_EX_MEM_MEM_WRITE,
      o_mem_read    => s_EX_MEM_MEM_READ,
      o_reg_write   => s_EX_MEM_REG_WRITE,
      o_wb_sel      => s_EX_MEM_WB_SEL,
      o_ld_byte     => s_EX_MEM_LD_BYTE,
      o_ld_half     => s_EX_MEM_LD_HALF,
      o_ld_unsigned => s_EX_MEM_LD_UNSIGNED,
      o_halt        => s_EX_MEM_HALT,
      o_check_overflow => s_EX_MEM_CHECK_OVERFLOW,
      o_alu_result  => s_EX_MEM_ALU_RESULT,
      o_rs2_val     => s_EX_MEM_RS2_VAL,
      o_pc_plus4    => s_EX_MEM_PC_PLUS4,
      o_rd_addr     => s_EX_MEM_RD_ADDR,
      o_overflow    => s_EX_MEM_OVERFLOW
    );

  --MEMORY STAGE

  --Load/store logic
  LSU: load_store_unit
  port map(
    i_addr        => s_EX_MEM_ALU_RESULT,  -- Address from ALU
    i_rs2_wdata   => s_EX_MEM_RS2_VAL,     -- Data to store (rs2 value)
    i_mem_read    => s_EX_MEM_MEM_READ,    -- Load enable (from opcode decode)
    i_mem_write   => s_EX_MEM_MEM_WRITE,   -- Store enable (from opcode decode)
    i_ld_byte     => s_EX_MEM_LD_BYTE,     -- Load byte flag
    i_ld_half     => s_EX_MEM_LD_HALF,     -- Load half flag
    i_ld_unsigned => s_EX_MEM_LD_UNSIGNED, -- Zero/sign extend flag
    o_mem_addr    => s_DMemAddr,           -- Address to memory
    o_mem_wdata   => s_DMemData,           -- Write data to memory
    o_mem_we      => s_DMemWr,             -- Write enable to memory
    i_mem_rdata   => s_DMemOut,            -- Read data from memory
    o_load_data   => s_LoadedData          -- Load data for writeback
  );
    -- MEM/WB Pipeline Register
  MEM_WB_PIPE: MEM_WB_reg
    port map(
      i_CLK         => iCLK,
      i_RST         => iRST,
      i_reg_write   => s_EX_MEM_REG_WRITE,
      i_wb_sel      => s_EX_MEM_WB_SEL,
      i_halt        => s_EX_MEM_HALT,
      i_check_overflow => s_EX_MEM_CHECK_OVERFLOW,
      i_alu_result  => s_EX_MEM_ALU_RESULT,
      i_mem_data    => s_LoadedData,
      i_pc_plus4    => s_EX_MEM_PC_PLUS4,
      i_rd_addr     => s_EX_MEM_RD_ADDR,
      i_overflow    => s_EX_MEM_OVERFLOW,
      o_reg_write   => s_MEM_WB_REG_WRITE,
      o_wb_sel      => s_MEM_WB_WB_SEL,
      o_halt        => s_MEM_WB_HALT,
      o_overflow    => s_MEM_WB_OVERFLOW,
      o_alu_result  => s_MEM_WB_ALU_RESULT,
      o_check_overflow => s_MEM_WB_CHECK_OVERFLOW,
      o_mem_data    => s_MEM_WB_MEM_DATA,
      o_pc_plus4    => s_MEM_WB_PC_PLUS4,
      o_rd_addr     => s_MEM_WB_RD_ADDR
    );


--Writeback mux
MUX_WB: mux4t1_N
  generic map(N => 32)
  port map(
    i_S  => s_MEM_WB_WB_SEL,       -- 2-bit select from Control Unit
    i_D0 => s_MEM_WB_ALU_RESULT,
    i_D1 => s_MEM_WB_MEM_DATA,
    i_D2 => s_MEM_WB_PC_PLUS4,
    i_D3 => (others => '0'), --Don't need, so 0
    o_O  => s_WBData
  );
  -- Writeback to register file
  s_RegWrData <= s_WBData;
  s_RegWrAddr <= s_MEM_WB_RD_ADDR;
  s_RegWr     <= s_MEM_WB_REG_WRITE;



  oALUOut <= s_ALURes;
  s_Ovfl  <= s_MEM_WB_OVERFLOW and s_MEM_WB_CHECK_OVERFLOW;
  s_Halt  <= s_MEM_WB_HALT;

end structure;
