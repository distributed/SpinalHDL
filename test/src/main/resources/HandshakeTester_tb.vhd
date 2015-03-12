library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

library work;
use work.pkg_scala2hdl.all;
use work.pkg_enum.all;

-- #spinalBegin userLibrary
library IEEE;
use ieee.math_real.all;
-- #spinalEnd userLibrary


entity HandshakeTester_tb is
end HandshakeTester_tb;

architecture arch of HandshakeTester_tb is
  signal io_slave0_valid : std_logic;
  signal io_slave0_ready : std_logic;
  signal io_slave0_data_a : unsigned(7 downto 0);
  signal io_slave0_data_b : std_logic;
  signal io_master0_valid : std_logic;
  signal io_master0_ready : std_logic;
  signal io_master0_data_a : unsigned(7 downto 0);
  signal io_master0_data_b : std_logic;
  signal io_fifo0_occupancy : unsigned(4 downto 0);
  signal clk : std_logic;
  signal reset : std_logic;
  -- #spinalBegin userDeclarations
  shared variable done : integer := 0;
  
  signal slave0_counter : unsigned(7 downto 0);
  signal master0_counter : unsigned(7 downto 0);
  constant slave0_transactionCount : integer := 10000;
  -- #spinalEnd userDeclarations
begin
  -- #spinalBegin userLogics
  
  process
  begin
    clk <= '0';
    wait for 5 ns;
    if done = 1 then
      wait;
    end if;
    assert now < 1 ms report "timeout" severity failure;
    clk <= '1';
    wait for 5 ns;
  end process;


  process
    procedure waitClk(value:  integer) is
    begin
      for i in 0 to value -1 loop
        wait until rising_edge(clk);  
      end loop;
    end waitClk;
    
    procedure slave0_push is
    begin
      io_slave0_valid <= '1';
      io_slave0_data_a <= slave0_counter;
      io_slave0_data_b <= slave0_counter(2) xor slave0_counter(0);
      slave0_counter <= slave0_counter + X"01";
      wait until rising_edge(clk) and io_slave0_ready = '1';
      io_slave0_valid <= '0';
      io_slave0_data_a <= (others => 'X');
      io_slave0_data_b <= 'X';
    end slave0_push;
    
    
    variable seed1, seed2: positive;
    impure function randomBool return boolean is
      variable rand: real;
    begin
      UNIFORM(seed1, seed2, rand);
      return rand >= 0.5;
    end randomBool;
    
  begin
    reset <= '1';
    slave0_counter <= X"00";
    io_slave0_valid <= '0';
    waitClk(3);
    reset <= '0';

    for i in 0 to slave0_transactionCount loop
        slave0_push;
        while randomBool loop
          wait until rising_edge(clk);
        end loop;
    end loop;
    
    wait;
  end process;
  
  process
    procedure waitClk(value:  integer) is
    begin
      for i in 0 to value -1 loop
        wait until rising_edge(clk);  
      end loop;
    end waitClk;
    
    procedure master0_pop is
    begin
      wait until rising_edge(clk) and io_master0_valid = '1' and io_master0_ready = '1';
      assert (io_master0_data_a = master0_counter and (io_master0_data_b = (master0_counter(2) xor master0_counter(0)))) report "master0_pop fail" severity failure;
      master0_counter <= master0_counter + X"01";
    end master0_pop;
 
  begin
    master0_counter <= X"00";
    wait until rising_edge(clk) and reset = '0';

    
    for i in 0 to slave0_transactionCount loop
      master0_pop;
    end loop;
    
    done := done + 1;
    wait;
  end process;


  process
    variable seed1, seed2: positive;
    variable testCounter : integer := 0;
    procedure random(signal that: out std_logic) is
      variable rand: real;
      variable int_rand: integer;
      variable vector: std_logic_vector(11 DOWNTO 0);
    begin
      UNIFORM(seed1, seed2, rand);
      int_rand := INTEGER(TRUNC(rand*4096.0));
      vector := std_logic_vector(to_unsigned(int_rand, vector'LENGTH));
      that <= vector(3);
    end random;
  begin
    wait until rising_edge(clk);
    random(io_master0_ready);
  end process;
  
  -- #spinalEnd userLogics
  uut : entity work.HandshakeTester
    port map (
      io_slave0_valid =>  io_slave0_valid,
      io_slave0_ready =>  io_slave0_ready,
      io_slave0_data_a =>  io_slave0_data_a,
      io_slave0_data_b =>  io_slave0_data_b,
      io_master0_valid =>  io_master0_valid,
      io_master0_ready =>  io_master0_ready,
      io_master0_data_a =>  io_master0_data_a,
      io_master0_data_b =>  io_master0_data_b,
      io_fifo0_occupancy =>  io_fifo0_occupancy,
      clk =>  clk,
      reset =>  reset 
    );
end arch;
