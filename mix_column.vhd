library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mix_column is
  port (
        column : in std_logic_vector(31 downto 0);
        mixed_column : out std_logic_vector(31 downto 0)
        );
end mix_column;

architecture arch of mix_column is
				 	 
signal s0, s1, s2, s3 : std_logic_vector (7 downto 0);
signal s0x2, s0x3, s1x2,s1x3, s2x2, s2x3, s3x2, s3x3 : std_logic_vector (7 downto 0);
signal ns0, ns1, ns2, ns3 : std_logic_vector (7 downto 0);

						 
begin

s0 <= column(31 downto 24);
s1 <= column(23 downto 16);
s2 <= column(15 downto 8);
s3 <= column(7 downto 0);


process (s0,s1,s2,s3)
begin
	if (s0(7) = '1') then
		s0x2 <=(s0(6 downto 0) & '0') xor x"1B";
	else
		s0x2 <= s0(6 downto 0) & '0';
	end if;
	
	if (s1(7) = '1') then
		s1x2 <=(s1(6 downto 0) & '0') xor x"1B";
	else
		s1x2 <= s1(6 downto 0) & '0';
	end if;
	
	if (s2(7) = '1') then
		s2x2 <=(s2(6 downto 0) & '0') xor x"1B";
	else
		s2x2 <= s2(6 downto 0) & '0';
	end if;
	
	if (s3(7) = '1') then
		s3x2 <=(s3(6 downto 0) & '0') xor x"1B";
	else
		s3x2 <= s3(6 downto 0) & '0';
	end if;
	
end process;

s0x3<= s0x2 xor s0;
s1x3<= s1x2 xor s1;
s2x3<= s2x2 xor s2;
s3x3<= s3x2 xor s3;
	

		ns0 <= s0x2 xor s1x3 xor s2 xor s3;
		ns1 <= s1x2 xor s2x3 xor s3 xor s0;
		ns2 <= s2x2 xor s3x3 xor s0 xor s1;
		ns3 <= s3x2 xor s0x3 xor s1 xor s2;

mixed_column <= ns0 & ns1 & ns2 & ns3;


end arch;