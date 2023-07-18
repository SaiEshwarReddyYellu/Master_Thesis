----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2023 11:07:52 AM
-- Design Name: 
-- Module Name: delay - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.merge_sort_pkg.all;

entity delay is
generic(size : integer := 1; data_width_d : integer);

port(
    clk : in std_logic;
    ready_buf : in std_logic;
    input_d : in A_vector;
    output_d : out A_vector 
);

end delay;

architecture Behavioral of delay is

begin

  i0:if SIZE=0 generate

       output_d <= input_d;

     end generate;


  il:if SIZE>0 generate
           
       type T_MATRIX is array(INTEGER range <>) of A_vector(output_d'range)(data_width_d-1 downto 0);
        
       signal D :T_MATRIX(1 to SIZE):=(others => (others =>(others => '0')));

       attribute keep:STRING;

       attribute keep of D:signal is "TRUE";

     begin

       process(CLK)

       begin

         if rising_edge(CLK) then
            if ready_buf = '1' then
    
               for K in D'range loop
    
                 if K=D'low then
    
                   D(K)<=input_d;
    
                 else
    
                   D(K)<=D(K-1);
    
                 end if;
    
               end loop;
    
            end if;
          end if;
          
       end process;

       output_d <= D(D'high);

     end generate;


end Behavioral;
