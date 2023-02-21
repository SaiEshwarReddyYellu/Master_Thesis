----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/11/2023 02:51:17 PM
-- Design Name: 
-- Module Name: two_d_package - Behavioral
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

package two_d_functions is 

type two_d_matrix_type is array( integer range<>, integer range<>) of std_logic_vector(7 downto 0);        --8 bit data 

--functions
function matrix_fill_with_zeros(row_size : integer; column_size : integer) return two_d_matrix_type;

--procedure
procedure matrix_fill(row_size : in integer; column_size : in integer; signal samples_in : in std_logic_vector; --signal clk : in std_logic;
      signal cfar_window : out two_d_matrix_type);

end package;


package body two_d_functions is


---------------------   Reset matrix function  -----------------------------------
function matrix_fill_with_zeros(row_size : integer; column_size : integer) return two_d_matrix_type is
variable matrix_in : two_d_matrix_type(1 to (row_size),1 to (column_size));
begin
    for i in 1 to (row_size) loop
        for j in 1 to (column_size) loop
           matrix_in(i,j) := x"00";   
           
           if (i = row_size and j = column_size) then
                exit;
           end if; 
                     
        end loop;
    end loop;
    return matrix_in;
end function matrix_fill_with_zeros;


---------------------   filling image matrix procedure  -----------------------------------
procedure matrix_fill(row_size : in integer; column_size : in integer; signal samples_in : in std_logic_vector; --signal clk : in std_logic;
      signal cfar_window : out two_d_matrix_type) is

variable element : std_logic_vector(7 downto 0);
variable k : integer range 0 to 25 := 0;

begin
    
        for i in 1 to (row_size) loop
            for j in 1 to (column_size) loop
                  element := samples_in((((k+1)*8)-1) downto (k*8)); 
                           k := k +1;              
                     cfar_window(i,j) <= element; 
                     
                     if (i = row_size and j = column_size) then
                         exit;
                     end if;             
            end loop;
       end loop; 
   

end procedure matrix_fill;



end package body;