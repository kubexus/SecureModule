library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encrypter is
  port (
		clock:        			in std_logic;
		reset:            			in std_logic;
		start:             			in std_logic;
		stop:             			in std_logic;
		nonce:          			in std_logic_vector(95 downto 0);
		new_nonce: 			in std_logic;
		key:              				in std_logic_vector(127 downto 0);
		take:            				out std_logic;
		ciphertext:   		out std_logic_vector(127 downto 0));
		
end encrypter;

architecture arch of encrypter is

component counter 
port(
    clock: in std_logic;
	reset: in std_logic;
	start: in std_logic;
	new_nonce: in std_logic;
	output: out std_logic_vector(31 downto 0)
	);
end component;

component aes
port(
		clock :  IN  STD_LOGIC;
		reset :  IN  STD_LOGIC;
		start :  IN  STD_LOGIC;
		stop: IN STD_LOGIC;
		key :  IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		plaintext :  IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		done :  OUT  STD_LOGIC;
		ciphertext :  OUT  STD_LOGIC_VECTOR(127 DOWNTO 0)
		);
end component;


signal to_encrypt: std_logic_vector (31 downto 0);
signal some_key: std_logic_vector (127 downto 0);
signal count: std_logic;


begin
		
-- tutaj wszystkie funkcje kombinacyjne     

 
take <= count;


	
	process(clock)
	begin
		if(reset='1') then
			some_key <= key;
			
		elsif rising_edge(clock) then
			if(start='1') then
				
			
			
				
			
			
			end if;
	  	
		end if;

	end process;
	
	
licznik: counter port map (
	clock => clock,
	reset => reset,
	start => count,
	new_nonce => new_nonce,
	output => to_encrypt
);

szyfrator: aes port map (
	clock => clock,
	reset => reset,
	start => start,
	stop => stop,
	key => some_key,
	plaintext => (nonce & to_encrypt),
	done => count,
	ciphertext => ciphertext
);

end arch;