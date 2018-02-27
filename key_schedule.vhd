library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_schedule is
  port (
        clock: in std_logic;
        reset: in std_logic;
        start: in std_logic;
        key : in std_logic_vector(127 downto 0);
        
        round_number: out integer range 1 to 11;
        working: out std_logic := '1';
        round_key: out std_logic_vector(127 downto 0));
        
end key_schedule;

architecture arch of key_schedule is

type ARRAY_16  is ARRAY (0 to 15) of  std_logic_vector(7 downto 0);

constant rcon : ARRAY_16 :=  (X"01",X"02",X"04",X"08",X"10",X"20",X"40",X"80",X"1b",X"36",X"6c",X"d8",X"ab",X"4d",X"9a",X"2f");

component subbytes_32 
port(
    bytes    :	in  std_logic_vector(31 downto 0);
    subbed_bytes   :	out std_logic_vector(31 downto 0)
    );
end component;

signal counter: integer range 1 to 12;

signal key_in: std_logic_vector(127 downto 0);
signal key_out: std_logic_vector(127 downto 0);
signal next_key: std_logic_vector(127 downto 0);

signal first_word: std_logic_vector(31 downto 0);
signal second_word: std_logic_vector(31 downto 0);
signal third_word: std_logic_vector(31 downto 0);
signal fourth_word: std_logic_vector(31 downto 0);

signal rotted_word: std_logic_vector(31 downto 0);
signal subbed_rotted_word: std_logic_vector(31 downto 0);

signal nr_first_word: std_logic_vector(31 downto 0);
signal nr_second_word: std_logic_vector(31 downto 0);
signal nr_third_word: std_logic_vector(31 downto 0);
signal nr_fourth_word: std_logic_vector(31 downto 0);
							 
begin
		

	      
key_in <= key when counter = 1 else
		  next_key when counter /= 1;
	      

      
process(clock)
begin
    if(reset='1') then
		key_out <= (others =>'0');
		counter <= 1;
		round_number <= 1;
		working <= '1';
    elsif rising_edge(clock) then
		if(start='1') then
			
			if counter < 12 then
			key_out <= key_in;
			round_number <= counter;
			counter <= counter + 1;
			else
			working <= '0';
			end if;
			
	  	end if;
	  	
    end if;

end process;

	      
first_word(31 downto 0) <= key_out(127 downto 96);
second_word(31 downto 0) <= key_out(95 downto 64);
third_word(31 downto 0) <= key_out(63 downto 32);
fourth_word(31 downto 0) <= key_out(31 downto 0);

nr_first_word <= subbed_rotted_word xor first_word xor (rcon(counter-2) & "000000000000000000000000");
nr_second_word <= second_word xor nr_first_word;
nr_third_word <= third_word xor nr_second_word;
nr_fourth_word <= fourth_word xor nr_third_word;

next_key(127 downto 0) <=  (nr_first_word
						& nr_second_word 
						& nr_third_word 
						& nr_fourth_word);


rotted_word <= fourth_word(23 downto 16) &
               fourth_word(15 downto 8) &
               fourth_word(7 downto 0) &
               fourth_word(31 downto 24);



sub: subbytes_32 port map (
	bytes => rotted_word,
	subbed_bytes=> subbed_rotted_word
);



round_key <= key_out;	      
	      



end arch;