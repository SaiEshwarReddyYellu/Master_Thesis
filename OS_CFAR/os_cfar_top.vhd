----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2023 11:46:37 AM
-- Design Name: 
-- Module Name: os_cfar_top - Behavioral
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
use ieee.numeric_std.all;
use work.merge_sort_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity os_cfar_top is
    generic(
        scaling_fact_i : integer;            --step_size is 0.25(i.e range from 0.25 to 100)
        samples_per_packet_i : integer; 
        data_width_byte_i : integer;      --bytes
        ref_cells_i : integer;            --Reference cells
        guard_cells_i : integer            --guard cells
            );
            
    port (
        axi_clk_i : in std_logic;
        axi_rstn_i : in std_logic;
        
        s_axis_tdata_i : in std_logic_vector((8*data_width_byte_i - 1) downto 0);          --AXI Slave Stream
        s_axis_tvalid_i : in std_logic;
        s_axis_tready_i : out std_logic;
        s_axis_tlast_i : in std_logic;
        
        m_axis_tdata_i : out std_logic_vector((8*data_width_byte_i - 1) downto 0);           --AXI Master Stream           --extra "16" bits for obj_detection and sample_cnt value
        m_axis_tvalid_i : out std_logic;
        m_axis_tready_i : in std_logic;
        m_axis_tlast_i : out std_logic;
        m_axis_tuser_i : out std_logic_vector(15 downto 0)                    --_m_axis_tuser "MSB-bit" shows "object detection or noise" and the remaining bits displays its value 
           
            );
end os_cfar_top;

architecture Behavioral of os_cfar_top is


------------constants declaration --------------------------

constant total_ref_cells : integer := 2 * (ref_cells_i);
constant kth_value : integer :=  (3*2*ref_cells_i)/4;             ---k=3/4(window size)


-----------------------constants declaration end------------


--------------------type declaration -----------------------
type output_stage is record                                                 --output record for (obj_det = object detection, sample_cnt = sample number, sample_value = actual sample range)
obj_det : std_logic ;
sample_cnt : integer range 0 to 2**((8*data_width_byte_i)/2);
sample_value : A((8*data_width_byte_i - 1)downto 0);
end record;

type buffer_array is array(natural range <>) of std_logic;  

--------------------type declaration end-----------------------

-------------------function declaration -----------------------
function array_to_unsign(array_in : A_vector) return A;
function unsign_to_array(buf_in : A) return A_vector; 
function logn( i : integer) return integer;

-----function bodies --------------

function array_to_unsign(array_in : A_vector) return A is

variable left_win_hg : integer range 0 to 4*ref_cells_i;            --left window boundary to calculate noise
variable right_win_min : integer range 0 to 4*ref_cells_i;           -- right window

variable samples_left : A (8*data_width_byte_i*ref_cells_i-1 downto 0);
variable samples_right : A (8*data_width_byte_i*ref_cells_i-1 downto 0);  

begin
left_win_hg := (ref_cells_i-1); 
right_win_min := (ref_cells_i + (2*guard_cells_i)+1);


     for i in 0 to (ref_cells_i-1) loop                  --left window
       samples_left((i * (8*data_width_byte_i) + 8*data_width_byte_i-1) downto (i*8*data_width_byte_i)) := array_in(i);
       samples_right((i * (8*data_width_byte_i) + 8*data_width_byte_i-1) downto (i*8*data_width_byte_i)) := array_in(i + right_win_min); 
    end loop; 
               
   return samples_left & samples_right;
   
end function array_to_unsign;

------------function from std logic vector to array ---
function unsign_to_array(buf_in : A) return A_vector is
variable input_buf : A((8*data_width_byte_i * 2*ref_cells_i) -1 downto 0);
variable output_array : A_vector(0 to (2*ref_cells_i)-1)(8*data_width_byte_i-1 downto 0);

begin
    
    input_buf := buf_in;
        
        for i in 0 to (2*ref_cells_i)-1 loop
        output_array(i) :=  input_buf(i * (8*data_width_byte_i) + 8*data_width_byte_i-1 downto (i*8*data_width_byte_i));        
        end loop;
    return output_array;
    
end function unsign_to_array;

function logn( i : integer) return integer is
    constant n : integer := 10;
    variable temp :std_logic_vector(n-1 downto 0);
    variable ret_val : integer := 0; 
  begin 
     temp := std_logic_vector(to_unsigned(i,temp'length));             
    for i in temp'low to temp'high loop
            if temp(i) = '1' then
                ret_val := ret_val+1;
            end if;
    end loop;
    return ret_val;
end function;
-------------------functions declaration end -----------------------

--------------------------signal declaration ------------------
signal tval_1, tlas_1 : std_logic := '0';
signal tval_2, tlas_2 : std_logic := '0';
signal tval_3, tlas_3 : std_logic := '0';
signal tval_4, tlas_4 : std_logic := '0';

signal CUT1, CUT2, CUT3, CUT4: A ((8*data_width_byte_i - 1) downto 0) := (others => '0') ;          -- cell under test(CUT)


signal output : output_stage := ('0',0, (others => '0'));               ---record

------array logic signal
signal samples : A_vector(0 to 2*(ref_cells_i + guard_cells_i))((8*data_width_byte_i - 1) downto 0);     -- to create odd no. of samples in the array 
signal new_sample : A ((8*data_width_byte_i - 1) downto 0)  := (others => '0'); 

signal valid_buf, last_buf : buffer_array(0 to (ref_cells_i + guard_cells_i + 1)) := (others => '0'); 

--even-odd-merge sorting---------
signal merge_sort_in : A_vector(1 to total_ref_cells)((8*data_width_byte_i - 1) downto 0) := (others => (others => '0'));
signal merge_sort_out : A_VECTOR(1 to total_ref_cells)((8*data_width_byte_i - 1) downto 0):= (others => (others => '0'));
signal threshold_val : A((CUT1'length+8) downto 0) := (others => '0');                             --calculated threshold 


-------- Even-odd transition sort algorithm signals-----------
signal samples_buf : A((8*data_width_byte_i * 2*ref_cells_i) -1 downto 0) := (others => '0');        --without CUT & guard cells
signal sorted_buf : A((8*data_width_byte_i * 2*ref_cells_i) -1 downto 0) := (others => '0');  
signal sorted_array : A_vector(0 to (2*ref_cells_i)-1)((8*data_width_byte_i - 1) downto 0) := (others => (others => '0'));


------------------------------after sorting "kth sample" and that particular "CUT" signals-----------------
signal CUT5,CUT6 : A ((8*data_width_byte_i - 1) downto 0) := (others => '0') ;  
signal kth_sample_after_sort : A ((8*data_width_byte_i - 1) downto 0) := (others => '0') ;  
signal tval_5, tlas_5 : std_logic := '0';
signal tval_6, tlas_6 : std_logic := '0';

--axi block signals------------------------------
signal ready_buf : std_logic ;
        attribute direct_enable : string;
        attribute direct_enable of ready_buf : signal is "yes";

signal transfer_flag : std_logic := '0';
signal transfer_last : std_logic := '0';
signal sample_cnt_width : A(14 downto 0) := (others => '0');


------------------buffers for output ports ------------------------
signal m_valid_i, m_last_i : std_logic := '0';
signal m_data_i : A(8*data_width_byte_i - 1 downto 0) := (others => '0');  
signal m_user_i : A (15 downto 0) := (others => '0'); 
--------------------------signal declaration end ------------------


begin


---outputs
      m_axis_tlast_i <= m_last_i;
      m_axis_tvalid_i <= m_valid_i;     
      m_axis_tdata_i <= m_data_i;
      m_axis_tuser_i <= m_user_i;     
      s_axis_tready_i <= ready_buf;
      
      ready_buf <= m_axis_tready_i or (not m_valid_i);

array_logic : process(axi_clk_i)
begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            samples <= (others => (others => '0'));
            valid_buf <=(others => '0');
            last_buf <= (others => '0');
            new_sample <= (others => '0');
            
            else

                 if  (s_axis_tvalid_i = '1') and (ready_buf = '1') then                                                     -- based on valid signal samples are converted into integer and stored in array
                     new_sample <= s_axis_tdata_i;
                     samples <= new_sample & samples(0 to (2*(ref_cells_i + guard_cells_i))-1);        -- right shifting the new sample  
   
 
 
                    ----- cntrl logic pipelining 
                    valid_buf(0) <= s_axis_tvalid_i;
                    last_buf(0) <= s_axis_tlast_i;  

                    for i in 1 to (ref_cells_i + guard_cells_i + 1) loop
                        valid_buf(i) <= valid_buf(i-1);
                        last_buf(i) <= last_buf(i-1);                         
                    end loop; 
                end if;
                
                if (s_axis_tvalid_i = '0')and (ready_buf = '1') then 
                    new_sample <= (others => '0');
                    samples <= new_sample & samples(0 to (2*(ref_cells_i + guard_cells_i))-1);        -- right shifting the new sample 
                     
                    ----- cntrl logic pipelining 
                    valid_buf(0) <= s_axis_tvalid_i;
                    last_buf(0) <= s_axis_tlast_i;  

                    for i in 1 to (ref_cells_i + guard_cells_i + 1) loop
                        valid_buf(i) <= valid_buf(i-1);
                        last_buf(i) <= last_buf(i-1);                         
                    end loop; 
                end if; 
            
        
        end if;     
    end if;

end process array_logic;



odd_even_merge_sort_algorithm : if logn(total_ref_cells) = 1 generate

constant total_latency: integer := MERGE_LATENCY(total_ref_cells,1) + SORT_LATENCY(total_ref_cells,1);          ---even-odd-merge-sorting-algm latency
signal sort_valid_buf, sort_last_buf : buffer_array(0 to (total_latency-1)) := (others => '0');     
signal CUT_buf : A_vector(0 to total_latency-1)((8*data_width_byte_i - 1) downto 0) := (others => (others => '0'));
signal kth_sample : A ((8*data_width_byte_i - 1) downto 0) :=(others => '0') ;       --selected kth sample (x(k)) 
signal kth_sample_buf : A ((8*data_width_byte_i - 1) downto 0) :=(others => '0') ;       --selected kth sample (x(k)) 

begin


sorting_algorithm_begin : process(axi_clk_i)
----calc_cell_avg signals 

begin

    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT1 <= (others => '0');
            tval_1 <= '0';
            tlas_1 <= '0';
            
            merge_sort_in <= (others => (others => '0'));
            
            else
                case ready_buf is 
                    when '1' => 
                        cut1 <=  samples(ref_cells_i + guard_cells_i);
                        tval_1 <= valid_buf(ref_cells_i + guard_cells_i + 1); 
                        tlas_1 <= last_buf(ref_cells_i + guard_cells_i + 1);
                        merge_sort_in <= samples(0 to ref_cells_i - 1) & samples(2*guard_cells_i + ref_cells_i + 1 to samples'high);  
                   when others => 
                        CUT1 <= cut1;
                        tval_1 <= tval_1;
                        tlas_1 <= tlas_1;
                        merge_sort_in <= merge_sort_in;                   
                end case;

        end if;
    end if;
end process sorting_algorithm_begin;

even_odd_merge_sorting_ins : entity work.merge_sort_top 
    generic map(
            size => total_ref_cells,
            data_width => (8*data_width_byte_i)
                    )
    
    port map(
        clk => axi_clk_i,
        ready_buf => ready_buf,
        input => merge_sort_in,
        output => merge_sort_out
                );


pipeline_for_sorting : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT_buf <= (others => (others => '0'));
            sort_valid_buf <= (others => '0');
            sort_last_buf <= (others => '0');
            
            else
                
                case ready_buf is 
                    
                    when '1' =>
                         CUT_buf(0) <= CUT1;
                         sort_valid_buf(0) <= tval_1;
                         sort_last_buf (0) <= tlas_1;  
                         
                         for i in 1 to (total_latency-1) loop
                           CUT_buf(i) <= CUT_buf(i-1); 
                           sort_valid_buf(i) <= sort_valid_buf(i-1);
                           sort_last_buf(i) <= sort_last_buf(i-1);                         
                         
                         end loop;  
                    
                    when others => 
                        
                        CUT_buf <= CUT_buf;
                        sort_valid_buf <= sort_valid_buf;
                        sort_last_buf <= sort_last_buf;
                end case;
        end if;
    end if;
end process pipeline_for_sorting;


order_static_selection : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT2 <= (others => '0');
            tval_2 <= '0';
            tlas_2 <= '0';  
          
            else
                case ready_buf is 
                
                    when '1' =>
                        CUT2 <= CUT_buf(CUT_buf'high);
                        tval_2 <= sort_valid_buf(sort_valid_buf'high);
                        tlas_2 <= sort_last_buf(sort_last_buf'high);
                       
                    when others => 
                        CUT2 <= CUT2;
                        tval_2 <= tval_2;
                        tlas_2 <= tlas_2;

                end case;                    
            
        end if;
    end if;
end process order_static_selection;


kth_sample_selection : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT3 <= (others => '0');
            CUT4 <= (others => '0');
            tval_3 <= '0';
            tlas_3 <= '0';
            tval_4 <= '0';
            tlas_4 <= '0';
            kth_sample <= (others => '0');
            kth_sample_buf <= (others => '0');
            
            else      
     
                 case ready_buf  is 
                     when '1' =>
                            tval_3 <= tval_2;
                            tlas_3 <= tlas_2;                  
                            CUT3 <= CUT2;
                            kth_sample_buf <= merge_sort_out(kth_value-1);  
                            
                            CUT4 <= CUT3;
                            tval_4 <= tval_3;
                            tlas_4 <= tlas_3;
                            kth_sample <= kth_sample_buf;
                            
                    when others => 
                            tval_3 <= tval_3;
                            tlas_3 <= tlas_3;
                            CUT3 <= CUT3;
                            
                            tval_4 <= tval_4;
                            tlas_4 <= tlas_4;
                            CUT4 <= CUT4;
                            kth_sample_buf <= kth_sample_buf;
                            kth_sample <= kth_sample;
                    end case;

                
        end if;
    end if;
    
end process kth_sample_selection;



output_satge_for_merge_sort : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT5 <= (others => '0');
            tval_5 <= '0';
            tlas_5 <= '0';  
            kth_sample_after_sort <= (others => '0');
            
            else
                case ready_buf is 
                
                    when '1' =>
                        CUT5 <= CUT4;
                        tval_5 <= tval_4;
                        tlas_5 <= tlas_4;
                        kth_sample_after_sort <= kth_sample;
                        
                    when others => 
                        CUT5 <= CUT5;
                        tval_5 <= tval_5;
                        tlas_5 <= tlas_5;
                        kth_sample_after_sort <= kth_sample_after_sort;
                        
                end case;                    
            
        end if;
    end if;

end process output_satge_for_merge_sort;


end generate;



even_odd_transition_sorting_algorithm : if logn(total_ref_cells) /= 1 generate 

constant total_latency: integer := (2*ref_cells_i + ref_cells_i);          ---even-odd-merge-sorting-algm latency
signal sort_valid_buf, sort_last_buf : buffer_array(0 to (total_latency-1)) := (others => '0');     
signal CUT_buf : A_vector(0 to total_latency-1)((8*data_width_byte_i - 1) downto 0) := (others => (others => '0'));
signal kth_sample : A ((8*data_width_byte_i - 1) downto 0) :=(others => '0') ;       --selected kth sample (x(k)) 

begin


sorting_algorithm_begin : process(axi_clk_i)
----calc_cell_avg signals 

begin

    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT1 <= (others => '0');
            tval_1 <= '0';
            tlas_1 <= '0';
            samples_buf <= (others => '0');
            
            else
                if (ready_buf = '1') then         ---if sort flag is removed, junction temp exceeds to 457 degrees
                     CUT1 <= samples(ref_cells_i + guard_cells_i); 
                     tval_1 <= valid_buf(ref_cells_i + guard_cells_i + 1); 
                     tlas_1 <= last_buf(ref_cells_i + guard_cells_i + 1);  
                     samples_buf <= array_to_unsign(samples);           ---converts array to unsigned vector          
                end if;
                
                if ((ready_buf = '1') and valid_buf(ref_cells_i + guard_cells_i + 1) = '1') then 
                     samples_buf <= array_to_unsign(samples);           ---converts array to unsigned vector 
                     elsif (tval_1 = '0') then 
                     samples_buf <= (others => '0');
                end if;
        end if;
    end if;
end process sorting_algorithm_begin;

Even_odd_transition_algm_ins : entity work.complete_sorter
    generic map(
            m => 8*data_width_byte_i,
            n => 2*ref_cells_i
                )
    
    port map(
            clk => axi_clk_i,
            ready_buf => ready_buf,
            input_array => samples_buf,
            output_array => sorted_buf);

pipeline_for_sorting : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT_buf <= (others => (others => '0'));
            sort_valid_buf <= (others => '0');
            sort_last_buf <= (others => '0');
            
            else
 
                if ready_buf = '1' then
                     CUT_buf(0) <= CUT1;
                     sort_valid_buf(0) <= tval_1;
                     sort_last_buf (0) <= tlas_1;
                     
                    for i in 1 to (total_latency-1) loop
                       CUT_buf(i) <= CUT_buf(i-1); 
                       sort_valid_buf(i) <= sort_valid_buf(i-1);
                       sort_last_buf(i) <= sort_last_buf(i-1);                         
                   end loop; 
                    
                
                end if;
        end if;
    end if;
    
end process pipeline_for_sorting;

order_static_selection : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
             CUT2 <= (others => '0');
             tval_2 <= '0';
             tlas_2 <= '0';
             sorted_array <= (others => (others => '0'));
             
             else
                if ready_buf = '1' then
                    CUT2 <= CUT_buf(CUT_buf'high);             
                    tval_2 <= sort_valid_buf(sort_valid_buf'high);
                    tlas_2 <= sort_last_buf(sort_last_buf'high);
                    sorted_array <= unsign_to_array(sorted_buf);
                end if;
        end if;
    end if;
    
end process order_static_selection;

kth_sample_selection : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT3 <= (others => '0');
            CUT4 <= (others => '0');
            tval_3 <= '0';
            tlas_3 <= '0';
            tval_4 <= '0';
            tlas_4 <= '0';
            kth_sample <= (others => '0');
            
            else      
     
                 case ready_buf  is 
                     when '1' =>
                            tval_3 <= tval_2;
                            tlas_3 <= tlas_2;                  
                            CUT3 <= CUT2;
                            tval_4 <= tval_3;
                            tlas_4 <= tlas_3;                  
                            CUT4 <= CUT3;
                            kth_sample <= sorted_array(kth_value-1);  
           
                    when others => 
                            tval_3 <= tval_3;
                            tlas_3 <= tlas_3;
                            CUT3 <= CUT3;
                            tval_4 <= tval_4;
                            tlas_4 <= tlas_4;                  
                            CUT4 <= CUT4;
                            kth_sample <= kth_sample;
                    end case;

                
        end if;
    end if;
    
end process kth_sample_selection;

output_satge_for_transition_sort : process(axi_clk_i)

begin
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
            CUT5 <= (others => '0');
            tval_5 <= '0';
            tlas_5 <= '0';  
            kth_sample_after_sort <= (others => '0');
            
            else
                case ready_buf is 
                
                    when '1' =>
                        CUT5 <= CUT4;
                        tval_5 <= tval_4;
                        tlas_5 <= tval_4;
                        kth_sample_after_sort <= kth_sample;
                        
                    when others => 
                        CUT5 <= CUT5;
                        tval_5 <= tval_5;
                        tlas_5 <= tlas_5;
                        kth_sample_after_sort <= kth_sample_after_sort;
                        
                end case;                    
            
        end if;
    end if;

end process output_satge_for_transition_sort;


end generate;





threshold_calculation : entity work.threshold_cal

generic map(
        data_width_byte => data_width_byte_i,
        scaling_fact => scaling_fact_i,
        ext_bus_width => s_axis_tdata_i'length
            )
port map(
    clk => axi_clk_i,
    rstn => axi_rstn_i,
    ready_buf => ready_buf,
    cut_in => CUT5,
    tval_in => tval_5,
    tlas_in => tlas_5,
    overall_noise => unsigned(kth_sample_after_sort),
    cut_out => CUT6,
    tval_out => tval_6,
    tlas_out => tlas_6,
    final_threshold => threshold_val
        );  

detection_process : entity work.sample_detection

generic map(
    data_width_byte => data_width_byte_i,
        final_threshold_length => threshold_val'length,
        samples_per_packet => samples_per_packet_i,
        total_ref_cells => total_ref_cells
        )

port map(
    clk => axi_clk_i,
    rstn => axi_rstn_i,
    ready_buf => ready_buf,
    cut_in => CUT6,
    tval_in => tval_6,
    tlas_in => tlas_6,
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
            
process(axi_clk_i, axi_rstn_i,s_axis_tvalid_i,transfer_flag,transfer_last,ready_buf, output)

begin  
    
    if rising_edge(axi_clk_i) then
        if axi_rstn_i = '0' then
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
                             
                        if (s_axis_tvalid_i = '1') and (ready_buf = '1')  then
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
