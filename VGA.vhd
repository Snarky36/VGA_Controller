library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity vga_controller is 
	port( clk: in std_logic;
	rst: in std_logic;
	hMoveButton: in std_logic;
	vMoveButton: in std_logic;
	hSync: out std_logic;
	vSync: out std_logic;
	rgb: out std_logic_vector (11 downto 0);
	switch_direction: in std_logic;
	rgb_button: in std_logic;
	img_button: in std_logic);
end entity;

architecture comportamental of vga_controller is

signal clk25: std_logic := '0';
constant HD: integer := 639; -- horizontal display
constant HFP: integer := 16; -- 16 right border(front porch)
constant HSP: integer := 96; -- retrace(sync pulse)
constant HBP: integer := 48; -- back porch

constant VD: integer := 479; --vertical display
constant VFP: integer := 10; -- front porch 10
constant VSP: integer := 2; --retrace(sync pulse)
constant VBP: integer := 33; -- back porch

signal hPos: integer := 0;
signal vPos: integer := 0;	
signal videoOn : std_logic := '0';

type color_matrix is array(0 to 7) of std_logic_vector(2 downto 0);
signal mem: color_matrix:=("000", "001", "010","011","100","101","110","111");

type color_matrix_12 is array(0 to 11) of std_logic_vector(11 downto 0);
signal mem12: color_matrix_12 :=("000000000000","101010111100", "101111001101", "101010101010", "101110111011", "110011001100", "110010101100", "110100111000", "101011011000", "111000000000", "110010001100","111111111111");

signal rgb_select: integer range 0 to 4095 := 0;
signal last_rgb_button: std_logic := '0';

signal img_select: integer range 0 to 4 := 0;
signal last_img_button: std_logic :='0';
signal mode: std_logic:= '0';

constant xF_square: integer := 100;
constant yF_square: integer := 100;
constant xL_square: integer := 300;
constant yL_square: integer := 300;

signal radius: integer := 20;
signal Ox: integer := 50;
signal Oy: integer := 50;

--signal hMoveButton: std_logic:='0';	 
signal last_hMoveButton: std_logic:='0';
--signal vMoveButton: std_logic:='0';
signal last_vMoveButton: std_logic:='0';
signal hMove: integer:= 0;
signal vMove: integer:= 0;

signal switch: integer:= 0;
signal lastSwitch_direction: std_logic;

begin
	clk_divider: process(clk)
		begin
			if (clk'event and clk = '1') then
				clk25 <= (not clk25);
			end if;
		end process;
	
	rgb_selection: process(rgb_button, rst)
	begin
		if(rst = '1') then
			rgb_select <= 0;
		end if;
		if(rgb_button = '1' and last_rgb_button = '0') then
	   		rgb_select <= rgb_select + 1;
		end if;
	last_rgb_button <= rgb_button;
	end process;
	
	image_selection: process(img_button, rst)
	begin
		if(rst = '1') then
			img_select <= 0;
		end if;
		if(img_button = '1' and last_img_button = '0') then
	   		img_select <= img_select + 1;
		end if;
		if(img_select >= 4) then
			img_select <= 0;
	end if;
	last_img_button <= img_button;
	end process;
	
	Horizontal_Counter: process(clk, rst)
	begin	
		if(rst = '1') then 
			hPos <= 0;	
		elsif (clk'event and clk = '1' and clk25 = '1') then
			if (hPos = (HD + HFP + HSP + HBP)) then
				hPos <= 0;
			else 
				hPos <= hPos  + 1;
			end if;
		end if;
	end process;  

	Vertical_Counter: process(clk, rst, hPos)
	begin	
		if(rst = '1' ) then 
			vPos <= 0;	
		elsif (clk'event and clk = '1' and clk25 = '1') then
			if(hPos = (HD + HFP + HSP + HBP)) then
				if (vPos = (VD + VFP + VSP + VBP)) then
					vPos <= 0;
				else 
					vPos <= vPos  + 1;
				end if;
			end if;
		end if;
	end process;
	
	Horizontal_Sync: process(clk,rst,hPos)
	begin	
		if(rst = '1') then 
			hSync <= '0';	
		elsif (clk'event and clk ='1' and clk25 = '1') then
			if ((hPos <= (HD + HFP)) or (hPos > (HD + HFP + HSP))) then
				hSync <= '1';
			else
				hSync <= '0';
		end if;
		end if;
	end process;
	
	Vertical_Sync: process(clk ,rst,vPos)
	begin
		if(rst = '1') then 
			vSync <= '0';	
		elsif (clk'event and clk = '1' and clk25 = '1') then
			if ((vPos <= (VD + VFP)) or (vPos > (VD + VFP + VSP))) then
				vSync <= '1';
			else
				vSync <= '0';
		end if;	
		end if;		
	end process;
	video_on: process(clk,rst,vPos,hPos)
	begin	
		if(rst = '1') then 
			videoOn <= '0';	
		elsif (clk'event and clk = '1' and clk25 = '1') then
			if (hPos <= HD and vPos <= VD) then
				videoOn <= '1';
			else
				videoOn <= '0';
				
		end if;
		end if;
	end process;
	
	isSwitchPressed: process(switch_direction, rst)
	begin
		if(rst = '1') then
			switch <= 0;
		end if;
			if(switch_direction = '1' and lastSwitch_direction ='0') then
				switch <= -1;
			else 
				switch <= 1;
			end if;
			lastSwitch_direction <= switch_direction;
	end process;
	
	move_h: process(hMoveButton, switch, hPos, rst)
	begin
		if(rst = '1') then
			hMove <= 0;
		end if;
		if(hMoveButton = '1' and last_hMoveButton ='0')	then
			if(switch = 1) then
				hMove <= hMove + 10;
			else
				hMove <= hMove - 10;
			end if;
			if(hMove + hPos >= HD + HFP + HSP + HBP) then
				hMove <= hMove;
			end if;
			if(hPos - hMove <= 0 and hPos > 100) then
				hMove <= hMove;
			end if;
		end if;
		last_hMoveButton <= hMoveButton;
	end process;
	
	
	move_v: process(vMoveButton, switch, vPos, rst)
	begin
		if(rst = '1') then
			vMove <= 0;
		end if;
		if(vMoveButton = '1' and last_vMoveButton ='0')	then
			if(switch = 1) then
				vMove <= vMove + 10;
			else
				vMove <= vMove - 10;
			end if;
			if(vMove + vPos >= VD + VFP + VSP + VBP)then
				vMove <= vMove;
			end if;
			if(vPos - vMove < 0 and vPos > 50) then
				vMove <= vMove;
			end if;
		end if;
		last_vMoveButton <= vMoveButton;
	end process;
	
	
	draw: process(clk, rst, vPos, hPos, img_select, mem, rgb_select)
	--variable auxiliar_vPos: integer:= vPos;
	--variable auxiliar_hPos:	integer:= hPos;
	begin	
		if(rst = '1') then 
			rgb <= mem12(0);	
		elsif (clk'event and clk = '1' and clk25 = '1') then
			if (videoOn = '1') then
				if (img_select = 0) then
					if ((hPos >= xF_square + hMove  and hPos <= xL_square + hMove) and (vPos >= yF_square + vMove and vPos <= yL_square + vMove)) then 	--dreptunghi
						rgb <= mem12(rgb_select);
					else
						rgb <=mem12(0);
				end if;
				elsif(img_select = 1) then
					if ((hPos >= xF_square + hMove and hPos <=xL_square-200 + hMove) and (vPos >= yF_square + vMove and vPos <=yL_square-200 + vMove)) then	--patrat
						rgb <=mem12(rgb_select);
					else
						rgb <=mem12(0);
				end if;
				elsif(img_select = 2) then
					if ((hPos >= xF_square + hMove and hPos <=xL_square + hMove) and (vPos >= yF_square + vMove and vPos <=yL_square + vMove)) then --triunghi trebuie modificat
						if (vPos + hMove <= hPos + vMove) then
							rgb <= mem12(rgb_select);
						else 
							rgb <= mem12(0);
						end if;
					else
						rgb <=mem12(0);
				end if;
				else 
					if ((vPos >= (Oy + vMove - radius)) and (vPos <= (Oy + vMove + radius))) then  --cerc trebuie modficat
						if ((hPos >= (Ox + hMove - radius)) and (hPos <= (Ox + hMove + radius))) then
							if ((vPos - Oy + vMove)*(vPos - Oy + vMove) + (hPos - Ox + hMove)*(hPos - Ox + hMove) <= radius*radius) then
								rgb <= mem12(rgb_select);	
							else
								rgb <= mem12(0);
							end if;
						else 
							rgb <= mem12(0);
						end if;
					else
						rgb <=mem12(0);
				end if;
				end if;		
			else
				rgb <= mem12(0); 
		end if;	--elsif
		end if; --rst
	end process;
end comportamental;
	
