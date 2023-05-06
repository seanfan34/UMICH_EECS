module rps2(
        input [1:0]req,en,sel,
        output logic [1:0]gnt,req_up); 
    assign req_up =req[1]|req[0];
    always_comb begin 

    	if(sel==1'b1 && en==1'b1)
		if(req[1]==1'b1)
			gnt[1:0]=2'b10;
		else if(req[0]==1'b1)
			gnt[1:0]=2'b01;
		else 
			gnt[1:0]=2'b00;	
	else if(sel==1'b0 && en==1'b1) begin
		if(req[0]==1'b1)
			gnt[1:0]=2'b01;
		else if(req[1]==1'b1)
			gnt[1:0]=2'b10;
		else 
			gnt[1:0]=2'b00;
	end
	else
		gnt[1:0]=2'b00;

    end		
endmodule

module rps4(
        input clock,
	input reset,
	input [3:0]req,
	input en,
	output logic [3:0]gnt,
        output logic [1:0]count); 

    logic [3:0]tmp,req_up;
    always_ff @(posedge clock) begin
	if(reset == 1'b1)
		count[1:0] <= #1 2'b00;
	else
		count[1:0] <= #1 count+2'b01;
    end

    rps2 rps2_right( req[1:0],tmp[2],count[0],gnt[1:0],tmp[0]);
    rps2 rps2_left( req[3:2],tmp[3],count[0],gnt[3:2],tmp[1]);
    rps2 rps2_top( tmp[1:0],en,count[1],tmp[3:2],req_up);
endmodule





    

