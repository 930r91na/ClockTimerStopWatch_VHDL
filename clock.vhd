library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock is
    Port ( 
        clk50mz         : in STD_LOGIC;
        rst             : in STD_LOGIC;
		  rst_mode			: in STD_LOGIC;
        control         : in STD_LOGIC;
		  init_ps			: in STD_LOGIC; -- iniciar y pausar
        incrementar     : in STD_LOGIC; 
        decrementar     : in STD_LOGIC; 
        cambiar_hora    : in STD_LOGIC;
        seg_hr1         : out STD_LOGIC_VECTOR(6 downto 0); -- 7 segments for first hour display
        seg_hr2         : out STD_LOGIC_VECTOR(6 downto 0); -- 7 segments for second hour display
        seg_min1        : out STD_LOGIC_VECTOR(6 downto 0); -- 7 segments for first minute display
        seg_min2        : out STD_LOGIC_VECTOR(6 downto 0); -- 7 segments for second minute display
        seg_sec1        : out STD_LOGIC_VECTOR(6 downto 0); -- 7 segments for first second display
        seg_sec2        : out STD_LOGIC_VECTOR(6 downto 0)  -- 7 segments for second second/display AM indication
    );
end clock;


architecture arch_clock of clock is 
	-- Constants
	constant ONE_SECOND_COUNT: INTEGER := 25000000;
	signal count: INTEGER range 0 to ONE_SECOND_COUNT;
	signal clk_state: STD_LOGIC := '0'; -- Second counter
	
	constant ONE_HOUR_COUNT: INTEGER := 60; -- An hour is 60 minutes
	signal count_hour: INTEGER range 0 to ONE_HOUR_COUNT;
	constant ONE_MINUTE_COUNT: INTEGER := 60; -- An hours is 60 seconds
	signal count_minute: INTEGER range 0 to ONE_MINUTE_COUNT;
	constant TW_HOUR_COUNT: INTEGER := 12; -- An hours is 60 seconds
	signal count_half_day: INTEGER range 1 to TW_HOUR_COUNT;
	signal isAm: BOOLEAN := TRUE;
	
	-- Chrono counters 
	signal chrono_minutes: INTEGER range 0 to ONE_HOUR_COUNT - 1 := 0;
	signal chrono_seconds: INTEGER range 0 to ONE_MINUTE_COUNT - 1 := 0;
	
	
	-- Timer counters 
	signal timer_minutes: INTEGER range 0 to ONE_HOUR_COUNT - 1 := 0;
	signal timer_seconds: INTEGER range 0 to ONE_MINUTE_COUNT - 1 := 0;
	
	-- States
	type State_type is (Clock, Timer, Chronometer, Alarm);
	signal current_state, next_state: State_type;

	-- Function digit to 7 segments
	function digit_to_7seg(digit: INTEGER) return STD_LOGIC_VECTOR is
		type seg_array is array(0 to 9) of STD_LOGIC_VECTOR(6 downto 0);
		constant seg_map: seg_array := (
        "0000001", -- 0
        "1001111", -- 1
        "0010010", -- 2
        "0000110", -- 3
        "1001100", -- 4
        "0100100", -- 5
        "0100000", -- 6
        "0001111", -- 7
        "0000000", -- 8
        "0000100"  -- 9
    );
	begin
		return seg_map(digit);
	end digit_to_7seg;

	-- BEGIN OF ARCHITECTURE
	begin
	
	-- State Memory checks 1/2 each second for a change
	STATE_MEMORY: process (clk_state, rst)
	begin
      if (rst = '1') then
        current_state <= Clock;
      elsif (clk_state'event and clk_state ='1') then
			current_state <= next_state;
      end if;
	end process;
	
	-- Next State Logic
    NEXT_STATE_LOGIC: process(clk_state, rst, control)
    begin
        if rst = '1' then
            next_state <= Clock; -- Reset to Clock state
        elsif (clk_state'event and clk_state ='1') then
            if control = '1' then
                case current_state is
                    when Clock =>
                        next_state <= Timer;
                    when Timer =>
                        next_state <= Chronometer;
                    when Chronometer =>
                        next_state <= Clock;
                    when others =>
                        next_state <= Clock; -- Default or safe state
                end case;
            else
                next_state <= current_state; -- Remain in current state
            end if;
        end if;
    end process NEXT_STATE_LOGIC;
	

	-- clock that carries the seconds clk_state
	seconds : process (clk50mz, clk_state, count)
	begin
		if (clk50mz'event and clk50mz = '1') then
			if(count < ONE_SECOND_COUNT) then
				count <= count +1;
			else
				clk_state <= not clk_state;
				count <= 0;
			end if;
		end if;
	end process seconds;
	
	clock_logic : process (current_state,clk_state, cambiar_hora, incrementar, decrementar)
	begin
	----------------------------------------------------------------------------------------
												-- CLOCK MODE -- 
	----------------------------------------------------------------------------------------
	
		if current_state = Clock then	
		 if rst_mode = '1' then 
			count_hour <= 0;
			count_minute <= 0;
			count_half_day <= 12;
			isAm <= True;
		 else
				if cambiar_hora = '1' then
				  -- Manual adjustments when cambiar_hora is active
				  if incrementar = '1'  then
						-- Increment hour logic
						if count_hour < ONE_HOUR_COUNT - 1  then
							 count_hour <= count_hour + 1;
						else
							 count_hour <= 0;
							 if count_half_day < TW_HOUR_COUNT then
								  count_half_day <= count_half_day + 1;
							 else
								  count_half_day <= 1;
								  isAm <= not isAm;
							 end if;
						end if;
				  elsif decrementar = '1' then
						-- Decrement hour logic
						if count_hour > 0 then
							 count_hour <= count_hour - 1;
						else
							 count_hour <= ONE_HOUR_COUNT - 1;
							 if count_half_day > 1 then
								  count_half_day <= count_half_day - 1;
							 else
								  count_half_day <= TW_HOUR_COUNT;
								  isAm <= not isAm;
							 end if;
						end if;
				  end if;
				else
					if rising_edge(clk_state) then
					  -- Automatic time update logic when cambiar_hora is not active
					  if count_minute < ONE_MINUTE_COUNT - 1  then
							count_minute <= count_minute + 1;
					  else
							count_minute <= 0;
							if count_hour < ONE_HOUR_COUNT - 1 then
								 count_hour <= count_hour + 1;
							else
								 count_hour <= 0;
								 if count_half_day < TW_HOUR_COUNT - 1  then
									  count_half_day <= count_half_day + 1;
								 else
									  count_half_day <= 12;
									  isAm <= not isAm;
								 end if;
							end if;
					  end if;
				  end if;
				end if;
		end if;
	----------------------------------------------------------------------------------------
												-- Timer MODE -- 
	----------------------------------------------------------------------------------------
	
		elsif current_state = Timer then
		  if rst_mode = '1' then
			timer_seconds <= 0;
			timer_minutes <= 0;
			else
				
				if cambiar_hora = '1' and rising_edge(clk_state) then
					-- Timer setting mode
					if incrementar = '1' then
						-- Increment timer logic
							if timer_seconds < ONE_MINUTE_COUNT - 1  then
								 timer_seconds <= timer_seconds + 1;
							else
								 timer_seconds <= 0;
								 if timer_minutes < ONE_HOUR_COUNT - 1 then
									  timer_minutes <= timer_minutes + 1;
								 else
									  timer_minutes <= 1;
								 end if;
							end if;
						
					elsif decrementar = '1' and rising_edge(clk_state) then
						-- Decrement timer logic
						if timer_seconds > 0 then
							timer_seconds <= timer_seconds - 1;
						else
							  if timer_minutes > 0 then
									timer_minutes <= timer_minutes - 1;
									timer_minutes <= ONE_MINUTE_COUNT - 1;
							  else
									-- When both count_hour and timer_seconds are 0, do nothing (stay at 0)
									timer_minutes <= 0;
									timer_seconds <= 0;
							  end if;
						end if;
					end if;
				else
					-- Timer countdown mode
				  if init_ps = '1' then
						
						if (rising_edge(clk_state)) then
							if timer_seconds > 0 then
									 timer_seconds <= timer_seconds - 1;
								else
									 timer_seconds <= ONE_MINUTE_COUNT - 1;
									 if timer_minutes > 1 then
										  timer_minutes <= timer_minutes - 1;
									 else
										  timer_minutes <= ONE_HOUR_COUNT - 1; --change TODO
									 end if;					
						end if;
					  end if;
					else 
						timer_seconds <= timer_seconds;
						timer_minutes <= timer_minutes;
					end if;
				end if;
			end if;
		
			
	----------------------------------------------------------------------------------------
												-- Chronometer MODE -- 
	----------------------------------------------------------------------------------------
		elsif current_state = Chronometer then
			-- Default values (to avoid latches)
			 chrono_minutes <= chrono_minutes;
			 chrono_seconds <= chrono_seconds;

			 if rst_mode = '1'  then
				  -- Reset chronometer
				  chrono_minutes <= 0;
				  chrono_seconds <= 0;
			 elsif  init_ps = '1' then 
				  chrono_minutes <= chrono_minutes;
				  chrono_seconds <= chrono_seconds;
			 else
				 if rising_edge(clk_state) then
					  -- Increment chronometer time
					  if chrono_seconds < ONE_MINUTE_COUNT - 1 then
							chrono_seconds <= chrono_seconds + 1;
					  else
							chrono_seconds <= 0;
							if chrono_minutes < ONE_HOUR_COUNT - 1 then
								 chrono_minutes <= chrono_minutes + 1;
							else
								 chrono_minutes <= 0;
								 chrono_seconds <= 0;
							end if;
					  end if;
				 end if;
			end if;
		
	----------------------------------------------------------------------------------------
												-- Alarm MODE -- 
	----------------------------------------------------------------------------------------
	
		elsif current_state = Alarm then
		
		end if;
	end process clock_logic;
	
	
	-----------------------------------------------------------------------------------------
												-- OutPut --
	-----------------------------------------------------------------------------------------

	display_time: process(count_hour, count_half_day, isAm,count_minute,current_state)
        variable digit1, digit2, digit3, digit4, digit5, digit6: INTEGER;
    begin
			if current_state = Clock then	
	 
			  -- Display hours
			  digit1 := count_half_day / 10; -- First digit of hour
			  digit2 := count_half_day mod 10; -- Second digit of hour
			  seg_hr1 <= digit_to_7seg(digit1);
			  seg_hr2 <= digit_to_7seg(digit2);

			  -- Display minutes
			  digit3 := count_hour / 10; -- First digit of minute
			  digit4 := count_hour mod 10; -- Second digit of minute
			  seg_min1 <= digit_to_7seg(digit3);
			  seg_min2 <= digit_to_7seg(digit4);
			  
			  -- Display seconds
			  digit5 := count_minute / 10; -- First digit of minute
			  digit6 := count_minute mod 10; -- Second digit of minute
			  seg_sec1 <= digit_to_7seg(digit5);
			  seg_sec2 <= digit_to_7seg(digit6);
			  
			  
			  -- Display AM/PM indicator
			  if isAm then
				 --seg_sec1 <= "0001000"; -- Pattern for AM
				 --seg_sec2 <= "1111111"; -- Pattern for off
			  else
				 --seg_sec1 <= "0011000"; -- Pattern for PM
				 --seg_sec2 <= "1111111"; -- Pattern for off
			  end if;
			  
		elsif current_state = Timer then
			  seg_hr1 <= "1001111";
			  seg_hr2 <= "1111111";
			  
			  -- Display minutes			  
			  digit3 := timer_seconds / 10; -- First digit of minute
			  digit4 := timer_seconds mod 10; -- Second digit of minute
			  seg_sec1 <= digit_to_7seg(digit3);
			  seg_sec2 <= digit_to_7seg(digit4);
			  
			  -- Display seconds
			  digit5 := timer_minutes / 10; -- First digit of minute
			  digit6 := timer_minutes mod 10; -- Second digit of minute
			  seg_min1 <= digit_to_7seg(digit5);
			  seg_min2 <= digit_to_7seg(digit6);
			
		elsif current_state = Chronometer then
			  -- Display chronometer minutes and seconds
			 seg_hr1 <= "0010010";
			 seg_hr2 <= "1111111";
			  
			 digit3 := chrono_minutes / 10; -- First digit of minute
			 digit4 := chrono_minutes mod 10; -- Second digit of minute
			 seg_min1 <= digit_to_7seg(digit3);
			 seg_min2 <= digit_to_7seg(digit4);
			 
			 digit5 := chrono_seconds / 10; -- First digit of second
			 digit6 := chrono_seconds mod 10; -- Second digit of second
			 seg_sec1 <= digit_to_7seg(digit5);
			 seg_sec2 <= digit_to_7seg(digit6);
		elsif current_state = Alarm then
			 seg_hr1 <= "1111111";
			 seg_hr2 <= "1111111";
				
		end if;
		
    end process display_time;
	
end arch_clock;