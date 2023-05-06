module dispatch_freelist_testbench;
    int test;
	logic skip_dispatch, skip_internal;
	logic dispatch_correct, internal_correct, rs_correct, correct;

	// Inputs for fetch
    logic clock, reset, br_recover_enable;
    MAPTABLE_PACKET recovery_maptable;
	RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0] freelist_retire_in;

    // Inputs for dispatch
	logic branch_flush_en;
    MAPTABLE_PACKET dispatch_maptable_in;
    RS_DISPATCH_PACKET dispatch_rs_in;  
    ROB_DISPATCH_PACKET dispatch_rob_in;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

    // Outputs from dispatch
    DISPATCH_FETCH_PACKET dispatch_fetch_out, expected_dispatch_fetch_out;
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    // Connections between fetch and dispatch
    FREELIST_DISPATCH_PACKET  freelist_to_dispatch, expected_freelist_to_dispatch;
    DISPATCH_FREELIST_PACKET  dispatch_to_freelist, expected_dispatch_to_freelist;

	// Test
	FREELIST [`N_PHYS_REG-1:0] freelist_display;
    
	dispatch_freelist dispatch_freelist_tb(
		.clock(clock),
		.reset(reset),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		.freelist_retire_in(freelist_retire_in),
		.branch_flush_en(branch_flush_en),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rs_in(dispatch_rs_in),
		.dispatch_rob_in(dispatch_rob_in),
		.dispatch_fetch_in(dispatch_fetch_in),

		.dispatch_fetch_out(dispatch_fetch_out),
		.dispatch_rs_out(dispatch_rs_out),
		.dispatch_rob_out(dispatch_rob_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.freelist_to_dispatch(freelist_to_dispatch),
		.dispatch_to_freelist(dispatch_to_freelist)

		`ifdef TEST_MODE
    	, .freelist_display(freelist_display)
		, .logic_display(logic_display)
    	`endif
	);

    assign dispatch_correct = (dispatch_fetch_out === expected_dispatch_fetch_out) &
							  (dispatch_rob_out === expected_dispatch_rob_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) & rs_correct;
	
    assign internal_correct = (freelist_to_dispatch === expected_freelist_to_dispatch) &
							  (dispatch_to_freelist === expected_dispatch_to_freelist);

	assign correct = (skip_dispatch | dispatch_correct) & (skip_internal | internal_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_FREELIST TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;
		clear();

		$display("@@@ Test %1d: Reset", test);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_freelist_to_dispatch.t_idx[i]  = 8'b0;
			expected_freelist_to_dispatch.valid[i] = 0;
			expected_dispatch_to_freelist.new_pr_en[i] = 0;
		end
		verify_answer(0, 1);

		$display("@@@ Test %1d: dispatch 3 from freelist", test);
		reset = 0;
		br_recover_enable = 0;
	
		freelist_retire_in = 0;
		branch_flush_en =  0;

		for(int i = 0; i < `N_ARCH_REG; i++) begin
		dispatch_maptable_in.done[i] = 1;
		dispatch_maptable_in.map[i] = i;
		end
		recovery_maptable = dispatch_maptable_in;

	    for (int i = 0; i < 3; i++) begin
            dispatch_fetch_in[i].valid = 1'b1;
            dispatch_fetch_in[i].inst = `RV32_ADD;
            dispatch_fetch_in[i].inst.r.rs1 = 8;
            dispatch_fetch_in[i].inst.r.rs2 = 4;
            dispatch_fetch_in[i].inst.r.rd  = 2;
        end
		// dispatch_rs_in = 0;
		// dispatch_rob_in = 0;
		// dispatch_fetch_in[0].valid = 1;
		// dispatch_fetch_in[1].valid = 1;
		// dispatch_fetch_in[2].valid = 1;
		// dispatch_fetch_in[0].PC = 32'd0;
		// dispatch_fetch_in[1].PC = 32'd4;
		// dispatch_fetch_in[2].PC = 32'd8;
		// dispatch_fetch_in[0].NPC = 32'd4;
		// dispatch_fetch_in[1].NPC = 32'd8;
		// dispatch_fetch_in[2].NPC = 32'd12;
		// dispatch_fetch_in[0].inst = {7'd1, 5'd5, 5'd4, 3'd0, 5'd10, 7'b0110011};
		// dispatch_fetch_in[1].inst = {7'd1, 5'd6, 5'd7, 3'd0, 5'd2, 7'b0110011};
		// dispatch_fetch_in[2].inst = {7'd1, 5'd8, 5'd9, 3'd0, 5'd3, 7'b0110011};

		expected_freelist_to_dispatch.t_idx[0]  = 8'd63;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd62;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd61;
		expected_freelist_to_dispatch.valid[0] = 1;
		expected_freelist_to_dispatch.valid[1] = 1;
		expected_freelist_to_dispatch.valid[2] = 1;
		expected_dispatch_to_freelist.new_pr_en[0] = 1;
		expected_dispatch_to_freelist.new_pr_en[1] = 1;
		expected_dispatch_to_freelist.new_pr_en[2] = 1;
		verify_answer(0, 1);

		$display("@@@ Test %1d: dispatch 2 from freelist", test);
		reset = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		freelist_retire_in = 0;
		branch_flush_en =  0;
		dispatch_maptable_in = 0;
		dispatch_rs_in = 0;
		dispatch_rob_in = 0;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[2].valid = 0;
		dispatch_fetch_in[0].PC = 32'd12;
		dispatch_fetch_in[1].PC = 32'd16;
		dispatch_fetch_in[2].PC = 32'd16;
		dispatch_fetch_in[0].NPC = 32'd16;
		dispatch_fetch_in[1].NPC = 32'd20;
		dispatch_fetch_in[2].NPC = 32'd20;
		

		expected_freelist_to_dispatch.t_idx[0]  = 8'd60;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd59;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd0;
		expected_freelist_to_dispatch.valid[0] = 1;
		expected_freelist_to_dispatch.valid[1] = 1;
		expected_freelist_to_dispatch.valid[2] = 0;
		expected_dispatch_to_freelist.new_pr_en[0] = 1;
		expected_dispatch_to_freelist.new_pr_en[1] = 1;
		expected_dispatch_to_freelist.new_pr_en[2] = 0;
		verify_answer(0, 1);

		$display("@@@ Test %1d: retire 3 from freelist", test);
		reset = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		branch_flush_en =  0;
		dispatch_maptable_in = 0;
		dispatch_rs_in = 0;
		dispatch_rob_in = 0;
		dispatch_fetch_in[0].valid = 0;
		dispatch_fetch_in[1].valid = 0;
		dispatch_fetch_in[2].valid = 0;
		freelist_retire_in[0].valid = 1;
		freelist_retire_in[1].valid = 1;
		freelist_retire_in[2].valid = 1;
		freelist_retire_in[0].told_idx = 8'd1;
		freelist_retire_in[1].told_idx = 8'd63;
		freelist_retire_in[2].told_idx = 8'd61;

		expected_freelist_to_dispatch.t_idx[0]  = 8'd0;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd0;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd0;
		expected_freelist_to_dispatch.valid[0] = 0;
		expected_freelist_to_dispatch.valid[1] = 0;
		expected_freelist_to_dispatch.valid[2] = 0;
		expected_dispatch_to_freelist.new_pr_en[0] = 0;
		expected_dispatch_to_freelist.new_pr_en[1] = 0;
		expected_dispatch_to_freelist.new_pr_en[2] = 0;
		verify_answer(0, 1);

		$display("@@@ Test %1d: dispatch 1 from freelist", test);
		reset = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		branch_flush_en =  0;
		dispatch_maptable_in = 0;
		dispatch_rs_in = 0;
		dispatch_rob_in = 0;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[1].valid = 0;
		dispatch_fetch_in[2].valid = 0;
		freelist_retire_in = 0;

		expected_freelist_to_dispatch.t_idx[0]  = 8'd63;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd0;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd0;
		expected_freelist_to_dispatch.valid[0] = 1;
		expected_freelist_to_dispatch.valid[1] = 0;
		expected_freelist_to_dispatch.valid[2] = 0;
		expected_dispatch_to_freelist.new_pr_en[0] = 1;
		expected_dispatch_to_freelist.new_pr_en[1] = 0;
		expected_dispatch_to_freelist.new_pr_en[2] = 0;
		verify_answer(0, 1);

		$display("@@@ Test %1d: Precise state", test);
		reset = 0;
		br_recover_enable = 1;
		// map
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


		branch_flush_en =  0;
		dispatch_maptable_in = 0;
		dispatch_rs_in = 0;
		dispatch_rob_in = 0;
		dispatch_fetch_in[0].valid = 0;
		dispatch_fetch_in[1].valid = 0;
		dispatch_fetch_in[2].valid = 0;
		freelist_retire_in = 0;

		expected_freelist_to_dispatch.t_idx[0]  = 8'd0;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd0;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd0;
		expected_freelist_to_dispatch.valid[0] = 0;
		expected_freelist_to_dispatch.valid[1] = 0;
		expected_freelist_to_dispatch.valid[2] = 0;
		expected_dispatch_to_freelist.new_pr_en[0] = 0;
		expected_dispatch_to_freelist.new_pr_en[1] = 0;
		expected_dispatch_to_freelist.new_pr_en[2] = 0;
		
		verify_answer(0, 1);

		$display("@@@ Test %1d: dispatch 3 from freelist", test);
		reset = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		freelist_retire_in = 0;
		branch_flush_en =  0;
		dispatch_maptable_in = 0;
		dispatch_rs_in = 0;
		dispatch_rob_in = 0;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[2].valid = 1;

		expected_freelist_to_dispatch.t_idx[0]  = 8'd63;
		expected_freelist_to_dispatch.t_idx[1]  = 8'd61;
		expected_freelist_to_dispatch.t_idx[2]  = 8'd60;
		expected_freelist_to_dispatch.valid[0] = 1;
		expected_freelist_to_dispatch.valid[1] = 1;
		expected_freelist_to_dispatch.valid[2] = 1;
		expected_dispatch_to_freelist.new_pr_en[0] = 1;
		expected_dispatch_to_freelist.new_pr_en[1] = 1;
		expected_dispatch_to_freelist.new_pr_en[2] = 1;
		verify_answer(0, 1);




		$display("\nENDING DISPATCH_FREELIST TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task clear;
		br_recover_enable = 0;
		recovery_maptable = 0;
		freelist_retire_in = 0;
		branch_flush_en = 0;
        dispatch_fetch_in = 0;
        dispatch_rs_in = 0;
        dispatch_rob_in = 0;
        dispatch_maptable_in = 0;
        
		expected_dispatch_fetch_out = 0;
		expected_dispatch_rs_out = 0;
		expected_dispatch_rob_out = 0;
        expected_dispatch_maptable_out = 0;
        expected_dispatch_to_freelist = 0;
		expected_freelist_to_dispatch = 0;

        for (int i = 0; i < 3; i++) begin
            dispatch_fetch_in[i].inst.r.rs1 = 0;
            dispatch_fetch_in[i].inst.r.rs2 = 0;
            dispatch_fetch_in[i].inst.r.rd  = 0;

            expected_dispatch_rs_out[i].inst.r.rs1 = 0;
            expected_dispatch_rs_out[i].inst.r.rs2 = 0;
            expected_dispatch_rs_out[i].inst.r.rd  = 0;
        end
    endtask

	task verify_answer; 
		input check_dispatch;	 // check dispatch output other than dispatch_to_freelist is as expected
		input check_connection;  // check freelist_to_dispatch and dispatch_to_freelist are as expected
	begin
		skip_dispatch = ~check_dispatch;
		skip_internal = ~check_connection;
		rs_correct = 1'b1;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (expected_dispatch_rs_out[i].valid)
                rs_correct = rs_correct & dispatch_rs_out[i].valid &
                             (dispatch_rs_out[i].PC === expected_dispatch_rs_out[i].PC) &
                             (dispatch_rs_out[i].NPC === expected_dispatch_rs_out[i].NPC) &
                             (dispatch_rs_out[i].enable === expected_dispatch_rs_out[i].enable) &
                             (dispatch_rs_out[i].reg1_pr_idx === expected_dispatch_rs_out[i].reg1_pr_idx) &
                             (dispatch_rs_out[i].reg2_pr_idx === expected_dispatch_rs_out[i].reg2_pr_idx) &
							 (dispatch_rs_out[i].inst.r.rs1 === expected_dispatch_rs_out[i].inst.r.rs1) &
							 (dispatch_rs_out[i].inst.r.rs2 === expected_dispatch_rs_out[i].inst.r.rs2) &
                             (dispatch_rs_out[i].reg1_ready === expected_dispatch_rs_out[i].reg1_ready) &
                             (dispatch_rs_out[i].reg2_ready === expected_dispatch_rs_out[i].reg2_ready) &
                             (dispatch_rs_out[i].rob_idx === expected_dispatch_rs_out[i].rob_idx) &
							 (dispatch_rs_out[i].inst.r.rd === expected_dispatch_rs_out[i].inst.r.rd) &
                             (dispatch_rs_out[i].pr_idx === expected_dispatch_rs_out[i].pr_idx);
            else rs_correct = rs_correct & ~dispatch_rs_out[i].valid;
		end
        @(negedge clock);
	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b", reset, branch_flush_en);

		 	$display("@@@\tdone maptable entries:");
			for (int i = 0; i < `N_ARCH_REG; i++)
				if (dispatch_maptable_in.done[i])
		 			$display("@@@\t\tar_idx:%2d phys_reg_idx:%2d", i, dispatch_maptable_in.map[i]);

		 	$display("@@@\tdispatch_rs_in: stall:%b", dispatch_rs_in.stall);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				$display("@@@\tdispatch_fetch_in[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
						 i, dispatch_fetch_in[i].inst, dispatch_fetch_in[i].PC, 
						 dispatch_fetch_in[i].NPC, dispatch_fetch_in[i].valid);
			
		 	$display("@@@ Outputs:");

			if (~skip_dispatch) begin
				if (dispatch_fetch_out === expected_dispatch_fetch_out)
					$display("@@@\tcorrect dispatch_fetch_out: enable:%b first_stall_idx:%2d", 
							 dispatch_fetch_out.enable, dispatch_fetch_out.first_stall_idx);
				else begin
					$display("@@@\tincorrect dispatch_fetch_out: enable:%b first_stall_idx:%2d", 
							 dispatch_fetch_out.enable, dispatch_fetch_out.first_stall_idx);
					$display("@@@\t                    expected: enable:%b first_stall_idx:%2d", 
							 expected_dispatch_fetch_out.enable, 
							 expected_dispatch_fetch_out.first_stall_idx);
				end  // incorrect dispatch_to_fetch

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\tdispatch_rs_out[%1d]:", i);

					if (dispatch_rs_out[i].valid & ~expected_dispatch_rs_out[i].valid)
						$display("@@@\t\tincorrect valid:1\t\t       expected:0");
					else begin
						if (dispatch_rs_out[i].PC === expected_dispatch_rs_out[i].PC &
							dispatch_rs_out[i].NPC === expected_dispatch_rs_out[i].NPC)
							$display("@@@\t\tcorrect PCs: PC:%d NPC:%d",
									 dispatch_rs_out[i].PC, dispatch_rs_out[i].NPC);
						else begin
							$display("@@@\t\tincorrect PC(s): PC:%d NPC:%d",
									 dispatch_rs_out[i].PC, dispatch_rs_out[i].NPC);
							$display("@@@\t\t       expected: PC:%d NPC:%d",
									 expected_dispatch_rs_out[i].PC, expected_dispatch_rs_out[i].NPC);
						end  // incorrect PC or NPC

						if (dispatch_rs_out[i].valid === expected_dispatch_rs_out[i].valid &
							dispatch_rs_out[i].enable === expected_dispatch_rs_out[i].enable)
							$display("@@@\t\tcorrect valid and enable: valid:%b enable:%b",
									 dispatch_rs_out[i].valid, dispatch_rs_out[i].enable);
						else begin
							$display("@@@\t\tincorrect valid or enable: valid:%b enable:%b",
									 dispatch_rs_out[i].valid, dispatch_rs_out[i].enable);
							$display("@@@\t\t                 expected: valid:%b enable:%b",
									 expected_dispatch_rs_out[i].valid, expected_dispatch_rs_out[i].enable);
						end  // incorrect valid or enable

						if (dispatch_rs_out[i].inst.r.rs1 === expected_dispatch_rs_out[i].inst.r.rs1 &
							dispatch_rs_out[i].inst.r.rs2 === expected_dispatch_rs_out[i].inst.r.rs2 &
							dispatch_rs_out[i].inst.r.rd === expected_dispatch_rs_out[i].inst.r.rd)
							$display("@@@\t\tcorrect inst: rs1:%2d rs2:%2d rd:%2d",
									 dispatch_rs_out[i].inst.r.rs1, dispatch_rs_out[i].inst.r.rs2, 
									 dispatch_rs_out[i].inst.r.rd);
						else begin
							$display("@@@\t\tincorrect inst: rs1:%2d rs2:%2d rd:%2d",
									 dispatch_rs_out[i].inst.r.rs1, 
									 dispatch_rs_out[i].inst.r.rs2, 
									 dispatch_rs_out[i].inst.r.rd);
							$display("@@@\t\t      expected: rs1:%2d rs2:%2d rd:%2d",
									 expected_dispatch_rs_out[i].inst.r.rs1,
									 expected_dispatch_rs_out[i].inst.r.rs2,
									 expected_dispatch_rs_out[i].inst.r.rd);
						end  // incorrect inst

						if (dispatch_rs_out[i].reg1_pr_idx === expected_dispatch_rs_out[i].reg1_pr_idx &
							dispatch_rs_out[i].reg2_pr_idx === expected_dispatch_rs_out[i].reg2_pr_idx &
							dispatch_rs_out[i].pr_idx === expected_dispatch_rs_out[i].pr_idx)
							$display("@@@\t\tcorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 dispatch_rs_out[i].reg1_pr_idx, 
									 dispatch_rs_out[i].reg2_pr_idx, 
									 dispatch_rs_out[i].pr_idx);
						else begin
							$display("@@@\t\tincorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 dispatch_rs_out[i].reg1_pr_idx,
									 dispatch_rs_out[i].reg2_pr_idx, 
									 dispatch_rs_out[i].pr_idx);
							$display("@@@\t\t     expected: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 expected_dispatch_rs_out[i].reg1_pr_idx, 
									 expected_dispatch_rs_out[i].reg2_pr_idx,
									 expected_dispatch_rs_out[i].pr_idx);
						end  // incorrect prs

						if (dispatch_rs_out[i].reg1_ready === expected_dispatch_rs_out[i].reg1_ready &
							dispatch_rs_out[i].reg2_ready === expected_dispatch_rs_out[i].reg2_ready)
							$display("@@@\t\tcorrect readys: reg1_ready:%b reg2_ready:%b",
									 dispatch_rs_out[i].reg1_ready, 
									 dispatch_rs_out[i].reg2_ready);
						else begin
							$display("@@@\t\tincorrect readys: reg1_ready:%b reg2_ready:%b",
									 dispatch_rs_out[i].reg1_ready, 
									 dispatch_rs_out[i].reg2_ready);
							$display("@@@\t\t        expected: reg1_ready:%b reg2_ready:%b",
									 expected_dispatch_rs_out[i].reg1_ready, 
									 expected_dispatch_rs_out[i].reg2_ready);
						end  // incorrect reg readys

						if (dispatch_rs_out[i].rob_idx === expected_dispatch_rs_out[i].rob_idx)
							$display("@@@\t\tcorrect rob_idx:%2d", dispatch_rs_out[i].rob_idx);
						else begin
							$display("@@@\t\tincorrect rob_idx:%2d", dispatch_rs_out[i].rob_idx);
							$display("@@@\t\t           expected:%2d", expected_dispatch_rs_out[i].rob_idx);
						end  // incorrect rob entry
					end  // if (rs.valid & ~expected_rs.valid)
				end  // for RS output

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\tdispatch_rob_out[%1d]:", i);

					if (dispatch_rob_out[i].t_idx === expected_dispatch_rob_out[i].t_idx &
						dispatch_rob_out[i].told_idx === expected_dispatch_rob_out[i].told_idx &
						dispatch_rob_out[i].ar_idx === expected_dispatch_rob_out[i].ar_idx)
						$display("@@@\t\tcorrect reg idxes: t_idx:%2d told_idx:%2d ar_idx:%2d",
								 dispatch_rob_out[i].t_idx, 
								 dispatch_rob_out[i].told_idx, 
								 dispatch_rob_out[i].ar_idx);
					else begin
						$display("@@@\t\tincorrect reg idxes: t_idx:%2d told_idx:%2d ar_idx:%2d",
								 dispatch_rob_out[i].t_idx, 
								 dispatch_rob_out[i].told_idx, 
								 dispatch_rob_out[i].ar_idx);
						$display("@@@\t\t           expected: t_idx:%2d told_idx:%2d ar_idx:%2d",
								 expected_dispatch_rob_out[i].t_idx, 
								 expected_dispatch_rob_out[i].told_idx, 
								 expected_dispatch_rob_out[i].ar_idx);
					end  // incorrect reg index

					if (dispatch_rob_out[i].valid === expected_dispatch_rob_out[i].valid &
						dispatch_rob_out[i].enable === expected_dispatch_rob_out[i].enable)
						$display("@@@\t\tcorrect valid and enable: valid:%b enable:%b",
								 dispatch_rob_out[i].valid, dispatch_rob_out[i].enable);
					else begin
						$display("@@@\t\tincorrect valid or enable: valid:%b enable:%b",
								 dispatch_rob_out[i].valid, dispatch_rob_out[i].enable);
						$display("@@@\t\t                 expected: valid:%b enable:%b",
								 expected_dispatch_rob_out[i].valid, 
								 expected_dispatch_rob_out[i].enable);
					end  // incorrect valid or enable
				end  // for ROB output

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (dispatch_maptable_out[i] === expected_dispatch_maptable_out[i])
						$display("@@@\tcorrect dispatch_maptable_out[%1d]: enable:%b pr_idx:%2d ar_idx:%2d", 
								 i, dispatch_maptable_out[i].enable, dispatch_maptable_out[i].pr_idx, 
								 dispatch_maptable_out[i].ar_idx);
					else begin
						$display("@@@\tincorrect dispatch_maptable_out[%1d]: enable:%b pr_idx:%2d ar_idx:%2d", 
								 i, dispatch_maptable_out[i].enable, dispatch_maptable_out[i].pr_idx, 
								 dispatch_maptable_out[i].ar_idx);
						$display("@@@\t                     expected: enable:%b pr_idx:%2d ar_idx:%2d", 
								 expected_dispatch_maptable_out[i].enable, 
								 expected_dispatch_maptable_out[i].pr_idx, 
								 expected_dispatch_maptable_out[i].ar_idx);
					end  // incorrect map
				end  // for MAP output
			end  // if (~skip_dispatch)

			if (~skip_internal) begin
				`ifdef TEST_MODE
							$display("freelist_to_dispatch === expected_freelist_to_dispatch: %b", freelist_to_dispatch === expected_freelist_to_dispatch);
							$display ("dispatch_to_freelist === expected_dispatch_to_freelist: %b", dispatch_to_freelist === expected_dispatch_to_freelist);
							$display("logic display: %b", logic_display);
				`endif
				if (dispatch_to_freelist === expected_dispatch_to_freelist)
					$display("@@@\tcorrect dispatch_to_freelist: new_pr_en:%b",
							 dispatch_to_freelist.new_pr_en);
				else begin
					$display("@@@\tincorrect dispatch_to_freelist: new_pr_en:%b",
							 dispatch_to_freelist.new_pr_en);
					$display("@@@\t                      expected: new_pr_en:%b",
							 expected_dispatch_to_freelist.new_pr_en);
				end  // incorrect dispatch_to_freelist

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (freelist_to_dispatch[i] === expected_freelist_to_dispatch[i])
						$display("@@@\tcorrect freelist_to_dispatch[%1d]: t_idx:%2d valid:%b", i,
								 freelist_to_dispatch.t_idx[i], freelist_to_dispatch.valid[i]);
					else begin
						$display("@@@\tincorrect freelist_to_dispatch[%1d]: t_idx:%2d valid:%b", i,
								 freelist_to_dispatch.t_idx[i], freelist_to_dispatch.valid[i]);
						$display("@@@\t                         expected: t_idx:%2d valid:%b",
								 expected_freelist_to_dispatch.t_idx[i], 
								 expected_freelist_to_dispatch.valid[i]);
					end  // incorrect freelist_to_dispatch
				end  // for freelist_to_dispatch output
			end  // if (~skip_internal)
// `ifdef TEST_MODE
//             for(int i = 0; i < 64 ; i +=1 ) begin
//                 $display("\tfreelist_display[%3d]: valid:%b",
//                     i,freelist_display[i].valid);
//             end
// `endif
            $display("\nENDING DISPATCH_FREELIST TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer
endmodule  // dispatch_freelist_testbench