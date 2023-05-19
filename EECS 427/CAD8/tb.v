//`timescale 1ns/10ps

`define CYCLE 10
`define ENDCYCLE  400
module tb();
	// Input
	reg [15:0] Q, pc, sram_data_out;
	reg clk, RST, F, N, Z, Cout, scan_in, scan_en;
	
	wire [15:0] Rsrc;
 	wire  [15:0] dest_in;
  	wire  [15:0] WriteAddr_in;
  	wire  Write_en;
  	wire [7:0] Imm;
  	wire [7:0] disp;
  	//output [15:0] PC,
  	wire [1:0] OUT_SEL, ALU_SEL, shift_SEL;
  	wire  WEN,CEN,Cin, scan_out;
  	wire MUX_SEL_extend, MUX_SEL_dest, MUX_SEL_src;

  	// output to PC
  	wire Br, Jmp, JAL, stall;
        wire Write_EN, precharge, control;

        wire [15:0] RWL, WWL, datapath;

	decode decode(.Q(Q), .clk(clk), .RST(RST), .pc(pc),.sram_data_out(sram_data_out), .F(F), .N(N), .Z(Z), .Cout(Cout), .scan_in(scan_in), .scan_en(scan_en), .Rsrc(Rsrc), .dest_in(dest_in), .WriteAddr_in(WriteAddr_in), .Write_en(Write_en), 
			.Imm(Imm), .disp(disp), .OUT_SEL(OUT_SEL), .ALU_SEL(ALU_SEL), .shift_SEL(shift_SEL), .WEN(WEN), .CEN(CEN), .Cin(Cin), .scan_out(scan_out), .MUX_SEL_extend(MUX_SEL_extend), 				.MUX_SEL_dest(MUX_SEL_dest), .MUX_SEL_src(MUX_SEL_src), .Br(Br), .Jmp(Jmp), .JAL(JAL), .stall(stall)
			.Write_EN(Write_EN), .precharge(precharge), .control(control), .RWL(RWL), .WWL(WWL),
			.datapath(datapath));

	always #(`CYCLE * 0.5) clk = ~clk;

	initial begin
	
		$display("STARTING TESTBENCH!\n");

		//INIT STATE
		$display("@@@ Test 0: RESET");
		clk = 0;		
		Q = 16'b0000000000000000;
                pc = 16'd0;
		sram_data_out = 0;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 0;

		$display("@@@ Test 1: STORE");
				
		Q = 16'b1010_0001_1111_0001;
                pc = 16'd0;
		sram_data_out = 16'd1;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 2: STORE");
				
		Q = 16'b1010_0010_1111_0010;
                pc = 16'd0;
		sram_data_out = 16'd3;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 3: AND");
				
		Q = 16'b1010_0001_0100_0010;
                pc = 16'd0;
		sram_data_out = 16'd2;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 4: NOR");
				
		Q = 16'b1010_0001_1000_0010;
                pc = 16'd0;
		sram_data_out = 16'd4;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;


		$display("@@@ Test 5: LOAD");
				
		Q = 16'b1010_0001_1100_0010;
                pc = 16'd0;
		sram_data_out = 16'd5;
		RST = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;


/*	
		$display("@@@ Test 1: ADDI");
		@(negedge clk);
		Q = 16'b0101100000001100;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;
		
		$display("@@@ Test 2: MOV");
		@(negedge clk);
		Q = 16'b0000_0110_1101_0001;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		
		$display("@@@ Test 3: MOVI");
		@(negedge clk);
		Q = 16'b1101_0100_1100_0010;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 4: LSH");
		@(negedge clk);
		Q = 16'b1000_0001_0100_0011;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 5: LSHI");
		@(negedge clk);
		Q = 16'b1000_0010_0000_0100;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 6: LUI");
		@(negedge clk);
		Q = 16'b1111_0011_0110_0101;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 7: LOAD");
		@(negedge clk);
		Q = 16'b0100_0100_0000_0110;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 8: STORE");
		@(negedge clk);
		Q = 16'b0100_0101_0100_0111;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 9: Bcond");
		@(negedge clk);
		Q = 16'b1100_0110_0101_1000;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;
		
		$display("@@@ Test 10: Bcond EQ");
		@(negedge clk);
		Q = 16'b1100_0000_0101_1000;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 1;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 11: Jcond");
		@(negedge clk);
		Q = 16'b0100_0111_1100_1001;
		RST = 1;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 12: JAL");
		@(negedge clk);
		Q = 16'b0100_1000_1000_1010;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 0;
		scan_en = 1;

		$display("@@@ Test 13: Scan in = 1");
		@(negedge clk);
		Q = 16'b0100_1000_1000_1010;
		RST = 1;
		pc = 16'd0;
		sram_data_out = 0;
		F = 0;
		N = 0;
		Z = 0;
		Cout = 0;
		scan_in = 1;
		scan_en = 0;
		#160

*/

		@(negedge clk);
		$finish;
	end
endmodule

