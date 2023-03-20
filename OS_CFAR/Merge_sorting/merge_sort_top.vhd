----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2023 11:01:04 AM
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
    size : integer := 8;
    data_width : integer := 32
        );

port(
    clk : in std_logic;
    ready_buf : in std_logic;
    Input : in A_vector(1 to size)(data_width-1 downto 0);
    output : out A_vector(1 to size)(data_width-1 downto 0)
        );
        
end merge_sort_top;

architecture Behavioral of merge_sort_top is

signal input_array_buf : A_vector(1 to size)(data_width-1 downto 0);

begin

    process(clk)
    
    begin
        if rising_edge(clk) then
            if ready_buf = '1' then
                input_array_buf <= Input;   
            end if;        
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
                ready_buf => ready_buf,
                input_m => input_array_buf,
                output_m => output
                        );


end Behavioral;

