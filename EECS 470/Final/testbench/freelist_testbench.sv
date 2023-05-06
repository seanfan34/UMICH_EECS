//TESTBENCH FOR FREELISTfreelist
//Class:    EECS470
//Specific:  Project 4
//Description:

module freelist_testbench;
	logic clock, reset;
    DISPATCH_FREELIST_PACKET freelist_dispatch_in;
    RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]          freelist_retire_in;

    //Precise State
    logic                                                   br_recover_enable;
    MAPTABLE_PACKET                                              recovery_maptable;


	FREELIST_DISPATCH_PACKET freelist_dispatch_out, expected_freelist_dispatch_out;
`ifdef TEST_MODE
    logic [64-1:0] freelist_display ;
    logic [`SUPERSCALAR_WAYS-1:0][64-1:0] gnt_free_idx_display;
`endif

    logic correct;
    int test;

	freelist freelist1(.clock(clock), .reset(reset),
        .freelist_dispatch_in(freelist_dispatch_in),
        .freelist_retire_in(freelist_retire_in),
		.freelist_dispatch_out(freelist_dispatch_out),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable)
`ifdef TEST_MODE
        , .freelist_display(freelist_display)
        , .gnt_free_idx_display(gnt_free_idx_display)
`endif
    );

	assign correct = (freelist_dispatch_out === expected_freelist_dispatch_out);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);

        $display("INITIALIZING FREELIST TESTBENCH");
		test = 0; clock = 0; reset = 1;
        freelist_dispatch_in = 0; freelist_retire_in = 0;
        br_recover_enable = 0;
        expected_freelist_dispatch_out = 0;
		$display("@@@ Test %d: Reset the FREELIST", test);
		verify_answer();

		$display("@@@ Test %d: Dispatch invalid instruction to freelist", test);
		reset = 0;
		verify_answer();


		$display("@@@ Test %d: Dispatch 3 instructions", test);
		dispatch_3_instruction();
		
		expected_freelist_dispatch(1, 1, 1, 6'd63, 6'd62, 6'd61);
        verify_answer();


		$display("@@@ Test %d: Dispatch 3 instructions full case", test);	
		for (int i = 0; i < 9; i = i + 1) begin
			$display("@@@ Test %d: Dispatch 3 instructions", test);
			dispatch_3_instruction();

			expected_freelist_dispatch(1, 1, 1, 6'd60 - (6'd3 * i) , 6'd60 - (6'd3 * i) - 6'd1, 6'd60 - (6'd3 * i) - 6'd2 );
			verify_answer();
		end


		$display("@@@ Test %d: Dispatch 2 instructions", test);
		dispatch_2_instruction();

		expected_freelist_dispatch(1, 1, 0, 6'd33, 6'd32, 6'd0);
		verify_answer();


		$display("@@@ Test %d: Retire 3 instructions and dispatch the 3 instructions", test);
		retire_3_instruction(6'd0, 6'd1, 6'd2);
		dispatch_3_instruction();

		expected_freelist_dispatch(1, 1, 1, 6'd2, 6'd1, 6'd0);
		verify_answer();

		$display("@@@ Test %d: Retire 2 instructions", test);
		retire_2_instruction(6'd12, 6'd5);
        freelist_dispatch_in = 0;

		expected_freelist_dispatch_out = 0;
		verify_answer();


		$display("@@@ Test %d: Retire 1 instructions", test);
		retire_1_instruction(6'd33);
        freelist_dispatch_in = 0;

		expected_freelist_dispatch_out = 0;
		verify_answer();


		$display("@@@ Test %d: Dispatch 1 instructions", test);
		freelist_retire_in = 0;

		dispatch_1_instruction();
		expected_freelist_dispatch(1, 0, 0, 6'd33, 6'd0, 6'd0);
		verify_answer();


		$display("@@@ Test %d: Reset the FREELIST", test);
		reset = 1;
		freelist_retire_in = 0; freelist_dispatch_in = 0;
		expected_freelist_dispatch_out = 0;
		verify_answer();


		$display("@@@ Test %d: Retire 3 instructions and Dispatch 1", test);
		reset = 0;
		retire_3_instruction(6'd0, 6'd31, 6'd1);
		dispatch_1_instruction();
		
		expected_freelist_dispatch(1, 0, 0, 6'd63, 6'd0, 6'd0);
		verify_answer();


		$display("@@@ Test %d: Retire 3 instructions and Dispatch 2", test);
		retire_3_instruction(6'd30, 6'd29, 6'd25);
		dispatch_2_instruction();

		expected_freelist_dispatch(1, 1, 0, 6'd62, 6'd61, 6'd0);
		verify_answer();


        $display("@@@ Test %d: Precise State ", test);
        reset = 1;
        @(negedge clock);
        reset = 0;
        recovery_maptable = 0;
        recovery_maptable.map[5] = 6'd10;
        recovery_maptable.done[5] = 1'b1;
        recovery_maptable.map[3] = 6'd45;
        recovery_maptable.done[3] = 1'b1;
        recovery_maptable.map[7] = 6'd32;
        recovery_maptable.done[7] = 1'b1;
        recovery_maptable.map[31] = 6'd56;
        recovery_maptable.done[31] = 1'b1;
        recovery_maptable.map[28] = 6'd9;
        recovery_maptable.done[28] = 1'b1;
        recovery_maptable.map[18] = 6'd12;
        recovery_maptable.done[18] = 1'b1;
        recovery_maptable.map[29] = 6'd55;
        recovery_maptable.done[29] = 1'b1;

        recovery_maptable.map[10] = 6'd2; //pr 2 in use
        recovery_maptable.done[10] = 1'b1;

        recovery_maptable.map[11] = 6'd3; // pr 3 in use
        recovery_maptable.done[11] = 1'b1;

        recovery_maptable.map[14] = 6'd62; // pr 62 in use
        recovery_maptable.done[14] = 1'b1;


        br_recover_enable = 1'b1;

        dispatch_3_instruction();

        expected_freelist_dispatch(1, 1, 1, 6'd63, 6'd61, 6'd60);
        verify_answer();

        $display("@@@ Test %d: After Precise State ", test);
        br_recover_enable = 1'b0;
        dispatch_3_instruction();
        freelist_retire_in = 0;
        expected_freelist_dispatch(1, 1, 1, 6'd59, 6'd58, 6'd57);
        verify_answer();


        $display("\nENDING FREELIST TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial

	task expected_freelist_dispatch; input valid1, valid2, valid3; input [5:0] t_idx1, t_idx2, t_idx3;begin
		expected_freelist_dispatch_out.valid = { valid3, valid2, valid1 };
		expected_freelist_dispatch_out.t_idx = { t_idx3, t_idx2, t_idx1 };
	end endtask

	task dispatch_3_instruction; begin
		for (int i = 0; i < 3; i = i + 1) begin
            freelist_dispatch_in.new_pr_en[i] = 1;
		end
	end endtask  // dispatch_3_instruction

	task dispatch_2_instruction; begin
        freelist_dispatch_in.new_pr_en[0] = 1;
        freelist_dispatch_in.new_pr_en[1] = 1;
        freelist_dispatch_in.new_pr_en[2] = 0;
	end endtask  // dispatch_2_instruction

	task dispatch_1_instruction; begin
        freelist_dispatch_in.new_pr_en[0] = 1;
        freelist_dispatch_in.new_pr_en[1] = 0;
        freelist_dispatch_in.new_pr_en[2] = 0;
	end endtask  // dispatch_1_instruction

	task retire_3_instruction; input [5:0] told_idx1, told_idx2, told_idx3; begin
		for (int i = 0; i < 3; i = i + 1) begin
            freelist_retire_in[i].valid = 1;
		end
		freelist_retire_in[0].told_idx = told_idx1;
		freelist_retire_in[1].told_idx = told_idx2;
		freelist_retire_in[2].told_idx = told_idx3;
	end endtask  // retire_3_instruction

	task retire_2_instruction; input [5:0] told_idx1, told_idx2; begin
		freelist_retire_in[0].valid = 1;
		freelist_retire_in[1].valid = 1;
		freelist_retire_in[2].valid = 0;

		freelist_retire_in[0].told_idx = told_idx1;
		freelist_retire_in[1].told_idx = told_idx2;
		freelist_retire_in[2].told_idx = 6'd0;
	end endtask  // retire_2_instruction

	task retire_1_instruction; input [5:0] told_idx1; begin
		freelist_retire_in[0].valid = 1;
		freelist_retire_in[1].valid = 0;
		freelist_retire_in[2].valid = 0;

		freelist_retire_in[0].told_idx = told_idx1;
		freelist_retire_in[1].told_idx = 6'd0;
		freelist_retire_in[2].told_idx = 6'd0;
	end endtask  // retire_1_instruction

    task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:\n\treset:%b", reset);

                // Print freelist_dispatch_in input
                for (int i = 0; i < 3; i = i + 1)
                    $display("\tfreelist_dispatch_in.new_pr_en[%d]:%b ", i,
                            freelist_dispatch_in.new_pr_en[i]
                        );

                // Print freelist_retire_in input
                for (int i = 0; i < 3; i = i + 1)
                    $display("\tfreelist_retire_in[%d]: told_idx:%d valid:%b", i,
                        freelist_retire_in[i].told_idx, freelist_retire_in[i].valid);

                // Precise State
                    $display("\tbr_recover_enable:%b", br_recover_enable);

                if(br_recover_enable)
                    for (int i =0 ; i < `N_ARCH_REG ; i += 1)
                        $display("\trecovery_maptable[%d]: PR:%d done:%d", i,
                            recovery_maptable.map[i], recovery_maptable.done[i]);

			$display("@@@ Outputs:");

                // Print freelist_dispatch_out output
                for (int i = 0; i < 3; i = i + 1)
                    $display("\tfreelist_dispatch_out[%d]: t_idx:%d valid:%b", i,
                        freelist_dispatch_out.t_idx[i], freelist_dispatch_out.valid[i]);

			$display("@@@ Expected outputs:");

            // Print expected freelist_dispatch_out output
                for (int i = 0; i < 3; i = i + 1)
                    $display("\texpected_freelist_dispatch_out[%d]: t_idx:%d valid:%b", i,
                        expected_freelist_dispatch_out.t_idx[i], expected_freelist_dispatch_out.valid[i]);

            $display("\tfreelist_dispatch_out === freelist_dispatch_out:%b", freelist_dispatch_out === expected_freelist_dispatch_out);

            for(int i = 0; i < `SUPERSCALAR_WAYS  ; i +=1 ) begin
                $display("\tfreelist_dispatch_out[%d]: t_idx:%d valid:%b <-> expected_freelist_dispatch_out[%d]: t_idx:%d valid:%b",
                    i,freelist_dispatch_out.t_idx[i], freelist_dispatch_out.valid[i],
                    i,expected_freelist_dispatch_out.t_idx[i], expected_freelist_dispatch_out.valid[i]
                    );
            end

`ifdef TEST_MODE
            for(int i = 0; i < 64 ; i +=1 ) begin
                $display("\tfreelist_display[%d]: valid:%b",
                    i,freelist_display[i]);
            end

            // for (int i =0 ; i <3 ;i +=1) begin
            //     for(int j =0 ; j < 64; j +=1) begin
            //         if(gnt_free_idx_display[i][j])
            //             $display("\t gnt_free_idx_display[%d]: %d",
            //                 i,j);
            //     end
            // end
`endif


            $display("ENDING FREELIST TESTBENCH: ERROR!");
			$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer
endmodule
