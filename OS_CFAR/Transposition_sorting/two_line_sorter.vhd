----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2022 11:33:50 AM
-- Design Name: 
-- Module Name: two_line_sorter - Behavioral
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
--use work.p.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity two_line_sorter is
    generic(
         m : positive;
         n : positive
            );
    
    port(
        clk : in std_logic;
        ready_buf : in std_logic;
        input_array : in A((m * n) -1 downto 0);
        output_array : out A((m * n) -1 downto 0)
            );

--        attribute direct_enable : string;
--        attribute direct_enable of ready_buf : signal is "yes";             
            
end two_line_sorter;

architecture Behavioral of two_line_sorter is

type between_levels is array(0 to n-1) of A(m-1 downto 0);
signal b0, b1,b2 : between_levels;

begin

process(clk)
begin
  if rising_edge(clk) then
    if ready_buf = '1' then
        for i in 0 to n-1 loop
            b0(i) <= input_array((m*(i+1)-1) downto m*i);
        end loop;
    end if;
 end if;
 
end process;

generate_even_com : for i in 0 to (n/2)-1 generate 
even_comp : entity work.comparator  
    generic map(
                m => m
                )
    port map(
            clk => clk,
            ready_buf => ready_buf,
            in_1 => b0(i*2), 
            in_2 => b0(i*2+1),
            out_max => b1(i*2),
            out_min => b1(i*2+1));

end generate generate_even_com;

generate_odd_com : for i in 0 to (n/2)-2 generate 
odd_comp : entity work.comparator
    
    generic map(
                m => m
                )
    port map(
            clk => clk,
            ready_buf => ready_buf,    
            in_1 => b1(i*2+1), 
            in_2 => b1(i*2+2),
            out_max => b2(i*2+1),
            out_min => b2(i*2+2));

end generate generate_odd_com;

process(clk)
begin
    if rising_edge(clk) then
        if ready_buf = '1' then
            b2(0) <= b1(0);
            b2(n-1) <= b1(n-1);      
        end if;
    end if;    
end process;

process(clk)
begin
    if ready_buf = '1' then
        for i in 0 to n-1 loop
            output_array(m * (i+1)-1 downto m*i) <= b2(i);
        end loop;
    end if;
end process;

end Behavioral;
