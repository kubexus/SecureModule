library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mix_columns is
  port (
        bytes : in std_logic_vector(127 downto 0);
        mixed_bytes : out std_logic_vector(127 downto 0)
        );
end mix_columns;

architecture arch of mix_columns is


component mix_column
	port(
		column : in std_logic_vector(31 downto 0);       
		mixed_column : out std_logic_vector(31 downto 0)
		);
	end component;
	
						 
begin

mix_column_0: mix_column port map(
		column => bytes(127 downto 96),
		mixed_column => mixed_bytes(127 downto 96)
	);

mix_column_1: mix_column port map(
		column => bytes(95 downto 64),
		mixed_column => mixed_bytes(95 downto 64)
	);

mix_column_2: mix_column port map(
		column => bytes(63 downto 32),
		mixed_column => mixed_bytes(63 downto 32)
	);

mix_column_3: mix_column port map(
		column => bytes(31 downto 0),
		mixed_column => mixed_bytes(31 downto 0)
	);




end arch;