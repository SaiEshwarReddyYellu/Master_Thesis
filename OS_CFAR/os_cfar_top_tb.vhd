----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/23/2022 10:46:41 AM
-- Design Name: 
-- Module Name: os_cfar_top_tb - Behavioral
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

library std;
use std.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity os_cfar_top_tb is
--  Port ( );
end os_cfar_top_tb;

architecture Behavioral of os_cfar_top_tb is

constant clk_sig : time := 5ns;

signal clk : std_logic := '0';

signal rst : std_logic := '0';
signal tval, tlas, sready : std_logic := '0';
signal mval, mlas, mready : std_logic := '0' ;
signal m_data_buf : std_logic_vector(31 downto 0);

file samples_from_octave : text;

shared variable temp_int : integer := 0;
signal cnt_tb : integer range 0 to 1025;
signal fft_slv_buf_out : std_logic_vector(31 downto 0) := (others => '0');


signal mready_cnt : integer range 0 to 10 := 0;

signal file_open_flag, file_close_flag : std_logic := '0';



begin


clk <= not clk after clk_sig/2;

cfar_uut : entity work.os_cfar_final
    
    port map (
        axi_clk => clk,
        axi_rstn => rst,
        
        s_axis_tdata => fft_slv_buf_out,
        s_axis_tvalid => tval,
        s_axis_tready => sready,
        s_axis_tlast => tlas,
        m_axis_tdata => m_data_buf,
        m_axis_tvalid => mval,
        m_axis_tready => mready,
        m_axis_tlast => mlas
                );

process
begin
    
   wait for 150ns;
    
    wait until rising_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);
    rst <= '1';
    wait; 
end process;

process(clk)

begin
    if rising_edge(clk) then
        if rst = '1' then
           
    --       mready_cnt <= mready_cnt + 1;
           
    --       if (mready_cnt > 6) and (mready_cnt < 8) then
    --            mready <= '0'; 
    --        else
                mready <= '1';        
    --       end if;
           
    --       if mready_cnt = 8 then
    --            mready_cnt <= 1;
    --       end if;
            
        end if;
    end if;

end process;


process

variable fstatus : file_open_status;
variable line_1 : line;

begin
        wait until rising_edge (clk); 
        file_open_flag <= '1';
        file_open(fstatus, samples_from_octave, "C:/Users/yellu/octave/project_fft_mag/samples_from_octave.txt", READ_MODE);
        
        tval <= '0';
        tlas <= '0';
        
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        cnt_tb <= 0;
        wait until rst = '1';
        
         while not endfile(samples_from_octave) loop 
            
             
                wait until rising_edge(clk) and sready = '1';      
                     readline(samples_from_octave, line_1); 
                     read(line_1,temp_int);
                     fft_slv_buf_out <= std_logic_vector(to_unsigned(temp_int, fft_slv_buf_out'length));
                            tval <= '1'; 
                            tlas <= '0'; 
                            cnt_tb <= cnt_tb + 1;
                            
                     if cnt_tb = 3071 then
                       tval <= '1';
                       tlas <= '1';
                            exit ;
                     end if;

         end loop;

    wait until rising_edge (clk);
        file_close(samples_from_octave);
        file_close_flag <= '1';
--        fft_slv_buf_out <= (others => '0');
        tval <= '0';
        tlas <= '0';
     wait;   
end process;

end Behavioral;
