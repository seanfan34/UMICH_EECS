module decode(
  // Inputs from Fetch
  input [15:0] Q,
  input clk, RST, F, N, Z, Cout, scan_in, scan_en,
  
  // Outputs to Reg File
  output reg [15:0] Rsrc,
  output reg [15:0] dest_in,
  output  [15:0] WriteAddr_in,
  output reg Write_en,
  output reg [7:0] Imm,
  output [7:0] disp,
  //output [15:0] PC,
  output reg [1:0] OUT_SEL, ALU_SEL, shift_SEL,
  output reg WEN,CEN,Cin, 
  output reg MUX_SEL_extend, MUX_SEL_dest, MUX_SEL_src, 
  // output MUX_SEL_sign, scan_out,  // MUX_SEL_sign is disp[7]
  output scan_out,


  // output to PC
  output reg Br, Jmp,
  output reg JAL, stall
  //output [15:0] Rtarget
  //output reg flag
);

wire [3:0] opcode, Rdest_1, ImmHi_1, ImmLo_1, cond;
reg flag;
reg tmpF, tmpN, tmpZ, tmpC, Write_en_in;
reg [15:0] tmpQ, Write_Addr_reg;

//assign Rtarget = Rsrc;

//assign op_test = opcode;

assign {opcode, Rdest_1, ImmHi_1, ImmLo_1} = tmpQ[15:0];

// assign MUX_SEL_sign = tmpQ[7];

assign disp = tmpQ[7:0];

assign scan_out = tmpQ[15]; 

assign WriteAddr_in = {16{clk}} & Write_Addr_reg;
//assign Write_en_out = Write_en_wire & clk;

  always@(posedge clk) begin
	if (RST == 1'b0) begin
		Write_Addr_reg <= 16'd0;
		tmpF <= 0;
		tmpN <= 0;
		tmpZ <= 0;
		tmpC <= 0;
		//Write_en_wire <= 0;
	end
	else begin
		Write_Addr_reg <= dest_in;
		tmpF <= F;
		tmpN <= N;
		tmpZ <= Z;
		
		tmpC <= Cout;
		//Write_en_wire <= Write_en;
	end
  end

  always@(posedge clk) begin
	if (RST == 1'b0) begin
		tmpQ <= 0;
	end
	else if(scan_en) begin
		tmpQ[15:0] <= Q[15:0];
	end 
	else begin
		tmpQ[15:0] <= {tmpQ[14:0], scan_in};
	end

  end	
  			 
//signal calculations for most wires 
  always @(*) begin 
    Write_en = Write_en_in & ~clk;
    Rsrc = 1 << ImmLo_1;
    dest_in = 1 << Rdest_1;
    stall = 1'b0;
    JAL = 1'b0;
    Jmp = 1'b0;
    Cin = 1'b0;
    ALU_SEL = 2'b00;
    Br = 1'b0;
    Imm = 8'd0;
    Write_en_in = 0;
    case (opcode) 
	   4'b0000: begin // R-type
		  

		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 0;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 0;
		 
		  
		  Rsrc = 1 << ImmLo_1;
		  dest_in = 1 << Rdest_1;
		  
		  if (ImmHi_1 == 4'b0101) begin//add
			Cin = 0;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b00;
		  end
		 
		  else if (ImmHi_1 == 4'b1001) begin 
		  	Cin = 1;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b00;
		  end
		  else if (ImmHi_1 == 4'b1011) begin 
		    	Cin = 1;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b00;
		  end 
		  else if (ImmHi_1 == 4'b0001) begin 
		    	Cin = 0;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b01;
		  end 
		  else if (ImmHi_1 == 4'b0010) begin 
		    	Cin = 0;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b10;
		  end
		  else if (ImmHi_1 == 4'b0011) begin 
		    	Cin = 0;
		  	Imm = {ImmHi_1, ImmLo_1};
			ALU_SEL = 2'b11;
		  end 
		  else if(ImmHi_1 == 4'b1101) begin//MOV
			MUX_SEL_dest = 1;
			Cin = 0;
		  	Imm = {ImmHi_1, ImmLo_1};
			Rsrc = 1 << ImmLo_1;
			//dest_in = 0;
			ALU_SEL = 2'b00;
		  end
		  else if(ImmHi_1 == 4'b0) begin // Wait
			Write_en_in = 0;
			Cin = 0;
		  end
	end	  
   
 		  
	4'b0101: begin // I-type
		 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;

		  Rsrc = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};

		  ALU_SEL = 2'b00;
		  
       end
       4'b1001: begin	 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;
		  Rsrc = 0;
		  Cin = 1;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b00;
		  
       end 
		  
    
      4'b1011: begin	 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;
		  Rsrc = 0;
		  Cin = 1;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b00;
		  
      end
      4'b0001: begin	 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;
		  Rsrc = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b01;
		  
      end
      4'b0010: begin	 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;
		  Rsrc = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b10;
		  
      end
      4'b0011: begin	 
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 1;		  
		  dest_in = 1 << Rdest_1;
		  Rsrc = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b11;
		  
      end
      //MOVI
      4'b1101: begin
		  Write_en_in = 1;
		  OUT_SEL = 2'b01;
		  
		  shift_SEL = 2'b11;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 1;
		  MUX_SEL_src = 1;
		  Rsrc = 0;
		  //dest_in = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b00;
      end
      //LSH
      4'b1000: begin
		  Write_en_in = 1;
		  OUT_SEL = 2'b10;
		  
		  shift_SEL = 2'b00;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 0;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 0;
		  //Rsrc = 0;
		  //dest_in = 0;
		  Cin = 0;
		  ALU_SEL = 2'b00;
		  if(ImmHi_1 == 4'b0100) begin //LSH
		  Imm = {ImmHi_1, ImmLo_1};
		  end
		  else begin //LSHI
		  Rsrc = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  shift_SEL = 2'b01;
		  end	  
      end
     //LUI
      4'b1111: begin
		  Write_en_in = 1;
		  OUT_SEL = 2'b10;
		  
		  shift_SEL = 2'b10;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 1;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 0;
		  Rsrc = 0;
		  //dest_in = 0;
		  Cin = 0;
		  ALU_SEL = 2'b00;
		  Imm = {ImmHi_1, ImmLo_1};
      end

      4'b0100: begin
		  
		  MUX_SEL_extend = 0;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 0;
//		  Rsrc = 0;
//		  dest_in = 0;
		  Cin = 0;
		  ALU_SEL = 2'b00;
		  Imm = {ImmHi_1, ImmLo_1};
		  OUT_SEL = 2'b00;
		  shift_SEL = 2'b11;
		  CEN = 0;
		  // default
		  Br = 0;
		  Jmp = 0;
		  JAL = 0;
		  WEN = 1'b0;

		  if(ImmHi_1 == 4'b0000) begin // LOAD
			//dest_in = 0;
		  	Write_en_in = 1;
		  	WEN = 1;
		  end
		  else if(ImmHi_1 == 4'b0100) begin //STORE
			dest_in = Rsrc;
		  	Write_en_in = 0;
		  	WEN = 0;
		  end 		
		  else if(ImmHi_1 == 4'b1100) begin //Jcond

		  	dest_in = 0;
		  	CEN = 1;
			Write_en_in = 0;
		  	WEN = 1;	
		  	if (flag) begin
				Br = 0; 
				Jmp = 1;
				JAL = 0;
				stall =0;
		  	end
		  
		  	else begin
				Br = 0; 
				Jmp = 0;
				JAL = 0;
				stall =0;
		  	end

		  end 
		  else if(ImmHi_1 == 4'b1000) begin //JAL
			
		  	//dest_in = 0;
		  	CEN = 1;
			Write_en_in = 1;
		  	WEN = 1;
			Br = 0;
			Jmp = 0;
			JAL = 1;
			stall =0;
			OUT_SEL = 2'b11;
//??

			
		  end 
      end
      4'b1100: begin//Bcond
		   	MUX_SEL_extend = 0;
		  	MUX_SEL_dest = 0;
		  	MUX_SEL_src = 0;
			Rsrc = 0;
		  	dest_in = 0;
		  	Cin = 0;
		  	ALU_SEL = 2'b00;
		  	Imm = {ImmHi_1, ImmLo_1};
		  	OUT_SEL = 2'b00;
		  	shift_SEL = 2'b11;
		  	CEN = 1;
			Write_en_in = 0;
		  	WEN = 1;	
		  	if (flag) begin
				Br = 1;
				Jmp = 0;
				JAL = 0;
				stall =0;
		  	end
		  
		  	else begin
				Br = 0;
				Jmp = 0;
				JAL = 0;
				stall = 0;
		  	end
      end
      default: begin
		  Write_en_in = 0;
		  OUT_SEL = 2'b00;
		  
		  shift_SEL = 2'b00;
		  WEN = 1;
		  CEN = 1;
		  MUX_SEL_extend = 0;
		  MUX_SEL_dest = 0;
		  MUX_SEL_src = 0;

		  Rsrc = 0;
		  dest_in = 0;
		  Cin = 0;
		  Imm = {ImmHi_1, ImmLo_1};
		  ALU_SEL = 2'b00;

	end
    endcase 
  end	 

  assign cond = Rdest_1;
  always@(*) begin
    case (cond) 
	   4'b0000: begin // EQ
		if (tmpZ == 1)	flag = 1;
		else flag = 0;
	   end
	   4'b0001: begin // NEQ
		if (tmpZ == 0)	flag = 1;
		else flag = 0;
	   end
	   4'b1101: begin // GE
		if (tmpZ == 1 || tmpN == 1)	flag = 1;
		else flag = 0;
	   end
	   4'b0010: begin // CS
		if (tmpC == 1)	flag = 1;
		else flag = 0;
	   end
	   4'b0011: begin // CC
		if (tmpC== 0)	flag = 1;
		else flag = 0;
	   end
	   4'b0110: begin // GT
		if (tmpN == 1)	flag = 1;
		else flag = 0;
	   end
	   4'b0111: begin // LE
		if (tmpN == 0)	flag = 1;
		else flag = 0;
	   end
	   4'b1000: begin // FS
		if (tmpF == 1)	flag = 1;
		else flag = 0;
	   end
	   4'b1001: begin // FC
		if (tmpF == 0)	flag = 1;
		else flag = 0;
	   end
	   4'b1100: begin // LT
		if (tmpN == 0 && tmpZ == 0)	flag = 1;
		else flag = 0;
	   end
	   4'b1110: begin // UC
		flag = 1;
	   end
	   default: begin
		flag = 0;
	   end
	endcase

  end

endmodule


