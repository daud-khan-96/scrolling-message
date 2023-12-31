library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ScrollingMessage is 
	port(CLOCK_50_B5B:	in std_logic; -- 50MHz clock on the board
		  GPIO:	out std_logic_vector(35 downto 0));
end entity ScrollingMessage;

architecture main of ScrollingMessage is
signal counter: unsigned(2 downto 0);
signal row_driver: std_logic_vector(0 to 7);
signal col_driver: std_logic_vector(0 to 7) := "01111111";
signal clock_1000_Hz: std_logic;
signal clock_2_Hz: std_logic;
signal counter_1000_Hz: unsigned(21 downto 0);
signal counter_2_Hz: unsigned(23 downto 0);
signal row_bits: std_logic_vector(0 to 47);
signal current_char: std_logic_vector(0 to 63);
signal shifting_counter: unsigned(2 downto 0);

constant message_length: integer := 10; -- Length of string
constant message_string: string(1 to message_length) := "VERY GOOD ";

signal one_char: character := ' ';
signal integer_one_char: integer;
signal ascii_code: std_logic_vector(6 downto 0); -- ASCII Code
signal char_pointer: unsigned(5 downto 0) := "000001"; -- Pointing to first character

begin

one_char <= message_string(to_integer(char_pointer)); -- character type w/ pointer
integer_one_char <= character'pos(one_char); --integer type
ascii_code <= std_logic_vector(to_unsigned(integer_one_char, 7)); 

counting_1000_Hz: process(CLOCK_50_B5B)
begin
	if rising_edge(CLOCK_50_B5B) then
		if counter_1000_Hz = to_unsigned(24999, 22) then
			counter_1000_Hz <= to_unsigned(0, 22);
			clock_1000_Hz <= not clock_1000_Hz;
		else
			counter_1000_Hz <= counter_1000_Hz + 1;
		end if;
	end if;
end process;

counting_10_Hz: process(CLOCK_50_B5B)
begin
	if rising_edge(CLOCK_50_B5B) then
		if counter_2_Hz = to_unsigned(6249999, 24) then
			counter_2_Hz <= to_unsigned(0, 24);
			clock_2_Hz <= not clock_2_Hz;
		else
			counter_2_Hz <= counter_2_Hz + 1;
		end if;
	end if;
end process;

switch_state: process(clock_2_Hz)
begin
	if rising_edge(clock_2_Hz) then
		if shifting_counter = to_unsigned(0, 3) then
			current_char <= current_char(8 to 63) & row_bits(0 to 7);
		elsif shifting_counter = to_unsigned(1, 3) then
			current_char <= current_char(8 to 63) & row_bits(8 to 15);
		elsif shifting_counter = to_unsigned(2, 3) then
			current_char <= current_char(8 to 63) & row_bits(16 to 23);
		elsif shifting_counter = to_unsigned(3, 3) then
			current_char <= current_char(8 to 63) & row_bits(24 to 31);
		elsif shifting_counter = to_unsigned(4, 3) then
			current_char <= current_char(8 to 63) & row_bits(32 to 39);
		end if;
		
		if shifting_counter = to_unsigned(5, 3) then
			current_char <= current_char(8 to 63) & row_bits(40 to 47);
			if char_pointer = message_length then
				char_pointer <= to_unsigned(1, 6);
			else
				char_pointer <= char_pointer + 1;
			end if;
			shifting_counter <= to_unsigned(0, 3);
		else
			shifting_counter <= shifting_counter + 1;
		end if;
	end if;
end process;

scrolling_message: process(clock_1000_Hz)
begin
	if rising_edge(clock_1000_Hz) then
		case counter is
			when to_unsigned(0, 3) =>
				row_driver <= current_char(0 to 7);
				col_driver <= "01111111";
			when to_unsigned(1, 3) => 
				row_driver <= current_char(8 to 15);
				col_driver <= "10111111";
			when to_unsigned(2, 3) =>
				row_driver <= current_char(16 to 23);
				col_driver <= "11011111";
			when to_unsigned(3, 3) =>
				row_driver <= current_char(24 to 31);
				col_driver <= "11101111";
			when to_unsigned(4, 3) =>
				row_driver <= current_char(32 to 39);
				col_driver <= "11110111";
			when to_unsigned(5, 3) =>
				row_driver <= current_char(40 to 47);
				col_driver <= "11111011";
				counter <= to_unsigned(0, 3);
			when to_unsigned(6, 3) =>
				row_driver <= current_char(48 to 55);
				col_driver <= "11111101";
			when to_unsigned(7, 3) =>
				row_driver <= current_char(56 to 63);
				col_driver <= "11111110";
		end case;
		counter <= counter + 1;
	end if;
end process;
				
row_bits <= "011111101001000010010000100100000111111000000000" when ascii_code = "1000001" else -- A (0x41)
				"111111101001001010010010100100100110110000000000"	when ascii_code = "1000010" else -- B (0x42)
				"011111001000001010000010100000100100010000000000"	when ascii_code = "1000011" else -- C (0x43)
				"111111101000001010000010100000100111110000000000"	when ascii_code = "1000100" else -- D (0x44)
				"111111101001001010010010100100101000001000000000"	when ascii_code = "1000101" else -- E (0x45)
				"111111101001000010010000100100001000000000000000"	when ascii_code = "1000110" else -- F (0x46)
				"011111001000001010001010100010100100111000000000"	when ascii_code = "1000111" else -- G (0x47)
				"111111100001000000010000000100001111111000000000"	when ascii_code = "1001000" else -- H (0x48)
				"000000001000001011111110100000100000000000000000"	when ascii_code = "1001001" else -- I (0x49)
				"000001000000001000000010000000101111110000000000"	when ascii_code = "1001010" else -- J (0x4A)
				"111111100001000000101000010001001000001000000000"	when ascii_code = "1001011" else -- K (0x4B)
				"111111100000001000000010000000100000001000000000"	when ascii_code = "1001100" else -- L (0x4C)
				"111111100100000000110000010000001111111000000000"	when ascii_code = "1001101" else -- M (0x4D)
				"111111100010000000010000000010001111111000000000"	when ascii_code = "1001110" else -- N (0x4E)
				"011111001000001010000010100000100111110000000000"	when ascii_code = "1001111" else -- O (0x4F)
				"111111101000100010001000100010000111000000000000"	when ascii_code = "1010000" else -- P (0x50)
				"011111001000001010001010100001000111101000000000"	when ascii_code = "1010001" else -- Q (0x51)
				"111111101001000010011000100101000110001000000000"	when ascii_code = "1010010" else -- R (0x52)
				"011001001001001010010010100100100100110000000000"	when ascii_code = "1010011" else -- S (0x53)
				"100000001000000011111110100000001000000000000000"	when ascii_code = "1010100" else -- T (0x54)
				"111111000000001000000010000000101111110000000000"	when ascii_code = "1010101" else -- U (0x55)
				"111110000000010000000010000001001111100000000000"	when ascii_code = "1010110" else -- V (0x56)
				"111111100000010000011000000001001111111000000000"	when ascii_code = "1010111" else -- W (0x57)
				"110001100010100000010000001010001100011000000000"	when ascii_code = "1011000" else -- X (0x58)
				"110000000010000000011110001000001100000000000000"	when ascii_code = "1011001" else -- Y (0x59)
				"100001101000101010010010101000101100001000000000"	when ascii_code = "1011010" else -- Z (0x5A)
				"011111001000101010010010101000100111110000000000"	when ascii_code = "0110000" else -- 0 (0x30)
				"000000000100001011111110000000100000000000000000"	when ascii_code = "0110001" else -- 1 (0x31)
				"010001101000101010010010100100100110000000000000"	when ascii_code = "0110010" else -- 2 (0x32)
				"010001001000001010010010100100100110110000000000"	when ascii_code = "0110011" else -- 3 (0x33)
				"000110000010100001001000111111100000100000000000"	when ascii_code = "0110100" else -- 4 (0x34)
				"111001001010001010100010101000101001110000000000"	when ascii_code = "0110101" else -- 5 (0x35)
				"001111000101001010010010100100101000110000000000"	when ascii_code = "0110110" else -- 6 (0x36)
				"100000001000111010010000101000001100000000000000"	when ascii_code = "0110111" else -- 7 (0x37)
				"011011001001001010010010100100100110110000000000"	when ascii_code = "0111000" else -- 8 (0x38)
				"011001001001001010010010100100100111110000000000"	when ascii_code = "0111001" else -- 9 (0x39)
				"000000000000000000000000000000000000000000000000"	when ascii_code = "0100000" else -- Blank (0x20)
				"000100000001000000010000000100000001000000000000"	when ascii_code = "0101101" else -- Dash (0x2D)
				"100100101001001010010010100100101001001000000000"; 							-- Error 




GPIO( 0) <= row_driver(0);	GPIO( 1) <= row_driver(0); 	-- Pin connections between GPIO port and the PCB 
GPIO( 2) <= row_driver(1);	GPIO( 3) <= row_driver(1); 
GPIO( 4) <= row_driver(2);	GPIO( 5) <= row_driver(2); 
GPIO( 6) <= row_driver(3);	GPIO( 7) <= row_driver(3); 
GPIO( 8) <= row_driver(4);	GPIO( 9) <= row_driver(4); 
GPIO(10) <= row_driver(5);	GPIO(11) <= row_driver(5); 
GPIO(12) <= row_driver(6);	GPIO(13) <= row_driver(6); 
GPIO(14) <= row_driver(7);	GPIO(15) <= row_driver(7); 

GPIO(20) <= col_driver(0);	GPIO(21) <= col_driver(0); 
GPIO(22) <= col_driver(1);	GPIO(23) <= col_driver(1); 
GPIO(24) <= col_driver(2);	GPIO(25) <= col_driver(2); 
GPIO(26) <= col_driver(3);	GPIO(27) <= col_driver(3); 
GPIO(28) <= col_driver(4);	GPIO(29) <= col_driver(4); 
GPIO(30) <= col_driver(5);	GPIO(31) <= col_driver(5); 
GPIO(32) <= col_driver(6);	GPIO(33) <= col_driver(6); 
GPIO(34) <= col_driver(7);	GPIO(35) <= col_driver(7); 
end architecture main; 				
				
				
				
				
				
				
				
				
				
				
				
