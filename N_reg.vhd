--N-bit register using DFF
--Dylan Kramer
use work.RISCV_types.all;
library IEEE;
use IEEE.std_logic_1164.all;

entity N_reg is

  generic(N : integer := 32);

  port(
       Data_in 	       : in std_logic_vector(N-1 downto 0);
       CLK	       : in std_logic;
       WE	       : in std_logic;
       RST 	       : in std_logic;
       Data_out        : out std_logic_vector(N-1 downto 0)
       );

end N_reg;

architecture structural of N_reg is

component dffg_neg 
       port(
       i_CLK        : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       i_WE         : in std_logic;     -- Write enable input
       i_D          : in std_logic;     -- Data value input
       o_Q          : out std_logic
       ); 
end component;

signal reg : std_logic_vector(N-1 downto 0) := (others => '0');
begin

       

G_DFFG: for i in 0 to N-1 generate
    DFFGI : dffg_neg port map(
       i_CLK => CLK,  
       i_RST => RST,
       i_WE  => WE,         
       i_D   => Data_in(i),          
       o_Q   => reg(i));

  end generate G_DFFG;
	
Data_out <= reg;

end structural;