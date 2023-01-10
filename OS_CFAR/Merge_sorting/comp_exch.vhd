----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2022 10:31:10 AM
-- Design Name: 
-- Module Name: comp_exch - Behavioral
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

entity comp_exch is
generic(
    latency : integer := 0;
    data_width_c : integer
        );

port(
    clk : in std_logic;
    in_1 : in A(data_width_c-1 downto 0);
    in_2 : in A(data_width_c-1 downto 0);
    out_1 : out A(data_width_c-1 downto 0);
    out_2 : out A(data_width_c-1 downto 0)
        );
end comp_exch;

architecture Behavioral of comp_exch is


begin
    process(clk)
    begin
        if rising_edge(clk) then
            case in_1 >= in_2 is
                when true => 
                    out_1 <= in_2;
                    out_2 <= in_1;
                    
                when false => 
                    out_1 <= in_1;
                    out_2 <= in_2;
            end case;
        end if;
    end process;
end Behavioral;
