library IEEE;
use IEEE.std_logic_1164.all;

entity pzs_test is
generic (
	CCD_CLK_DIVIDER : integer, -- 50Mhz => 5Mhz :=5
										-- 50Mhz => 4.16Mhz :=6	
										-- 50Mhz => 2.5Mhz :=10
	ADC_CLK_DIVIDER  : integer,-- 50Mhz => 5Mhz :=2(3)
										-- 50Mhz => 4.16Mhz :=3
										-- 50Mhz => 2.5Mhz := 5
	CCD_COUNT_ROG : integer := 5,
	CCD_COUNT_DUM1 : integer := 33 + 3 * CCD_COUNT_ROG,
	CCD_COUNT_DATA : integer := 2048 + CCD_COUNT_DUM1,
	CCD_COUNT_DUM2 : integer := 6 + CCD_COUNT_DATA,
	
	CCD_LINES_NUMBER : integer, -- Number of lines that ccd should read
	
	START_SEQUENCE1 : std_logic_vector(11 DOWNTO 0) := "000001010011", --S
	START_SEQUENCE2 : std_logic_vector(11 DOWNTO 0) := "000001111111", --?
	START_SEQUENCE3 : std_logic_vector(11 DOWNTO 0) := "000001000001" --A
	);

port (
	---DATA---
	data_out : out std_logic_vector(11 DOWNTO 0);
	---EXTERNAL CLOCK---
	clk_in : in std_logic;  -- 50 Mhz
	---CCD---
	ccd_clk : out std_logic; -- 2.5 Mhz /clk
	rog : out std_logic; -- /rog signal
	shut : out std_logic; -- /shut signal;
	---ADC---
	adc_clk : out std_logic;
	ccd_ready : out std_logic;
	adc_data_in : in std_logic_vector(11 DOWNTO 0);
	---START TRIGGER----
	trigger_start : in std_logic
);
end entity;

architecture pzs_test of pzs_test is
-----------------
----SIGNALS------
-----------------
-------CCD-------
	signal ccd_clk_div : std_logic := '1';
	signal clk_reg : std_logic := '1'; 
	signal rog_reg : std_logic := '1'; 
	signal shut_reg : std_logic := '1';
	signal data_reg : std_logic_vector (11 DOWNTO 0);  
-------ADC--------
	signal adc_clk_div : std_logic := '1'; -- reads Vout of ccd on rising_edge
														-- gives data on negative_edge 
-----------------
-----------------
-----------------	
begin
-------CCD-------------
-- NOT because of inverted Schmitt trigger 
	clk <=  NOT clk_reg; 
	rog <=  NOT rog_reg;	
	shut <= NOT shut_reg;
-------ADC--------------
	adc_clk <= NOT adc_clk_div;
	data_out <= data_reg; 
------------------------
---CLOCK FOR CCD, ADC---
------------------------
process (clk_in)
	variable count : integer := 0; -- divider for clock
	variable ccd_freq : integer := CCD_CLK_DIVIDER;
	variable adc_freq : integer := ADC_CLK_DIVIDER;
 begin
	if rising_edge(clk_in) then
		---CCD---
		if (count = ccd_freq) then
			ccd_clk_div <= NOT ccd_clk_div;
			count := 0;
		else
			count := count + 1;
		end if;		
		---ADC---
		if (count = adc_freq) then
			adc_clk_div <= NOT adc_clk_div;
		end if;
	end if;	
end process;
------------------------
------------------------
------------------------
process (ccd_clk_div)
	variable count_rog : integer := CCD_COUNT_ROG;
	variable count_dummies1 : integer := CCD_COUNT_DUM1;
	variable count_data : integer := CCD_COUNT_DATA;
	variable count_dummies2 : integer := CCD_COUNT_DUM2;
	
	variable lines_number : integer := CCD_LINES_NUMBER;
	variable ccd_ready_reg : std_logic := '0';
	
	variable count : integer := CCD_COUNT_DUM2;
	variable line_numb : integer := CCD_LINES_NUMBER
	variable count_line : integer := CCD_LINES_NUMBER;
	variable count_start_seq : integer := 0;
	variable trigger_start_reg : std_logic := '0';
 begin
	if rising_edge(ccd_clk_div) then
		ccd_ready <= ccd_ready_reg;
		----------------
		-- ROG TIMING --
		----------------
		if (count < count_rog) then
			clk_reg <= '1';
			ccd_ready_reg := '0';
		elsif (count >= count_rog AND count < 2 * count_rog) then
			rog_reg <= '0';
		elsif (count >= 2 * count_rog AND count < 3 * count_rog) then
			rog_reg <= '1';
			count_start_seq := 0;
		-------------------------
		-- DUMMIES BEFORE DATA --
		-------------------------
		elsif (count >=  3 * count_rog AND count < count_dummies1) then
			clk_reg <= NOT clk_reg;
			if (count_start_seq < 3) then
				if (clk_reg = '0') then
					ccd_ready_reg := '1';
					count_start_seq := count_start_seq + 1;
					if (count_start_seq = 0) then
						data_out <= START_SEQUENCE1;
					elsif (count_start_seq = 1) then 
						data_out <= START_SEQUENCE2;
					elsif (count_start_seq = 2) then
						data_out <= START_SEQUENCE3;
					end if;
				else
					ccd_ready_reg := '0';
				end if;
			end if;
		-----------------
		-- DATA TIMING --
		-----------------
		elsif (count >=  count_dummies1 AND count < count_data) then
			clk_reg <= NOT clk_reg;
			data_out <= data_in;
			if (clk_reg = '0') then
				ccd_ready_reg := '1';
			else
				ccd_ready_reg := '0';
			end if;
		--------------------------
		-- DUMMIES AFTER TIMING --
		--------------------------
		elsif (count >=  count_data AND count < count_dummies2) then
			clk_reg <= NOT clk_reg;
		end if; 
		-------------------------
		---LINE NUMBER CONTROL---
		-------------------------
		if (trigger_start = '1' AND trigger_start_reg = '0') then
			count_line := 0;
			count := 0;
		elsif (count_line >= line_numb) then
			trigger_start_reg := '0';
		elsif (count_line < line_numb) then
			if (count >= count_dummies2) then
				count_line := count_line + 1;
				count := 0;
			end if;
			count := count + 1;
		end if;
	 end if; 
 end process;
end architecture;
