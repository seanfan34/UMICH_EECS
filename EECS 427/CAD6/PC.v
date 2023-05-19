
module PC (
	input         clk,                  // system clock
	input         reset,                  // system reset
	input         [7:0] disp,      // only go to next instruction when true
    input         [15:0] Rtarget,
	
	input         Br, Jmp,
	input	      stall,JAL,

	input         scan_en, // scan chain enable
	input	      scan_in, // scan chain input
	output reg [15:0] Rlink,                                    
	output reg [15:0] PC_out,
	output  scan_out
);
		
    reg [15:0] Q;
        
	wire [15:0] extend_disp;

	assign scan_out = Q[15]; 

	assign extend_disp = disp[7]? {{8{1'b1}}, disp} : {{8{1'b0}}, disp};

	
	always @(posedge clk) begin
		if(reset) begin
			PC_out <= 0;       // initial PC value is 0
			Rlink <= 0;
		end
		else if(stall)
			PC_out <= PC_out;
		else if (Br)
			PC_out <= PC_out + extend_disp; 
		else if (Jmp)
			PC_out <= Rtarget;
		else if (JAL) begin
			Rlink <=  PC_out + 1;
			PC_out <= Rtarget;
		end
		else 
			PC_out <= PC_out + 1;
	end


	always @(posedge clk) begin
		if(scan_en) begin
			Q[15:0] <= PC_out[15:0];
		end else begin
			Q[15:0] <= {Q[14:0], scan_in};
		end
	end


endmodule  // module if_stage
