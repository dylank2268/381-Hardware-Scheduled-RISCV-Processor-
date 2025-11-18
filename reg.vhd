--Dylan Kramer
--reg file with internal forwarding
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity reg is
  generic(N : integer := DATA_WIDTH);
  port(
    RS1      : in  std_logic_vector(4 downto 0);
    RS2      : in  std_logic_vector(4 downto 0);
    DATA_IN  : in  std_logic_vector(N-1 downto 0); 
    W_SEL    : in  std_logic_vector(4 downto 0);
    WE       : in  std_logic;
    RST      : in  std_logic;
    CLK      : in  std_logic;
    RS1_OUT  : out std_logic_vector(N-1 downto 0);
    RS2_OUT  : out std_logic_vector(N-1 downto 0)
  );
end reg;

architecture structural of reg is 

  --Decoder instantiation
  component decoder5t32
    port(
      DIN : in  std_logic_vector(4 downto 0);
      EN  : in  std_logic;
      Y   : out std_logic_vector(31 downto 0)
    );
  end component;
  
  --32t1 mux instantiation
  component mux32t1
    port (
      i_S     : in  std_logic_vector(4 downto 0);
      data_in : in  bus_32;
      o_O     : out std_logic_vector(N-1 downto 0)
    );
  end component;
  
  --N_reg instantiation
  component N_reg
    port(
      Data_in  : in  std_logic_vector(N-1 downto 0);
      CLK      : in  std_logic;
      WE       : in  std_logic;
      RST      : in  std_logic;
      Data_out : out std_logic_vector(N-1 downto 0)
    );
  end component;

  -- Write decoder and register array
  signal s_decoder : std_logic_vector(31 downto 0);
  signal s_reg     : bus_32;
  
  -- Intermediate signals from muxes (before forwarding)
  signal s_rs1_mux : std_logic_vector(N-1 downto 0);
  signal s_rs2_mux : std_logic_vector(N-1 downto 0);
  
  -- Masked write enable to ensure x0 isn't written
  signal s_we_masked : std_logic;

begin

  -- Prevent writes to x0
  s_we_masked <= WE when (W_SEL /= "00000") else '0';
  
  -- Write decoder
  DECODER: decoder5t32
    port map(
      DIN => W_SEL,
      EN  => s_we_masked,
      Y   => s_decoder
    );

  -- x0 register: HARDWIRED TO ZERO
  s_reg(0) <= (others => '0');

  -- x1..x31 normal registers
  NREG1TO31: for i in 1 to 31 generate
    REGI: N_reg
      port map(
        Data_in  => DATA_IN,
        CLK      => CLK,
        WE       => s_decoder(i),
        RST      => RST,
        Data_out => s_reg(i)
      );
  end generate NREG1TO31;

  -- Read muxes (connect to intermediate signals)
  MUX32T1FIRST: mux32t1
    port map(
      i_S     => RS1,
      data_in => s_reg,
      o_O     => s_rs1_mux
    );
    
  MUX32T1SECOND: mux32t1 
    port map(
      i_S     => RS2,
      data_in => s_reg,
      o_O     => s_rs2_mux
    );

  -- Internal forwarding logic - but NEVER forward to x0
  -- Also ensure x0 always reads as 0 even with forwarding
  RS1_OUT <= (others => '0') when (RS1 = "00000") else
             DATA_IN when (WE = '1' and W_SEL = RS1 and RS1 /= "00000") else 
             s_rs1_mux;
             
  RS2_OUT <= (others => '0') when (RS2 = "00000") else
             DATA_IN when (WE = '1' and W_SEL = RS2 and RS2 /= "00000") else 
             s_rs2_mux;

end structural;