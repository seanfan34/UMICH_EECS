module testbench;

logic reset;
logic [63:0]value;
logic clock;
logic [31:0]result;
logic done;
logic [31:0]guess;
wire correct = (guess===result) | ~done;

integer i;

ISR ISR_test(
    .reset(reset),
    .value(value),
    .clock(clock),
    .result(result),
    .done(done)
);


task guess_value;
        input [63:0] int_input;
        output [31:0] guess;
        begin
            integer k ;
            guess[31:0] = 32'b0;
            for (k=31; k >= 0; k=k-1) begin
                 guess[k] = 1'b1;
		 if (guess * guess > int_input )
                 guess[k] = 1'b0;
		 else
		 guess[k] = 1'b1;
            end
        end
endtask

task wait_until_done;
		forever begin : wait_loop
			//@(posedge done);
			@(negedge clock);
			if(done) disable wait_until_done;
		end
endtask

always begin 
    #5;
    clock=~clock; 
end

always begin
  #2
     if(!correct) begin
         $display("@@@ Incorrect at time %4.0f", $time);
         $display("@@@ Time:%4.0f clock:%b value:%d result:%d guess:%d reset:%b done:%b",
         $time, clock, value, result, guess, reset, done);
         $display("@@@Failed");
         $finish;
     end
end


initial begin
    $dumpvars;
    clock = 0;
    reset = 1;
 
    $display("STARTING TESTBENCH!");
    $monitor("@@@ Time:%4.0f clock:%b value:%d result:%d guess:%d reset:%b done:%b, correct:%b",$time, clock, value, result, guess, reset, done,correct);

    @(negedge clock); 
    reset = 1'b1;
    value = 9;
    guess_value(value, guess);
    #1
    @(negedge clock);
    reset = 1'b0;
    wait_until_done();
    // Test 1
    @(negedge clock); 
    reset = 1'b1;
    value = 121;
    guess_value(value, guess);
    #1
    @(negedge clock);
    reset = 1'b0;
    wait_until_done();
    //Test 2
    @(negedge clock); 
    reset = 1'b1;
    value = 258;
    guess_value(value, guess);
    #1
    @(negedge clock);
    reset = 1'b0;
    wait_until_done();
    //Test 3
    
    //random
    for (i = 0; i < 99; i=i++) begin
         @(negedge clock); 
         reset = 1'b1;
         value = {$random,$random};
         guess_value(value, guess);
         #1
         @(negedge clock);
         reset = 1'b0;
         
         wait_until_done();
    end

    //corner case
    @(negedge clock);
    reset =1'b1;
    value = 64'hFFFF_FFFF_FFFF_FFFF;
    guess_value(value, guess);
    #1
    @(negedge clock);
    reset = 1'b0;
    wait_until_done();

    $display("\n@@@ ENDING TESTBENCH!\n");
    $display("\n@@@ Passed\n");
    $finish;

end

endmodule

