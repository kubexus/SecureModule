library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  port (
		clock: in std_logic;
		reset: in std_logic;
		start: in std_logic;
		new_nonce: in std_logic;
		
		output: out std_logic_vector(31 downto 0));
end counter;

architecture arch of counter is

signal counter_value: unsigned(31 downto 0);

begin
		
-- tutaj wszystkie funkcje kombinacyjne      


	
	process(clock)
	begin
		if(reset='1') or (new_nonce='1') then
			counter_value <= (others =>'0');
		elsif rising_edge(clock) then
			if(start='1') then
				counter_value <= counter_value + 1;
			
			
				
			
			
			end if;
	  	
		end if;

	end process;

output <= std_logic_vector(counter_value);


end arch;