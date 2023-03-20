----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2023 11:24:31 AM
-- Design Name: 
-- Module Name: merge_sort - Behavioral
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

entity merge_sort is
generic(
    ce_latency : integer := 0;
    size : integer;
    data_width_m : integer
        );
port(
    clk : in std_logic;
    ready_buf : in std_logic;
    input_m : in A_vector(1 to size)(data_width_m-1 downto 0);
    output_m : out A_vector(1 to size)(data_width_m-1 downto 0)
        );

end merge_sort;

architecture Behavioral of merge_sort is

constant N : natural := input_m'length;

begin

    i1 : if N = 1 generate 
            
            output_m <= input_m;
          end generate;
    
    i2 : if N = 2 generate
            cx : entity work.comp_exch 
                generic map(latency => ce_latency,
                            data_width_c => data_width_m
                            )
                port map(
                        clk => clk,
                        ready_buf => ready_buf,
                        in_1 => input_m(input_m'low),
                        in_2 => input_m(input_m'high),
                        out_1 => output_m(output_m'low),
                        out_2 => output_m(output_m'high)
                            );                   
            
          end generate;

          
     i3 : if N > 2 generate 
            
            signal sl : A_vector(input_m'low to input_m'low + (N+1)/2 - 1)(data_width_m-1 downto 0);
            signal sh : A_vector( input_m'low + (N+1)/2 to input_m'high)(data_width_m-1 downto 0);
            signal s : A_vector(input_m'range)(data_width_m-1 downto 0) ;
            
            begin
                
                ml : entity work.merge_sort 
                        generic map(
                                    ce_latency => ce_latency,
                                    size => (N+1)/2,
                                    data_width_m => data_width_m
                                        )
                        port map(
                            clk => clk,
                            ready_buf => ready_buf,
                            input_m => input_m(input_m'low to input_m'low + (N+1)/2 - 1),
                            output_m => sl
                                    );

                mh : entity work.merge_sort 
                        generic map(
                                    ce_latency => ce_latency,
                                    size => input_m'length - (N+1)/2,
                                    data_width_m => data_width_m
                                        )
                        port map(
                            clk => clk,
                            ready_buf => ready_buf,
                            input_m => input_m( input_m'low + (N+1)/2 to input_m'high),
                            output_m => sh
                                    );

                           
                s <= sl & sh;

            
               me : entity work.merge
                    generic map(
                                ce_latency => ce_latency,
                                size => size,
                                data_width_me => data_width_m                              
                                    )   
                    
                    port map(
                            clk => clk,
                            ready_buf => ready_buf,
                            input_me => s,
                            output_me => output_m
                                );
                
          end generate;


end Behavioral;
