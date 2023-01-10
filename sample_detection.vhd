----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/21/2022 02:40:29 PM
-- Design Name: 
-- Module Name: sample_detection - Behavioral
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
use ieee.std_logic_unsigned.all;

entity sample_detection is

    generic (
    data_width_byte : integer;
        final_threshold_length : integer;
        samples_per_packet : integer;
        total_ref_cells : integer            --Reference cells(left + right)
            );

    port(
        clk : in std_logic;
        rstn : in std_logic;
        ready_buf : in std_logic;
        cut_in : in std_logic_vector ((8*data_width_byte - 1) downto 0) ;
        tval_in : in std_logic;
        tlas_in : in std_logic;
        threshold_val_in : in std_logic_vector(final_threshold_length-1 downto 0);
        
        detected : out std_logic;
        sample_cnt : out integer range 0 to 2**((8*data_width_byte)/2);
        sample_value : out std_logic_vector((8*data_width_byte - 1)downto 0);
        transfer_flag_out : out std_logic;
        transfer_last_out : out std_logic
        );

attribute direct_reset : string;
attribute direct_reset of rstn : signal is "yes";

end sample_detection;

architecture Behavioral of sample_detection is


----output signals
signal detected_i, transfer_flag_i,transfer_last_i : std_logic;
signal sample_cnt_i : integer range 0 to 2**((8*data_width_byte)/2);
signal sample_value_i : std_logic_vector((8*data_width_byte - 1)downto 0);

begin


detection_process_i : process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            detected_i <= '0';
            sample_cnt_i <= 0;
            sample_value_i <= (others => '0');
            transfer_flag_i <= '0';
            transfer_last_i <= '0';
               
            else

		if (ready_buf = '1') and tval_in = '1' then
               if (cut_in >= threshold_val_in) then             --objecct detection with sample range and sample number.
                     detected_i <= '1';
                     sample_value_i <= cut_in;
                     sample_cnt_i <= sample_cnt_i + 1;
                                           
                     else
                     detected_i <= '0';
                     sample_value_i <= cut_in;
                     sample_cnt_i <= sample_cnt_i + 1;                      
               end if;
			
                if sample_cnt_i = samples_per_packet then
                    sample_cnt_i  <= 1;
                    else
                    null;						
                end if;
			
        end if; 

        if (ready_buf = '1') and (tval_in = '0') then 
                if sample_cnt_i = samples_per_packet then
                    sample_cnt_i  <= 0;	
                    else
                    null;				
                end if;         
        end if;

            
            if ready_buf = '1' then
                transfer_flag_i <= tval_in;
                transfer_last_i <= tlas_in;
            end if;
        
                  
        end if;
    end if;
end process detection_process_i;


process(clk)

begin
    if rising_edge(clk) then
       if ready_buf = '1' then

-----outputs
        detected <= detected_i;
        sample_cnt <= sample_cnt_i;
        sample_value <= sample_value_i;
        transfer_flag_out <= transfer_flag_i;
        transfer_last_out <= transfer_last_i;
                   
      end if;
    end if;
    
end process;

end Behavioral;

