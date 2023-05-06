module retire_rob_arch_freelist_testbench;
    int test;

    logic correct;

    logic clock, reset;
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_dispatch_in;


    // freelist input
    DISPATCH_FREELIST_PACKET freelist_dispatch_in;

    // rob output
    ROB_DISPATCH_PACKET rob_dispatch_out, expected_rob_dispatch_out;

    // freelist output
    FREELIST_DISPATCH_PACKET freelist_dispatch_out, expected_freelist_dispatch_out;

    // retire connection   
    RETIRE_CONNECTION_PACKET [`SUPERSCALAR_WAYS-1:0] retire_connect_packet, expected_retire_connect_packet;
    FREELIST_CONNECTION_PACKET [`SUPERSCALAR_WAYS-1:0] freelist_connect_packet, expected_freelist_connect_packet;

    ROB_CONNECTION_ENTRY [`SUPERSCALAR_WAYS-1:0] rob_connect_packet, expected_rob_connect_packet;
    MAPTABLE_PACKET recovery_maptable;
    logic br_recover_enable;
    logic [`XLEN-1:0] target_pc;

    retire_rob_arch_freelist retire_rob_arch_freelist_tb (
	.clock(clock), .reset(reset),
		// Inputs 
        .rob_complete_in(rob_complete_in),
        .rob_dispatch_in(rob_dispatch_in),
	.freelist_dispatch_in(freelist_dispatch_in),

		// Outputs
        .rob_dispatch_out(rob_dispatch_out),
        .freelist_dispatch_out(freelist_dispatch_out),

        .retire_connect_packet(retire_connect_packet),
	.freelist_connect_packet(freelist_connect_packet),
	.rob_connect_packet(rob_connect_packet),
        .recovery_maptable(recovery_maptable),                                        
        .br_recover_enable(br_recover_enable),
        .target_pc(target_pc)
    );

	assign correct = (retire_connect_packet === expected_retire_connect_packet) & //(rob_connect_packet === expected_rob_connect_packet)
			& (freelist_connect_packet === expected_freelist_connect_packet);
					 

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_ROB TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;
		
               $display("@@@ Test %1d: Reset", test);
		rob_complete_in = 0;
		rob_dispatch_in = 0;
		freelist_dispatch_in = 0;
		//output
		expected_retire_connect_packet = 0;
		expected_rob_connect_packet = 0;
	        expected_freelist_connect_packet = 0;
		verify_answer();

		$display("@@@ Test %1d: dispatch & complete", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd0;
		rob_complete_in[1].rob_idx = 5'd3;
		rob_complete_in[2].rob_idx = 5'd6;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;

/*		rob_complete_in[0].precise_state_enable = 0;
		rob_complete_in[1].precise_state_enable = 0;
		rob_complete_in[2].precise_state_enable = 0;

		rob_complete_in[0].target_pc = 32'd0;
		rob_complete_in[1].target_pc = 32'd0;
		rob_complete_in[2].target_pc = 32'd0;
*/	
		rob_dispatch_in[0].t_idx = 6'd15;
		rob_dispatch_in[1].t_idx = 6'd18;
		rob_dispatch_in[2].t_idx = 6'd29;
		rob_dispatch_in[0].told_idx = 6'd20;
		rob_dispatch_in[1].told_idx = 6'd21;
		rob_dispatch_in[2].told_idx = 6'd32;
		rob_dispatch_in[0].ar_idx = 5'd17;
		rob_dispatch_in[1].ar_idx = 5'd18;
		rob_dispatch_in[2].ar_idx = 5'd19;
		rob_dispatch_in[0].valid = 1;
		rob_dispatch_in[1].valid = 1;
		rob_dispatch_in[2].valid = 1;
		rob_dispatch_in[0].enable = 1;
		rob_dispatch_in[1].enable = 1;
		rob_dispatch_in[2].enable = 1;

		freelist_dispatch_in.new_pr_en = 3'd7;
		//output
		expected_retire_connect_packet[0].t_idx = 6'd15;
		expected_retire_connect_packet[1].t_idx = 6'd18;
		expected_retire_connect_packet[2].t_idx = 6'd29;

		expected_retire_connect_packet[0].ar_idx = 5'd17;
		expected_retire_connect_packet[1].ar_idx = 5'd18;
		expected_retire_connect_packet[2].ar_idx = 5'd19;
		
		expected_retire_connect_packet[0].complete = 0;
		expected_retire_connect_packet[1].complete = 0;
		expected_retire_connect_packet[2].complete = 0;

		expected_rob_connect_packet[0].t_idx = 6'd15;
		expected_rob_connect_packet[1].t_idx = 6'd18;
		expected_rob_connect_packet[2].t_idx = 6'd29;
		expected_rob_connect_packet[0].told_idx = 6'd20;
		expected_rob_connect_packet[1].told_idx = 6'd21;
		expected_rob_connect_packet[2].told_idx = 6'd32;
		expected_rob_connect_packet[0].ar_idx = 5'd17;
		expected_rob_connect_packet[1].ar_idx = 5'd18;
		expected_rob_connect_packet[2].ar_idx = 5'd19;
/*
		expected_rob_connect_packet[0].precise_state_enable = 0;
		expected_rob_connect_packet[1].precise_state_enable = 0;
		expected_rob_connect_packet[2].precise_state_enable = 0;

		expected_rob_connect_packet[0].target_pc = 32'd0;
		expected_rob_connect_packet[1].target_pc = 32'd0;
		expected_rob_connect_packet[2].target_pc = 32'd0;
		
*/		expected_rob_connect_packet[0].complete = 0;
		expected_rob_connect_packet[1].complete = 0;
		expected_rob_connect_packet[2].complete = 0;


		expected_freelist_connect_packet[0].told_idx =  6'd20;
		expected_freelist_connect_packet[1].told_idx =  6'd21;
		expected_freelist_connect_packet[2].told_idx =  6'd32;
		expected_freelist_connect_packet[0].valid = 0;
		expected_freelist_connect_packet[1].valid = 0;
		expected_freelist_connect_packet[2].valid = 0;
		verify_answer();

		$display("@@@ Test %1d: dispatch & complete", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd21;
		rob_complete_in[1].rob_idx = 5'd24;
		rob_complete_in[2].rob_idx = 5'd27;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;

/*		rob_complete_in[0].precise_state_enable = 0;
		rob_complete_in[1].precise_state_enable = 0;
		rob_complete_in[2].precise_state_enable = 0;

		rob_complete_in[0].target_pc = 32'd0;
		rob_complete_in[1].target_pc = 32'd0;
		rob_complete_in[2].target_pc = 32'd0;
*/	
		rob_dispatch_in[0].t_idx = 6'd15;
		rob_dispatch_in[1].t_idx = 6'd18;
		rob_dispatch_in[2].t_idx = 6'd29;
		rob_dispatch_in[0].told_idx = 6'd20;
		rob_dispatch_in[1].told_idx = 6'd21;
		rob_dispatch_in[2].told_idx = 6'd32;
		rob_dispatch_in[0].ar_idx = 5'd17;
		rob_dispatch_in[1].ar_idx = 5'd18;
		rob_dispatch_in[2].ar_idx = 5'd19;
		rob_dispatch_in[0].valid = 1;
		rob_dispatch_in[1].valid = 1;
		rob_dispatch_in[2].valid = 1;
		rob_dispatch_in[0].enable = 1;
		rob_dispatch_in[1].enable = 1;
		rob_dispatch_in[2].enable = 1;

		freelist_dispatch_in.new_pr_en = 3'd7;
		//output
		expected_retire_connect_packet[0].t_idx = 6'd15;
		expected_retire_connect_packet[1].t_idx = 6'd18;
		expected_retire_connect_packet[2].t_idx = 6'd29;

		expected_retire_connect_packet[0].ar_idx = 5'd17;
		expected_retire_connect_packet[1].ar_idx = 5'd18;
		expected_retire_connect_packet[2].ar_idx = 5'd19;
		
		expected_retire_connect_packet[0].complete = 0;
		expected_retire_connect_packet[1].complete = 0;
		expected_retire_connect_packet[2].complete = 0;

		expected_rob_connect_packet[0].t_idx = 6'd15;
		expected_rob_connect_packet[1].t_idx = 6'd18;
		expected_rob_connect_packet[2].t_idx = 6'd29;
		expected_rob_connect_packet[0].told_idx = 6'd20;
		expected_rob_connect_packet[1].told_idx = 6'd21;
		expected_rob_connect_packet[2].told_idx = 6'd32;
		expected_rob_connect_packet[0].ar_idx = 5'd17;
		expected_rob_connect_packet[1].ar_idx = 5'd18;
		expected_rob_connect_packet[2].ar_idx = 5'd19;
/*
		expected_rob_connect_packet[0].precise_state_enable = 0;
		expected_rob_connect_packet[1].precise_state_enable = 0;
		expected_rob_connect_packet[2].precise_state_enable = 0;

		expected_rob_connect_packet[0].target_pc = 32'd0;
		expected_rob_connect_packet[1].target_pc = 32'd0;
		expected_rob_connect_packet[2].target_pc = 32'd0;
		
*/		expected_rob_connect_packet[0].complete = 0;
		expected_rob_connect_packet[1].complete = 0;
		expected_rob_connect_packet[2].complete = 0;


		expected_freelist_connect_packet[0].told_idx =  6'd20;
		expected_freelist_connect_packet[1].told_idx =  6'd21;
		expected_freelist_connect_packet[2].told_idx =  6'd32;
		expected_freelist_connect_packet[0].valid = 0;
		expected_freelist_connect_packet[1].valid = 0;
		expected_freelist_connect_packet[2].valid = 0;
		verify_answer();


     $display("@@@ Test %1d: Complete instructions", test);
		rob_dispatch_in = 0;
		rob_complete_in[0].rob_idx = 5'b0;
		rob_complete_in[1].rob_idx = 5'd15;
		rob_complete_in[2].rob_idx = 5'd30;
		expected_retire_connect_packet[0].complete = 1;
		expected_retire_connect_packet[1].complete = 0;
		expected_retire_connect_packet[2].complete = 0;
		expected_rob_connect_packet[0].complete = 1;
		expected_rob_connect_packet[1].complete = 0;
		expected_rob_connect_packet[2].complete = 0;
        	verify_answer();


		$display("\nENDING RETIRE_CONNECTION TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; begin
        @(negedge clock);
	     if (~correct) begin
		 $display("@@@ Incorrect at time %4.0f", $time);
		 $display("@@@ Inputs:\n\treset:%b", reset);

            // Print retire_packet output
           for (int i = 0; i < 3; i = i + 1) begin
		$display("@@@\t\tretire_connect_packet[%1d]: t_idx:%d ar_idx:%d complete:%b", i, 
				 retire_connect_packet[i].t_idx, 
				 retire_connect_packet[i].ar_idx, 
				 retire_connect_packet[i].complete);

		$display("@@@\t\trob_connect_packet[%1d]: t_idx:%d told_idx:%d, ar_idx:%d, complete:%b", i, 
				 rob_connect_packet[i].t_idx, 
				 rob_connect_packet[i].told_idx,
				 rob_connect_packet[i].ar_idx, rob_connect_packet[i].complete);
		$display("@@@\t\tfreelist_connect_packet[%1d]: told_idx:%d valid:%b", i, 
				 freelist_connect_packet[i].told_idx,
				 freelist_connect_packet[i].valid);
                
                
            end
/*            for (int i = 0; i < 32; i = i + 1) begin
                
		$display("\tarch_maptable[%d]:%d", i, arch_maptable[i]);
            end
*/
            $display("@@@ Expected outputs:");	
            // Print expected retire_packet output
            for (int i = 0; i < 3; i = i + 1) begin 
	       	$display("@@@\t\texpected_retire_connect_packet[%1d]: t_idx:%d ar_idx:%d complete:%b", i,
			 	expected_retire_connect_packet[i].t_idx,
			 	expected_retire_connect_packet[i].ar_idx, 
				expected_retire_connect_packet[i].complete);
		$display("@@@\t\texpected_rob_connect_packet[%1d]: t_idx:%d told_idx:%d, ar_idx:%d, complete:%b", i, 
				 expected_rob_connect_packet[i].t_idx, 
				 expected_rob_connect_packet[i].told_idx,
				 expected_rob_connect_packet[i].ar_idx, expected_rob_connect_packet[i].complete);
		$display("@@@\t\texpected_freelist_connect_packet[%1d]: told_idx:%d valid:%b", i, 
				 expected_freelist_connect_packet[i].told_idx,
				 expected_freelist_connect_packet[i].valid);
                
	    end
            
	    $display("\nENDING RETIRE_CONNECTION TESTBENCH: ERROR!\n");
	    $finish;
            end

            $display("@@@ Passed Test!");
       	    test = test + 1;
       
       end endtask  // verify_answer

endmodule  // dispatch_rob_testbench
