-- Dylan Kramer
-- Load/Store Unit
-- Loads supported: LW, LH/LHU, LB/LBU
--Stores: SW
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity load_store_unit is
  port (
    i_addr        : in  std_logic_vector(31 downto 0); --Memory address
    i_rs2_wdata   : in  std_logic_vector(31 downto 0); --Data to be written to mem
    i_mem_read    : in  std_logic;
    i_mem_write   : in  std_logic;
    i_ld_byte     : in  std_logic;
    i_ld_half     : in  std_logic;
    i_ld_unsigned : in  std_logic;  -- 1: zero-extend, 0: sign-extend
    i_mem_rdata   : in  std_logic_vector(31 downto 0); --data read from mem
    o_mem_addr    : out std_logic_vector(31 downto 0); --Aligned mem addr
    o_mem_wdata   : out std_logic_vector(31 downto 0); --Data to write to mem
    o_mem_we      : out std_logic; --Write enable
    o_load_data   : out std_logic_vector(31 downto 0) --Data forwarded to WB
  );
end entity;

architecture simple of load_store_unit is
  signal ofs          : std_logic_vector(1 downto 0); --Offset signal
  signal addr_aligned : std_logic_vector(31 downto 0); 

  --Select and extend signals
  signal b_sel  : std_logic_vector(7  downto 0);
  signal h_sel  : std_logic_vector(15 downto 0);
  signal lb_ext : std_logic_vector(31 downto 0);
  signal lh_ext : std_logic_vector(31 downto 0);
begin

  ofs          <= i_addr(1 downto 0); --we take the byte offset and then create a word-aligned addr by clearing the lower 2 bits
  addr_aligned <= std_logic_vector(unsigned(i_addr) and not(to_unsigned(3, 32)));
  --map our ouputs to correct data
  o_mem_addr <= addr_aligned;
  o_mem_we   <= i_mem_write;

 --SW logic
-- For SW, write full word and assert all byte enables
-- data from i_rs2_wdata is mapped to output port
  o_mem_wdata <= i_rs2_wdata;

--Load logic below
  -- Select byte based on address offset
  with ofs select
    b_sel <= i_mem_rdata(7  downto 0)  when "00",
             i_mem_rdata(15 downto 8)  when "01",
             i_mem_rdata(23 downto 16) when "10",
             i_mem_rdata(31 downto 24) when others;

  --bit 1 of the OFS is used to select the lower or upper halfword
  h_sel <= i_mem_rdata(15 downto 0) when ofs(1) = '0' else
           i_mem_rdata(31 downto 16);

  --Zero/sign extend (we need to pad with zeros for LBU and LHU)
  lb_ext <= (31 downto 8  => '0')       & b_sel  when i_ld_unsigned = '1' else
            (31 downto 8  => b_sel(7))  & b_sel;

  lh_ext <= (31 downto 16 => '0')       & h_sel  when i_ld_unsigned = '1' else
            (31 downto 16 => h_sel(15)) & h_sel;

  --Final load data mux (we select the correct res based on load type)
  o_load_data <= lb_ext        when i_ld_byte = '1' else
                 lh_ext        when i_ld_half = '1' else
                 i_mem_rdata;
end architecture;
