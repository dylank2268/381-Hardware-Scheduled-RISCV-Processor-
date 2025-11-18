
--Michael Berg
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALUUnit is
  port (
    A         : in  std_logic_vector(31 downto 0);
    B         : in  std_logic_vector(31 downto 0);
    shift_amt : in  std_logic_vector(4 downto 0);
    ALU_op    : in  std_logic_vector(3 downto 0);
    F         : out std_logic_vector(31 downto 0); 
    Zero      : out std_logic;                     
    Overflow  : out std_logic                      
  );
end entity;

architecture structural of ALUUnit is

  -- signals
  signal sum, diff : std_logic_vector(31 downto 0);
  signal and_out, or_out, xor_out : std_logic_vector(31 downto 0);
  signal shifter_out : std_logic_vector(31 downto 0);
  signal slt_bit, slti_bit, sltiu_bit : std_logic;

  signal sh_mode : std_logic_vector(1 downto 0);
  signal overflow_add, overflow_sub : std_logic;

  -- Barrel Shifter 
  component barrel_shifter
    port (
      data_in   : in  std_logic_vector(31 downto 0);
      shift_amt : in  std_logic_vector(4 downto 0);
      mode      : in  std_logic_vector(1 downto 0); -- 00=SLL, 01=SRL, 10=SRA
      data_out  : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  
  -- addition and subtraction 
  sum  <= std_logic_vector(signed(A) + signed(B));
  diff <= std_logic_vector(signed(A) - signed(B));

  
  -- Overflow detection
  overflow_add <= '1' when ((A(31) = B(31)) and (A(31) /= sum(31))) else '0';
  overflow_sub <= '1' when ((A(31) /= B(31)) and (A(31) /= diff(31))) else '0';

  
  -- Logical operation (and or xor)
  and_out <= A and B;
  or_out  <= A or B;
  xor_out <= A xor B;


  
 -- Shift mode select (00=SLL, 01=SRL, 10=SRA 10=SRAI)
  with ALU_op select
    sh_mode <= "00" when "0111",  -- SLL
                "01" when "1000",  -- SRL
                "11" when "1001",  -- SRAI
                "10" when "0101",  -- SRA
                "00" when others;  -- default

  
  -- Barrel shifter instance
  shift_unit: barrel_shifter
    port map (
      data_in   => A,
      shift_amt => shift_amt,
      mode      => sh_mode,
      data_out  => shifter_out
    );

  
  -- Set Less Than
  slt_bit   <= diff(31) xor overflow_sub;                      -- SLT
  slti_bit  <= slt_bit;                                        -- SLTI
  sltiu_bit <= '1' when unsigned(A) < unsigned(B) else '0';    -- SLTIU

  
  -- Final ALU output multiplexer
  with ALU_op select
    F <= sum                              when "0000",  -- ADD
         diff                             when "0001",  -- SUB
         and_out                          when "0010",  -- AND
         or_out                           when "0011",  -- OR
         xor_out                          when "0100",  -- XOR
         shifter_out                      when "0101",  -- SRA
         (31 downto 1 => '0') & slt_bit   when "0110",  -- SLT
         shifter_out                      when "0111",  -- SLL
         shifter_out                      when "1000",  -- SRL
         shifter_out                      when "1001",  -- SRAI
         (31 downto 1 => '0') & slti_bit  when "1010",  -- SLTI
         (31 downto 1 => '0') & sltiu_bit when "1011",  -- SLTIU
         (others => '0')                  when others;  -- Default

  
  -- Zero flag and overflow flag
  Zero <= '1' when F = x"00000000" else '0';

  with ALU_op select
    Overflow <= overflow_add when "0000",  -- ADD
                 overflow_sub when "0001",  -- SUB
                 '0'           when others;

end architecture;