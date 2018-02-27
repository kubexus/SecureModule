-- Copyright (C) 1991-2010 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II"
-- VERSION		"Version 9.1 Build 304 01/25/2010 Service Pack 1 SJ Web Edition"
-- CREATED		"Tue Feb 20 19:57:26 2018"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY aes IS 
	PORT
	(
		clock :  IN  STD_LOGIC;
		reset :  IN  STD_LOGIC;
		start :  IN  STD_LOGIC;
		stop: IN STD_LOGIC;
		key :  IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		plaintext :  IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		
		done :  OUT  STD_LOGIC;
		ciphertext :  OUT  STD_LOGIC_VECTOR(127 DOWNTO 0)
	);
END aes;

ARCHITECTURE bdf_type OF aes IS 

COMPONENT key_schedule
	PORT(clock : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 start : IN STD_LOGIC;
		 key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		 working : OUT STD_LOGIC;
		 round_key : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
		 round_number : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT aes_core
	PORT(clock : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 start : IN STD_LOGIC;
		 plaintext : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		 round_key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		 stop: in std_logic;
		 done : OUT STD_LOGIC;
		 ciphertext : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
		 round_number : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT memory
	PORT(clock : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 
		 write_enabled : IN STD_LOGIC;
		 data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		 read_address : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 write_address : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 done : OUT STD_LOGIC;
		 data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC_VECTOR(127 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC_VECTOR(127 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC_VECTOR(3 DOWNTO 0);


BEGIN 



b2v_inst : key_schedule
PORT MAP(clock => clock,
		 reset => reset,
		 start => start,
		 key => key,
		 working => SYNTHESIZED_WIRE_2,
		 round_key => SYNTHESIZED_WIRE_3,
		 round_number => SYNTHESIZED_WIRE_5);


b2v_inst1 : aes_core
PORT MAP(clock => clock,
		 reset => reset,
		 start => SYNTHESIZED_WIRE_0,
		 plaintext => plaintext,
		 round_key => SYNTHESIZED_WIRE_1,
		 stop => stop,
		 done => done,
		 ciphertext => ciphertext,
		 round_number => SYNTHESIZED_WIRE_4);


b2v_inst8 : memory
PORT MAP(clock => clock,
		 reset => reset,
		 
		 write_enabled => SYNTHESIZED_WIRE_2,
		 data_in => SYNTHESIZED_WIRE_3,
		 read_address => SYNTHESIZED_WIRE_4,
		 write_address => SYNTHESIZED_WIRE_5,
		 done => SYNTHESIZED_WIRE_0,
		 data_out => SYNTHESIZED_WIRE_1);


END bdf_type;