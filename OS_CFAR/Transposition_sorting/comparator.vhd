----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2022 11:34:14 AM
-- Design Name: 
-- Module Name: comparator - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.merge_sort_pkg.all;

entity comparator is
    
    generic (m : positive);

    port (
        clk : in std_logic;
        ready_buf : in std_logic;
        in_1 : in A(m -1 downto 0);
        in_2 : in A(m -1 downto 0);
        out_max : out A(m -1 downto 0);
        out_min : out A(m -1 downto 0)   
    );
--        attribute direct_enable : string;
--        attribute direct_enable of ready_buf : signal is "yes"; 

end comparator;

architecture Behavioral of comparator is

begin   
    process(clk)
    begin
    if rising_edge (clk) then
        if ready_buf = '1' then
            if in_1 >= in_2 then
                out_max <= in_2;
                out_min <= in_1;
           else
                out_max <= in_1;
                out_min <= in_2; 
        
            end if;
        end if; 
    end if;        
    end process;
end Behavioral;
