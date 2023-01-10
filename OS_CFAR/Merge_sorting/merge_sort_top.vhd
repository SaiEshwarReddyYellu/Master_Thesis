----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2022 10:39:59 AM
-- Design Name: 
-- Module Name: merge_sort_top - Behavioral
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

entity merge_sort_top is
generic(
    ce_latency : integer := 1;
    size : integer;
    data_width : integer
        );

port(
    clk : in std_logic;
    Input : in A_vector(1 to size);
    output : out A_vector(1 to size)
        );
        
end merge_sort_top;

architecture Behavioral of merge_sort_top is

signal input_array_buf : A_vector(1 to size)(data_width-1 downto 0);

begin

    process(clk)
    
    begin
        if rising_edge(clk) then
            input_array_buf <= Input;           
        end if;
    end process;
 
    
    ms : entity work.merge_sort
          
          generic map(
                    ce_latency => ce_latency, 
                    size => size,
                    data_width_m => data_width
                        )
          
          port map(
                clk => clk,
                input_m => input_array_buf,
                output_m => output
                        );


end Behavioral;
