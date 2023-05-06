module dispatch_fetch_freelist_testbench;
    int test;
	logic skip_fetch, skip_dispatch, skip_fetch_dispatch, skip_freelist_dispatch;
	logic fetch_correct, dispatch_correct, fetch_dispatch_correct, 
		  freelist_dispatch_correct, rs_correct, correct;

    // Inputs for freelist and fetch
	logic clock, reset;

    // Inputs for fetch and dispatch
	logic branch_flush_en;
	logic [`XLEN-1:0] target_pc;

    // Inputs for freelist
    logic br_recover_enable;
    MAPTABLE_PACKET recovery_maptable;
	RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0] freelist_retire_in;

    // Inputs for fetch
	logic [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data;

    // Inputs for dispatch
    MAPTABLE_PACKET dispatch_maptable_in;
    RS_DISPATCH_PACKET dispatch_rs_in;
    ROB_DISPATCH_PACKET dispatch_rob_in;

	// Outputs from fetch
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr, expected_proc2Imem_addr;

    // Outputs from dispatch   
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    // Connections between freelist, fetch, and dispatch
    FREELIST_DISPATCH_PACKET freelist_to_dispatch, expected_freelist_to_dispatch;
    DISPATCH_FREELIST_PACKET dispatch_to_freelist, expected_dispatch_to_freelist;
	DISPATCH_FETCH_PACKET dispatch_to_fetch, expected_dispatch_to_fetch;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch, expected_fetch_to_dispatch;

	// "Pipeline" connecting the dispatch and fetch stages and the freelist module
	dispatch_fetch_freelist dispatch_fetch_freelist_0 (
		.clock(clock),
		.reset(reset),
		.branch_flush_en(branch_flush_en),
		.target_pc(target_pc),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		.freelist_retire_in(freelist_retire_in),
		.Imem2proc_data(Imem2proc_data),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rs_in(dispatch_rs_in),
		.dispatch_rob_in(dispatch_rob_in),
		.proc2Imem_addr(proc2Imem_addr),
		.dispatch_rs_out(dispatch_rs_out),
		.dispatch_rob_out(dispatch_rob_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.freelist_to_dispatch(freelist_to_dispatch),
		.dispatch_to_freelist(dispatch_to_freelist),
		.dispatch_to_fetch(dispatch_to_fetch),
		.fetch_to_dispatch(fetch_to_dispatch)
	);

    assign fetch_correct 	= (proc2Imem_addr === expected_proc2Imem_addr);

    assign dispatch_correct = (dispatch_rob_out === expected_dispatch_rob_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) & rs_correct;
	
    assign fetch_dispatch_correct 	 = (fetch_to_dispatch === expected_fetch_to_dispatch) &
							  		   (fetch_to_dispatch === expected_fetch_to_dispatch);
	
    assign freelist_dispatch_correct = (dispatch_to_freelist === expected_dispatch_to_freelist) &
							  		   (freelist_to_dispatch === expected_freelist_to_dispatch);

	assign correct = (skip_fetch | fetch_correct) & 
					 (skip_dispatch | dispatch_correct) & 
					 (skip_fetch_dispatch | fetch_dispatch_correct) & 
					 (skip_freelist_dispatch | freelist_dispatch_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_FETCH_FREELIST TESTBENCH\n");
		test = 0;
		clock = 0; 
		clear();
		
		$display("@@@ Test %1d: Reset", test);
		reset = 1'b1;

		set_expected_fetch_pcs(32'd0);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_rs_out[i].enable  = 1'b1;
			expected_dispatch_rob_out[i].enable = 1'b1;
			expected_dispatch_maptable_out[i].enable = 1'b1;
		end
		verify_answer(1, 1, 0, 0);
		
		$display("@@@ Test %1d: Fetch 3 instructions", test);
		reset = 1'b0;
		set_inst();

		set_expected_enables(3'b111);
		set_expected_pcs(32'd12, 32'd0);
		set_expected_pr_idx({ 6'd63, 6'd62, 6'd61 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b111;
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 3 instructions for ROB", test);
		set_inst();
		dispatch_rob_in.stall = 3'b111;

		set_expected_enables(3'b000);
		set_expected_pcs(32'd24, 32'd12);
		set_expected_pr_idx({ 6'd60, 6'd59, 6'd58 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b000;
		set_expected_dispatch_to_fetch(1'b1, 2'd0);
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 2 instructions for ROB", test);
		set_inst();
		dispatch_rob_in.stall = 3'b010;

		set_expected_enables(3'b001);
		set_expected_pcs(32'd28, 32'd16);
		set_expected_pr_idx({ 6'd59, 6'd58, 6'd57 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b001;
		set_expected_dispatch_to_fetch(1'b1, 2'd1);
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 1 instruction for ROB and RS", test);
		set_inst();
		dispatch_rs_in.stall  = 3'b100;
		dispatch_rob_in.stall = 3'b100;

		set_expected_enables(3'b011);
		set_expected_pcs(32'd36, 32'd24);
		set_expected_pr_idx({ 6'd57, 6'd56, 6'd55 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b011;
		set_expected_dispatch_to_fetch(1'b1, 2'd2);
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Dispatch 3 instructions", test);
		set_inst();
		dispatch_rs_in.stall  = 3'b000;
		dispatch_rob_in.stall = 3'b000;

		set_expected_enables(3'b111);
		set_expected_pcs(32'd48, 32'd36);
		set_expected_pr_idx({ 6'd54, 6'd53, 6'd52 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b111;
		set_expected_dispatch_to_fetch(1'b0, 2'd0);
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 3 instructions for RS", test);
		set_inst();
		dispatch_rs_in.stall  = 3'b101;

		set_expected_enables(3'b000);
		set_expected_pcs(32'd60, 32'd36);
		set_expected_pr_idx({ 6'd54, 6'd53, 6'd52 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b000;
		set_expected_dispatch_to_fetch(1'b1, 2'd0);
		verify_answer(1, 1, 1, 1);
		
		$display("@@@ Test %1d: Stall 3 instructions for RS and ROB", test);
		set_inst();
		dispatch_rs_in.stall  = 3'b001;
		dispatch_rob_in.stall = 3'b100;

		set_expected_enables(3'b000);
		set_expected_pcs(32'd60, 32'd36);
		set_expected_pr_idx({ 6'd54, 6'd53, 6'd52 }, 3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b000;
		set_expected_dispatch_to_fetch(1'b1, 2'd0);
		verify_answer(1, 1, 1, 1);
		
		dispatch_rs_in.stall  = 3'b000;
		dispatch_rob_in.stall = 3'b000;

		set_expected_enables(3'b111);
		expected_dispatch_to_freelist.new_pr_en = 3'b111;
		set_expected_dispatch_to_fetch(1'b0, 2'd0);
		for (int i = 0; i < 6; i++) begin
			$display("@@@ Test %1d: Dispatch 3 instructions", test);
			set_inst();
			set_expected_pcs((32'd72 + (32'd12 * i)), (32'd40 + (32'd12 * i)));
			set_expected_pr_idx({ (6'd51 - (6'd3 * i)), (6'd50 - (6'd3 * i)), (6'd49 - (6'd3 * i)) }, 3'b111);
			verify_answer(1, 1, 1, 1);
		end
		
		$display("\nENDING DISPATCH_FETCH_FREELIST TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_fetch;		 		// check fetch output is as expected
		input check_dispatch;	 		// check dispatch output is as expected
		input check_fetch_dispatch;  	// check fetch/dispatch connections are as expected
		input check_freelist_dispatch;  // check freelist/dispatch connections are as expected
	begin
        @(negedge clock);
		skip_fetch = ~check_fetch;
		skip_dispatch = ~check_dispatch;
		skip_fetch_dispatch = ~check_fetch_dispatch;
		skip_freelist_dispatch = ~check_freelist_dispatch;

		rs_correct = 1'b1;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (expected_dispatch_rs_out[i].valid)
                rs_correct = rs_correct & dispatch_rs_out[i].valid &
                             (dispatch_rs_out[i].PC === expected_dispatch_rs_out[i].PC) &
                             (dispatch_rs_out[i].NPC === expected_dispatch_rs_out[i].NPC) &
                             (dispatch_rs_out[i].enable === expected_dispatch_rs_out[i].enable) &
                             (dispatch_rs_out[i].reg1_pr_idx === expected_dispatch_rs_out[i].reg1_pr_idx) &
                             (dispatch_rs_out[i].reg2_pr_idx === expected_dispatch_rs_out[i].reg2_pr_idx) &
                             (dispatch_rs_out[i].reg1_ready === expected_dispatch_rs_out[i].reg1_ready) &
                             (dispatch_rs_out[i].reg2_ready === expected_dispatch_rs_out[i].reg2_ready) &
                             (dispatch_rs_out[i].rob_idx === expected_dispatch_rs_out[i].rob_idx) &
                             (dispatch_rs_out[i].pr_idx === expected_dispatch_rs_out[i].pr_idx);
            else rs_correct = rs_correct & ~dispatch_rs_out[i].valid;
		end #1;

	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b br_recover_enable:%b branch_flush_en:%b target_pc:%2d",
					 reset, br_recover_enable, branch_flush_en, target_pc);

			if (br_recover_enable) begin
		 		$display("@@@\trecovery_maptable:");
				for (int i = 0; i < `N_ARCH_REG; i++)
		 			$display("@@@\tar_idx:%2d phys_reg_idx:%2d done:%b",
							 i, recovery_maptable.map[i], recovery_maptable.done[i]);
			end

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tfreelist_retire_in[%1d]: told_idx:%2d valid:%b", 
						 i, freelist_retire_in[i].told_idx, freelist_retire_in[i].valid);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tImem2proc_data[%1d]:%h", i, Imem2proc_data[i]);

		 	$display("@@@\tdone maptable entries:");
			for (int i = 0; i < `N_ARCH_REG; i++)
				if (dispatch_maptable_in.done[i])
		 			$display("@@@\t\tar_idx:%2d phys_reg_idx:%2d", i, dispatch_maptable_in.map[i]);

		 	$display("@@@\tdispatch_rs_in: stall:%b", dispatch_rs_in.stall);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

		 	$display("@@@ Outputs:");

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
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\tdispatch_rs_out[%1d]:", i);

					if (dispatch_rs_out[i].valid & ~expected_dispatch_rs_out[i].valid)
						$display("@@@\t\tincorrect valid:1\n@@@\t\t       expected:0");
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

			if (~skip_freelist_dispatch) begin
				if (dispatch_to_freelist === expected_dispatch_to_freelist)
					$display("@@@\tcorrect dispatch_to_freelist: new_pr_en:%b",
							 dispatch_to_freelist.new_pr_en);
				else begin
					$display("@@@\tincorrect dispatch_to_freelist: new_pr_en:%b",
							 dispatch_to_freelist.new_pr_en);
					$display("@@@\t                      expected: new_pr_en:%b",
							 expected_dispatch_to_freelist.new_pr_en);
				end  // incorrect new_pr_en

				if (freelist_to_dispatch === expected_freelist_to_dispatch)
					$display("@@@\tcorrect freelist_to_dispatch: t_idx[0]:%2d t_idx[1]:%2d t_idx[2]:%2d valid:%b",
							 freelist_to_dispatch.t_idx[0], 
							 freelist_to_dispatch.t_idx[1], 
							 freelist_to_dispatch.t_idx[2], 
							 freelist_to_dispatch.valid);
				else begin
					$display("@@@\tincorrect freelist_to_dispatch: t_idx[0]:%2d t_idx[1]:%2d t_idx[2]:%2d valid:%b",
							 freelist_to_dispatch.t_idx[0], 
							 freelist_to_dispatch.t_idx[1], 
							 freelist_to_dispatch.t_idx[2], 
							 freelist_to_dispatch.valid);
					$display("@@@\t                      expected: t_idx[0]:%2d t_idx[1]:%2d t_idx[2]:%2d valid:%b",
							 expected_freelist_to_dispatch.t_idx[0], 
							 expected_freelist_to_dispatch.t_idx[1], 
							 expected_freelist_to_dispatch.t_idx[2], 
							 expected_freelist_to_dispatch.valid);
				end  // incorrect freelist_to_dispatch
			end  // if (~skip_freelist_dispatch)

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
						$display("@@@\tcorrect fetch_to_dispatch[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
								 i, fetch_to_dispatch[i].inst, fetch_to_dispatch[i].PC, 
								 fetch_to_dispatch[i].NPC, fetch_to_dispatch[i].valid);
					else begin
						$display("@@@\tincorrect fetch_to_dispatch[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
								 i, fetch_to_dispatch[i].inst, fetch_to_dispatch[i].PC, 
								 fetch_to_dispatch[i].NPC, fetch_to_dispatch[i].valid);
						$display("@@@\t                      expected: inst:%h PC:%d NPC:%d valid:%b", 
								 expected_fetch_to_dispatch[i].inst, expected_fetch_to_dispatch[i].PC, 
								 expected_fetch_to_dispatch[i].NPC, expected_fetch_to_dispatch[i].valid);
					end  // incorrect fetch_to_dispatch
				end  // for fetch_to_dispatch output
			end  // if (~skip_fetch_dispatch)

            $display("\nENDING DISPATCH_FETCH_FREELIST TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer

	task clear;
		branch_flush_en    = 0;
		target_pc   = 0;
		br_recover_enable = 0;
		recovery_maptable 	   = 0;
		freelist_retire_in = 0;
		Imem2proc_data     = 0;
		dispatch_maptable_in    = 0;
		dispatch_rs_in 	   = 0;
		dispatch_rob_in    = 0;
		expected_proc2Imem_addr   	  = 0;
		expected_dispatch_rs_out  	  = 0;
		expected_dispatch_rob_out 	  = 0;
		expected_dispatch_maptable_out 	  = 0;
		expected_freelist_to_dispatch = 0;
		expected_dispatch_to_freelist = 0;
		expected_dispatch_to_fetch 	  = 0;
		expected_fetch_to_dispatch 	  = 0;
	endtask

	task set_expected_pcs;
		input [`XLEN-1:0] fetch_starting_pc, dispatch_starting_pc;
	begin
		set_expected_fetch_pcs(fetch_starting_pc);
		expected_dispatch_rs_out[0].PC  = dispatch_starting_pc;
		expected_dispatch_rs_out[0].NPC = dispatch_starting_pc + 4;
		expected_dispatch_rs_out[1].PC  = dispatch_starting_pc + 4;
		expected_dispatch_rs_out[1].NPC = dispatch_starting_pc + 8;
		expected_dispatch_rs_out[2].PC  = dispatch_starting_pc + 8;
		expected_dispatch_rs_out[2].NPC = dispatch_starting_pc + 12;
	end endtask

	task set_expected_fetch_pcs;
		input [`XLEN-1:0] starting_pc;
	begin
		expected_fetch_to_dispatch[0].PC  = starting_pc;
		expected_fetch_to_dispatch[0].NPC = starting_pc + 4;
		expected_fetch_to_dispatch[1].PC  = starting_pc + 4;
		expected_fetch_to_dispatch[1].NPC = starting_pc + 8;
		expected_fetch_to_dispatch[2].PC  = starting_pc + 8;
		expected_fetch_to_dispatch[2].NPC = starting_pc + 12;

		if (starting_pc[2]) begin
			expected_proc2Imem_addr[0] = starting_pc - 4;
			expected_proc2Imem_addr[1] = starting_pc + 4;
			expected_proc2Imem_addr[2] = starting_pc + 4;
		end
		else begin
			expected_proc2Imem_addr[0] = starting_pc;
			expected_proc2Imem_addr[1] = starting_pc;
			expected_proc2Imem_addr[2] = starting_pc + 8;
		end
	end endtask

	task set_inst;
		logic [`SUPERSCALAR_WAYS-1:0][`N_ARCH_REG_BITS-1:0] rs1, rs2, rd;
		logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] reg1_pr_idx, reg2_pr_idx, told_idx;
		logic [`SUPERSCALAR_WAYS-1:0] reg1_ready, reg2_ready;
		INST inst;

		rs1 = $random;
		rs2 = $random;
		rd  = $random;
		reg1_pr_idx    = $random;
		reg2_pr_idx    = $random;
		told_idx   = $random;
		reg1_ready = $random;
		reg2_ready = $random;
		inst.inst  = `RV32_ADD;

		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			inst.r.rs1 = rs1[i];
			inst.r.rs2 = rs2[i];
			inst.r.rd  = rd[i];
			
			Imem2proc_data[i] = { inst, inst };
			dispatch_maptable_in.map[rs1[i]]  = reg1_pr_idx[i];
			dispatch_maptable_in.done[rs1[i]] = reg1_ready[i];
			dispatch_maptable_in.map[rs2[i]]  = reg2_pr_idx[i];
			dispatch_maptable_in.done[rs2[i]] = reg2_ready[i];
			dispatch_maptable_in.map[rd[i]]   = told_idx[i];

			expected_fetch_to_dispatch[i].inst  = inst;
			expected_fetch_to_dispatch[i].valid = 1'b1;
			expected_dispatch_rs_out[i].reg1_pr_idx    = reg1_pr_idx[i];
			expected_dispatch_rs_out[i].reg1_ready = reg1_ready[i];
			expected_dispatch_rs_out[i].reg2_pr_idx    = reg2_pr_idx[i];
			expected_dispatch_rs_out[i].reg2_ready = reg2_ready[i];
			expected_dispatch_rob_out[i].ar_idx  = rd[i];
			expected_dispatch_rob_out[i].told_idx  = told_idx[i];
			expected_dispatch_maptable_out[i].ar_idx = rd[i];
		end  // for each inst
	endtask  // set_inst

	task set_expected_pr_idx;
		input [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] pr_idx;
		input [`SUPERSCALAR_WAYS-1:0] valid;
	begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_rs_out[i].pr_idx = pr_idx[i];
			expected_dispatch_rob_out[i].t_idx  = pr_idx[i];
			expected_dispatch_maptable_out[i].pr_idx = pr_idx[i];
			expected_freelist_to_dispatch.t_idx[i] = pr_idx[i];
			expected_freelist_to_dispatch.valid[i] = valid[i];
		end
	end endtask  // set_expected_pr_idx

	task set_expected_enables;
		input [`SUPERSCALAR_WAYS-1:0] enable;
	begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_rs_out[i].valid   = enable[i];
			expected_dispatch_rs_out[i].enable  = enable[i];
			expected_dispatch_rob_out[i].valid  = enable[i];
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
endmodule  // dispatch_fetch_testbench