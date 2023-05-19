module sram16( 
  
	input [15:0] data, RWL, WWL,
	input precharge, sram_write_en, control,
	input clk, reset,
        output reg [15:0] RBL_out
);


  reg [15:0] SRAM [15:0];

  wire [3:0] RWL_out1, RWL_out2, WWL_out1, WWL_out2;

  //reg [15:0] SRAM_b [15:0];
  
//  integer i;

// one_hot_encoder encoder1(.in(RWL), .out1(RWL_out1), .out2(RWL_out2));
// one_hot_encoder encoder2(.in(WWL), .out1(WWL_out1), .out2(WWL_out2));

  wire [7:0] data_8;
  wire [3:0] data_4;
  wire [1:0] data_2;

  wire [7:0] data2_8, data3_8, data4_8;
  wire [3:0] data2_4, data3_4, data4_4;
  wire [1:0] data2_2, data3_2, data4_2;


assign RWL_out1[3] = |RWL[15:8];
assign data_8 = RWL_out1[3]? RWL[15:8] : RWL[7:0];
assign RWL_out1[2] = |data_8[7:4];
assign data_4 = RWL_out1[2]? data_8[7:4] : data_8[3:0];
assign RWL_out1[1] = |data_4[3:2];
assign data_2 = RWL_out1[1]? data_4[3:2] : data_4[1:0];
assign RWL_out1[0] = data_2[1];

assign RWL_out2[3] = ~|RWL[7:0];
assign data2_8 = RWL_out2[3]? RWL[15:8]: RWL[7:0];
assign RWL_out2[2] = ~|data2_8[3:0];
assign data2_4 = RWL_out2[2]? data2_8[7:4]: data2_8[3:0];
assign RWL_out2[1] = ~|data2_4[1:0];
assign data2_2 = RWL_out2[1]? data2_4[3:2]: data2_4[1:0];
assign RWL_out2[0] = ~data2_2[0]; 


assign WWL_out1[3] = |WWL[15:8];
assign data3_8 = WWL_out1[3]? WWL[15:8] : WWL[7:0];
assign WWL_out1[2] = |data3_8[7:4];
assign data3_4 = WWL_out1[2]? data3_8[7:4] : data3_8[3:0];
assign WWL_out1[1] = |data3_4[3:2];
assign data3_2 = WWL_out1[1]? data3_4[3:2] : data3_4[1:0];
assign WWL_out1[0] = data3_2[1];

assign WWL_out2[3] = ~|WWL[7:0];
assign data4_8 = WWL_out2[3]? WWL[15:8]: WWL[7:0];
assign WWL_out2[2] = ~|data4_8[3:0];
assign data4tmpQ_4 = WWL_out2[2]? data4_8[7:4]: data4_8[3:0];
assign WWL_out2[1] = ~|data4_4[1:0];
assign data4_2 = WWL_out2[1]? data4_4[3:2]: data4_4[1:0];
assign WWL_out2[0] = ~data4_2[0]; 

  always @(negedge clk) begin

	  if (reset) begin
		RBL_out <= 16'b1111_1111_1111_1111;
//		for(i = 0; i < 16; i = i + 1) begin
//	   		SRAM [i] = 16'hFFFF;
//	   	end
		SRAM[0] <= 16'hFFFF;
		SRAM[1] <= 16'hFFFF;
		SRAM[2] <= 16'hFFFF;
		SRAM[3] <= 16'hFFFF;
		SRAM[4] <= 16'hFFFF;
		SRAM[5] <= 16'hFFFF;
		SRAM[6] <= 16'hFFFF;
		SRAM[7] <= 16'hFFFF;
		SRAM[8] <= 16'hFFFF;
		SRAM[9] <= 16'hFFFF;
		SRAM[10] <= 16'hFFFF;
		SRAM[11] <= 16'hFFFF;
		SRAM[12] <= 16'hFFFF;
		SRAM[13] <= 16'hFFFF;
		SRAM[14] <= 16'hFFFF;
		SRAM[15] <= 16'hFFFF;
	  end

  	else begin
 
   //RBL_out= 16'b1111_1111_1111_1111;
 //  for(i = 0; i < 16; i = i + 1) begin
  // 	SRAM [i] = 16'hFFFF;
  // end

//   for(i = 0; i < 16; i = i + 1) begin
//   	SRAM_b [i] = #1 ~SRAM[i];
//   end

	    if (control == 1'b0) begin	//and

	  	if (sram_write_en == 1'b1) begin // write

	   		//SRAM [WWL] = data;
			SRAM [WWL_out1] <= data;

	   	end

	    

	  	else  begin // read
			if (^RWL == 0) begin // two hot
	   			// RBL_out <= SRAM [RWL];
				RBL_out <= SRAM[RWL_out1] & SRAM[RWL_out2];
			end
			else begin // one hot
				RBL_out <= SRAM[RWL_out1];
			end
	  	end
	end
	
	    else begin	//nor
		if (sram_write_en == 1'b0) begin // read
			if (^RWL == 0) begin // two hot
	   			// RBL_out <= SRAM [RWL];
				RBL_out <= ~(SRAM[RWL_out1] | SRAM[RWL_out2]);
			end
//			else begin // one hot
//				RBL_out <= SRAM[RWL_out1];
//			end

			
		end
	    end
	  
  	end
   end

endmodule
/*

module one_hot_encoder (
	input 	   [15:0] in,
	output  [3:0]  out1, out2
);

wire [7:0] data_8;
wire [3:0] data_4;
wire [1:0] data_2;

wire [7:0] data2_8;
wire [3:0] data2_4;
wire [1:0] data2_2;


assign out1[3] = |in[15:8];
assign data_8 = out1[3]? in[15:8] : in[7:0];
assign out1[2] = |data_8[7:4];
assign data_4 = out1[2]? data_8[7:4] : data_8[3:0];
assign out1[1] = |data_4[3:2];
assign data_2 = out1[1]? data_4[3:2] : data_4[1:0];
assign out1[0] = data_2[1];

assign out2[3] = ~|in[7:0];
assign data2_8 = out2[3]? in[15:8]: in[7:0];
assign out2[2] = ~|data2_8[3:0];
assign data2_4 = out2[2]? data2_8[7:4]: data2_8[3:0];
assign out2[1] = ~|data2_4[1:0];
assign data2_2 = out2[1]? data2_4[3:2]: data2_4[1:0];
assign out2[0] = ~data2_2[0];

/*
assign data 
   always@(*) begin
	case(in) 
		16'b0000_0000_0000_0001: out1 = 4'd0;
		16'b0000_0000_0000_0010: out1 = 4'd1;
		16'b0000_0000_0000_0100: out1 = 4'd2;
		16'b0000_0000_0000_1000: out1 = 4'd3; 
		16'b0000_0000_0001_0000: out = 4'd4; 
		16'b0000_0000_0010_0000: out = 4'd5; 
		16'b0000_0000_0100_0000: out = 4'd6; 
		16'b0000_0000_1000_0000: out = 4'd7; 
		16'b0000_0001_0000_0000: out = 4'd8; 
		16'b0000_0010_0000_0000: out = 4'd9; 
 		16'b0000_0100_0000_0000: out = 4'd10; 
 		16'b0000_1000_0000_0000: out = 4'd11; 
 		16'b0001_0000_0000_0000: out = 4'd12; 
 		16'b0010_0000_0000_0000: out = 4'd13; 
 		16'b0100_0000_0000_0000: out = 4'd14; 
 		16'b1000_0000_0000_0000: out = 4'd15; 
	endcase
*/	

	
	
 //  end
//endmodule

