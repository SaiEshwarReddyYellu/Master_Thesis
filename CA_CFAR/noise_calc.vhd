----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/18/2022 10:02:10 AM
-- Design Name: 
-- Module Name: noise_calc - Behavioral
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

package sub_routines is

function log2( i : natural) return integer;

end package;

package body sub_routines is

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

end sub_routines;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.sub_routines.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity noise_calc is

Generic(
    data_width_byte : integer ;
    ref_cells : integer;
    guard_cells : integer   
       );

--  Port ( );

port(
    clk : in std_logic;
    rstn : in std_logic;
    t_valid : in std_logic;
    t_ready : in std_logic;
    t_data : in std_logic_vector((8*data_width_byte - 1) downto 0); 
    t_last : in std_logic;
    
    final_noise : out unsigned(((8*data_width_byte - 1) + log2(ref_cells) + 1) downto 0);           --total noise
    Cell_under_test : out unsigned((8*data_width_byte - 1) downto 0);
    valid_out : out std_logic;
    last_out : out std_logic
    );
    
   attribute direct_reset : string;          
   attribute direct_reset of rstn : signal is "yes";  
  
   attribute direct_enable : string;
   attribute direct_enable of t_ready : signal is "yes";
     
end noise_calc;

architecture Behavioral of noise_calc is

----array logic signal
-----------1D array-----------
type samples_array_type is array(natural range <>) of unsigned((8*data_width_byte - 1) downto 0) ;
signal samples : samples_array_type(0 to 2*(ref_cells + guard_cells));          -- to create odd no. of samples in the array 
signal new_sample : unsigned ((8*data_width_byte - 1) downto 0);

-----------for pipeline----------
type buffer_array is array(integer range <>) of std_logic;                          --pipelining control signals for 1d array
signal valid_buf, last_buf : buffer_array(0 to (ref_cells + guard_cells + 1));  



signal tval_1, tlas_1 : std_logic;
signal tval_p, tlas_p : std_logic;
signal tval_2, tlas_2 : std_logic;

signal CUT1,CUT_p,CUT2  : unsigned ((8*data_width_byte - 1) downto 0) ;          --pipelining the cell under test(CUT)

type output_noise is record
left, right : unsigned(((8*data_width_byte - 1) + log2(ref_cells)) downto 0);
end record;

signal ot_noise : output_noise;


function calc_noise(array_in : samples_array_type) return output_noise;

function calc_noise(array_in : samples_array_type) return output_noise is 

constant left_win_hg : integer := (ref_cells-1);             --left window boundary to calculate noise
constant right_win_min : integer := (ref_cells + (2*guard_cells)+1);           -- right signal

variable output_i : output_noise;
    attribute use_dsp : string;
    attribute use_dsp of output_i : variable is "yes";

begin


output_i := ((others => '0'),(others => '0'));


    for i in 0 to ref_cells - 1 loop 
         output_i.left := output_i.left + array_in(i);
         output_i.right := output_i.right + array_in(i+right_win_min);
    end loop;
    
    return output_i;
end function calc_noise;



---------noise signals -----------------
constant log2_check : integer := log2(ref_cells);
--signal lt_noise : unsigned(((8*data_width_byte - 1) + log2(ref_cells)) downto 0);              -- noise for left Reference cells
--signal rt_noise : unsigned(((8*data_width_byte - 1) + log2(ref_cells)) downto 0);              -- noise for right reference cells


signal overall_noise : unsigned(((8*data_width_byte - 1) + log2(ref_cells) + 1) downto 0);           --total noise

attribute use_dsp : string;
attribute use_dsp of overall_noise : signal is "yes";
--attribute use_dsp of ot_noise : signal is "yes";


begin

-----outputs 
final_noise <= overall_noise;
Cell_under_test <= CUT2;
valid_out <= tval_2;
last_out <= tlas_2;




array_logic : process(clk)
begin
    if rising_edge(clk) then
        if rstn = '0' then
            samples <= (others => (others => '0'));
            valid_buf <=(others => '0');
            last_buf <= (others => '0');
            new_sample <= (others => '0');
            
            else
                 if  (t_valid = '1') and (t_ready = '1') then                                                     -- based on valid signal samples are converted into integer and stored in array
                     new_sample <= (unsigned(t_data));
                     samples <= new_sample & samples(0 to (2*(ref_cells+guard_cells))-1);        -- right shifting the new sample 
 
                    ----- cntrl logic pipelining 
                    valid_buf(0) <= t_valid;
                    last_buf(0) <= t_last;  

                    for i in 1 to (ref_cells + guard_cells + 1) loop
                        valid_buf(i) <= valid_buf(i-1);
                        last_buf(i) <= last_buf(i-1);                         
                    end loop; 
                end if;
                
                if (t_valid = '0')and (t_ready = '1') then 
                    new_sample <= (others => '0');
                    samples <= new_sample & samples(0 to (2*(ref_cells+guard_cells))-1);        -- right shifting the new sample 
                     
                    ----- cntrl logic pipelining 
                    valid_buf(0) <= t_valid;
                    last_buf(0) <= t_last;  

                    for i in 1 to (ref_cells + guard_cells + 1) loop
                        valid_buf(i) <= valid_buf(i-1);
                        last_buf(i) <= last_buf(i-1);                         
                    end loop; 
                end if; 
                
                
        end if;
        
    end if;

end process array_logic;


calc_cell_avg : process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            CUT1 <= (others => '0');  
            tlas_1 <= '0';
            tval_1 <= '0';
            ot_noise <= ((others => '0'),(others => '0'));
            
            else 
                if (t_ready = '1') then      
                     CUT1 <= samples(ref_cells+guard_cells); 
                     tlas_1 <= last_buf(ref_cells + guard_cells + 1);
                     tval_1 <= valid_buf(ref_cells + guard_cells + 1);   
                     ot_noise <= calc_noise(samples);
                             
                end if;             
                
                
        end if;
    end if;
end process calc_cell_avg;


final_noise_proc : process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            overall_noise <= (others => '0');
            CUT2 <= (others => '0');
            tval_2 <= '0';
            tlas_2 <= '0';
            
            else
                if t_ready = '1' then
                    overall_noise <= resize((ot_noise.left + ot_noise.right), overall_noise);
                    CUT2 <= CUT1;
                    tval_2 <= tval_1;
                    tlas_2 <= tlas_1;
                end if;
        end if;
    end if;
    
end process final_noise_proc;

end Behavioral;
