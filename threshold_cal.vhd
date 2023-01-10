----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/21/2022 11:22:17 AM
-- Design Name: 
-- Module Name: threshold_cal - Behavioral
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

use work.fixed_generic_pkg_mod.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity threshold_cal is
--  Port ( );
    generic (
    data_width_byte : integer;
        ext_bus_width : integer;
        scaling_fact : integer range 1 to 400
            );
            
    port(
        clk : in std_logic;
        rstn : in std_logic;
        ready_buf : in std_logic;
        cut_in : in std_logic_vector ((8*data_width_byte - 1) downto 0) ;
        tval_in : in std_logic;
        tlas_in : in std_logic;
        overall_noise : in unsigned(ext_bus_width-1 downto 0);
        cut_out : out std_logic_vector ((8*data_width_byte - 1) downto 0);
        tval_out : out std_logic;
        tlas_out : out std_logic;
        final_threshold : out std_logic_vector((ext_bus_width + 8) downto 0)  
            );
            
attribute direct_reset : string;
attribute direct_reset of rstn : signal is "yes";

end threshold_cal;

architecture Behavioral of threshold_cal is

constant scaling_val : ufixed := to_ufixed((real(scaling_fact)/(4.0)),7,-7);
signal overall_noise_reg : ufixed(overall_noise'length downto -7); 
signal temp_reg : ufixed (overall_noise'length + 8 downto -14); 

signal output_reg : std_logic_vector((ext_bus_width + 8) downto 0); 

signal cut_1_t, cut_2_t, cut_3_t :  std_logic_vector ((8*data_width_byte - 1) downto 0) ;
signal tval_1_t, tval_2_t, tval_3_t : std_logic ;
signal tlas_1_t, tlas_2_t, tlas_3_t : std_logic ;

attribute use_dsp : string;
attribute use_dsp of temp_reg,overall_noise_reg : signal is "yes";

begin

process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            cut_1_t <= (others => '0');
            tval_1_t <= '0';
            tlas_1_t <= '0';
            overall_noise_reg <= (others => '0');
            
            else
                if ready_buf = '1' then
                    cut_1_t <= cut_in;
                    tval_1_t <= tval_in;
                    tlas_1_t <= tlas_in; 
                    overall_noise_reg <= to_ufixed(overall_noise, (overall_noise'length),-7);                    
               end if;
        end if;
    end if;
    
end process;

process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            cut_2_t <= (others => '0');
            tval_2_t <= '0';
            tlas_2_t <= '0';
            temp_reg <= (others => '0');
            
            else
                if ready_buf = '1' then
                    cut_2_t <= cut_1_t;
                    tval_2_t <= tval_1_t;
                    tlas_2_t <= tlas_1_t;    
                    temp_reg <= (scaling_val * overall_noise_reg);                
               end if;
        end if;
    end if;
    
end process;

process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            cut_3_t <= (others => '0');
            tval_3_t <= '0';
            tlas_3_t <= '0';
            output_reg <= (others => '0');
            
            else
                if ready_buf = '1' then
                    cut_3_t <= cut_2_t;
                    tval_3_t <= tval_2_t;
                    tlas_3_t <= tlas_2_t;   
                    output_reg <= std_logic_vector(temp_reg((overall_noise'length+1+7) downto 0));                
               end if;
        end if;
    end if;
    
end process;

process(clk)

begin
    if rising_edge(clk) then
       if ready_buf = '1' then
             final_threshold <= output_reg;
             cut_out <= cut_3_t;
             tval_out <= tval_3_t;
             tlas_out <= tlas_3_t;             
      end if;
    end if;
    
end process;
end Behavioral;

