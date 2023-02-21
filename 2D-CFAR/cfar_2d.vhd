----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/06/2022 09:49:57 AM
-- Design Name: 
-- Module Name: cfar_2d - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cfar_2d is
Generic(
    scaling_fact : integer range 1 to 400 := 110;            --step_size is 0.25(i.e range from 0.25 to 100)
    samples_per_packet : integer range 0 to 2**23 := 1024*512;    
    reference_window_size : integer range 1 to 25 := 5;
    Gaurd_window_size : integer range 1 to 15 := 3;
    data_width_byte : integer range 1 to 7 := 1
);

port(
    axi_clk : in std_logic;
    axi_rstn : in std_logic;
    
    s_axis_tdata : in std_logic_vector((8*data_width_byte - 1) downto 0);          --AXI Slave Stream
    s_axis_tvalid : in std_logic;
    s_axis_tready : out std_logic;
    s_axis_tlast : in std_logic;

    m_axis_tdata : out std_logic_vector((8*data_width_byte - 1) downto 0);           --AXI Master Stream           --extra "16" bits for obj_detection and sample_cnt value    
    m_axis_tvalid : out std_logic;    
    m_axis_tready : in std_logic;    
    m_axis_tlast : out std_logic;    
    m_axis_tuser : out std_logic_vector(23 downto 0);                    --_m_axis_tuser "MSB-bit" shows "object detection or noise" and the remaining bits displays its value     

    interrupt : out std_logic
 );
 
end cfar_2d;

architecture Behavioral of cfar_2d is

signal s_data_i : std_logic_vector(1 to s_axis_tdata'length) := (others => '0');

signal s_last_cnt : integer range 0 to 512 := 0;
signal s_last_i : std_logic := '0';

-------buffers for output ports 
signal m_valid_i, m_last_i : std_logic := '0' ;
signal m_data_i : std_logic_vector(8*data_width_byte - 1 downto 0);  
signal m_user_i : std_logic_vector (23 downto 0); 

signal ready_buf : std_logic ;

-----samples management signals 
signal samples_manag_out : std_logic_vector(199 downto 0) := (others => '0');
signal samples_manag_out_valid : std_logic := '0';

----2D window 
signal sample_out_valid_2d : std_logic := '0';
signal CUT_2d : std_logic_vector(7 downto 0) := (others => '0');
signal final_noise : unsigned(12 downto 0) := (others => '0');

-----threshold calculation signals
signal CUT_t : unsigned (7 downto 0) := (others => '0');
signal tval_t : std_logic := '0';
signal tlas_t : std_logic := '0';

---------------output signals --------------
signal threshold_val : unsigned((final_noise'length+8) downto 0);                            --calculated threshold

type output_stage is record                                                 --output record for (obj_det = object detection, sample_cnt = sample number, sample_value = actual sample range)
obj_det : std_logic ;
sample_cnt : integer range 0 to samples_per_packet-1;
sample_value : std_logic_vector((8*data_width_byte - 1)downto 0);
end record;

signal output : output_stage;

------------axi block signals---
signal transfer_flag : std_logic;
signal transfer_last : std_logic;



signal sample_cnt_width : std_logic_vector(22 downto 0);

begin


--   ----------- outputs
             m_axis_tlast <= m_last_i;
             m_axis_tvalid <= m_valid_i;     
             m_axis_tdata <= m_data_i;
             m_axis_tuser <= m_user_i;
             s_axis_tready <= ready_buf;
            ready_buf <= m_axis_tready or (not m_valid_i);

process(axi_clk)

begin
    if rising_edge(axi_clk) then
        if s_axis_tlast = '1' and ready_buf = '1' then
            s_last_cnt <= s_last_cnt + 1;
            else
            s_last_cnt <= s_last_cnt;
                      
        end if;
        
        if s_last_cnt=512 then
            s_last_i <= '1';
            else
            s_last_i <= '0';
        end if;
        
    end if;
end process;




sample_manag_ins : entity work. samples_management

port map (
clk_ma => axi_clk,
rstn_ma => axi_rstn,
sample_ma => s_axis_tdata,
sample_valid => s_axis_tvalid,
sample_out => samples_manag_out,
sample_out_valid => samples_manag_out_valid,
intr_out => interrupt
);

two_d_window_ins : entity work.two_d_window

port map(
clk_in_d  => axi_clk,
rstn_d => axi_rstn,
two_d_samples => samples_manag_out,
two_d_valid_in => samples_manag_out_valid,
tready_i => ready_buf,
tlast_i => s_last_i,
sample_valid_out => sample_out_valid_2d,
CUT_out => CUT_2d,
total_noise => final_noise,
tlast_out => s_last_i
);

threshold_calculation : entity work.threshold_cal

generic map(
scaling_fact => scaling_fact,
ext_bus_width => final_noise'length
)

port map(
    clk => axi_clk,
    rstn => axi_rstn,
    ready_buf => ready_buf,
    cut_in => unsigned(CUT_2d),
    tval_in => sample_out_valid_2d,
    tlas_in => s_last_i,
    overall_noise => final_noise,
    cut_out => CUT_t,
    tval_out => tval_t,
    tlas_out => tlas_t,
    final_threshold => threshold_val
        );


detection_process : entity work.sample_detection

generic map(
    data_width_byte => data_width_byte,
        final_threshold_length => threshold_val'length,
        samples_per_packet => samples_per_packet,
        total_ref_cells => 16
        )

port map(
    clk => axi_clk,
    rstn => axi_rstn,
    ready_buf => ready_buf,
    cut_in => CUT_t,
    tval_in => tval_t,
    tlas_in => tlas_t,
    threshold_val_in => threshold_val,
    detected => output.obj_det,
    sample_cnt => output.sample_cnt,
    sample_value => output.sample_value,
    transfer_flag_out => transfer_flag,
    transfer_last_out => transfer_last
        );  


axi_protocol : block                                                --separate block for axi stream where both combinational logic and sequential logic is lumped in the same process
--state machine for axi stream 
type state_type is (idle, waiting, processing);
signal pr_state : state_type := idle;

begin           
            
process(axi_clk, axi_rstn,s_axis_tvalid,transfer_flag,transfer_last,ready_buf, output)

begin  
    
    if rising_edge(axi_clk) then
        if axi_rstn = '0' then
            pr_state <= idle;
            m_valid_i <= '0';
            m_user_i <= (others => '0');
            m_last_i <= '0';
            m_data_i <= (others => '0');
            sample_cnt_width <= (others => '0');
            
            else                         
                case pr_state is 
                
                    when idle =>  
                        m_last_i <= '0';
                        m_valid_i <= '0';
                             
                        if (s_axis_tvalid = '1') and (ready_buf = '1')  then
                            pr_state <= waiting;
                            else
                            pr_state <= idle;
                        end if;
                
                   when waiting =>                      -- this state is for calculating internal computations and starting the first output data
                        if (transfer_flag = '1') and (ready_buf = '1') then
                            pr_state <= processing;
                            m_data_i <= output.sample_value; 
                            m_user_i(23) <= output.obj_det;
                            m_user_i(22 downto 0) <= std_logic_vector(to_unsigned(output.sample_cnt, sample_cnt_width'length));
                            m_valid_i <= transfer_flag;
                            m_last_i <= transfer_last;
                    
                            else
                            m_data_i <= m_data_i;
                            m_valid_i <= m_valid_i;
                            m_user_i <= m_user_i;
                            m_last_i <= m_last_i;
                            pr_state <= waiting;
                        end if;
                        
                  when processing =>  
                    if (transfer_flag = '1') and (ready_buf = '1') then
                            pr_state <= processing;
                            m_data_i <= output.sample_value; 
                            m_user_i(23) <= output.obj_det;
                            m_user_i(22 downto 0) <= std_logic_vector(to_unsigned(output.sample_cnt, sample_cnt_width'length));                   
                            m_valid_i <= transfer_flag;                
                            m_last_i <= transfer_last;
                       
                       elsif ready_buf = '0' then
                            pr_state <= pr_state;                     
                            
                        elsif transfer_flag = '0' then
                             pr_state <= idle;
                            
                    end if;
					
                 when others =>
                    pr_state <= idle;
                    
                end case; 
            end if;
       end if;      
end process;

end block;




end Behavioral;
