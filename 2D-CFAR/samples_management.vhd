----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/18/2022 11:54:41 AM
-- Design Name: 
-- Module Name: samples_management - Behavioral
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
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity samples_management is

port(
clk_ma : in std_logic;
rstn_ma :in std_logic;
sample_ma : in std_logic_vector(7 downto 0);
sample_valid : in std_logic;
sample_out : out std_logic_vector(199 downto 0);
sample_out_valid : out std_logic;
 intr_out : out std_logic
);

end samples_management;

architecture Behavioral of samples_management is

signal sample_counter : std_logic_vector(8 downto 0);
signal write_line : integer range 0 to 5;
signal row_matrix_data_valid : std_logic_vector(5 downto 0);        ---for six rows


signal read_line : integer range 0 to 5;
signal read_row_matrix_valid : std_logic_vector(5 downto 0);        ---for six rows reading 
signal rd_cnt : std_logic_vector(8 downto 0);
signal read_line_buf : std_logic;

signal rb_data_0 : std_logic_vector(39 downto 0);
signal rb_data_1 : std_logic_vector(39 downto 0);
signal rb_data_2 : std_logic_vector(39 downto 0);
signal rb_data_3 : std_logic_vector(39 downto 0);
signal rb_data_4 : std_logic_vector(39 downto 0);
signal rb_data_5 : std_logic_vector(39 downto 0);


signal total_sample_counter : integer range 0 to 3071;      -- 512 * 6 rows

 
type state_type is (idle, read);
signal state : state_type;

begin

sample_out_valid <= read_line_buf;

process(clk_ma)

begin
    if rising_edge(clk_ma) then
        if rstn_ma = '0' then
            sample_counter <= (others => '0');
            elsif sample_valid = '1' then
                sample_counter <= sample_counter + 1;
            
        end if;
    end if;
end process;

---demux part with write logic ------

process(clk_ma)

begin
    if rising_edge (clk_ma) then
        if rstn_ma = '0' then
            write_line <= 0;
            else
                if sample_counter = o"777"  and write_line < 5 then
                    write_line <= write_line + 1;
                    elsif sample_counter = o"777" and write_line = 5 then
                    write_line <= 0;                    
                end if;
        end if;
    end if;
end process;

process(clk_ma)

begin
    if rising_edge(clk_ma) then
        if (rstn_ma = '0') then
            row_matrix_data_valid <= (others => '0');
          else
              if (write_line = 0) then 
                row_matrix_data_valid(write_line ) <= sample_valid;
                row_matrix_data_valid(row_matrix_data_valid'high) <= '0';
                
              else
                row_matrix_data_valid(write_line) <= sample_valid;
                row_matrix_data_valid(write_line-1) <= '0';
              end if;
        end if;
    end if;
end process;

---end of demux part with write logic ------

--mux part with read logic ----------
process(clk_ma)

begin
    if rising_edge(clk_ma) then
        if rstn_ma = '0' then
            rd_cnt <= (others => '0');
            else
                if read_line_buf = '1' and rd_cnt /= o"777" then
                    rd_cnt <= rd_cnt + 1;
                    else
                    rd_cnt <= (others => '0');
                end if;
        end if;
    end if;
end process;

process(clk_ma)

begin
    if rising_edge(clk_ma) then
        if rstn_ma = '0' then
            read_line <= 0;
            else
                if rd_cnt = o"777" and read_line_buf = '1' then 
                    read_line <= read_line + 1;
                end if;
        end if;
        
        case (read_line) is
        
            when 0 => 
                sample_out <= rb_data_4 & rb_data_3 & rb_data_2 & rb_data_1 & rb_data_0;
            when 1 => 
                sample_out <= rb_data_5 & rb_data_4 & rb_data_3 & rb_data_2 & rb_data_1;            
            when 2 => 
                 sample_out <= rb_data_0 & rb_data_5 & rb_data_4 & rb_data_3 & rb_data_2;           
            when 3 => 
                sample_out <= rb_data_1 & rb_data_0 & rb_data_5 & rb_data_4 & rb_data_3;            
            when 4 => 
                sample_out <= rb_data_2 & rb_data_1 & rb_data_0 & rb_data_5 & rb_data_4;  
            when 5 => 
                sample_out <= rb_data_3 & rb_data_2 & rb_data_1 & rb_data_0 & rb_data_5; 
                          
            when others => 
                read_line <= 0;
        end case;
    
    end if;
    
end process;

process(clk_ma)

begin
    if rising_edge(clk_ma) then
        case read_line is 
            when 0 => 
                read_row_matrix_valid(0) <= read_line_buf;
                read_row_matrix_valid(1) <= read_line_buf;
                read_row_matrix_valid(2) <= read_line_buf;
                read_row_matrix_valid(3) <= read_line_buf;
                read_row_matrix_valid(4) <= read_line_buf;  
                read_row_matrix_valid(5) <= '0';  

            when 1 => 
                read_row_matrix_valid(0) <= '0';
                read_row_matrix_valid(1) <= read_line_buf;
                read_row_matrix_valid(2) <= read_line_buf;
                read_row_matrix_valid(3) <= read_line_buf;
                read_row_matrix_valid(4) <= read_line_buf;  
                read_row_matrix_valid(5) <= read_line_buf;  

            when 2 => 
                read_row_matrix_valid(0) <= read_line_buf;
                read_row_matrix_valid(1) <= '0';
                read_row_matrix_valid(2) <= read_line_buf;
                read_row_matrix_valid(3) <= read_line_buf;
                read_row_matrix_valid(4) <= read_line_buf;  
                read_row_matrix_valid(5) <= read_line_buf;  

            when 3 => 
                read_row_matrix_valid(0) <= read_line_buf;
                read_row_matrix_valid(1) <= read_line_buf;
                read_row_matrix_valid(2) <= '0';
                read_row_matrix_valid(3) <= read_line_buf;
                read_row_matrix_valid(4) <= read_line_buf;  
                read_row_matrix_valid(5) <= read_line_buf;  
                
            when 4 => 
                read_row_matrix_valid(0) <= read_line_buf;
                read_row_matrix_valid(1) <= read_line_buf;
                read_row_matrix_valid(2) <= read_line_buf;
                read_row_matrix_valid(3) <= '0';
                read_row_matrix_valid(4) <= read_line_buf;  
                read_row_matrix_valid(5) <= read_line_buf;  

            when 5 => 
                read_row_matrix_valid(0) <= read_line_buf;
                read_row_matrix_valid(1) <= read_line_buf;
                read_row_matrix_valid(2) <= read_line_buf;
                read_row_matrix_valid(3) <= read_line_buf;
                read_row_matrix_valid(4) <= '0';  
                read_row_matrix_valid(5) <= read_line_buf;                 
                                               
            when others => 
--                read_line <= 0;
        
        end case;
    end if;
end process;


process(clk_ma)

begin
if rising_edge(clk_ma) then
    if rstn_ma = '0' then
       total_sample_counter <= 0; 
        else
            if (sample_valid = '1') and ( read_line_buf = '0') then
                total_sample_counter <= total_sample_counter + 1;
                elsif (sample_valid = '0') and ( read_line_buf = '1') then
                total_sample_counter <= total_sample_counter - 1;
            end if;
    end if;
end if;
end process;

--end of mux part with read logic ----------


process(clk_ma)

begin 
if rising_edge(clk_ma) then
    if rstn_ma = '0' then
        state <= idle;
        read_line_buf <= '0';
        intr_out <= '0';
        else
        case state is
            when idle => 
                intr_out <= '0';
                if (total_sample_counter >= 2560) then                   --------- min 5 rows to read for first time 
                   read_line_buf <= '1';
                   state <= read;
                end if; 
                
            when read => 
                if rd_cnt = 511 then
                   state <= idle; 
                   read_line_buf <= '0';
                end if; 
                intr_out <= '1';   
        end case;
    end if;
end if;

end process;


-------rows instantiation ----------


row_1_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(0),
    read_data_intr => read_row_matrix_valid(0),
    data_out => rb_data_0      
    );


row_2_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(1),
    read_data_intr => read_row_matrix_valid(1),
    data_out => rb_data_1      
    );
    
row_3_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(2),
    read_data_intr => read_row_matrix_valid(2),
    data_out =>  rb_data_2     
    );
    
row_4_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(3),
    read_data_intr => read_row_matrix_valid(3),
    data_out =>  rb_data_3     
    );
    
    
row_5_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(4),
    read_data_intr => read_row_matrix_valid(4),
    data_out => rb_data_4      
    );
    
    
row_6_ins : entity work.row_matrix

port map(
    clk => clk_ma,
    rstn => rstn_ma,
    sample_in => sample_ma,
    tvalid_in => row_matrix_data_valid(5),
    read_data_intr => read_row_matrix_valid(5),
    data_out =>  rb_data_5     
    );
    
    
    
    
    
    
end Behavioral;
