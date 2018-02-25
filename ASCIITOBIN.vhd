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

ENTITY ASCIITOBIN IS PORT
(	
	ASCII	:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	BIN	:OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
);
END ENTITY;


ARCHITECTURE ASCIITOBIN_ARCH OF ASCIITOBIN IS
		
BEGIN
		
	WITH ASCII SELECT
	BIN <=	B"0000" WHEN X"30",
				B"0001" WHEN X"31",
				B"0010" WHEN X"32",
				B"0011" WHEN X"33",
				B"0100" WHEN X"34",
				B"0101" WHEN X"35",
				B"0110" WHEN X"36",
				B"0111" WHEN X"37",
				B"1000" WHEN X"38",
				B"1001" WHEN X"39",
				B"1010" WHEN X"61",
				B"1011" WHEN X"62",
				B"1100" WHEN X"63",
				B"1101" WHEN X"64",
				B"1110" WHEN X"65",
				B"1111" WHEN OTHERS;
				
END ARCHITECTURE;