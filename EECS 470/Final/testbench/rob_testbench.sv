//TESTBENCH FOR ROB
//Class:    EECS470
//Specific:  Project 4
//Description:

module rob_testbench;
	logic clock, reset, correct;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_dispatch_in;
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in;
	ROB_DISPATCH_PACKET rob_dispatch_out, expected_rob_dispatch_out;
    ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_retire_out, expected_rob_retire_out;

    int test;

	rob rob_tb(
		.clock(clock), .reset(reset),
        .rob_dispatch_in(rob_dispatch_in),
        .rob_complete_in(rob_complete_in), 
		.rob_dispatch_out(rob_dispatch_out),
        .rob_retire_out(rob_retire_out)
	);

	assign correct = (rob_dispatch_out.stall === expected_rob_dispatch_out.stall) & 
					 (rob_retire_out === expected_rob_retire_out);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;

        $display("INITIALIZING ROB TESTBENCH");
		test = 0;
		clock = 0;
		reset = 1;
        rob_dispatch_in = 0;
		rob_complete_in = 0;
		expected_rob_dispatch_out = 0;
		expected_rob_retire_out = 0;

		$display("@@@ Test %1d: Reset the ROB", test);
		verify_answer();

		$display("@@@ Test %1d: Dispatch invalid instruction to empty ROB", test);
		reset = 0;
		verify_answer();

		run_single_packet_tests(0);
		run_single_packet_tests(1);
		run_single_packet_tests(2);

		$display("@@@ Test %1d: Dispatch multiple instructions", test);
		rob_dispatch_in[0].enable = 1;
		rob_dispatch_in[1].enable = 1;
		rob_dispatch_in[2].enable = 1;
		rob_dispatch_in[0].valid = 1;
		rob_dispatch_in[1].valid = 1;
		rob_dispatch_in[2].valid = 1;
        increment_dispatch_t_told_idx(1, 6'b1, 6'b1);
        increment_dispatch_t_told_idx(2, 6'd2, 6'd2);
		expected_rob_retire_out[1].t_idx = 6'b1;
		expected_rob_retire_out[1].told_idx = 6'b1;
		expected_rob_retire_out[2].t_idx = 6'd2;
		expected_rob_retire_out[2].told_idx = 6'd2;
        verify_answer();
        
		rob_complete_in[0].complete = 1;
		rob_complete_in[1].complete = 1;
		rob_complete_in[2].complete = 1;
		rob_complete_in[0].rob_idx = 5'b1;
		rob_complete_in[1].rob_idx = 5'd6;
		rob_complete_in[2].rob_idx = 5'd11;
		for (int i = 0; i < 5; i = i + 1) begin
		    $display("@@@ Test %1d: Complete and dispatch multiple instructions", test);
            increment_dispatch_t_told_idx(0, 6'd3, 6'd3);
            increment_dispatch_t_told_idx(1, 6'd3, 6'd3);
            increment_dispatch_t_told_idx(2, 6'd3, 6'd3);
            verify_answer();
		    rob_complete_in[0].rob_idx = rob_complete_in[0].rob_idx + 5'd15;
		    rob_complete_in[1].rob_idx = rob_complete_in[1].rob_idx + 5'd15;
		    rob_complete_in[2].rob_idx = rob_complete_in[2].rob_idx + 5'd15;
        end
		
        $display("@@@ Test %1d: Complete multiple instructions", test);
		rob_dispatch_in = 0;
		rob_complete_in[0].rob_idx = 5'b0;
		rob_complete_in[1].rob_idx = 5'd3;
		rob_complete_in[2].rob_idx = 5'd6;
		expected_rob_retire_out[0].complete = 1'b1;
		expected_rob_retire_out[1].complete = 1'b1;
		expected_rob_retire_out[2].complete = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: Retire multiple instructions", test);
		rob_complete_in = 0;
		expected_rob_retire_out[0].t_idx = 6'd3;
		expected_rob_retire_out[0].told_idx = 6'd3;
		expected_rob_retire_out[1].t_idx = 6'd4;
		expected_rob_retire_out[1].told_idx = 6'd4;
		expected_rob_retire_out[2].t_idx = 6'd5;
		expected_rob_retire_out[2].told_idx = 6'd5;
		expected_rob_retire_out[2].complete = 1'b0;
        verify_answer();

		$display("@@@ Test %1d: Reset the ROB", test);
		reset = 1;
        rob_dispatch_in = 0; rob_complete_in = 0;
		expected_rob_dispatch_out = 0; expected_rob_retire_out = 0;
		verify_answer();
		reset = 0;

		$display("@@@ Test %1d: Dispatch 2 instructions", test);
		rob_dispatch_in[0].enable = 1;
		rob_dispatch_in[1].enable = 1;
		rob_dispatch_in[2].enable = 1;
		rob_dispatch_in[0].valid = 1;
		rob_dispatch_in[2].valid = 1;
		rob_complete_in[1].complete = 1;
		rob_complete_in[2].complete = 1;
		rob_complete_in[1].rob_idx = 5'b1;
		rob_complete_in[2].rob_idx = 5'b0;
        increment_dispatch_t_told_idx(2, 6'd2, 6'd2);
		expected_rob_retire_out[0].t_idx = 6'd0;
		expected_rob_retire_out[0].told_idx = 6'd0;
		expected_rob_retire_out[1].t_idx = 6'd2;
		expected_rob_retire_out[1].told_idx = 6'd2;
        verify_answer();
        
		$display("@@@ Test %1d: Complete all instructions", test);
		rob_dispatch_in[0].valid = 0;
		rob_dispatch_in[2].valid = 0;
		expected_rob_retire_out[0].complete = 1'b1;
		expected_rob_retire_out[1].complete = 1'b1;
        verify_answer();
        
		$display("@@@ Test %1d: Retire all instructions and dispatch", test);
		rob_dispatch_in[0].valid = 1;
		rob_dispatch_in[2].valid = 1;
		expected_rob_retire_out[0].complete = 1'b0;
		expected_rob_retire_out[1].complete = 1'b0;
        verify_answer();

		rob_dispatch_in[1].valid = 1;
        increment_dispatch_t_told_idx(1, 6'd4, 6'd4);
		expected_rob_retire_out[2].t_idx = 6'd6;
		expected_rob_retire_out[2].told_idx = 6'd6;
		rob_complete_in = 0;
		for (int i = 0; i < 8; i = i + 1) begin
		    $display("@@@ Test %1d: Dispatch multiple instructions", test);
            increment_dispatch_t_told_idx(0, 6'd6, 6'd6);
            increment_dispatch_t_told_idx(1, 6'd6, 6'd6);
            increment_dispatch_t_told_idx(2, 6'd6, 6'd6);
            verify_answer();
        end

		$display("@@@ Test %1d: Dispatch one instruction", test);
		rob_dispatch_in[1].enable = 0;
		rob_dispatch_in[2].enable = 0;
        verify_answer();
		
        $display("@@@ Test %1d: Dispatch 3 instructions to ROB that can only fit 2", test);
		rob_dispatch_in[1].enable = 1;
		rob_dispatch_in[2].enable = 1;
        expected_rob_dispatch_out.stall[2] = 1'b1;
        verify_answer();

        $display("\nENDING ROB TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial


    task run_single_packet_tests; input int packet_idx; begin
        $display("RUNNING SINGLE INPUT TESTS WITH PACKET %d", packet_idx);

		$display("@@@ Test %1d: Dispatch valid instruction to empty, disabled ROB", test);
		rob_dispatch_in[packet_idx].valid = 1;
		verify_answer();

		$display("@@@ Test %1d: Dispatch valid instruction to empty ROB", test);
		rob_dispatch_in[packet_idx].t_idx = 6'b0;
		rob_dispatch_in[packet_idx].told_idx = 6'b1;
        expected_rob_retire_out[0].t_idx = 6'b0;
        expected_rob_retire_out[0].told_idx = 6'b1;
		rob_dispatch_in[packet_idx].enable = 1;
		verify_answer();

		$display("@@@ Test %1d: Dispatch invalid instructions to non-empty, non-full ROB", test);
		rob_dispatch_in[packet_idx].enable = 0;
		rob_dispatch_in[packet_idx].valid = 0;
		verify_answer();
        
        $display("@@@ Test %1d: Dispatch valid instruction to disabled ROB with 1 entry", test);
		rob_dispatch_in[packet_idx].valid = 1;
        verify_answer();
        
        $display("@@@ Test %1d: Dispatch valid instruction to ROB with 1 entry", test);
        expected_rob_retire_out[1].t_idx = 6'd2;
        expected_rob_retire_out[1].told_idx = 6'd3;
        increment_dispatch_t_told_idx(packet_idx, 6'd2, 6'd2);
		rob_dispatch_in[packet_idx].enable = 1;
        verify_answer();
        
        $display("@@@ Test %1d: Dispatch valid instruction to ROB with 2 entries", test);
		rob_dispatch_in[packet_idx].valid = 1;
        expected_rob_retire_out[2].t_idx = 6'd4;
        expected_rob_retire_out[2].told_idx = 6'd5;
        increment_dispatch_t_told_idx(packet_idx, 6'd2, 6'd2);
        verify_answer();

		for (int i = 0; i < 28; i = i + 1) begin
            $display("@@@ Test %1d: Dispatch valid instructions to non-empty, non-full ROB", test);
            increment_dispatch_t_told_idx(packet_idx, 6'd2, 6'd2);
            verify_answer();
		end
        
		$display("@@@ Test %1d: Fill ROB", test);
        increment_dispatch_t_told_idx(packet_idx, 6'd2, 6'd2);
		expected_rob_dispatch_out.stall[packet_idx] = 1;
		verify_answer();

		$display("@@@ Test %1d: Dispatch invalid instruction to full ROB", test);
		expected_rob_dispatch_out.stall[packet_idx] = 0;
		rob_dispatch_in[packet_idx].valid = 0;
		verify_answer();

		$display("@@@ Test %1d: Dispatch valid instruction to full ROB", test);
		rob_dispatch_in[packet_idx].valid = 1;
		expected_rob_dispatch_out.stall[packet_idx] = 1;
		verify_answer();
        
		rob_complete_in[packet_idx].complete = 1;
		for (rob_complete_in[packet_idx].rob_idx = 5'b1;
             rob_complete_in[packet_idx].rob_idx != 5'b0; 
             rob_complete_in[packet_idx].rob_idx = rob_complete_in[packet_idx].rob_idx + 1'b1)
        begin
		    $display("@@@ Test %1d: Complete non-head instructions in full ROB", test);
            rob_dispatch_in[packet_idx].valid = $random;
            expected_rob_dispatch_out.stall[packet_idx] = rob_dispatch_in[packet_idx].valid;
            verify_answer();
        end

		$display("@@@ Test %1d: Complete head instruction in ROB", test);
        rob_dispatch_in[packet_idx].valid = 0;
        expected_rob_dispatch_out.stall[packet_idx] = 0;
        expected_rob_retire_out[0].complete = 1;
        expected_rob_retire_out[1].complete = 1;
        expected_rob_retire_out[2].complete = 1;
		verify_answer();

        for (int i = 0; i < 6; i = i + 1) begin
		    $display("@@@ Test %1d: Retire head instruction in ROB", test);
            increment_retire_t_told_idx(6'd6, 6'd6);
            verify_answer();
        end

        for (int i = 0; i < 3; i = i + 1) begin
		    $display("@@@ Test %1d: Dispatch and retire head instruction in ROB", test);
            increment_retire_t_told_idx(6'd6, 6'd6);
            increment_dispatch_t_told_idx(packet_idx, 6'd2, 6'd3);
            verify_answer();
        end
		
		$display("@@@ Test %1d: Dispatch, complete, and retire head instruction in ROB", test);
        increment_retire_t_told_idx(6'd6, 6'd6);
        expected_rob_retire_out[2].told_idx = expected_rob_retire_out[2].told_idx + 6'b1;
        verify_answer();

		$display("@@@ Test %1d: Reset the ROB", test);
		reset = 1;
        rob_dispatch_in = 0; rob_complete_in = 0;
		expected_rob_dispatch_out = 0; expected_rob_retire_out = 0;
		verify_answer();
		reset = 0;
    end endtask  // run_single_dispatch_tests

    task increment_dispatch_t_told_idx; input int packet_idx; input [5:0] t_inc, told_inc; begin
		rob_dispatch_in[packet_idx].t_idx = rob_dispatch_in[packet_idx].t_idx + t_inc;
		rob_dispatch_in[packet_idx].told_idx = rob_dispatch_in[packet_idx].told_idx + told_inc;
    end endtask  // increment_dispatch_t_told_idx

    task increment_retire_t_told_idx; input [5:0] t_inc, told_inc; begin
            expected_rob_retire_out[0].t_idx = expected_rob_retire_out[0].t_idx + t_inc;
            expected_rob_retire_out[0].told_idx = expected_rob_retire_out[0].told_idx + told_inc;
            expected_rob_retire_out[1].t_idx = expected_rob_retire_out[1].t_idx + t_inc;
            expected_rob_retire_out[1].told_idx = expected_rob_retire_out[1].told_idx + told_inc;
            expected_rob_retire_out[2].t_idx = expected_rob_retire_out[2].t_idx + t_inc;
            expected_rob_retire_out[2].told_idx = expected_rob_retire_out[2].told_idx + told_inc;
    end endtask  // increment_retire_t_told_idx

    task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:\n\treset:%b", reset);

            // Print rob_dispatch_in input
            for (int i = 0; i < 3; i = i + 1)
                $display("\trob_dispatch_in[%1d]: t_idx:%2d told_idx:%2d valid:%b", i,
                    rob_dispatch_in[i].t_idx, rob_dispatch_in[i].told_idx, rob_dispatch_in[i].valid);

            // Print rob_complete_in input
            for (int i = 0; i < 3; i = i + 1)
			    $display("\trob_complete_in[%1d]: rob_idx:%2d complete:%b", i,
                    rob_complete_in[i].rob_idx, rob_complete_in[i].complete);

			$display("@@@ Outputs:");

			if (rob_dispatch_out.stall === expected_rob_dispatch_out.stall)
				$display("\tcorrect rob_dispatch_out.stall:%b", rob_dispatch_out.stall);
			else begin
				$display("\tincorrect rob_dispatch_out.stall:%b", rob_dispatch_out.stall);
				$display("\t\texpected:%b", expected_rob_dispatch_out.stall);
			end

            // Print rob_retire_out output
            for (int i = 0; i < 3; i = i + 1) begin
				if (rob_retire_out[i] === expected_rob_retire_out[i])
			    	$display("\tcorrect rob_retire_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b", 
						i, rob_retire_out[i].t_idx, rob_retire_out[i].told_idx,
						rob_retire_out[i].ar_idx, rob_retire_out[i].complete);
				else begin
			    	$display("\tincorrect rob_retire_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b", 
						i, rob_retire_out[i].t_idx, rob_retire_out[i].told_idx,
						rob_retire_out[i].ar_idx, rob_retire_out[i].complete);
			    	$display("\t\texpected: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b", 
						expected_rob_retire_out[i].t_idx, expected_rob_retire_out[i].told_idx,
						expected_rob_retire_out[i].ar_idx, expected_rob_retire_out[i].complete);
				end
			end

            $display("ENDING ROB TESTBENCH: ERROR!");
			//$finish;
		end

        $display("@@@ Passed Test %1d!", test);
        test++;
    end endtask  // verify_answer
endmodule