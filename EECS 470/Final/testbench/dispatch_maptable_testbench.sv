module dispatch_maptable_testbench;
    int test;
	logic skip_dispatch, skip_internal;
	logic dispatch_correct, internal_correct, rs_correct, correct;

	// Inputs for maptable
	logic clock, reset, br_recover_enable;
    MAPTABLE_PACKET recovery_maptable;
    CDB_PACKET maptable_cdb_in;

    // Inputs for dispatch
	logic branch_flush_en;
    RS_DISPATCH_PACKET dispatch_rs_in;  
    ROB_DISPATCH_PACKET dispatch_rob_in;
    FREELIST_DISPATCH_PACKET dispatch_freelist_in;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

    // Outputs from dispatch
	DISPATCH_FETCH_PACKET dispatch_fetch_out, expected_dispatch_fetch_out;
    DISPATCH_FREELIST_PACKET dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;

    // Connections between maptable and dispatch
    MAPTABLE_PACKET maptable_to_dispatch, expected_maptable_to_dispatch;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_maptable, expected_dispatch_to_maptable;
    
	dispatch_maptable dispatch_maptable_tb(
		.clock(clock),
		.reset(reset),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		.maptable_cdb_in(maptable_cdb_in),
		.branch_flush_en(branch_flush_en),
		.dispatch_rs_in(dispatch_rs_in),
		.dispatch_rob_in(dispatch_rob_in),
		.dispatch_freelist_in(dispatch_freelist_in),
		.dispatch_fetch_in(dispatch_fetch_in),
		.dispatch_fetch_out(dispatch_fetch_out),
		.dispatch_freelist_out(dispatch_freelist_out),
		.dispatch_rs_out(dispatch_rs_out),
		.dispatch_rob_out(dispatch_rob_out),
		.maptable_to_dispatch(maptable_to_dispatch),
		.dispatch_to_maptable(dispatch_to_maptable)
	);

    assign dispatch_correct = (dispatch_fetch_out === expected_dispatch_fetch_out) &
							  (dispatch_freelist_out === expected_dispatch_freelist_out) &
							  (dispatch_rob_out === expected_dispatch_rob_out) & rs_correct;
	
    assign internal_correct = (maptable_to_dispatch == expected_maptable_to_dispatch) &
							  (dispatch_to_maptable == expected_dispatch_to_maptable);

	assign correct = (skip_dispatch | dispatch_correct) & (skip_internal | internal_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_MAPTABLE TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;

		$display("@@@ Test reset %d: ", test);

		expected_maptable_to_dispatch.done = {32{1'b1}};
		for (int i=0; i<32; i++) begin
                expected_maptable_to_dispatch.map[i] = i;
            end //for
		
		expected_dispatch_to_maptable = 0;

		verify_answer(0, 1);

		$display("@@@ Test dispatch pass in %d: ", test);
		reset = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		maptable_cdb_in = 0;
		branch_flush_en = 0;
		dispatch_rs_in.stall = 0;
		dispatch_rob_in.stall = 0;
		dispatch_rob_in.new_entry_idx[0] = 5'd1;
		dispatch_rob_in.new_entry_idx[1] = 5'd2;
		dispatch_rob_in.new_entry_idx[2] = 5'd3;
		dispatch_freelist_in.t_idx[0] = 6'd32;
		dispatch_freelist_in.t_idx[1] = 6'd33;
		dispatch_freelist_in.t_idx[2] = 6'd34;
		dispatch_freelist_in.valid = 3'b111;
		dispatch_fetch_in[0].NPC = 32'd8;
		dispatch_fetch_in[0].PC = 32'd4;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[0].inst = {7'd1, 5'd5, 5'd4, 3'd0, 5'd10, 7'b0110011};
		dispatch_fetch_in[1].NPC = 32'd12;
		dispatch_fetch_in[1].PC = 32'd8;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[1].inst = {7'd1, 5'd6, 5'd7, 3'd0, 5'd2, 7'b0110011};
		dispatch_fetch_in[2].NPC = 32'd16;
		dispatch_fetch_in[2].PC = 32'd12;
		dispatch_fetch_in[2].valid = 1;
		dispatch_fetch_in[2].inst = {7'd1, 5'd8, 5'd9, 3'd0, 5'd3, 7'b0110011};

		expected_dispatch_to_maptable[0].pr_idx = 6'd32;
		expected_dispatch_to_maptable[0].ar_idx = 5'd10;
		expected_dispatch_to_maptable[0].enable = 5'd1;
		expected_dispatch_to_maptable[1].pr_idx = 6'd33;
		expected_dispatch_to_maptable[1].ar_idx = 5'd2;
		expected_dispatch_to_maptable[1].enable = 5'd1;
		expected_dispatch_to_maptable[2].pr_idx = 6'd34;
		expected_dispatch_to_maptable[2].ar_idx = 5'd3;
		expected_dispatch_to_maptable[2].enable = 5'd1;


		expected_maptable_to_dispatch.map[10] = 6'd32;
		expected_maptable_to_dispatch.map[2]  = 6'd33;
		expected_maptable_to_dispatch.map[3]  = 6'd34;
		expected_maptable_to_dispatch.done[10] = 1'b0;
		expected_maptable_to_dispatch.done[2] = 1'b0;
		expected_maptable_to_dispatch.done[3] = 1'b0;

		verify_answer(0, 1);

		for (int i=0; i<32; i++) begin
                recovery_maptable.map[i] = i;
            end //for
		recovery_maptable.done = {32{1'b1}};

		br_recover_enable = 1;
		branch_flush_en = 1;

		recovery_maptable.map[10] = 6'd35;
		recovery_maptable.map[2] = 6'd36;
		recovery_maptable.map[3] = 6'd37;

		expected_maptable_to_dispatch.map[10] = 6'd35;
		expected_maptable_to_dispatch.map[2] = 6'd36;
		expected_maptable_to_dispatch.map[3] = 6'd37;
		expected_maptable_to_dispatch.done[10] = 1'b1;
		expected_maptable_to_dispatch.done[2] = 1'b1;
		expected_maptable_to_dispatch.done[3] = 1'b1;
		expected_dispatch_to_maptable[0].enable = 5'd0;
		expected_dispatch_to_maptable[1].enable = 5'd0;
		expected_dispatch_to_maptable[2].enable = 5'd0;

		verify_answer(0, 1);



		


		

		

		$display("\nENDING DISPATCH_MAPTABLE TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_dispatch;	 // check dispatch output other than dispatch_to_maptable is as expected
		input check_connection;  // check maptable_to_dispatch and dispatch_to_maptable are as expected
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

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tdispatch_freelist_in[%1d]: t_idx:%2d valid:%b", i,
						 dispatch_freelist_in.t_idx[i], dispatch_freelist_in.valid[i]);

		 	$display("@@@\tdispatch_rs_in: stall:%b", dispatch_rs_in.stall);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				$display("@@@\tdispatch_fetch_in[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
						 i, dispatch_fetch_in[i].inst, dispatch_fetch_in[i].PC, 
						 dispatch_fetch_in[i].NPC, dispatch_fetch_in[i].valid);
			
		 	$display("@@@ Outputs:");

			if (~skip_dispatch) begin
				if (dispatch_freelist_out === expected_dispatch_freelist_out)
					$display("@@@\tcorrect dispatch_freelist_out: new_pr_en:%b",
							 dispatch_freelist_out.new_pr_en);
				else begin
					$display("@@@\tincorrect dispatch_freelist_out: new_pr_en:%b",
							 dispatch_freelist_out.new_pr_en);
					$display("@@@\t                       expected: new_pr_en:%b",
							 expected_dispatch_freelist_out.new_pr_en);
				end  // incorrect new_pr_en

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
						$display("@@@\t\tincorrect valid:1\n\t\t       expected:0");
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
			end  // if (~skip_dispatch)

			if (~skip_internal) begin
		 		$display("@@@\tmaptable entries:");
				for (int i = 0; i < `N_ARCH_REG; i++) begin
					if (maptable_to_dispatch.map[i] === expected_maptable_to_dispatch.map[i] &
						maptable_to_dispatch.done[i] === expected_maptable_to_dispatch.done[i])
		 				$display("@@@\t\tcorrect maptable_to_dispatch[%1d]: map:%2d done:%b",
								 i, maptable_to_dispatch.map[i], maptable_to_dispatch.done[i]);
					else begin
		 				$display("@@@\t\tincorrect maptable_to_dispatch[%1d]: map:%2d done:%b",
								 i, maptable_to_dispatch.map[i], maptable_to_dispatch.done[i]);
		 				$display("@@@\t\t                    expected: map:%2d done:%b",
								 i, expected_maptable_to_dispatch.map[i], expected_maptable_to_dispatch.done[i]);
					end
				end  // incorrect maptable_to_dispatch

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (dispatch_to_maptable[i] === expected_dispatch_to_maptable[i])
						$display("@@@\tcorrect dispatch_to_maptable[%1d]: enable:%b pr_idx:%2d ar_idx:%2d", 
								 i, dispatch_to_maptable[i].enable, dispatch_to_maptable[i].pr_idx, 
								 dispatch_to_maptable[i].ar_idx);
					else begin
						$display("@@@\tincorrect dispatch_to_maptable[%1d]: enable:%b pr_idx:%2d ar_idx:%2d", 
								 i, dispatch_to_maptable[i].enable, dispatch_to_maptable[i].pr_idx, 
								 dispatch_to_maptable[i].ar_idx);
						$display("@@@\t                      expected: enable:%b pr_idx:%2d ar_idx:%2d", 
								 expected_dispatch_to_maptable[i].enable, 
								 expected_dispatch_to_maptable[i].pr_idx, 
								 expected_dispatch_to_maptable[i].ar_idx);
					end  // incorrect dispatch_to_maptable
				end  // for dispatch_to_maptable output
			end  // if (~skip_internal)

            $display("\nENDING DISPATCH_MAPTABLE TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer
endmodule  // dispatch_maptable_testbench