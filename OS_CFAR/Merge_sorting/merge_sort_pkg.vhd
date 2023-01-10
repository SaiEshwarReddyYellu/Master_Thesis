----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2022 10:29:25 AM
-- Design Name: 
-- Module Name: merge_sort_pkg - Behavioral
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
use IEEE.numeric_std.all;

package merge_sort_pkg is

subtype A is std_logic_vector;

type A_vector is array(natural range <>) of A;

function merge_latency(N, CE_latency : integer) return integer;

function sort_latency(N, CE_latency : integer) return integer;


end merge_sort_pkg;

package body merge_sort_pkg is

function sort_latency(N, CE_latency : integer) return integer is 

begin
    case N is
        when 1 => return 0;
        
        when 2 => return CE_latency;
        
        when others => return sort_latency((N+1)/2, CE_latency) + merge_latency(N, CE_latency);
        
    end case;
end function sort_latency;

function merge_latency(N, CE_latency : integer) return integer is 

begin
    
    case N is 
        
        when 1 => return 0;
        
        when 2 => return CE_latency;
        
        when others => return merge_latency((N+1)/2-1, CE_latency) + CE_latency; 
        
    end case;

end function merge_latency;



end merge_sort_pkg;
