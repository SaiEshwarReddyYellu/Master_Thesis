----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2022 09:21:10 AM
-- Design Name: 
-- Module Name: cfar_top - Behavioral
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

use work.sub_routines.all;

-------------------CA-CFAR CALCULATIONS-------------------
--interference power  (beta) = (1/ no.of.ref_cells)(sum of 'ref_cells')
--scaling factor (alpha) = constant => (total_samples.no)[(pfa**(-1/total_samples .no))-1] 
---Calculated threshold (T) <= (alpha)(beta);
-- target <= when (T =< CUT) else noise.
-----------------------------------------------------------

------------------------ca-cfar calculations here followed--------------------
-- 1. noise calculation := sum of left and right ref_cells 
--2 . threshold calculation := noise * scaling factor.
--3: sample_detection := CUT * total_ref_cells >=  threshold, then target is present else noise.

------------------------------------------------

entity cfar_top is
--  Port ( );
    generic(
        scaling_fact : integer range 1 to 400 := 14;            --step_size is 0.25(i.e range from 0.25 to 100)
        samples_per_packet : integer range 0 to 2**14 := 1024*3; 
        data_width_byte : integer range 1 to 16 := 4;      --bytes
        ref_cells : integer range 0 to 50 := 5;            --Reference cells
        guard_cells : integer range 0 to 50 := 5           --guard cells
            );
      
         port (
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
        m_axis_tuser : out std_logic_vector(15 downto 0)                    --_m_axis_tuser "MSB-bit" shows "object detection or noise" and the remaining bits displays its value
           
            );
            
  attribute direct_reset : string;          
  attribute direct_reset of axi_rstn : signal is "yes";          
end cfar_top;

architecture Behavioral of cfar_top is

attribute x_interface_info : string;

--master interface
ATTRIBUTE X_INTERFACE_INFO OF axi_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 axi_clk CLK";
ATTRIBUTE X_INTERFACE_INFO OF axi_rstn: SIGNAL IS "xilinx.com:signal:reset:1.0 axi_rstn RST";

attribute x_interface_info of m_axis_tdata : signal is "xilinx.com:interface:axis:1.0 Master_m_axis_tdata TDATA";      
attribute x_interface_info of m_axis_tvalid : signal is "xilinx.com:interface:axis:1.0 Master_m_axis_tdata TVALID";
attribute x_interface_info of m_axis_tready : signal is "xilinx.com:interface:axis:1.0 Master_m_axis_tdata TREADY";
attribute x_interface_info OF m_axis_tlast : signal is "xilinx.com:interface:axis:1.0 Master_m_axis_tdata TLAST";
attribute x_interface_info OF m_axis_tuser : signal is "xilinx.com:interface:axis:1.0 Master_m_axis_tdata TUSER";

--slave interface
attribute x_interface_info of s_axis_tdata : signal is "xilinx.com:interface:axis:1.0 Slave_s_axis_tdata TDATA";
attribute x_interface_info of s_axis_tvalid : signal is "xilinx.com:interface:axis:1.0 Slave_s_axis_tdata TVALID";
attribute x_interface_info of s_axis_tready : signal is "xilinx.com:interface:axis:1.0 Slave_s_axis_tdata TREADY";
attribute x_interface_info of s_axis_tlast : signal is "xilinx.com:interface:axis:1.0 Slave_s_axis_tdata TLAST"; 

---AXI CLK AND RESET 
attribute X_INTERFACE_PARAMETER : STRING;
attribute X_INTERFACE_PARAMETER of axi_clk : signal is  " XIL_INTERFACENAME axi_clk, ASSOCIATED_RESET axi_rstn, ASSOCIATED_BUSIF m_axis:s_axis";
attribute X_INTERFACE_PARAMETER of axi_rstn : signal is  " XIL_INTERFACENAME axi_rstn POLARITY ACTIVE_LOW";

constant total_ref_cells : integer := 2 * (ref_cells);

                                                
--------------------------------------------------------------------------------------------------------------new set----------------------------------------------------------    

----calc_cell_avg signals 
shared variable left_win_hg : integer range 0 to 4*ref_cells;             --left window boundary to calculate noise
shared variable right_win_min : integer range 0 to 4*ref_cells;           -- right window

----control signals                       --pipelining the control signals while doing mathematical operations
signal tval_2, tlas_2 : std_logic;
signal tval_3, tlas_3 : std_logic;
signal tval_4, tlas_4 : std_logic;


signal CUT2, CUT3, CUT4 : unsigned ((8*data_width_byte - 1) downto 0) ;          --pipelining the cell under test(CUT)

-------------noise calculation component outputs---
signal CUT2_out : unsigned ((8*data_width_byte - 1) downto 0) ;  
signal tval_2_out, tlas_2_out : std_logic;
signal overall_noise_out : unsigned(((8*data_width_byte - 1) + log2(ref_cells) + 1) downto 0);           --total noise
-------------------------


---------------output signals --------------
signal threshold_val : unsigned((overall_noise_out'length+8) downto 0);                            --calculated threshold
 


type output_stage is record                                                 --output record for (obj_det = object detection, sample_cnt = sample number, sample_value = actual sample range)
obj_det : std_logic ;
sample_cnt : integer range 0 to 2**((8*data_width_byte)/2);
sample_value : std_logic_vector((8*data_width_byte - 1)downto 0);
end record;

signal output : output_stage;

------------axi block signals---
signal transfer_flag : std_logic;
signal transfer_last : std_logic;
signal ready_buf : std_logic ;
    attribute direct_enable : string;
    attribute direct_enable of ready_buf : signal is "yes";

signal sample_cnt_width : std_logic_vector(14 downto 0);

-------buffers for output ports 
signal m_valid_i, m_last_i : std_logic := '0' ;
signal m_data_i : std_logic_vector(8*data_width_byte - 1 downto 0);  
signal m_user_i : std_logic_vector (15 downto 0); 
-----------------------------------------------------------------------------------------------------------------


begin

--   ----------- outputs
             m_axis_tlast <= m_last_i;
             m_axis_tvalid <= m_valid_i;     
             m_axis_tdata <= m_data_i;
             m_axis_tuser <= m_user_i;
             s_axis_tready <= ready_buf;
            ready_buf <= m_axis_tready or (not m_valid_i);

noise_calculation : entity work.noise_calc

generic map(
        data_width_byte => data_width_byte,
        ref_cells => ref_cells,
        guard_cells => guard_cells      
    )

port map(
    clk => axi_clk,
    rstn => axi_rstn,
    t_valid => s_axis_tvalid,
    t_ready => ready_buf,
    t_data => s_axis_tdata,
    t_last => s_axis_tlast,
    
    final_noise => overall_noise_out,
    Cell_under_test => CUT2_out,
    valid_out => tval_2_out,
    last_out => tlas_2_out
        );  


threshold_calculation : entity work.threshold_cal

generic map(
        data_width_byte => data_width_byte,
        scaling_fact => scaling_fact,
        ext_bus_width => overall_noise_out'length
            )
port map(
    clk => axi_clk,
    rstn => axi_rstn,
    ready_buf => ready_buf,
    cut_in => CUT2_out,
    tval_in => tval_2_out,
    tlas_in => tlas_2_out,
    overall_noise => overall_noise_out,
    cut_out => CUT3,
    tval_out => tval_3,
    tlas_out => tlas_3,
    final_threshold => threshold_val
        );  



detection_process : entity work.sample_detection

generic map(
    data_width_byte => data_width_byte,
        final_threshold_length => threshold_val'length,
        samples_per_packet => samples_per_packet,
        total_ref_cells => total_ref_cells
        )

port map(
    clk => axi_clk,
    rstn => axi_rstn,
    ready_buf => ready_buf,
    cut_in => CUT3,
    tval_in => tval_3,
    tlas_in => tlas_3,
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
                            m_user_i(15) <= output.obj_det;
                            m_user_i(14 downto 0) <= std_logic_vector(to_unsigned(output.sample_cnt, sample_cnt_width'length));
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
                            m_user_i(15) <= output.obj_det;
                            m_user_i(14 downto 0) <= std_logic_vector(to_unsigned(output.sample_cnt, sample_cnt_width'length));                   
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
