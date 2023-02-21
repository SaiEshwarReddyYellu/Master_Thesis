----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/16/2022 09:49:35 AM
-- Design Name: 
-- Module Name: row_matrix - Behavioral
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
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity row_matrix is
--  Port ( );
port(
    clk : in std_logic;
    rstn : in std_logic;
    sample_in : in std_logic_vector(7 downto 0);
    tvalid_in : in std_logic;
    read_data_intr : in std_logic;
    data_out : out std_logic_vector(39 downto 0)        -- 5 elements in a row
    );
end row_matrix;

architecture Behavioral of row_matrix is


component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
end component blk_mem_gen_0;


signal wea_i : std_logic_vector(0 downto 0) := (others => '0');
signal addra_i : std_logic_vector(8 downto 0) := (others => '0');
signal enb_i : std_logic;
signal addrb_i : std_logic_vector(8 downto 0);

signal sample_read : std_logic_vector(7 downto 0);
signal row_read : std_logic_vector(39 downto 0);

begin

data_out <= row_read;

row_matrix_ins : blk_mem_gen_0
    port map(
        clka => clk,
        ena => tvalid_in,
        wea => wea_i,
        addra => addra_i,
        dina => sample_in,
        clkb => clk,
        enb => enb_i,
        addrb => addrb_i,
        doutb => sample_read
        );

process(clk)

begin
    if rising_edge(clk) then
       if (tvalid_in = '1') and (read_data_intr = '0') then
            wea_i <= "1";
            enb_i <= '0';
            
       elsif (tvalid_in = '0') and (read_data_intr = '1') then 
            wea_i <= "0";
            enb_i <= '1';
            
       else
            wea_i <= "0";
            enb_i <= '0';       
            
       end if; 
    end if;
end process;
 

process(clk)

begin
    if rising_edge(clk) then
        if rstn = '0' then
                addra_i <= (others => '0'); 
            elsif (wea_i = "1") and (addra_i /= o"777") then            
                addra_i <= addra_i + 1;       
            elsif (wea_i = "0") and (addra_i = o"777") then
                addra_i <= addra_i;
            else
                addra_i <= (others => '0'); 
       end if; 
    end if;
end process;    

process(clk)

begin
    if rising_edge(clk) then         
         if rstn = '0' then
                addrb_i <= (others => '0'); 
            elsif (enb_i = '1') and (addrb_i /= o"777") then            
                addrb_i <= addrb_i + 1;       
            elsif (enb_i = '0') and (addrb_i = o"777") then
                addrb_i <= addrb_i;
            else 
                addrb_i <= (others => '0'); 
        end if;                    
  
        row_read <= sample_read & row_read(39 downto 8);
    end if;

end process;


end Behavioral;
