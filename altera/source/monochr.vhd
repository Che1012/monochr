library IEEE;
use IEEE.std_logic_1164.all;

entity monochr is
port (
------------------------
---------ADC------------
------------------------
	adc_clk : out std_logic;
	adc_data_in : in std_logic_vector(11 DOWNTO 0);
------------------------
----START TRIGGER-------
------------------------
	trigger_start : in std_logic;
------------------------
------CCD-PORT----------
------------------------
	clk50Mhz : in std_logic := '1';  -- 50 Mhz
	ccd_clk : out std_logic; -- 2.5 Mhz /clk
	ccd_rog : out std_logic; -- /rog signal
	ccd_shut : out std_logic; -- /shut signal;
------------------------
--------USB-PORT--------
------------------------
	usb_clk : in std_logic;
	usb_txe : in std_logic := '1';
	usb_data : out std_logic_vector(7 DOWNTO 0);
	usb_oe : out std_logic := '1';
	usb_wr : out std_logic := '1';
	usb_rd : out std_logic := '1'
);
end entity;
-------------------------
-------------------------
-------------------------
architecture monochr of monochr is
--------------------------
---USB-COMPONENT----------
--------------------------
component usb
generic (
	TIMING_MSB : integer := 0;
	TIMING_LSB : integer := 1;
	TIMING_END : integer := 2
);

port (
	clk_in : in std_logic;
	txe : in std_logic;
	ccd_ready : in std_logic;
	data_in : in std_logic_vector(11 DOWNTO 0);
	data_out : out std_logic_vector(7 DOWNTO 0);
	oe : out std_logic := '1';
	wr : out std_logic := '1';
	rd : out std_logic := '1'
);
end component;
--------------------------
---CCD-COMPONENT----------
--------------------------
component pzs_test
generic (
	CCD_CLK_DIVIDER : integer; 
										-- 50Mhz => 4.16Mhz :=2	
	ADC_CLK_DIVIDER  : integer;
										-- 50Mhz => 4.16Mhz :=1
	CCD_COUNT_EXPOSURE : integer := 10;
	CCD_COUNT_ROG_START : integer := 15;
	CCD_COUNT_ROG_END : integer := 20;
	CCD_COUNT_DUM1 : integer := 33 + 20;
	CCD_COUNT_DATA : integer := 2048 + 53;
	CCD_COUNT_DUM2 : integer := 6 + 2101;
	CCD_COUNT_END : integer := 6 + 2101 + 5;
	
	TRIGGER_ACTIVE : std_logic := '0';
	
	CCD_LINES_NUMBER : integer; -- Number of lines that ccd should read
	
	START_SEQUENCE1 : std_logic_vector(11 DOWNTO 0) := "000001010011"; --S
	START_SEQUENCE2 : std_logic_vector(11 DOWNTO 0) := "000001111111"; --?
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
end component;
-------------------------
--------SIGNALS----------
-------------------------
signal ccd_ready_reg : std_logic;
signal usb_data_in_reg : std_logic_vector(11 DOWNTO 0);
-------------------------
-------------------------
-------------------------
begin
-----------------------
---CCD-PORTMAP---------
-----------------------
COMP_CCD : pzs_test  generic map (CCD_CLK_DIVIDER => 2,
											 ADC_CLK_DIVIDER => 1,
											 CCD_LINES_NUMBER => 2)
							port map (data_out => usb_data_in_reg,
										 clk_in => clk50Mhz,                             
                               ccd_clk => ccd_clk,
                               rog => ccd_rog,
										 shut => ccd_shut,
                               adc_clk => adc_clk,
										 ccd_ready => ccd_ready_reg,
										 adc_data_in => adc_data_in,
                               trigger_start => trigger_start
);
-----------------------
---USB-PORTMAP---------
-----------------------
COMP_USB : usb port map (clk_in => usb_clk,
								 txe => usb_txe,
								 ccd_ready => ccd_ready_reg,
								 data_in => usb_data_in_reg,
								 data_out => usb_data,
								 oe => usb_oe,
								 wr => usb_wr,
								 rd => usb_rd
);
end architecture;