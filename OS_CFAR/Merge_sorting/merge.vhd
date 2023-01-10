----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2022 10:36:19 AM
-- Design Name: 
-- Module Name: merge - Behavioral
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
use IEEE.numeric_std.all;
use work.merge_sort_pkg.all;

entity merge is
    generic (
            ce_latency : integer := 0; 
            size : integer;
            data_width_me : integer := 32
                );
                
     port(
        clk : in std_logic;
        input_me : in A_vector(1 to size)(data_width_me-1 downto 0);
        output_me : out A_vector(1 to size)(data_width_me-1 downto 0)
            );           
end merge;

architecture Behavioral of merge is

  constant N:NATURAL := input_me'length;
  constant M:INTEGER := N/2-(N-1) mod 4/3; -- N/2-1 when N mod 4=0 else N/2 
  
  function EVEN(I: A_vector) return A_vector is

    constant N:NATURAL:=I'length;
    variable Result : A_vector(I'low to I'low+(N+1)/2-1)(data_width_me-1 downto 0);

  begin

    for K in Result'range loop
         
      Result(K) := I(I'low + 2*(K - Result'low));

    end loop;

    return Result;

  end;


  function ODD(I: A_VECTOR) return A_VECTOR is

    constant N:NATURAL:=I'length;  
    variable Result : A_VECTOR(I'low to I'low + N/2-1)(data_width_me-1 downto 0);
   
  begin

    for K in Result'range loop
      
      Result(K) := I(I'low + 2*(K - Result'low) + 1);

    end loop;
        
        return Result;
  end; 


begin

assert input_me'length = output_me'length report "ports must have equal length!!!" severity ERROR;

  i1:if N=1 generate

       output_me <= input_me;

     end generate; 

    
   i2 : if N = 2 generate
           cx : entity work.comp_exch 
               generic map(latency => ce_latency,
                           data_width_c => data_width_me
                           )
               port map(
                       clk => clk,
                       in_1 => input_me(input_me'low),
                       in_2 => input_me(input_me'high),
                       out_1 => output_me(output_me'low),
                       out_2 => output_me(output_me'high)
                           );                   
           
         end generate;

  i3 : if N > 2 generate
 
       signal IL,ML:A_VECTOR(input_me'low to input_me'low+(N+1)/2-1+(N+1) mod 4/3)(data_width_me-1 downto 0);
       signal IH,MH:A_VECTOR(input_me'low+(N+1)/2+(N+1) mod 4/3 to input_me'high)(data_width_me-1 downto 0);
       signal V:A_VECTOR(input_me'range)(data_width_me-1 downto 0);       
        
       begin 
        IL <= EVEN(input_me(input_me'low to input_me'high));

       lm:entity work.MERGE generic map(CE_LATENCY=>CE_LATENCY, size => IL'length, data_width_me => data_width_me)

                            port map(CLK=>CLK,
                                     input_me=>IL,
                                     output_me=>ML);
      
        IH <= ODD(input_me(input_me'low to input_me'high));


       hm:entity work.MERGE generic map(CE_LATENCY=>CE_LATENCY,size => IH'length, data_width_me => data_width_me)

                            port map(CLK=>CLK,
                                     input_me=> IH,
                                     output_me => MH);  

               V <= ML & MH;                            
              
       
       d0 : entity work.delay generic map(size => ce_latency, data_width_d => data_width_me)
        
                        port map(
                                clk => clk,
                                input_d => V(V'low to V'low),
                                output_d => output_me(output_me'low to output_me'low)
                                    );
       
       
       lk:for K in 1 to (N+1)/2-1 generate

            cx : entity work.comp_exch 
                generic map(latency => ce_latency,
                            data_width_c => data_width_me
                            )
                port map(
                        clk => clk,
                        in_1 => V(V'low+K),
                        in_2 => V(V'low+K+M),
                        out_1 => output_me(output_me'low + 2*K-1),
                        out_2 => output_me(output_me'low + 2*K)
                            ); 
            
           end generate; 
            
            
           i0:if N mod 4=0 generate 
              dl : entity work.delay generic map(size => ce_latency, data_width_d => data_width_me)
                           
                        port map(
                                clk => clk,
                                input_d => V(V'high to V'high),
                                output_d => output_me(output_me'high to output_me'high)
                                    );                        
           
           
              end generate;


       i2:if N mod 4=2 generate

            dl:entity work.DELAY generic map(size => ce_latency, data_width_d => data_width_me)

                port map(clk => clk,
                         input_d => V(V'low+M to V'low+M),
                         output_d => output_me(output_me'high to output_me'high));

          end generate;
                 
       end generate;

        

end Behavioral;

