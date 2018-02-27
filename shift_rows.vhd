library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_rows is
  port (
        bytes : in std_logic_vector(127 downto 0);
        shifted_bytes : out std_logic_vector(127 downto 0));
end shift_rows;

architecture arch of shift_rows is
				 	 
							 
begin

shifted_bytes <= bytes(127 downto 120) &
				 bytes(87 downto 80) &
				 bytes(47 downto 40) &
				 bytes(7 downto 0) &
				 bytes(95 downto 88) &
				 bytes(55 downto 48) &
				 bytes(15 downto 8) &
				 bytes(103 downto 96) &
				 bytes(63 downto 56) &
				 bytes(23 downto 16) &
				 bytes(111 downto 104) &
				 bytes(71 downto 64) &
				 bytes(31 downto 24) &
				 bytes(119 downto 112) &
				 bytes(79 downto 72) &
				 bytes(39 downto 32);


		

end arch;