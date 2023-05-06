module ISR(
				input  reset,
				input [63:0] value,
				input clock,
				
				output logic [31:0] result,
				output logic done
			);

   logic [63:0]value_reg;
   logic [31:0]guess;
   logic [5:0]x; 
   logic [63:0]guess_result;
   logic done1;
   logic start_state;



   mult multiple_guess(.clock(clock),.reset(reset),
				.mcand({32'b0,guess}),
                		.mplier({32'b0,guess}),
				.start(start_state),
				.product(guess_result),
				.done(done1)
				);



   always_ff @(posedge clock) begin
       
      	if (reset==1'b1) begin
		value_reg <=  #1 value;
		x <= #1 6'b100000;
		start_state <= #1 1'b1;
		guess <= #1 32'h8000_0000; 
                
	end

	else begin
    
	       if(x != 1'b0 && done1==1'b1) begin 
		  start_state <=#1 1'b1;
		  x <=  #1 x-1'b1;
		  guess[x-1] <= #1 result[x-1];
 		  guess[x-2] <= #1 1'b1;	
               end
               else begin
                 
                  start_state <= #1 1'b0;
                      
		end
        end
       
   end

   always_comb begin
	if( x==1'b0 && done1==1'b1)
    		done =  1'b1;
        else begin
		done =  1'b0;
		if (reset)
                	result =32'b0;               
		
        	else if (guess_result > value_reg) begin
			result[x-1] = 1'b0 ;
		end
		else begin
			result[x-1] = 1'b1;
			
		end
		
	end
   end

	        


endmodule
