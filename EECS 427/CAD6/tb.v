//`timescale 1ns/10ps

`define CYCLE 10
`define ENDCYCLE  400
module tb();
	// Input
	reg clk, reset;
	reg [7:0] disp;
	reg [15:0] Rtarget;
	reg Br, Jmp;
	reg stall, JAL;
	reg scan_en, scan_in;
	// Output
	wire [15:0] Rlink;
	wire [15:0] PC;
	wire scan_out;
	// Test
	wire correct;
	reg [15:0] correct_Rlink, correct_PC, correct_scan_out;
       	
	PC pc(.clk(clk), .reset(reset), .disp(disp), .Rtarget(Rtarget), .Br(Br), .Jmp(Jmp), .stall(stall), .JAL(JAL),.scan_en(scan_en), .scan_in(scan_in), .Rlink(Rlink), .PC(PC), .scan_out(scan_out));
	
	assign correct = (Rlink == correct_Rlink) && (PC == correct_PC) && (scan_out == correct_scan_out);

	always #(`CYCLE * 0.5) clk = ~clk;

	task exit_on_error;
	begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
			$display("ENDING TESTBENCH : ERROR !");
			//$finish;
	end
	endtask

	task verify_answer; begin
	
	
		if( !correct ) begin //CORRECT CASE
			exit_on_error;
	
		end

	end	
	endtask


	initial begin
	
		$display("STARTING TESTBENCH!\n");

		//INIT STATE
		
		clk = 0;
		reset = 1;
		disp = 0;
		Rtarget = 0;
		Br = 0;
		Jmp = 0;
		stall = 0;
		JAL = 0;
		scan_en = 0;
		scan_in = 0;
		correct_PC = 0;
		correct_Rlink = 0;
		correct_scan_out = 0;
		$display("@@@ Test 0: RESET");
		reset = 1;
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);

		$display("@@@ Test 1: Normal");
		@(negedge clk);
		reset = 0;
		disp = 8'b00000001;
		Rtarget = 16'd128;
		Br = 0;
		Jmp = 0;
		stall = 0;
		JAL = 0;
		scan_en = 1;
		scan_in = 0;
		
		@(negedge clk);
		scan_en = 0;
		
		correct_PC = 16'd1;
		correct_Rlink = 0;
		correct_scan_out = 0;

		stall = 1;
		#150
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
		verify_answer;

		$display("@@@ Test 2: Br");
		@(negedge clk);
		disp = 8'b00000001;
		Rtarget = 16'd128;
		Br = 1;
		Jmp = 0;
		stall = 0;
		JAL = 0;
		scan_en = 1;
		scan_in = 1;
	
		@(negedge clk);
		scan_en = 0;

		correct_PC = 16'd2;
		correct_Rlink = 0;
		correct_scan_out = 0;
		stall = 1;
		#150
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
		verify_answer;

		$display("@@@ Test 3: Jmp");
		@(negedge clk);
		disp = 8'b00000001;
		Rtarget = 16'd256;
		Br = 0;
		Jmp = 1;
		stall = 0;
		JAL = 0;
		scan_en = 1;
		scan_in = 1;

		@(negedge clk);
		scan_en = 0;
		
		correct_PC = 16'd258;
		correct_Rlink = 0;
		correct_scan_out = 0;
		stall = 1;
		#150
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
		verify_answer;

		$display("@@@ Test 4: stall");
		@(negedge clk);
		disp = 8'b00000001;
		Rtarget = 16'd256;
		Br = 0;
		Jmp = 0;
		stall = 1;
		JAL = 0;
		scan_en = 1;
		scan_in = 1;

		@(negedge clk);
		scan_en = 0;
		
		correct_PC = 16'd258;
		correct_Rlink = 0;
		correct_scan_out = 0;
		stall = 1;
		#150
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
		verify_answer;

		$display("@@@ Test 5: JAL");
		@(negedge clk);
		disp = 8'b00000001;
		Rtarget = 16'd256;
		Br = 0;
		Jmp = 0;
		stall = 0;
		JAL = 1;
		scan_en = 1;
		scan_in = 1;
		
		@(negedge clk);
		scan_en = 0;
		
		correct_PC = 16'd259;
		correct_Rlink = 16'd259;
		correct_scan_out = 0;
		stall = 1;
		#150
		$display("@@@ Time:%4.0f, clock:%b ,reset:%h, Rlink:%d, PC:%d, scan_out:%b, correct:%b, correct_Rlink: %d, correct_PC: %d, correct_scan_out: %b", $time, clk, reset, Rlink, PC, scan_out, correct, correct_Rlink, correct_PC, correct_scan_out);
		verify_answer;
		

		@(negedge clk);
		$finish;
	end
endmodule

