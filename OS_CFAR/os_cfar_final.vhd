----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/25/2022 01:27:05 PM
-- Design Name: 
-- Module Name: os_cfar_final - Behavioral
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

entity os_cfar_final is
    generic(
        scaling_fact : integer range 1 to 400 := 14;            --step_size is 0.25(i.e range from 0.25 to 100)
        samples_per_packet : integer range 0 to 2**14 := 3072; 
        data_width_byte : integer range 1 to 16 := 4;      --bytes
        ref_cells : integer range 0 to 100 := 8;            --Reference cells       
        guard_cells : integer range 0 to 100 := 4            --guard cells
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
end os_cfar_final;

architecture Behavioral of os_cfar_final is

attribute x_interface_info : string;

--master interface
attribute X_INTERFACE_INFO OF axi_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 axi_clk CLK";
attribute X_INTERFACE_INFO OF axi_rstn: SIGNAL IS "xilinx.com:signal:reset:1.0 axi_rstn RST";

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

signal s_data_i : std_logic_vector((8*data_width_byte - 1) downto 0) := (others => '0'); 
signal s_valid_i,s_ready_i,s_last_i : std_logic := '0';

signal m_data_i : std_logic_vector((8*data_width_byte - 1) downto 0) := (others => '0'); 
signal m_valid_i,m_ready_i,m_last_i : std_logic := '0';
signal m_user_i : std_logic_vector(15 downto 0) := (others => '0');


begin

--process(axi_clk)
--begin
--    if rising_edge(axi_clk) then
        s_data_i <= s_axis_tdata;
        s_valid_i <= s_axis_tvalid;
        s_axis_tready <= s_ready_i;
        s_last_i <= s_axis_tlast;
        
        
        m_axis_tdata <= m_data_i;
        m_axis_tvalid <= m_valid_i;
        m_ready_i <= m_axis_tready;
        m_axis_tuser <= m_user_i;
        m_axis_tlast <= m_last_i;    
--    end if;
--end process;


os_cfar_ins : entity work.os_cfar_top

generic map(
    scaling_fact_i => scaling_fact,
    samples_per_packet_i => samples_per_packet,
    data_width_byte_i => data_width_byte,
    ref_cells_i => ref_cells,
    guard_cells_i => guard_cells
            )
            
 port map(
    axi_clk_i => axi_clk,
    axi_rstn_i => axi_rstn,
    
    s_axis_tdata_i => s_data_i,
    s_axis_tvalid_i => s_valid_i,
    s_axis_tready_i => s_ready_i,
    s_axis_tlast_i => s_last_i,
    
    m_axis_tdata_i => m_data_i,
    m_axis_tvalid_i => m_valid_i,
    m_axis_tready_i => m_ready_i,
    m_axis_tlast_i => m_last_i,
    m_axis_tuser_i => m_user_i
 );


end Behavioral;
