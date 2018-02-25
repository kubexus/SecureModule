----------------------------------
-- Łukasz DZIEŁ (883533374)     --
-- FPGACOMMEXAMPLE-v2           --
-- 01.2016                      --
-- 1.0                          --
----------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY BINTOASCII IS PORT
(	
	BIN	:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	ASCII	:OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END ENTITY;


ARCHITECTURE BINTOASCII_ARCH OF BINTOASCII IS
		
BEGIN
		
	WITH BIN SELECT
	ASCII <=	X"30"	WHEN B"0000",
				X"31"	WHEN B"0001",
				X"32"	WHEN B"0010",
				X"33"	WHEN B"0011",
				X"34"	WHEN B"0100",
				X"35"	WHEN B"0101",
				X"36"	WHEN B"0110",
				X"37"	WHEN B"0111",
				X"38"	WHEN B"1000",
				X"39"	WHEN B"1001",
				X"61"	WHEN B"1010",
				X"62"	WHEN B"1011",
				X"63"	WHEN B"1100",
				X"64"	WHEN B"1101",
				X"65"	WHEN B"1110",
				X"66"	WHEN OTHERS;
				
END ARCHITECTURE;