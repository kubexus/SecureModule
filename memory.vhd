library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
  port (
    clock   : in  std_logic;
	reset : in std_logic;
	write_enabled : in std_logic;
    write_address : in  integer range 1 to 11;
    read_address : in integer range 1 to 11;
    data_in  : in  std_logic_vector(127 downto 0);
    
    
    done : buffer std_logic;
    data_out : out std_logic_vector(127 downto 0)
  );
end entity memory;

architecture arch of memory is


   type ram_type is array (1 to 11) of std_logic_vector(127 downto 0);
   signal ram : ram_type;

begin

process(clock) is

  begin
  if(reset='1') then
		done <= '0';
    elsif rising_edge(clock) then
    
      if write_enabled = '1' and done ='0' then
        
        
        ram(write_address) <= data_in;
        
		
      end if;
      
      if write_address= 11 then
      done <= '1';
      end if;
      
     
	data_out <= ram(read_address);

      
    end if;
    
end process;



end architecture arch;