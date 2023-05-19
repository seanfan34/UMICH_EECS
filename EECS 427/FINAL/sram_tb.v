//`timescale 1ns/10ps

`define CYCLE 10
`define ENDCYCLE  400
module tb();
	// Input
	reg [15:0] data, RWL, WWL;
	reg precharge, sram_write_en, control;
	reg clk,reset;
        wire [15:0] RBL_out;
	sram16 sram16( .data(data), .RWL(RWL), .WWL(WWL), .precharge(precharge), .sram_write_en(sram_write_en), .control(control),
			.RBL_out(RBL_out),.clk(clk),. reset(reset));
always #(`CYCLE * 0.5) clk = ~clk;
	initial begin
	
		$display("STARTING TESTBENCH!\n");

		//INIT STATE
		$display("@@@ Test 0: RESET");
		
		clk =0;
		reset = 1;
		data = 0;		
		RWL = 16'b0000000000000000;
                WWL = 16'b0000000000000000;
		precharge = 1'b0;
                sram_write_en = 1'b0;
		control = 1'b0;

		@(posedge clk)
		reset =0;
		data = 16'b0101_0000_0000_0000;		
		RWL = 16'b0000000000000000;
                WWL = 16'b0001000000000000;
		precharge = 1'b0;
                sram_write_en = 1'b1;
		control = 1'b0;

		@(posedge clk)
		data = 16'b0001_1010_0000_0000;		
		RWL = 16'b0001000000000000;
                WWL = 16'b0000000000000000;
		precharge = 1'b0;
                sram_write_en = 1'b0;
		control = 1'b0;

		@(posedge clk)
		data = 16'b0001_1010_0000_0000;		
		RWL = 16'b1001000000000000;
                WWL = 16'b0000000000000000;
		precharge = 1'b0;
                sram_write_en = 1'b0;
		control = 1'b0;

		@(posedge clk)
		data = 16'b0001_1010_0000_0000;		
		RWL = 16'b1001000000000000;
                WWL = 16'b0000000000000000;
		precharge = 1'b0;
                sram_write_en = 1'b0;
		control = 1'b1;

		@(posedge clk)
		$finish;
	end
endmodule

