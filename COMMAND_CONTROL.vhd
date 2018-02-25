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

ENTITY COMMAND_CONTROL IS PORT
(	
	CLK	:IN STD_LOGIC;
	INIT	:IN STD_LOGIC;
	
	RS232_DRL	:IN STD_LOGIC;
	RS232_LOAD	:OUT STD_LOGIC;
	RS232_STORE	:OUT STD_LOGIC;
	RS232_DIN	:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	RS232_DOUT	:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	INT_WR		:OUT STD_LOGIC;
	INT_RD		:OUT STD_LOGIC;
	INT_ADDR		:OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	INT_DIN		:IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	INT_DOUT		:OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE COMMAND_CONTROL_ARCH OF COMMAND_CONTROL IS
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	SIGNAL	FSM 		:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
	
	CONSTANT FSM_IDLE	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
	
	CONSTANT FSM_1_1	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"01";
	CONSTANT FSM_1_2	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"02";
	CONSTANT FSM_1_2_1:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"03";
	CONSTANT FSM_1_3	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"04";
	
	CONSTANT FSM_W_1	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"11";
	CONSTANT FSM_W_2	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"12";
	CONSTANT FSM_W_3	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"13";
	CONSTANT FSM_W_4	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"14";
	CONSTANT FSM_W_4_1:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"15";
	CONSTANT FSM_W_5	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"16";
	CONSTANT FSM_W_6	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"17";
	CONSTANT FSM_W_7	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"18";
	
	CONSTANT FSM_R_1	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"21";
	CONSTANT FSM_R_2	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"22";
	CONSTANT FSM_R_3	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"23";
	CONSTANT FSM_R_4	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"24";
	CONSTANT FSM_R_4_1:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"25";
	CONSTANT FSM_R_5	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"26";
	CONSTANT FSM_R_6	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"27";
	CONSTANT FSM_R_6_1:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"28";
	CONSTANT FSM_R_7	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"29";
	CONSTANT FSM_R_8	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"2A";
	CONSTANT FSM_R_9	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"2B";
	CONSTANT FSM_R_10	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"2C";
	CONSTANT FSM_R_11	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"2D";
	
	CONSTANT FSM_DONE_1		:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"31";
	CONSTANT FSM_ERR_1		:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"32";
	CONSTANT FSM_MESSAGE_1	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"33";
	CONSTANT FSM_MESSAGE_2	:STD_LOGIC_VECTOR(7 DOWNTO 0) := X"34";

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	SIGNAL REGISTER_DIN			:STD_LOGIC_VECTOR(7 DOWNTO 0);

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	SIGNAL REGISTER_WRITE		:STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL COUNTER_WRITE			:STD_LOGIC_VECTOR(7 DOWNTO 0);

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	SIGNAL REGISTER_READ			:STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL COUNTER_READ			:STD_LOGIC_VECTOR(7 DOWNTO 0);
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----


	SIGNAL REGISTER_MESSAGE		:STD_LOGIC_VECTOR(55 DOWNTO 0);
	SIGNAL COUNTER_MESSAGE		:STD_LOGIC_VECTOR(7 DOWNTO 0);
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	SIGNAL ASCIITOBIN_IN			:STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ASCIITOBIN_OUT		:STD_LOGIC_VECTOR(3 DOWNTO 0);

	SIGNAL BINTOASCII_IN			:STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL BINTOASCII_OUT		:STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----	
	
	asciitobin_1: ENTITY WORK.ASCIITOBIN PORT MAP (
		ASCII	=> ASCIITOBIN_IN,
		BIN	=> ASCIITOBIN_OUT);
	
	bintoascii_1: ENTITY WORK.BINTOASCII PORT MAP (
		BIN	=> BINTOASCII_IN,
		ASCII	=> BINTOASCII_OUT);

	ASCIITOBIN_IN <= REGISTER_DIN;
	
	BINTOASCII_IN <= REGISTER_READ(31 DOWNTO 28);

		
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	PROCESS(CLK, INIT)
	BEGIN
		IF (INIT = '1') THEN FSM <= FSM_IDLE;
		ELSIF(CLK'EVENT AND CLK = '1') THEN
			CASE FSM IS
				WHEN FSM_IDLE		=>	IF(RS232_DRL = '1') THEN
													FSM <= FSM_1_1;
											END IF;
				
				---- ---- ---- ---- ---- ---- ---- ---- ----
				
				WHEN FSM_1_1 		=>	FSM <= FSM_1_2;
				WHEN FSM_1_2		=>	FSM <= FSM_1_2_1;
				WHEN FSM_1_2_1		=> IF (REGISTER_DIN = X"0A" OR REGISTER_DIN = X"0D" OR REGISTER_DIN = X"20") THEN
												FSM <= FSM_IDLE;
											ELSE
												FSM <= FSM_1_3;
											END IF;
				WHEN FSM_1_3		=> IF(REGISTER_DIN = X"77") THEN -- w	
												FSM <= FSM_W_1;
											ELSIF(REGISTER_DIN = X"72") THEN --r
												FSM <= FSM_R_1;
											ELSE
												FSM <= FSM_ERR_1;
											END IF;
				---- ---- ---- ---- ---- ---- ---- ---- ----
				
				WHEN FSM_W_1		=> FSM <= FSM_W_2;
				WHEN FSM_W_2		=> IF(RS232_DRL = '1') THEN
												FSM <= FSM_W_3;
											END IF;
				WHEN FSM_W_3		=> FSM <= FSM_W_4;
				WHEN FSM_W_4		=> FSM <= FSM_W_4_1;
				WHEN FSM_W_4_1		=> IF (REGISTER_DIN = X"0A" OR REGISTER_DIN = X"0D" OR REGISTER_DIN = X"20") THEN
												FSM <= FSM_W_2;
											ELSE
												FSM <= FSM_W_5;
											END IF;
				WHEN FSM_W_5		=> IF (	((unsigned(REGISTER_DIN) > 47) AND (unsigned(REGISTER_DIN) < 58)) OR 
													((unsigned(REGISTER_DIN) > 96) AND (unsigned(REGISTER_DIN) < 103))) THEN
												FSM <= FSM_W_6;
											ELSE
												FSM <= FSM_ERR_1;
											END IF;
				WHEN FSM_W_6		=> IF(COUNTER_WRITE /= X"10") THEN
												FSM <= FSM_W_2;
											ELSE
												FSM <= FSM_W_7;
											END IF;
				WHEN FSM_W_7		=> FSM <= FSM_DONE_1;
				
				---- ---- ---- ---- ---- ---- ---- ---- ----
				
				WHEN FSM_R_1		=> FSM <= FSM_R_2;
				WHEN FSM_R_2		=> IF(RS232_DRL = '1') THEN
												FSM <= FSM_R_3;
											END IF;
				WHEN FSM_R_3		=> FSM <= FSM_R_4;
				WHEN FSM_R_4		=> FSM <= FSM_R_4_1;
				WHEN FSM_R_4_1		=> IF (REGISTER_DIN = X"0A" OR REGISTER_DIN = X"0D" OR REGISTER_DIN = X"20") THEN
												FSM <= FSM_R_2;
											ELSE
												FSM <= FSM_R_5;
											END IF;
				WHEN FSM_R_5		=> IF (	((unsigned(REGISTER_DIN) > 47) AND (unsigned(REGISTER_DIN) < 58)) OR 
													((unsigned(REGISTER_DIN) > 96) AND (unsigned(REGISTER_DIN) < 103))) THEN
												FSM <= FSM_R_6;
											ELSE
												FSM <= FSM_ERR_1;
											END IF;
				WHEN FSM_R_6		=> IF(COUNTER_READ /= X"08") THEN
												FSM <= FSM_R_2;
											ELSE
												FSM <= FSM_R_6_1;
											END IF;	
				WHEN FSM_R_6_1		=> FSM <= FSM_R_7;
				WHEN FSM_R_7		=> FSM <= FSM_R_8;
				WHEN FSM_R_8		=> FSM <= FSM_R_9;
				WHEN FSM_R_9		=> FSM <= FSM_R_10;
				WHEN FSM_R_10		=> FSM <= FSM_R_11;
				WHEN FSM_R_11		=> IF(COUNTER_READ /= X"08") THEN
												FSM <= FSM_R_10;
											ELSE
												FSM <= FSM_DONE_1;
											END IF;	
				
				---- ---- ---- ---- ---- ---- ---- ---- ----
				
				WHEN FSM_DONE_1		=> FSM <= FSM_MESSAGE_1;
				WHEN FSM_ERR_1			=> FSM <= FSM_MESSAGE_1;
				WHEN FSM_MESSAGE_1	=> FSM <= FSM_MESSAGE_2;
				WHEN FSM_MESSAGE_2	=> IF(COUNTER_MESSAGE /= X"0") THEN
													FSM <= FSM_MESSAGE_1;
												ELSE
													FSM <= FSM_IDLE;
												END IF;
				
				---- ---- ---- ---- ---- ---- ---- ---- ----
				
				WHEN OTHERS => FSM <= FSM_IDLE;
				
			END CASE;
		END IF;
	END PROCESS;

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN REGISTER_DIN <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF((FSM = FSM_1_2) OR (FSM = FSM_W_4) OR (FSM = FSM_R_4)) THEN
				REGISTER_DIN <= RS232_DIN;
			END IF;
		END IF;
	END PROCESS;
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	RS232_LOAD	<= '1' WHEN (FSM = FSM_1_1) OR (FSM = FSM_W_3) OR (FSM = FSM_R_3) ELSE '0';
	RS232_STORE	<= '1' WHEN (FSM = FSM_R_10) OR (FSM = FSM_MESSAGE_1) OR (FSM = FSM_W_4_1) OR (FSM = FSM_R_4_1) OR (FSM = FSM_1_2_1) OR (FSM = FSM_R_6_1) ELSE '0';

	RS232_DOUT	<= X"20" WHEN (FSM = FSM_R_6_1) ELSE
						REGISTER_DIN WHEN (FSM = FSM_W_4_1 OR FSM = FSM_R_4_1 OR FSM = FSM_1_2_1) ELSE
						BINTOASCII_OUT WHEN (FSM = FSM_R_10) ELSE 
						REGISTER_MESSAGE(55 DOWNTO 48) WHEN (FSM = FSM_MESSAGE_1) ELSE
						(others => '0');
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN REGISTER_WRITE <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF(FSM = FSM_W_1) THEN
				REGISTER_WRITE <= (others => '0');
			END IF;
			IF(FSM = FSM_W_5) THEN
				REGISTER_WRITE <= REGISTER_WRITE(59 DOWNTO 0) & ASCIITOBIN_OUT;
			END IF;
		END IF;
	END PROCESS;

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN COUNTER_WRITE <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF(FSM = FSM_W_1) THEN
				COUNTER_WRITE <= (others => '0');
			END IF;
			IF(FSM = FSM_W_5) THEN
				COUNTER_WRITE <= std_logic_vector(unsigned(COUNTER_WRITE) + 1);
			END IF;
		END IF;
	END PROCESS;

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----

	INT_WR		<= '1' WHEN (FSM = FSM_W_7) ELSE '0';
	
	INT_ADDR		<= REGISTER_WRITE(63 DOWNTO 32) WHEN (FSM = FSM_W_7) ELSE
						REGISTER_READ(31 DOWNTO 0) WHEN (FSM = FSM_R_7) ELSE
						(others => '0');
	
	INT_DOUT		<= REGISTER_WRITE(31 DOWNTO 0) WHEN (FSM = FSM_W_7) ELSE 
						(others => '0');
	
	INT_RD		<= '1' WHEN (FSM = FSM_R_7) ELSE '0';
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN REGISTER_READ <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF(FSM = FSM_R_1) THEN
				REGISTER_READ <= (others => '0');
			END IF;
			IF(FSM = FSM_R_5 OR FSM = FSM_R_10) THEN
				REGISTER_READ <= REGISTER_READ(27 DOWNTO 0) & ASCIITOBIN_OUT;
			END IF;
			IF(FSM = FSM_R_8) THEN
				REGISTER_READ <= INT_DIN;
			END IF;
		END IF;
	END PROCESS;
	
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN COUNTER_READ <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF((FSM = FSM_R_1) OR (FSM = FSM_R_9)) THEN
				COUNTER_READ <= (others => '0');
			END IF;
			IF((FSM = FSM_R_5) OR (FSM = FSM_R_10)) THEN
				COUNTER_READ <= std_logic_vector(unsigned(COUNTER_READ) + 1);
			END IF;
		END IF;
	END PROCESS;

	---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN REGISTER_MESSAGE <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF(FSM = FSM_DONE_1) THEN
				REGISTER_MESSAGE <= X"20646f6e650d00";
			END IF;
			IF(FSM = FSM_ERR_1) THEN
				REGISTER_MESSAGE <= X"206572726f720d";
			END IF;
			IF(FSM = FSM_MESSAGE_1) THEN
				REGISTER_MESSAGE <= REGISTER_MESSAGE(47 DOWNTO 0) & X"00";
			END IF;
		END IF;
	END PROCESS;
	
	---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
	
	PROCESS(CLK, INIT)
	BEGIN
		IF(INIT = '1') THEN COUNTER_MESSAGE <= (others => '0');
		ELSIF (CLK'EVENT AND CLK = '1') THEN
			IF(FSM = FSM_DONE_1) THEN
				COUNTER_MESSAGE <= X"06";
			END IF;
			IF(FSM = FSM_ERR_1) THEN
				COUNTER_MESSAGE <= X"07";
			END IF;
			IF(FSM = FSM_MESSAGE_1) THEN
				COUNTER_MESSAGE <= std_logic_vector(unsigned(COUNTER_MESSAGE) - 1);
			END IF;
		END IF;
	END PROCESS;


END ARCHITECTURE;