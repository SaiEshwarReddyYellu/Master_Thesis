----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/22/2022 01:30:21 PM
-- Design Name: 
-- Module Name: two_d_window - Behavioral
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
use work.two_d_functions.all;

entity two_d_window is
--  Port ( );

port(
clk_in_d : in std_logic;
rstn_d : in std_logic;
two_d_samples : in std_logic_vector(199 downto 0);
two_d_valid_in : in std_logic;
tready_i : in std_logic;
tlast_i : in std_logic;
sample_valid_out : out std_logic;
CUT_out : out std_logic_vector(7 downto 0);
total_noise : out unsigned(12 downto 0);
tlast_out : out std_logic
);

end two_d_window;

architecture Behavioral of two_d_window is

signal window : two_d_matrix_type(1 to 5, 1 to 5) := (others => (others => (others => '0')));
signal CUT, CUT1, CUT2 : std_logic_vector(7 downto 0);  -- := (others => '0');
signal tval, tval_1, tval_2 : std_logic := '0';
--signal tlas, tlas_1, tlas_2 : std_logic := '0';

type vector_1d_type is array(natural range <>) of unsigned(7 downto 0);
signal vector_array : vector_1d_type(1 to 16) := (others => (others => '0'));
signal row_array : vector_1d_type(1 to 10) := (others => (others => '0'));
signal column_array : vector_1d_type(1 to 6) := (others => (others => '0'));

function log2( i : natural) return integer is
    variable temp    : integer := i;
    variable ret_val : integer := 1; --log2 of 0 should equal 1 because you still need 1 bit to represent 0
  begin                 
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;     
    end loop;
    
    return ret_val;
end function;

function calc_noise (array_in : vector_1d_type(1 to 16)) return unsigned;

function calc_noise (array_in : vector_1d_type(1 to 16)) return unsigned is
variable output : unsigned((7 + log2(16)) downto 0) := (others => '0');

begin
    for i in 1 to 16 loop
        output := output + array_in(i);
    end loop;
 
 return output;
    
end function calc_noise;

signal noise : unsigned((7 + log2(16)) downto 0) := (others => '0');


begin

process(clk_in_d)

begin
    
     if rising_edge(clk_in_d) then
          if rstn_d = '0' then
            CUT <= (others => '0');
         else 
         
           if two_d_valid_in = '1' then               
               matrix_fill(5,5,two_d_samples, window); 
               CUT <= window(3,3);
               tval <= '1';
               
               else
               window <= window;
               CUT <= CUT; 
               tval <= tval;                   
           end if;
       end if;
 end if;
end process;

process(clk_in_d)
begin
    if rising_edge(clk_in_d) then
       if rstn_d = '0' then
            vector_array <= (others => (others => '0'));
            row_array <= (others => (others => '0'));
            column_array <= (others => (others => '0'));
            CUT1 <= (others => '0');
            
            else
                
                for i in 1 to 5 loop
                    row_array(i) <= unsigned(window(1,i));
                    row_array(5+i) <= unsigned(window(5,i));
                end loop;
               
               for j in 1 to 3 loop
                    column_array(j) <= unsigned(window(j+1,1));
                    column_array(3+j) <= unsigned(window(j+1,5));
               end loop;
                
               vector_array <= row_array & column_array; 
               CUT1 <= CUT;
               tval_1 <= tval;
                
       end if; 
    end if;
end process;

process(clk_in_d)

begin
    if rising_edge(clk_in_d) then
        if rstn_d = '0' then
            noise <= (others => '0');
            CUT2 <= (others => '0');
            
            else
                if tready_i = '1' and tval_1 = '1' then
                    noise <= calc_noise(vector_array);
                    CUT2 <= CUT1;
                    tval_2 <= tval_1;
                    
                    else
                    noise <= noise;
                    CUT2 <= CUT2;
                    tval_2 <= tval_2;
                    
                end if;
        end if;
    end if;
    
end process;

process(clk_in_d)

begin
    if rising_edge(clk_in_d) then
        sample_valid_out <= tval_2;
        CUT_out <= CUT2;
--        tlast_out <= tlas_2;
        total_noise <= noise;
    end if;
end process;
end Behavioral;
