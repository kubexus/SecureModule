library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_core is
  port (
        clock: in std_logic;
        reset: in std_logic;
        start: in std_logic;
        round_key: in std_logic_vector(127 downto 0);
        plaintext: in std_logic_vector(127 downto 0);
        stop: in std_logic;

        round_number: out integer range 1 to 11;
        done: out std_logic;
        ciphertext: out std_logic_vector(127 downto 0));
        
end aes_core;

architecture arch of aes_core is
--tutaj wszystkie sygnaly wewnetrzne i komponenty

component subbytes_128 
port(
    bytes    :	in  std_logic_vector(127 downto 0);
    subbed_bytes   :	out std_logic_vector(127 downto 0)
    );
end component;



component shift_rows
port(
    bytes    :	in  std_logic_vector(127 downto 0);
    shifted_bytes   :	out std_logic_vector(127 downto 0)
    );
end component;


component mix_columns
port(
    bytes    :	in  std_logic_vector(127 downto 0);
    mixed_bytes   :	out std_logic_vector(127 downto 0)
    );
end component;


signal state: std_logic_vector (127 downto 0);
signal subbed_state: std_logic_vector (127 downto 0);
signal ss_state: std_logic_vector (127 downto 0);
signal mixed_state: std_logic_vector(127 downto 0);
signal counter: integer range 1 to 14;
signal ddone: std_logic;


begin
		
-- tutaj wszystkie funkcje kombinacyjne
      
process(plaintext)
begin
ddone<='1';
end process;

	      
      
process(clock)
begin
    if(reset='1') or (stop='1') then
		done <= '0';
		ciphertext <= (others=> '0');
		counter <= 1;
    elsif rising_edge(clock) then
		if(start='1') then
			
			
			
			
			
		
		
			if ddone = '1' then
			done <= '0';
			--ciphertext <= (others=> '0');
			counter <= 1;
			end if;
		
		
		
		
			if counter < 12 then
			round_number <= counter;
			end if;
			
			
			if counter < 14 then
			counter <= counter + 1;
			else
			done <= '1';
			end if;
			
		
			
			if counter = 3 then
			state <= round_key xor plaintext;
			end if;
			
			
			if counter > 3 and counter < 13 then
			state <= mixed_state xor round_key;
			
			end if;
			
			if counter = 13 then
			state <= ss_state;
			end if;
			
			if counter = 14 then
			ciphertext <= state xor round_key;
			end if;
			
		
			
			
	  	end if;
	  	
    end if;

end process;

	

sub128: subbytes_128 port map (
	bytes => state,
	subbed_bytes => subbed_state
);

shift: shift_rows port map (
	bytes => subbed_state,
	shifted_bytes => ss_state
);

mixcolumn: mix_columns port map (
	bytes => ss_state,
	mixed_bytes => mixed_state
);




end arch;