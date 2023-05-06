module dispatch_fetch_rs_testbench;
    int test;
	logic skip_rs, skip_fetch, skip_dispatch, skip_rs_dispatch, skip_fetch_dispatch;
	logic rs_correct, fetch_correct, dispatch_correct, dispatch_rs_correct,
		  rs_dispatch_correct, fetch_dispatch_correct, correct;
	INST [24:0] insts;

	// Inputs for rs and fetch
    logic clock, reset;

    // Inputs for fetch and dispatch
	logic [`XLEN-1:0] target_pc;

    // Inputs for rs
    CDB_PACKET rs_cdb_in;
    FU_RS_PACKET fu_rs_in;

	// Inputs for fetch
	logic branch_flush_en;
	logic [`SUPERSCALAR_WAYS-1:0][63:0] Imem2proc_data;

    // Inputs for dispatch
    MAPTABLE_PACKET dispatch_maptable_in;
    ROB_DISPATCH_PACKET dispatch_rob_in;
    FREELIST_DISPATCH_PACKET dispatch_freelist_in;

    // Outputs from rs
    RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] rs_issue_out, expected_rs_issue_out;

	// Outputs from fetch
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr, expected_proc2Imem_addr;

    // Outputs from dispatch
    DISPATCH_FREELIST_PACKET dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    // Connections between rs, fetch, and dispatch
    RS_DISPATCH_PACKET rs_to_dispatch, expected_rs_to_dispatch;  
    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_rs, expected_dispatch_to_rs;
	DISPATCH_FETCH_PACKET dispatch_to_fetch, expected_dispatch_to_fetch;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch, expected_fetch_to_dispatch;

	// "Pipeline" connecting the dispatch and fetch stages and the rs module
	dispatch_fetch_rs dispatch_fetch_rs_0 (
		.clock(clock),
		.reset(reset),
		.rs_cdb_in(rs_cdb_in),
		.fu_rs_in(fu_rs_in),
		.Imem2proc_data(Imem2proc_data),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rob_in(dispatch_rob_in),
		.dispatch_freelist_in(dispatch_freelist_in),
		.branch_flush_en(branch_flush_en),
		.target_pc(target_pc),
		.rs_issue_out(rs_issue_out),
		.proc2Imem_addr(proc2Imem_addr),
		.dispatch_freelist_out(dispatch_freelist_out),
		.dispatch_rob_out(dispatch_rob_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.rs_to_dispatch(rs_to_dispatch),
		.dispatch_to_rs(dispatch_to_rs),
		.dispatch_to_fetch(dispatch_to_fetch),
		.fetch_to_dispatch(fetch_to_dispatch)
	);

    assign fetch_correct = (proc2Imem_addr === expected_proc2Imem_addr);

    assign dispatch_correct = (dispatch_freelist_out === expected_dispatch_freelist_out) &
							  (dispatch_rob_out === expected_dispatch_rob_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) & dispatch_rs_correct;
	
    assign fetch_dispatch_correct = (dispatch_to_fetch === expected_dispatch_to_fetch) &
									(fetch_to_dispatch === expected_fetch_to_dispatch);

	assign correct = (skip_rs | rs_correct) & 
					 (skip_fetch | fetch_correct) & 
					 (skip_dispatch | dispatch_correct) & 
					 (skip_rs_dispatch | rs_dispatch_correct) & 
					 (skip_fetch_dispatch | fetch_dispatch_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_FETCH_RS TESTBENCH\n");
		test = 0;
		clock = 0; 
		initialize();
		
		$display("@@@ Test %1d: Reset", test);
		reset = 1'b1;

		setup_test(32'd0, 32'd0, 32'd0);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_to_rs[i].enable  = 1'b1;
			expected_dispatch_rob_out[i].enable = 1'b1;
			expected_dispatch_maptable_out[i].enable = 1'b1;
		end
		verify_answer(0, 1, 0, 0, 0);
		
		$display("@@@ Test %1d: Dispatch 3 instructions", test);
		reset = 1'b0;
		set_rob_idx({ 5'd0, 5'd1, 5'd2 });

		setup_test(32'd12, 32'd0, 32'd0);
		set_expected_enables(3'b111, 3'b111);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
			expected_rs_issue_out[i].valid = 1'b0;
		set_expected_pr_idx({ 6'd63, 6'd62, 6'd61 }, 3'b111);
		expected_dispatch_freelist_out.new_pr_en = 3'b111;
		set_expected_dispatch_to_fetch(1'b0, 2'd0);
		expected_rs_to_dispatch.stall = 3'b000;
		verify_answer(0, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 1 instruction for freelist", test);
		setup_test(32'd20, 32'd8, 32'd0);
		set_expected_enables(3'b011, 3'b111);
		set_expected_dispatch_to_fetch(1'b1, 2'd2);
		set_expected_pr_idx({ 6'd60, 6'd59, 6'd58 }, 3'b011);
		expected_dispatch_freelist_out.new_pr_en = 3'b011;
		verify_answer(1, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Issue 3 instructions", test);
		setup_test(32'd32, 32'd20, 32'd8);
		set_expected_enables(3'b111, 3'b111);
		set_expected_dispatch_to_fetch(1'b0, 2'd0);
		set_expected_pr_idx({ 6'd63, 6'd60, 6'd59 }, 3'b111);
		verify_answer(1, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 2 instructions for ROB", test);
		dispatch_rob_in.stall = 3'b010;

		set_expected_enables(3'b001, 3'b111);
		setup_test(32'd36, 32'd24, 32'd12);
		set_expected_dispatch_to_fetch(1'b1, 2'd1);
		set_expected_pr_idx({ 6'd63, 6'd60, 6'd58 }, 3'b111);
		expected_dispatch_freelist_out.new_pr_en = 3'b001;
		verify_answer(1, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Issue 3 instructions", test);
		dispatch_rob_in.stall = 3'b000;

		set_expected_enables(3'b111, 3'b111);
		setup_test(32'd48, 32'd36, 32'd24);
		set_expected_dispatch_to_fetch(1'b0, 2'd0);
		set_expected_pr_idx({ 6'd57, 6'd56, 6'd55 }, 3'b111);
		expected_dispatch_freelist_out.new_pr_en = 3'b111;
		verify_answer(1, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Issue 3 instructions", test);
		setup_test(32'd60, 32'd48, 32'd36);
		set_expected_pr_idx({ 6'd57, 6'd56, 6'd55 }, 3'b111);
		verify_answer(1, 1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall for RS", test);
		setup_test(32'd64, 32'd52, 32'd40);
		set_expected_dispatch_to_fetch(1'b1, 2'd1);
		set_expected_pr_idx({ 6'd57, 6'd56, 6'd54 }, 3'b111);
		expected_dispatch_freelist_out.new_pr_en = 3'b001;
		expected_rs_to_dispatch.stall = 3'b110;
		verify_answer(1, 1, 1, 1, 1);
		

		$display("\nENDING DISPATCH_FETCH_RS TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_rs;  			 // check rs output is as expected
		input check_fetch;		 	 // check fetch output is as expected
		input check_dispatch;	 	 // check dispatch output is as expected
		input check_rs_dispatch;  	 // check rs_to_dispatch and dispatch_to_rs are as expected
		input check_fetch_dispatch;  // check fetch_to_dispatch and dispatch_to_fetch are as expected
	begin
        @(negedge clock);
		skip_rs = ~check_rs;
		skip_fetch = ~check_fetch;
		skip_dispatch = ~check_dispatch;
		skip_rs_dispatch = ~check_rs_dispatch;
		skip_fetch_dispatch = ~check_fetch_dispatch;
		//$display("f.rd:%2d d.rd:%2d", fetch_to_dispatch[0].inst.r.rd, dispatch_to_rs[0].inst.r.rd);
		//$display("f.rd:%2d d.rd:%2d", fetch_to_dispatch[1].inst.r.rd, dispatch_to_rs[1].inst.r.rd);
		//$display("f.rd:%2d d.rd:%2d", fetch_to_dispatch[2].inst.r.rd, dispatch_to_rs[2].inst.r.rd);
		rs_correct = 1'b1;
		dispatch_rs_correct = 1'b1;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (expected_dispatch_to_rs[i].valid)
                dispatch_rs_correct = dispatch_rs_correct & dispatch_to_rs[i].valid &
                             		  (dispatch_to_rs[i].PC === expected_dispatch_to_rs[i].PC) &
                             		  (dispatch_to_rs[i].NPC === expected_dispatch_to_rs[i].NPC) &
                             		  (dispatch_to_rs[i].enable === expected_dispatch_to_rs[i].enable) &
                             		  (dispatch_to_rs[i].reg1_pr_idx === expected_dispatch_to_rs[i].reg1_pr_idx) &
                             		  (dispatch_to_rs[i].reg2_pr_idx === expected_dispatch_to_rs[i].reg2_pr_idx) &
                             		  (dispatch_to_rs[i].reg1_ready === expected_dispatch_to_rs[i].reg1_ready) &
                             		  (dispatch_to_rs[i].reg2_ready === expected_dispatch_to_rs[i].reg2_ready) &
                             		  (dispatch_to_rs[i].rob_idx === expected_dispatch_to_rs[i].rob_idx) &
                             		  (dispatch_to_rs[i].pr_idx === expected_dispatch_to_rs[i].pr_idx);
            else dispatch_rs_correct = dispatch_rs_correct & ~dispatch_to_rs[i].valid;

            if (expected_rs_issue_out[i].valid)
				rs_correct = rs_correct & expected_rs_issue_out[i].valid &
                             (rs_issue_out[i].PC === expected_rs_issue_out[i].PC) &
                             (rs_issue_out[i].NPC === expected_rs_issue_out[i].NPC) &
                             (rs_issue_out[i].reg1_pr_idx === expected_rs_issue_out[i].reg1_pr_idx) &
                             (rs_issue_out[i].reg2_pr_idx === expected_rs_issue_out[i].reg2_pr_idx) &
                             (rs_issue_out[i].rob_idx === expected_rs_issue_out[i].rob_idx) &
                             (rs_issue_out[i].pr_idx === expected_rs_issue_out[i].pr_idx);
			else rs_correct = rs_correct & ~rs_issue_out[i].valid;
		end #1;

	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b target_pc:%2d",
					 reset, branch_flush_en, target_pc);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tImem2proc_data[%1d]:%h", i, Imem2proc_data[i]);

		 	$display("@@@\tnon-zero maptable entries:");
			for (int i = 0; i < `N_ARCH_REG; i++)
				if (dispatch_maptable_in.map[i] != 6'd0)
		 			$display("@@@\t\tar_idx:%2d phys_reg_idx:%2d", i, dispatch_maptable_in.map[i]);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tdispatch_freelist_in[%1d]: t_idx:%2d valid:%b", i,
						 dispatch_freelist_in.t_idx[i], dispatch_freelist_in.valid[i]);

		 	$display("@@@ Outputs:");

			if (~skip_rs) begin
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\trs_issue_out[%1d]:", i);

					if (rs_issue_out[i].valid & ~expected_rs_issue_out[i].valid)
						$display("@@@\t\tincorrect valid:1\n\t\t       expected:0");
					else begin
						if (rs_issue_out[i].PC === expected_rs_issue_out[i].PC &
							rs_issue_out[i].NPC === expected_rs_issue_out[i].NPC &
							rs_issue_out[i].valid === expected_rs_issue_out[i].valid)
							$display("@@@\t\tcorrect PCs and valid: PC:%3d NPC:%3d valid:%b",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC, 
									 rs_issue_out[i].valid);
						else begin
							$display("@@@\t\tincorrect PCs or valid: PC:%3d NPC:%3d valid:%b",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC, 
									 rs_issue_out[i].valid);
							$display("@@@\t\t              expected: PC:%3d NPC:%3d valid:%b",
									 expected_rs_issue_out[i].PC, expected_rs_issue_out[i].NPC, 
									 expected_rs_issue_out[i].valid);
						end  // incorrect PC, NPC, or valid

						if (rs_issue_out[i].reg1_pr_idx === expected_rs_issue_out[i].reg1_pr_idx &
							rs_issue_out[i].reg2_pr_idx === expected_rs_issue_out[i].reg2_pr_idx &
							rs_issue_out[i].pr_idx === expected_rs_issue_out[i].pr_idx)
							$display("@@@\t\tcorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 rs_issue_out[i].reg1_pr_idx, 
									 rs_issue_out[i].reg2_pr_idx, 
									 rs_issue_out[i].pr_idx);
						else begin
							$display("@@@\t\tincorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 rs_issue_out[i].reg1_pr_idx,
									 rs_issue_out[i].reg2_pr_idx, 
									 rs_issue_out[i].pr_idx);
							$display("@@@\t\t     expected: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 expected_rs_issue_out[i].reg1_pr_idx, 
									 expected_rs_issue_out[i].reg2_pr_idx,
									 expected_rs_issue_out[i].pr_idx);
						end  // incorrect prs

						if (rs_issue_out[i].rob_idx === expected_rs_issue_out[i].rob_idx)
							$display("@@@\t\tcorrect rob_idx:%2d", rs_issue_out[i].rob_idx);
						else begin
							$display("@@@\t\tincorrect rob_idx:%2d", rs_issue_out[i].rob_idx);
							$display("@@@\t\t           expected:%2d", expected_rs_issue_out[i].rob_idx);
						end  // incorrect rob entry
					end  // if (rs.valid & ~expected_rs.valid)
				end  // for RS output
			end  // if (~skip_rs)

			if (~skip_fetch) begin
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (proc2Imem_addr[i] === expected_proc2Imem_addr[i])
						$display("@@@\tcorrect proc2Imem_adder[%1d]:%d", i, proc2Imem_addr[i]);
					else  begin
						$display("@@@\tincorrect proc2Imem_adder[%1d]:%d", i, proc2Imem_addr[i]);
						$display("@@@\t                    expected:%d", expected_proc2Imem_addr[i]);
					end  // incorrect proc2Imem_adder
				end  // for each proc2Imem_adder
			end  // if (~skip_fetch)

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

			if (~skip_rs_dispatch) begin
				if (rs_to_dispatch === expected_rs_to_dispatch)
		 			$display("@@@\tcorrect rs_to_dispatch: stall:%b", rs_to_dispatch.stall);
				else begin
		 			$display("@@@\tincorrect rs_to_dispatch: stall:%b", rs_to_dispatch.stall);
		 			$display("@@@\t                expected: stall:%b", expected_rs_to_dispatch.stall);
				end

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\tdispatch_to_rs[%1d]:", i);

					if (dispatch_to_rs[i].valid & ~expected_dispatch_to_rs[i].valid)
						$display("@@@\t\tincorrect valid:1\n\t\t\texpected:0");
					else begin
						if (dispatch_to_rs[i].PC === expected_dispatch_to_rs[i].PC &
							dispatch_to_rs[i].NPC === expected_dispatch_to_rs[i].NPC)
							$display("@@@\t\tcorrect PCs: PC:%3d NPC:%3d",
									 dispatch_to_rs[i].PC, dispatch_to_rs[i].NPC);
						else begin
							$display("@@@\t\tincorrect PC(s): PC:%3d NPC:%3d",
									 dispatch_to_rs[i].PC, dispatch_to_rs[i].NPC);
							$display("@@@\t\t       expected: PC:%3d NPC:%3d",
									 expected_dispatch_to_rs[i].PC, expected_dispatch_to_rs[i].NPC);
						end  // incorrect PC or NPC

						if (dispatch_to_rs[i].valid === expected_dispatch_to_rs[i].valid &
							dispatch_to_rs[i].enable === expected_dispatch_to_rs[i].enable)
							$display("@@@\t\tcorrect valid and enable: valid:%b enable:%b",
									 dispatch_to_rs[i].valid, dispatch_to_rs[i].enable);
						else begin
							$display("@@@\t\tincorrect valid or enable: valid:%b enable:%b",
									 dispatch_to_rs[i].valid, dispatch_to_rs[i].enable);
							$display("@@@\t\t                 expected: valid:%b enable:%b",
									 expected_dispatch_to_rs[i].valid, expected_dispatch_to_rs[i].enable);
						end  // incorrect valid or enable

						if (dispatch_to_rs[i].reg1_pr_idx === expected_dispatch_to_rs[i].reg1_pr_idx &
							dispatch_to_rs[i].reg2_pr_idx === expected_dispatch_to_rs[i].reg2_pr_idx &
							dispatch_to_rs[i].pr_idx === expected_dispatch_to_rs[i].pr_idx)
							$display("@@@\t\tcorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 dispatch_to_rs[i].reg1_pr_idx, 
									 dispatch_to_rs[i].reg2_pr_idx, 
									 dispatch_to_rs[i].pr_idx);
						else begin
							$display("@@@\t\tincorrect prs: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 dispatch_to_rs[i].reg1_pr_idx,
									 dispatch_to_rs[i].reg2_pr_idx, 
									 dispatch_to_rs[i].pr_idx);
							$display("@@@\t\t     expected: reg1_pr_idx:%2d reg2_pr_idx:%2d pr_idx:%2d",
									 expected_dispatch_to_rs[i].reg1_pr_idx, 
									 expected_dispatch_to_rs[i].reg2_pr_idx,
									 expected_dispatch_to_rs[i].pr_idx);
						end  // incorrect prs

						if (dispatch_to_rs[i].reg1_ready === expected_dispatch_to_rs[i].reg1_ready &
							dispatch_to_rs[i].reg2_ready === expected_dispatch_to_rs[i].reg2_ready)
							$display("@@@\t\tcorrect readys: reg1_ready:%b reg2_ready:%b",
									 dispatch_to_rs[i].reg1_ready, 
									 dispatch_to_rs[i].reg2_ready);
						else begin
							$display("@@@\t\tincorrect readys: reg1_ready:%b reg2_ready:%b",
									 dispatch_to_rs[i].reg1_ready, 
									 dispatch_to_rs[i].reg2_ready);
							$display("@@@\t\t        expected: reg1_ready:%b reg2_ready:%b",
									 expected_dispatch_to_rs[i].reg1_ready, 
									 expected_dispatch_to_rs[i].reg2_ready);
						end  // incorrect reg readys

						if (dispatch_to_rs[i].rob_idx === expected_dispatch_to_rs[i].rob_idx)
							$display("@@@\t\tcorrect rob_idx:%2d", dispatch_to_rs[i].rob_idx);
						else begin
							$display("@@@\t\tincorrect rob_idx:%2d", dispatch_to_rs[i].rob_idx);
							$display("@@@\t\t           expected:%2d", expected_dispatch_to_rs[i].rob_idx);
						end  // incorrect rob entry
					end  // if (rs.valid & ~expected_rs.valid)
				end  // for dispatch_to_rs
			end  // if (~skip_rs_dispatch)

			if (~skip_fetch_dispatch) begin
				if (dispatch_to_fetch === expected_dispatch_to_fetch)
					$display("@@@\tcorrect dispatch_to_fetch: enable:%b first_stall_idx:%2d", 
							 dispatch_to_fetch.enable, dispatch_to_fetch.first_stall_idx);
				else begin
					$display("@@@\tincorrect dispatch_to_fetch: enable:%b first_stall_idx:%2d", 
							 dispatch_to_fetch.enable, dispatch_to_fetch.first_stall_idx);
					$display("@@@\t                   expected: enable:%b first_stall_idx:%2d", 
							 expected_dispatch_to_fetch.enable, 
							 expected_dispatch_to_fetch.first_stall_idx);
				end  // incorrect dispatch_to_fetch

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (fetch_to_dispatch[i] === expected_fetch_to_dispatch[i])
						$display("@@@\tcorrect fetch_to_dispatch[%1d]: inst:%h PC:%3d NPC:%3d valid:%b", 
								 i, fetch_to_dispatch[i].inst, fetch_to_dispatch[i].PC, 
								 fetch_to_dispatch[i].NPC, fetch_to_dispatch[i].valid);
					else begin
						$display("@@@\tincorrect fetch_to_dispatch[%1d]: inst:%h PC:%3d NPC:%3d valid:%b", 
								 i, fetch_to_dispatch[i].inst, fetch_to_dispatch[i].PC, 
								 fetch_to_dispatch[i].NPC, fetch_to_dispatch[i].valid);
						$display("@@@\t                      expected: inst:%h PC:%3d NPC:%3d valid:%b", 
								 expected_fetch_to_dispatch[i].inst, expected_fetch_to_dispatch[i].PC, 
								 expected_fetch_to_dispatch[i].NPC, expected_fetch_to_dispatch[i].valid);
					end  // incorrect fetch_to_dispatch
				end  // for fetch_to_dispatch output
			end  // if (~skip_fetch_dispatch)

            $display("\nENDING DISPATCH_FETCH_RS TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer

	task initialize;
		logic [`N_ARCH_REG_BITS-1:0] rs1, rs2, rd;
		logic [`N_ARCH_REG_BITS-1:0] reg1_pr_idx, reg2_pr_idx, told_idx;
		logic reg1_ready, reg2_ready;
		INST inst;
		inst.inst  = `RV32_ADD;

		branch_flush_en  = 1'b0;
		target_pc = 0;
		dispatch_rob_in.stall = 3'b000;

		for (int i = 0; i < 25; i++) begin
			rs1 = $random;
			rs2 = $random;
			rd  = $random;
			reg1_pr_idx    = $random;
			reg2_pr_idx    = $random;
			told_idx   = $random;
			reg1_ready = $random;
			reg2_ready = $random;

			inst.r.rs1 = rs1;
			inst.r.rs2 = rs2;
			inst.r.rd  = rd;
			//$display(rd);
			
			insts[i] = inst;
			dispatch_maptable_in.map[rs1]  = reg1_pr_idx;
			dispatch_maptable_in.done[rs1] = reg1_ready;
			dispatch_maptable_in.map[rs2]  = reg2_pr_idx;
			dispatch_maptable_in.done[rs2] = reg2_ready;
			dispatch_maptable_in.map[rd]   = told_idx;
		end  // for each inst
	endtask  // initialize

	task setup_test;
		input [`XLEN-1:0] fetch_starting_pc, dispatch_starting_pc, rs_starting_pc;
	begin
		INST inst;

		if (fetch_starting_pc[2]) begin
			expected_proc2Imem_addr[0] = fetch_starting_pc - 4;
			expected_proc2Imem_addr[1] = fetch_starting_pc + 4;
			expected_proc2Imem_addr[2] = fetch_starting_pc + 4;
		end
		else begin
			expected_proc2Imem_addr[0] = fetch_starting_pc;
			expected_proc2Imem_addr[1] = fetch_starting_pc;
			expected_proc2Imem_addr[2] = fetch_starting_pc + 8;
		end

		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_fetch_to_dispatch[i].PC  = fetch_starting_pc + 4*i;
			expected_fetch_to_dispatch[i].NPC = fetch_starting_pc + 4*i + 4;
			expected_dispatch_to_rs[i].PC  = dispatch_starting_pc + 4*i;
			expected_dispatch_to_rs[i].NPC = dispatch_starting_pc + 4*i + 4;
			expected_rs_issue_out[i].PC  = rs_starting_pc + 4*i;
			expected_rs_issue_out[i].NPC = rs_starting_pc + 4*i + 4;

			inst = insts[((dispatch_starting_pc/4) + i)];
			Imem2proc_data[i] = { inst, inst };
			expected_fetch_to_dispatch[i].inst  = inst;
			expected_fetch_to_dispatch[i].valid = 1'b1;
			expected_dispatch_to_rs[i].reg1_pr_idx = dispatch_maptable_in.map[inst.r.rs1];
			expected_dispatch_to_rs[i].reg2_pr_idx = dispatch_maptable_in.map[inst.r.rs2];
			expected_dispatch_to_rs[i].reg1_ready = dispatch_maptable_in.done[inst.r.rs1];
			expected_dispatch_to_rs[i].reg2_ready = dispatch_maptable_in.done[inst.r.rs2];
			expected_dispatch_rob_out[i].ar_idx = inst.r.rd;
			expected_dispatch_rob_out[i].told_idx = dispatch_maptable_in.map[inst.r.rd];
			expected_dispatch_maptable_out[i].ar_idx = inst.r.rd;

			inst = insts[((rs_starting_pc/4) + i)];
			expected_rs_issue_out[i].reg1_pr_idx = dispatch_maptable_in.map[inst.r.rs1];
			expected_rs_issue_out[i].reg2_pr_idx = dispatch_maptable_in.map[inst.r.rs2];
			expected_rs_issue_out[i].ar_idx = inst.r.rd;
		end
	end endtask  // setup_test

	task set_expected_pr_idx;
		input [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] pr_idx;
		input [`SUPERSCALAR_WAYS-1:0] valid;
	begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			dispatch_freelist_in.t_idx[i] = pr_idx[i];
			dispatch_freelist_in.valid[i] = valid[i];

			expected_rs_issue_out[i].pr_idx    = expected_dispatch_to_rs[i].pr_idx;
			expected_dispatch_to_rs[i].pr_idx  = pr_idx[i];
			expected_dispatch_rob_out[i].t_idx  = pr_idx[i];
			expected_dispatch_maptable_out[i].pr_idx = pr_idx[i];
		end
	end endtask  // set_expected_pr_idx

	task set_expected_enables;
		input [`SUPERSCALAR_WAYS-1:0] enable, valid;
	begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_to_rs[i].valid    = valid[i];
			expected_dispatch_to_rs[i].enable   = enable[i];
			expected_rs_issue_out[i].valid = valid[i];
			expected_dispatch_rob_out[i].valid  = valid[i];
			expected_dispatch_rob_out[i].enable = enable[i];
			expected_dispatch_maptable_out[i].enable = enable[i];
		end
	end endtask  // set_expected_enables

	task set_expected_dispatch_to_fetch;
		input enable;
		input [`SUPERSCALAR_WAYS-1:0] first_stall_idx;
	begin
		expected_dispatch_to_fetch.enable = enable;
		expected_dispatch_to_fetch.first_stall_idx = first_stall_idx;
	end endtask  // set_expected_dispatch_to_fetch

	task set_rob_idx;
		input [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] new_entry_idx;
	begin
		dispatch_rob_in.new_entry_idx = new_entry_idx;
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_to_rs[i].rob_idx = new_entry_idx[i];
			expected_rs_issue_out[i].rob_idx = new_entry_idx[i];
		end
	end endtask  // set_expected_dispatch_to_fetch
endmodule  // dispatch_fetch_testbench