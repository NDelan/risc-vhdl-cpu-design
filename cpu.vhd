library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is 

    port (
        clk   : in  std_logic;
        reset : in  std_logic;

        PCview : out std_logic_vector(7 downto 0); -- debugging the outputs
        IRview : out std_logic_vector(15 downto 0);
		  
        RAview : out std_logic_vector(15 downto 0);
        RBview : out std_logic_vector(15 downto 0);
        RCview : out std_logic_vector(15 downto 0);
        RDview : out std_logic_vector(15 downto 0);
        REview : out std_logic_vector(15 downto 0);

        iport : in  std_logic_vector(7 downto 0); 
        oport : out std_logic_vector(15 downto 0)

		--digit0 : out std_logic_vector(6 downto 0); -- output value 

    );
end entity;

architecture rlt of cpu is


    component ProgramROM is 

        port (
            address : in  std_logic_vector(7 downto 0);
            clock   : in  std_logic;
            q       : out std_logic_vector(15 downto 0)
        );

    end component;

    component DataRAM is 
        port 
		(
            address : in  std_logic_vector(7 downto 0);
            clock   : in  std_logic;
            data    : in  std_logic_vector(15 downto 0);
            wren    : in  std_logic;
            q       : out std_logic_vector(15 downto 0)
        );
    end component;

    component alu
        port(
            srcA : in  unsigned(15 downto 0);         -- input A
            srcB : in  unsigned(15 downto 0);         -- input B
            op   : in  std_logic_vector(2 downto 0);  -- operation
            cr   : out std_logic_vector(3 downto 0);  -- condition outputs
            dest : out unsigned(15 downto 0)         		 -- output value
        );
    end component;
	


    signal PC : unsigned(7 downto 0);
    signal SP : unsigned(7 downto 0);
	 signal RA : std_logic_vector(15 downto 0);
    signal IR  : std_logic_vector(15 downto 0);

	 signal RB: std_logic_vector(15 downto 0);
	 signal RC: std_logic_vector(15 downto 0);
	 signal RD: std_logic_vector(15 downto 0);
	 signal RE: std_logic_vector(15 downto 0);
	 signal OUTREG: std_logic_vector(15 downto 0); 
    signal CR:  std_logic_vector(3 downto 0);

    signal ALUInputA : unsigned(15 downto 0); 
    signal ALUInputB : unsigned(15 downto 0); 
    signal ALUOutput : unsigned(15 downto 0);
    signal ALUOP : std_logic_vector(2 downto 0); 
    signal ALUcondition    : std_logic_vector(3 downto 0); 

    signal MAR : unsigned(7 downto 0);  
    signal MBR : std_logic_vector(15 downto 0); 
    signal RAMwe     : std_logic := '0'; 
    signal RAMout : std_logic_vector(15 downto 0);

    signal ROMout : std_logic_vector(15 downto 0);

	type state_type is (start_in, fetch_in, execute_inSetup, execute_inALU, 
	execute_inWrite, execute_inMemoryWait, execute_inReturnPause1, execute_inReturnPause2, sHalt);


   signal state : state_type;
   signal internal_counter: unsigned(2 downto 0);

 begin
     rom0: ProgramROM port map(address => std_logic_vector(PC), clock => clk, q => ROMout);
	  ram0: DataRAM port map(address => std_logic_vector(MAR), clock => clk, data => MBR, 
									 wren => RAMwe, q => RAMout);

     alu0: alu port map(srcA => ALUInputA, srcB => ALUInputB, op => ALUOP, cr => ALUcondition, dest => ALUOutput);  
	  process (clk, reset)
	  begin
	  
			if reset = '0' then 
				 internal_counter <= (others => '0');
				 PC <= (others => '0');
				 MAR <= (others => '0');
				 RC <= (others => '0');
				 RD <= (others => '0');
				 RE <= (others => '0');
				 IR <= (others => '0');
				 OUTREG <= (others => '0');
				 MBR <= (others => '0');
				 RA <= (others => '0');
				 RB <= (others => '0');
				 SP <= (others => '0');
				 state <= start_in;
				 
			elsif (rising_edge(clk)) then
				 case state is 
					  when start_in =>
							if internal_counter = "111" then 
						state <= fetch_in;
							else
								 internal_counter <= internal_counter + 1;
							end if;
					  when fetch_in =>
							IR <= ROMout;
							PC <= PC + 1;
							state <= execute_inSetup;
					  when execute_inSetup =>
							case IR (15 downto 12) is 
								 when "0000" => 
									  if IR(11) = '1' then 
											MAR <= unsigned(IR(7 downto 0)) + unsigned(RE(7 downto 0));
									  else
											MAR <= unsigned(IR(7 downto 0));
									  end if;
								 when "0001" => 
									  if IR(11) = '1' then
											MAR <= unsigned(IR(7 downto 0)) + unsigned(RE(7 downto 0));
									  else
											MAR <= unsigned(IR (7 downto 0));
									  end if;
									  case IR (10 downto 8) is
											when "000" =>
												 MBR <= RA;
											when "001" =>
												 MBR <= RB;
											when "010" =>
												 MBR <= RC;
											when "011" =>
												 MBR <= RD;
											when "100" =>
												 MBR <= RE;
											when "101" =>
												 MBR <= std_logic_vector("00000000" & SP);
											when others =>
												 null;
									  end case;
								 when "0100" => 
									  MAR <= SP;
									  SP <= SP + 1;
									  case IR(11 downto 9) is 
											when "000" =>
												 MBR <= RA;
											when "001" =>
												 MBR <= RB;
											when "010" =>
												 MBR <= RC;
											when "011" =>
												 MBR <= RD;
											when "100" =>
												 MBR <= RE;
											when "101" =>
												 MBR <= std_logic_vector("00000000" & SP);
											when "110" => 
												 MBR <= "000000000000" & CR;
											when others =>
												 null;
									  end case;
								 when "0101" => 
									  MAR <= SP - 1;
									  SP <= SP - 1;
								 when "0010" => 
									  PC <= unsigned(IR(7 downto 0));
								 when "0011" => 
									  case IR (11 downto 10) is
											when "00" => 
												 case IR(9 downto 8) is
													  when "00" =>
															if ALUcondition(0) = '1' then
																 PC <= unsigned(IR(7 downto 0));
															end if;
													  when "01" => 
															if ALUcondition(1) = '1' then
																 PC <= unsigned(IR(7 downto 0));
															end if;
													  when "10" => 
															IF ALUcondition(2) = '1' then
																 PC <= unsigned(IR (7 downto 0));
															end if;
													  when others => 
															if ALUcondition(3) = '1' then
																 PC <= unsigned(IR(7 downto 0));
															end if;
												 end case;
											when "01" =>  
												 PC <= unsigned(IR(7 downto 0));
												 MAR <= SP;
												 SP <= SP + 1;
												 MBR <= "0000" & CR & std_logic_vector(PC);
											when "10" => 
												 MAR <= SP - 1;
												 SP <= SP - 1;
											when others => 
												 null;
									  end case;
								 when "1000" | "1001" | "1010" | "1011" | "1100" => 
									  case IR(11 downto 9) is 
											when "000" =>
												 ALUInputA <= unsigned(RA);
											when "001" => 
												 ALUInputA <= unsigned(RB);
											when "010" =>
												 ALUInputA <= unsigned(RC);
											when "011" =>
												 ALUInputA <= unsigned(RD);
											when "100" =>
												 ALUInputA <= unsigned(RE);
											when "101" =>
												 ALUInputA <= "00000000" & SP;
											when "110" =>
												 ALUInputA <= "0000000000000000";
											when "111" =>
												 ALUInputA <= "1111111111111111";
											when others =>
												 ALUInputA <= x"FFFF";
									  end case;
									  case IR(8 downto 6) is
											when "000" =>
												 ALUInputB <= unsigned(RA);
											when "001" =>
												 ALUInputB <= unsigned(RB);
											when "010" =>
												 ALUInputB <= unsigned(RC);
											when "011" =>
												 ALUInputB <= unsigned(RD);
											when "100" =>
												 ALUInputB <= unsigned(RE);
											when "101" =>
												 ALUInputB <= "00000000" & SP;
											when "110" =>
												 ALUInputB <= "0000000000000000";
											when "111" =>
												 ALUInputB <= "1111111111111111";
											when others =>
												 ALUInputB <= x"FFFF";
									  end case;
									  ALUOP <= IR(14 downto 12);
								 when "1101" | "1110" => 
									  ALUOP <= IR(14 downto 12);
									  case IR(10 downto 8) is
											when "000" =>
												 ALUInputA <= unsigned(RA);
											when "001" =>
												 ALUInputA <= unsigned(RB);
											when "010" =>
												 ALUInputA <= unsigned(RC);
											when "011" =>
												 ALUInputA <= unsigned(RD);
											when "100" =>
												 ALUInputA <= unsigned(RE);
											when "101" =>
												 ALUInputA <= "00000000" & SP;
											when "110" =>
												 ALUInputA <= "0000000000000000";
											when "111" =>
												 ALUInputA <= "1111111111111111";
											when others =>
												 null;
									  end case;
									  if IR(11) = '0' then 
											ALUInputB <= (others =>'0');
									  else 
											ALUInputB <= "0000000000000001";
									  end if;
								 when "1111" => 
									  ALUOP <= "111";
									  if IR(11) = '1' then 
											if IR(10) = '1' then
												 ALUInputA <= unsigned(x"FF" & IR(10 downto 3));
											else 
												 ALUInputA <= unsigned(x"00" & IR(10 downto 3));
											end if;
									  else 
											case IR(10 downto 8) is
												 when "000" =>
													  ALUInputA <= unsigned(RA);
												 when "001" =>
													  ALUInputA <= unsigned(RB);
												 when "010" =>
													  ALUInputA <= unsigned(RC);
												 when "011" =>
													  ALUInputA <= unsigned(RD);
												 when "100" =>
													  ALUInputA <= unsigned(RE);
												 when "101" =>
													  ALUInputA <= "00000000" & SP;
												 when "110" =>
													  ALUInputA <= "00000000" & PC;
												 when others =>
													  ALUInputA <= unsigned(IR);
											end case;
									  end if;
								 when others =>
									  null;
								 end case;
								 if IR(15 downto 0) = "001111" then
									  state <= sHalt;
								 else
									  state <= execute_inALU;
								 end if;
					  when execute_inALU => 
							if IR (15 downto 12) = "0100" or IR(15 downto 12) = "0011" or IR(15 downto 10) = "001101" then
								 RAMwe <= '1';
							end if;
							if IR(15 downto 12) = "0000" or IR(15 downto 12) = "0101" or IR(15 downto 10) = "001110" then
								 state <= execute_inMemoryWait;
							else
								 state <= execute_inWrite;
							end if;
					  when execute_inMemoryWait =>
							state <= execute_inWrite;
							
					  when execute_inWrite =>
							RAMwe <= '0';
							case IR (15 downto 12) is
								 when "0000" => 
									  case IR (10 downto 8) is
											when "000" => 
												 RA <= RAMout;
											when "001" => 
												 RB <= RAMout;
											when "010" => 
												 RC <= RAMout;
											when "011" => 
												 RD <= RAMout;
											when "100" => 
												 RE <= RAMout;
											when "101" => 
												 SP <= unsigned(RAMout(7 downto 0));
											when others => 
												 null;
									  end case;
								 when "0011" => 
									  case IR(11 downto 10) is
											when "10"=>  
												 PC <= unsigned(RAMout(7 downto 0));
												 CR <= RAMout(11 downto 8);
											when others=> 
												 null;
									  end case;
								 when "0101" => 
									  case IR(11 downto 9) is 
									  when "000" => 
											RA <= RAMout;
									  when "001" => 
											RB <= RAMout;
									  when "010" =>
											RC <= RAMout;
									  when "011" => 
											RD <= RAMout;
									  when "100" => 
											RE <= RAMout;
									  when "101" => 
											SP <= unsigned(RAMout(7 downto 0));
									  when "110" => 
											PC <= unsigned(RAMout(7 downto 0));
									  when others =>
											CR <= RAMout(3 downto 0);
									  end case;
								 when "0110" => 
									  case IR(11 downto 9) is 
											when "000" => 
												 OUTREG <= RA;
											when "001" => 
												 OUTREG <= RB;
											when "010" => 
												 OUTREG <= RC;
											when "011" => 
												 OUTREG <= RD;
											when "100" => 
												 OUTREG <= RE;
											when "101" => 
												 OUTREG <= std_logic_vector("00000000" & SP);
											when "110" => 
												 OUTREG <= "0000000000000000";
											when others => 
												 OUTREG <= x"FFFF";
									  end case;
								 when "0111" =>
									  case IR(11 downto 9) is 
											when "000" => 
												 if iport(7) = '1' then
													  RA <= x"FF" & iport;
												 else
													  RA <= x"00" & iport;
												 end if;
											when "001" => 
												 if iport(7) = '1' then
													  RB <= x"FF" & iport;
												 else
													  RB <= x"00" & iport;
												 end if;
											when "010" => 
												 if iport(7) = '1' then
													  RC <= x"FF" & iport;
												 else
													  RC <= x"00" & iport;
												 end if;
											when "011" => 
												 if iport(7) = '1' then
													  RD <= x"FF" & iport;
												 else
													  RD <= x"00" & iport;
												 end if;
											when "100" => 
												 if iport(7) = '1' then
													  RE <= x"FF" & iport;
												 else
													  RE <= x"00" & iport;
												 end if;
											when "101" => 
												 SP <= unsigned(iport);
											when others => 
												 null;
									  end case;
								 when "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110"  =>
									  case IR(2 downto 0) is 
											when "000" => 
												 RA <= std_logic_vector(ALUOutput);
											when "001" => 
												 RB <= std_logic_vector(ALUOutput);
											when "010" => 
												 RC <= std_logic_vector(ALUOutput);
											when "011" =>
												 RD <= std_logic_vector(ALUOutput);
											when "100" => 
												 RE <= std_logic_vector(ALUOutput);
											when "101" => 
											
												 SP <= ALUOutput(7 downto 0);
											when others =>
												 null;
									  end case;
									  CR <= ALUcondition;
								 when "1111" => 
									  CR <= ALUcondition;
									  case IR(2 downto 0) is 
											when "000" => 
												 RA <= std_logic_vector(ALUOutput);
											when "001" => 
												 RB <= std_logic_vector(ALUOutput);
											when "010" => 
												 RC <= std_logic_vector(ALUOutput);
											when "011" =>
												 RD <= std_logic_vector(ALUOutput);
											when "100" => 
												 RE <= std_logic_vector(ALUOutput);
											when "101" => 
												 SP <= ALUOutput(7 downto 0);
											when others =>
												 null;
									  end case;
								 when others =>
									  null;
					  end case;
					  if IR(15 downto 10) = "001110" then 
							state <= execute_inReturnPause1;
					  else
							state <= fetch_in;
					  end if;
			when execute_inReturnPause1 =>
				 state <= execute_inReturnPause2;
			when execute_inReturnPause2 =>
				 state <= fetch_in;
			when others => -- 
				 null;
	  end case;
	end if;
	
end process;

    PCview <= std_logic_vector(PC);
    IRview <= IR;
    RAview <= RA;
    RBview <= RB;
    RCview <= RC;
    RDview <= RD;
    REview <= RE;
    oport <= OUTREG;
	 
end rlt;