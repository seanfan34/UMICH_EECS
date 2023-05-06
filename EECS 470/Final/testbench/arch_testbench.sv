module arch_testbench;
    logic clock, reset;

    RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0] arch_retire_in;
    logic [31:0][5:0] arch_maptable, expected_arch_maptable;


    logic correct;
    int test, test1;
    

	arch arch_mpt(.clock(clock), .reset(reset), .arch_retire_in(arch_retire_in), .arch_maptable(arch_maptable));

        
        assign correct = arch_maptable === expected_arch_maptable;



	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    	initial begin
        $dumpvars;

        $display("INITIALIZING ARCH MAPTABLE TESTBENCH");
		clock = 0; 
		reset = 1;
                arch_retire_in = 0;

                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                end

                verify_answer();
		
	$display("@@@ Test 0: Reset the ARCH MAPTABLE");
                

	$display("@@@ Test %d: Retire 3 instructions", test);
		reset = 0;
                arch_retire_in[0].complete = 1'b1;
		arch_retire_in[1].complete = 1'b1;
		arch_retire_in[2].complete = 1'b1;

		arch_retire_in[0].ar_idx = 5'd1;
                arch_retire_in[1].ar_idx = 5'd2;
                arch_retire_in[2].ar_idx = 5'd3; 

		arch_retire_in[0].t_idx = 6'd5;
		arch_retire_in[1].t_idx = 6'd6;
		arch_retire_in[2].t_idx = 6'd7;

                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;
                end
		
        	verify_answer();

	$display("@@@ Test %d: Retire 2 instructions", test);
               
                arch_retire_in[0].complete = 1'b1;
		arch_retire_in[1].complete = 1'b1;
		arch_retire_in[2].complete = 1'b0;

		arch_retire_in[0].ar_idx = 5'd11;
                arch_retire_in[1].ar_idx = 5'd12;
		arch_retire_in[2].ar_idx = 5'd13;
		            
		arch_retire_in[0].t_idx = 6'd15;
		arch_retire_in[1].t_idx = 6'd16;
                arch_retire_in[2].t_idx = 6'd17;

		 for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;
			
                end

        	verify_answer();

	$display("@@@ Test %d: Retire 2 instructions", test);
               
                arch_retire_in[0].complete = 1'b1;
		arch_retire_in[1].complete = 1'b0;
		arch_retire_in[2].complete = 1'b1;

		arch_retire_in[0].ar_idx = 5'd14;
                arch_retire_in[1].ar_idx = 5'd15;
		arch_retire_in[2].ar_idx = 5'd16;
		            
		arch_retire_in[0].t_idx = 6'd24;
		arch_retire_in[1].t_idx = 6'd25;
                arch_retire_in[2].t_idx = 6'd26;

		 for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;

			
                end
	
        	verify_answer();

	$display("@@@ Test %d: Retire 2 instructions", test);
               
                arch_retire_in[0].complete = 1'b0;
		arch_retire_in[1].complete = 1'b1;
		arch_retire_in[2].complete = 1'b1;

		arch_retire_in[0].ar_idx = 5'd17;
                arch_retire_in[1].ar_idx = 5'd18;
		arch_retire_in[2].ar_idx = 5'd19;
		            
		arch_retire_in[0].t_idx = 6'd27;
		arch_retire_in[1].t_idx = 6'd28;
                arch_retire_in[2].t_idx = 6'd29;

		 for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;
			
			expected_arch_maptable[5'd18] = 6'd28;
			expected_arch_maptable[5'd19] = 6'd29;

                end

        	verify_answer();

	$display("@@@ Test %d: Retire 1 instruction", test);
               
                arch_retire_in[0].complete = 1'b1;
		arch_retire_in[1].complete = 1'b0;
		arch_retire_in[2].complete = 1'b0;

		arch_retire_in[0].ar_idx = 5'd22;
                arch_retire_in[1].ar_idx = 5'd23;
		arch_retire_in[2].ar_idx = 5'd24;		
                              
		arch_retire_in[0].t_idx = 6'd28;
		arch_retire_in[1].t_idx = 6'd30;
                arch_retire_in[2].t_idx = 6'd31;
                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;
			
			expected_arch_maptable[5'd18] = 6'd28;
			expected_arch_maptable[5'd19] = 6'd29;
                        
                        expected_arch_maptable[5'd22] = 6'd28;
                end
	
        	verify_answer();	

	
	$display("@@@ Test %d: Retire 1 instruction", test);
              
                arch_retire_in[0].complete = 1'b0;
		arch_retire_in[1].complete = 1'b1;
		arch_retire_in[2].complete = 1'b0;

		arch_retire_in[0].ar_idx = 5'd22;
                arch_retire_in[1].ar_idx = 5'd23;
		arch_retire_in[2].ar_idx = 5'd24;		
                              
		arch_retire_in[0].t_idx = 6'd28;
		arch_retire_in[1].t_idx = 6'd30;
                arch_retire_in[2].t_idx = 6'd31;
                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;
			
			expected_arch_maptable[5'd18] = 6'd28;
			expected_arch_maptable[5'd19] = 6'd29;
                        
                        expected_arch_maptable[5'd22] = 6'd28;

                        expected_arch_maptable[5'd23] = 6'd30;
                end
	
        	verify_answer();

	$display("@@@ Test %d: Retire 1 instruction", test);
              
                arch_retire_in[0].complete = 1'b0;
		arch_retire_in[1].complete = 1'b0;
		arch_retire_in[2].complete = 1'b1;

		arch_retire_in[0].ar_idx = 5'd22;
                arch_retire_in[1].ar_idx = 5'd23;
		arch_retire_in[2].ar_idx = 5'd24;		
                              
		arch_retire_in[0].t_idx = 6'd28;
		arch_retire_in[1].t_idx = 6'd30;
                arch_retire_in[2].t_idx = 6'd31;
                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;
			
			expected_arch_maptable[5'd18] = 6'd28;
			expected_arch_maptable[5'd19] = 6'd29;
                        
                        expected_arch_maptable[5'd22] = 6'd28;

                        expected_arch_maptable[5'd23] = 6'd30;

			expected_arch_maptable[5'd24] = 6'd31;

                end
	
        	verify_answer();


	$display("@@@ Test %d: Retire 0 instruction", test);
               
                arch_retire_in[0].complete = 1'b0;
		arch_retire_in[1].complete = 1'b0;
		arch_retire_in[2].complete = 1'b0;

		arch_retire_in[0].ar_idx = 5'd22;
                arch_retire_in[1].ar_idx = 5'd23;
		arch_retire_in[2].ar_idx = 5'd24;	
	                           
		arch_retire_in[0].t_idx = 6'd25;
		arch_retire_in[1].t_idx = 6'd26;
                arch_retire_in[2].t_idx = 6'd27;

		for(int i = 0; i < 32; i++) begin
                	
                	expected_arch_maptable[i] = i;
                        expected_arch_maptable[5'd1] = 6'd5;
			expected_arch_maptable[5'd2] = 6'd6;
			expected_arch_maptable[5'd3] = 6'd7;

                        expected_arch_maptable[5'd11] = 6'd15;
			expected_arch_maptable[5'd12] = 6'd16;

			expected_arch_maptable[5'd14] = 6'd24;
			expected_arch_maptable[5'd16] = 6'd26;
			
			expected_arch_maptable[5'd18] = 6'd28;
			expected_arch_maptable[5'd19] = 6'd29;
                        
                        expected_arch_maptable[5'd22] = 6'd28;

                        expected_arch_maptable[5'd23] = 6'd30;

			expected_arch_maptable[5'd24] = 6'd31;
                end	
        	verify_answer();


        
	$display("@@@ Test 0: Reset ARCH MAPTABLE");
		 
		reset = 1;
                arch_retire_in = 0;

                for(int i = 0; i < 32; i++) begin
                	expected_arch_maptable[i] = i;
                end

                verify_answer();

	$display("@@@ Test %d: Retire 3 instructions", test1);
		reset = 0;
                arch_retire_in[0].complete = 1'b1;
		arch_retire_in[1].complete = 1'b1;
		arch_retire_in[2].complete = 1'b1;

               
		arch_retire_in[0].ar_idx = $urandom_range(0,31);
                arch_retire_in[1].ar_idx = $urandom_range(0,31);
                arch_retire_in[2].ar_idx = $urandom_range(0,31); 

		arch_retire_in[0].t_idx = $urandom_range(0,63);
		arch_retire_in[1].t_idx = $urandom_range(0,63);
		arch_retire_in[2].t_idx = $urandom_range(0,63);
		
		verify_answer1();

	$display("@@@ Test %d: Retire random instructions", test1);
                retire_random_instruction();
               
		arch_retire_in[0].ar_idx = $urandom_range(0,31);
                arch_retire_in[1].ar_idx = $urandom_range(0,31);
                arch_retire_in[2].ar_idx = $urandom_range(0,31); 

		arch_retire_in[0].t_idx = $urandom_range(0,63);
		arch_retire_in[1].t_idx = $urandom_range(0,63);
		arch_retire_in[2].t_idx = $urandom_range(0,63);

		verify_answer1();

	$display("@@@ Test %d: Retire random instructions", test1);
                retire_random_instruction();
               
		arch_retire_in[0].ar_idx = $urandom_range(0,31);
                arch_retire_in[1].ar_idx = $urandom_range(0,31);
                arch_retire_in[2].ar_idx = $urandom_range(0,31); 

		arch_retire_in[0].t_idx = $urandom_range(0,63);
		arch_retire_in[1].t_idx = $urandom_range(0,63);
		arch_retire_in[2].t_idx = $urandom_range(0,63);

		verify_answer1();

	$display("@@@ Test %d: Retire random instructions", test1);
                retire_random_instruction();
               
		arch_retire_in[0].ar_idx = $urandom_range(0,31);
                arch_retire_in[1].ar_idx = $urandom_range(0,31);
                arch_retire_in[2].ar_idx = $urandom_range(0,31); 

		arch_retire_in[0].t_idx = $urandom_range(0,63);
		arch_retire_in[1].t_idx = $urandom_range(0,63);
		arch_retire_in[2].t_idx = $urandom_range(0,63);

		verify_answer1();

	$display("\nENDING ARCH TESTBENCH: SUCCESS!\n");
        $finish;
    	end // initial

	task retire_random_instruction; begin
		for( int i = 0; i < 3; i = i + 1)
		arch_retire_in[i].complete = $urandom_range(0,1);

	end endtask  // retire_random_instruction


	task verify_answer1; begin
        @(negedge clock);
            // Print arch_retire_in output
            for (int i = 0; i < 3; i = i + 1) begin
		
                $display("\tretire.packet[%d]: complete:%d", i, arch_retire_in[i].complete); 
		$display("\tretire.packet[%d]: ar_idx:%d", i, arch_retire_in[i].ar_idx);
		$display("\tarch_retire_in[%d]: t_idx:%d", i, arch_retire_in[i].t_idx);
            end
            for (int i = 0; i < 32; i = i + 1) begin
                
		$display("\tarch_maptable[%d]:%d", i, arch_maptable[i]);
            end
        test1 = test1 + 1;
        end endtask  // verify_answer

	task verify_answer; begin
        @(negedge clock);
	     if (~correct) begin
		 $display("@@@ Incorrect at time %4.0f", $time);
		 $display("@@@ Inputs:\n\treset:%b", reset);

            // Print arch_retire_in output
           for (int i = 0; i < 3; i = i + 1) begin
		$display("\tretire.packet[%d]: ar_idx:%d", i, arch_retire_in[i].ar_idx);		
		$display("\tarch_retire_in[%d]: t_idx:%d", i, arch_retire_in[i].t_idx);
		
                
            end
            for (int i = 0; i < 32; i = i + 1) begin
                
		$display("\tarch_maptable[%d]:%d", i, arch_maptable[i]);
            end

            $display("@@@ Expected outputs:");	
            // Print expected arch_retire_in output
            for (int j = 0; j < 32; j = j + 1) begin 
	        $display("\texpected_arch_maptable[%d]:%d", j, expected_arch_maptable[j]);
            end

            $display("ENDING ROB TESTBENCH: ERROR!");
	    $finish;
            end

            $display("@@@ Passed Test!");
       test = test + 1;
       
       end endtask  // verify_answer

endmodule
