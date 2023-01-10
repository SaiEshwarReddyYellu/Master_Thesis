----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2022 04:42:21 PM
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
        cut_in : in unsigned ((8*data_width_byte - 1) downto 0) ;
        tval_in : in std_logic;
        tlas_in : in std_logic;
        threshold_val_in : in unsigned(final_threshold_length-1 downto 0);
        
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

signal CUT_mul : unsigned(((8*data_width_byte - 1) + 8) downto 0);           -- here 8 bits is for ref-cells multiplication
    attribute use_dsp : string;
    attribute use_dsp of CUT_mul : signal is "yes";

signal threshold_buf_1 : unsigned(final_threshold_length-1 downto 0);

signal cut_1:  unsigned ((8*data_width_byte - 1) downto 0) ;

constant ref_cells_unsigned : unsigned(7 downto 0) := to_unsigned(total_ref_cells,8);          ---max ref-cells generic size should not exceed 128 (2*128 = 256)

signal tval_1 : std_logic ;
signal tlas_1 : std_logic ;

----output signals
signal detected_i, transfer_flag_i,transfer_last_i : std_logic;
signal sample_cnt_i : integer range 0 to 2**((8*data_width_byte)/2);
signal sample_value_i : std_logic_vector((8*data_width_byte - 1)downto 0);

begin

 process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
            cut_1 <= (others => '0');
            tval_1 <= '0';
            tlas_1 <= '0';
            CUT_mul <= (others => '0');
            threshold_buf_1 <= (others => '0');
            
            
            else            
                 if (ready_buf = '1') then
                        tval_1 <= tval_in;
                        tlas_1 <= tlas_in;               
                        cut_1 <= cut_in;
                        CUT_mul <= resize(cut_in *ref_cells_unsigned, CUT_mul);
                        threshold_buf_1 <= threshold_val_in;
                end if;
        end if;
    end if;
    
end process ;


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

		if (ready_buf = '1') and tval_1 = '1' then
               if (CUT_mul >= threshold_buf_1) then             --objecct detection with sample range and sample number.
                     detected_i <= '1';
                     sample_value_i <= std_logic_vector(cut_1);
                     sample_cnt_i <= sample_cnt_i + 1;
                                           
                     else
                     detected_i <= '0';
                     sample_value_i <= std_logic_vector(cut_1);
                     sample_cnt_i <= sample_cnt_i + 1;                      
               end if;
			
                if sample_cnt_i = samples_per_packet then
                    sample_cnt_i  <= 1;	
                    else
                    null;				
                end if; 
			     
        end if; 
 
        if (ready_buf = '1') and tval_1 = '0' then 
               if sample_cnt_i = samples_per_packet then
                    sample_cnt_i  <= 0;	
                    else
                    null;				
                end if;         
        end if;
        
            
            if ready_buf = '1' then
                transfer_flag_i <= tval_1;
                transfer_last_i <= tlas_1;
            end if;
        
                  
        end if;
    end if;
end process detection_process_i;


process(clk)

begin
    if rising_edge(clk) then
--       if ready_buf = '1' then

-----outputs
        detected <= detected_i;
        sample_cnt <= sample_cnt_i;
        sample_value <= sample_value_i;
        transfer_flag_out <= transfer_flag_i;
        transfer_last_out <= transfer_last_i;
                   
--      end if;
    end if;
    
end process;

end Behavioral;
