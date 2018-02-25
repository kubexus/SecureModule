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

PACKAGE RS232_INTERFACE_PKG IS
	CONSTANT MEM_SIZE			:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"80";
	CONSTANT BIT_RATE_VAL	:STD_LOGIC_VECTOR(15 DOWNTO 0) := X"01B0"; --50 MHz 115200bps
	--CONSTANT BIT_RATE_VAL	:STD_LOGIC_VECTOR(15 DOWNTO 0) := X"1456"; --50 MHz 9600bps
END;