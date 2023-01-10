----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2022 11:32:31 AM
-- Design Name: 
-- Module Name: complete_sorter - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity complete_sorter is
    generic(
         m : positive;
         n : positive
            );

--  Port ( );
        port(
        clk : in std_logic;
        ready_buf : in std_logic;
        input_array : in A((m * n) -1 downto 0);
        output_array : out A((m * n) -1 downto 0)
            );
--        attribute direct_enable : string;
--        attribute direct_enable of ready_buf : signal is "yes";     
end complete_sorter;

architecture Behavioral of complete_sorter is

type between_levels is array(0 to n/2) of A((m * n) -1 downto 0);
signal b0 : between_levels;

begin

b0(0) <= input_array;

complete_sort_network : for i in 0 to (n/2)-1 generate 
    combine : entity work.two_line_sorter
        
        generic map(
                m => m,
                n => n
                    )
        
        port map(
            clk => clk,
            ready_buf => ready_buf,
            input_array => (b0(i)),
            output_array => b0(i+1)
                );
end generate complete_sort_network;

process(clk)
begin
    if rising_edge(clk) then
        if ready_buf = '1' then
            output_array <= b0(n/2);
        end if;
    end if;
    
end process;
end Behavioral;
