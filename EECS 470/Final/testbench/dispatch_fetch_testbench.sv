module dispatch_fetch_testbench;
    int test;
	logic skip_fetch, skip_dispatch, skip_internal;
	logic fetch_correct, dispatch_correct, internal_correct, rs_correct, correct;

	// Inputs for fetch
    logic clock, reset;
	logic [`SUPERSCALAR_WAYS-1:0][63:0] Imem2proc_data;

    // Inputs for dispatch
    MAPTABLE_PACKET dispatch_maptable_in;
    RS_DISPATCH_PACKET dispatch_rs_in;  
    ROB_DISPATCH_PACKET dispatch_rob_in;
    FREELIST_DISPATCH_PACKET dispatch_freelist_in;

    // Inputs for both
	logic branch_flush_en;
	logic [`XLEN-1:0] target_pc;

	// Outputs from fetch
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr, expected_proc2Imem_addr;

    // Outputs from dispatch
    DISPATCH_FREELIST_PACKET dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    // Connections between fetch and dispatch
	DISPATCH_FETCH_PACKET dispatch_to_fetch, expected_dispatch_to_fetch;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch, expected_fetch_to_dispatch;

	// "Pipeline" connecting the dispatch and fetch stages
	dispatch_fetch dispatch_fetch_0 (
		.clock(clock),
		.reset(reset),
		.Imem2proc_data(Imem2proc_data),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rs_in(dispatch_rs_in),
		.dispatch_rob_in(dispatch_rob_in),
		.dispatch_freelist_in(dispatch_freelist_in),
		.branch_flush_en(branch_flush_en),
		.target_pc(target_pc),
		.proc2Imem_addr(proc2Imem_addr),
		.dispatch_freelist_out(dispatch_freelist_out),
		.dispatch_rs_out(dispatch_rs_out),
		.dispatch_rob_out(dispatch_rob_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.dispatch_to_fetch(dispatch_to_fetch),
		.fetch_to_dispatch(fetch_to_dispatch)
	);

    assign fetch_correct = (proc2Imem_addr === expected_proc2Imem_addr);

    assign dispatch_correct = (dispatch_freelist_out === expected_dispatch_freelist_out) &
							  (dispatch_rob_out === expected_dispatch_rob_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) & rs_correct;
	
    assign internal_correct = (dispatch_to_fetch === expected_dispatch_to_fetch) &
							  (fetch_to_dispatch === expected_fetch_to_dispatch);

	assign correct = (skip_fetch | fetch_correct) & 
					 (skip_dispatch | dispatch_correct) & 
					 (skip_internal | internal_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_FETCH TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;
		clear();
		
		$display("@@@ Test %1d: Reset", test);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_maptable_out[i].enable = 1;
			expected_fetch_to_dispatch[i].inst  = `NOP;
		end
		expected_proc2Imem_addr[2] = 8;
		verify_answer(1, 1, 1);
		
		$display("@@@ Test %1d: Freelist stall", test);
		reset = 0;
		set_fetch_expected_pcs(`XLEN'd0);
		set_dispatch_expected_pcs(`XLEN'd0);
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			expected_dispatch_rs_out[i].enable  = 0;
			expected_dispatch_rob_out[i].enable = 0;
			expected_dispatch_maptable_out[i].enable = 0;
			expected_fetch_to_dispatch[i].inst  = 0;
			expected_dispatch_rob_out[i].ar_idx = 1;
			expected_dispatch_maptable_out[i].ar_idx = 1;
		end
		expected_dispatch_to_fetch.enable = 1;
		expected_proc2Imem_addr[0] = 8;
		expected_proc2Imem_addr[1] = 16;
		expected_proc2Imem_addr[2] = 16;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: Hold freelist stall", test);
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: Hold freelist stall again", test);
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: Stall 1 instruction for freelist", test);
		dispatch_freelist_in.t_idx = { 6'd4, 6'd9, 6'd16 };
		dispatch_freelist_in.valid = 3'b011;
		Imem2proc_data = { 32'hb0, 32'h23, 32'ha0, 32'h20, 32'haa, 32'h42 };

		set_fetch_expected_pcs(32'd8);
		set_dispatch_expected_pcs(32'd8);
		expected_dispatch_freelist_out.new_pr_en = 3'b011;
		expected_dispatch_to_fetch.first_stall_idx = 2;
		for (int i = 0; i < 2; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_maptable_out[i].enable = 1;
		end
		expected_dispatch_rs_out[0].pr_idx = 5'd16;
		expected_dispatch_rob_out[0].t_idx  = 5'd16;
		expected_dispatch_maptable_out[0].pr_idx = 5'd16;
		expected_dispatch_rs_out[1].pr_idx = 5'd9;
		expected_dispatch_rob_out[1].t_idx  = 5'd9;
		expected_dispatch_maptable_out[1].pr_idx = 5'd9;
		expected_dispatch_rs_out[2].pr_idx = 5'd4;
		expected_dispatch_rob_out[2].t_idx  = 5'd4;
		expected_dispatch_maptable_out[2].pr_idx = 5'd4;
		expected_fetch_to_dispatch[1].inst = 32'haa;
		expected_fetch_to_dispatch[2].inst = 32'h20;
		expected_proc2Imem_addr[0] = 16;
		expected_proc2Imem_addr[1] = 24;
		expected_proc2Imem_addr[2] = 24;

		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: Stall 2 instructions for rs", test);
		dispatch_rs_in.stall[1] = 1;
		dispatch_rs_in.stall[2] = 1;

		expected_dispatch_freelist_out.new_pr_en = 3'b001;
		for (int i = 1; i < 2; i++) begin
			expected_dispatch_rs_out[i].enable  = 0;
			expected_dispatch_rob_out[i].enable = 0;
			expected_dispatch_maptable_out[i].enable = 0;
		end
		expected_dispatch_to_fetch.first_stall_idx = 1;
		set_fetch_expected_pcs(32'd12);
		set_dispatch_expected_pcs(32'd12);	
		expected_fetch_to_dispatch[0].inst = 32'haa;	
		expected_fetch_to_dispatch[1].inst = 32'h20;	
		expected_fetch_to_dispatch[2].inst = 32'haa;
		expected_proc2Imem_addr[0] = 24;
		expected_proc2Imem_addr[1] = 24;
		expected_proc2Imem_addr[2] = 32;

		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: Stall 2 instructions for everything", test);
		dispatch_rob_in.stall[1] = 1;

		set_fetch_expected_pcs(32'd16);
		set_dispatch_expected_pcs(32'd16);
		expected_fetch_to_dispatch[0].inst = 32'h20;	
		expected_fetch_to_dispatch[1].inst = 32'haa;	
		expected_fetch_to_dispatch[2].inst = 32'h42;
		expected_proc2Imem_addr[0] = 24;
		expected_proc2Imem_addr[1] = 32;
		expected_proc2Imem_addr[2] = 32;

		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: No stalls", test);
		dispatch_rs_in.stall  = 0;
		dispatch_rob_in.stall = 0;
		dispatch_freelist_in.valid = 3'b111;

		set_fetch_expected_pcs(32'd28);
		set_dispatch_expected_pcs(32'd28);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_maptable_out[i].enable = 1;
		end
		expected_dispatch_freelist_out.new_pr_en = 3'b111;
		expected_fetch_to_dispatch[0].inst = 32'haa;	
		expected_fetch_to_dispatch[1].inst = 32'h20;	
		expected_fetch_to_dispatch[2].inst = 32'hb0;
		expected_dispatch_to_fetch = 0;
		expected_proc2Imem_addr[0] = 40;
		expected_proc2Imem_addr[1] = 40;
		expected_proc2Imem_addr[2] = 48;

		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: No stalls again", test);
		set_fetch_expected_pcs(32'd40);
		set_dispatch_expected_pcs(32'd40);
		expected_fetch_to_dispatch[0].inst = 32'h42;	
		expected_fetch_to_dispatch[1].inst = 32'ha0;	
		expected_fetch_to_dispatch[2].inst = 32'h23;
		expected_proc2Imem_addr[0] = 48;
		expected_proc2Imem_addr[1] = 56;
		expected_proc2Imem_addr[2] = 56;

		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: 1 cycle long stall", test);
		dispatch_rs_in.stall = 3'b001;
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i].enable  = 0;
			expected_dispatch_rob_out[i].enable = 0;
			expected_dispatch_maptable_out[i].enable = 0;
		end
		expected_dispatch_to_fetch.enable = 1;
		expected_dispatch_freelist_out.new_pr_en = 0;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: No stalls again", test);
		dispatch_rs_in.stall = 0;
		set_fetch_expected_pcs(32'd52);
		set_dispatch_expected_pcs(32'd52);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_maptable_out[i].enable = 1;
		end
		expected_dispatch_to_fetch.enable = 0;
		expected_dispatch_freelist_out.new_pr_en = 3'b111;
		expected_fetch_to_dispatch[0].inst = 32'haa;	
		expected_fetch_to_dispatch[1].inst = 32'h20;	
		expected_fetch_to_dispatch[2].inst = 32'hb0;
		expected_proc2Imem_addr[0] = 64;
		expected_proc2Imem_addr[1] = 64;
		expected_proc2Imem_addr[2] = 72;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: branch_flush_en with a stall", test);
		dispatch_freelist_in = 0;
		branch_flush_en = 1;
		target_pc = 4;
		Imem2proc_data = 0;

		set_fetch_expected_pcs(32'd64);
		set_dispatch_expected_pcs(32'd64);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_maptable_out[i] = 0;
			expected_dispatch_rs_out[i]  = 0;
			expected_dispatch_rob_out[i] = 0;
			expected_fetch_to_dispatch[i].valid = 0;	
		end
		expected_dispatch_freelist_out.new_pr_en = 0;
		expected_fetch_to_dispatch[0].inst = 0;	
		expected_fetch_to_dispatch[1].inst = 0;	
		expected_fetch_to_dispatch[2].inst = 0;
		expected_proc2Imem_addr[0] = 0;
		expected_proc2Imem_addr[1] = 8;
		expected_proc2Imem_addr[2] = 8;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: take branch with a stall", test);
		branch_flush_en = 0;

		set_fetch_expected_pcs(32'd4);
		set_dispatch_expected_pcs(32'd4);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i].enable  = 0;
			expected_dispatch_rs_out[i].valid   = 1;
			expected_dispatch_rob_out[i].enable = 0;
			expected_dispatch_rob_out[i].valid  = 1;
			expected_fetch_to_dispatch[i].valid = 1;	
			expected_dispatch_rob_out[i].ar_idx = 1;
			expected_dispatch_maptable_out[i].ar_idx = 1;
		end
		expected_dispatch_to_fetch.enable = 1;
		expected_dispatch_freelist_out.new_pr_en = 0;
		expected_proc2Imem_addr[0] = 16;
		expected_proc2Imem_addr[1] = 16;
		expected_proc2Imem_addr[2] = 24;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: branch pushes to dispatch", test);
		dispatch_freelist_in.valid = 3'b011;
		set_fetch_expected_pcs(32'd12);
		set_dispatch_expected_pcs(32'd12);
		for (int i = 0; i < 2; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_maptable_out[i].enable = 1;
		end
		expected_dispatch_to_fetch.first_stall_idx = 2;
		expected_dispatch_freelist_out.new_pr_en = 3'b011;
		expected_proc2Imem_addr[0] = 24;
		expected_proc2Imem_addr[1] = 24;
		expected_proc2Imem_addr[2] = 32;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: branch_flush_en with no stalls", test);
		dispatch_freelist_in.valid = 3'b111;
		branch_flush_en = 1;
		target_pc = 88;
		expected_dispatch_to_fetch = 0;
		set_fetch_expected_pcs(32'd24);
		set_dispatch_expected_pcs(32'd24);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i]  = 0;
			expected_dispatch_maptable_out[i] = 0;
			expected_dispatch_rob_out[i] = 0;	
			expected_fetch_to_dispatch[i].valid = 0;
		end
		expected_dispatch_freelist_out.new_pr_en = 0;
		expected_proc2Imem_addr[0] = 88;
		expected_proc2Imem_addr[1] = 88;
		expected_proc2Imem_addr[2] = 96;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: take branch", test);
		branch_flush_en = 0;

		set_fetch_expected_pcs(32'd88);
		set_dispatch_expected_pcs(32'd88);
		for (int i = 0; i < 3; i++) begin
			expected_dispatch_rs_out[i].enable  = 1;
			expected_dispatch_rs_out[i].valid   = 1;
			expected_dispatch_rob_out[i].enable = 1;
			expected_dispatch_rob_out[i].valid  = 1;
			expected_dispatch_maptable_out[i].enable = 1;
			expected_fetch_to_dispatch[i].valid = 1;	
			expected_dispatch_rob_out[i].ar_idx = 1;
			expected_dispatch_maptable_out[i].ar_idx = 1;
		end
		expected_dispatch_freelist_out.new_pr_en = 3'b111;
		expected_proc2Imem_addr[0] = 96;
		expected_proc2Imem_addr[1] = 104;
		expected_proc2Imem_addr[2] = 104;
		verify_answer(1, 1, 1);

		$display("@@@ Test %1d: branch goes through", test);
		set_fetch_expected_pcs(32'd100);
		set_dispatch_expected_pcs(32'd100);
		expected_proc2Imem_addr[0] = 112;
		expected_proc2Imem_addr[1] = 112;
		expected_proc2Imem_addr[2] = 120;
		verify_answer(1, 1, 1);

		$display("\nENDING DISPATCH_FETCH TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_fetch;		 // check fetch output other than fetch_to_dispatch is as expected
		input check_dispatch;	 // check dispatch output other than dispatch_to_fetch is as expected
		input check_connection;  // check fetch_to_dispatch and dispatch_to_fetch are as expected
	begin
        @(negedge clock);
		skip_fetch = ~check_fetch;
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
                             (dispatch_rs_out[i].reg1_ready === expected_dispatch_rs_out[i].reg1_ready) &
                             (dispatch_rs_out[i].reg2_ready === expected_dispatch_rs_out[i].reg2_ready) &
                             (dispatch_rs_out[i].rob_idx === expected_dispatch_rs_out[i].rob_idx) &
                             (dispatch_rs_out[i].pr_idx === expected_dispatch_rs_out[i].pr_idx);
            else rs_correct = rs_correct & ~dispatch_rs_out[i].valid;
		end

        #1;
	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b target_pc:%2d",
					 reset, branch_flush_en, target_pc);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tImem2proc_data[%1d]:%h", i, Imem2proc_data[i]);

		 	$display("@@@\tdone maptable entries:");
			for (int i = 0; i < `N_ARCH_REG; i++)
				if (dispatch_maptable_in.done[i])
		 			$display("@@@\t\tar_idx:%2d phys_reg_idx:%2d", i, dispatch_maptable_in.map[i]);

		 	$display("@@@\tdispatch_rs_in: stall:%b", dispatch_rs_in.stall);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tdispatch_freelist_in[%1d]: t_idx:%2d valid:%b", i,
						 dispatch_freelist_in.t_idx[i], dispatch_freelist_in.valid[i]);

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

			if (~skip_internal) begin
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
			end  // if (~skip_internal)

            $display("\nENDING DISPATCH_FETCH TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer

	task clear;
		Imem2proc_data   = 0;
		branch_flush_en  = 0;
		target_pc = 0;
		dispatch_rs_in 	 = 0;  
		dispatch_maptable_in  = 0;
		dispatch_rob_in  = 0;
		dispatch_freelist_in = 0;

		expected_proc2Imem_addr   = 0;
		expected_dispatch_rs_out  = 0;
		expected_dispatch_rob_out = 0;
		expected_dispatch_maptable_out = 0;
		expected_dispatch_freelist_out = 0;
		expected_dispatch_to_fetch = 0;
		expected_fetch_to_dispatch = 0;
	endtask

	task set_fetch_expected_pcs;
		input [`XLEN-1:0] starting_pc;
	begin
		expected_fetch_to_dispatch[0].PC  = starting_pc;
		expected_fetch_to_dispatch[0].NPC = starting_pc + 4;
		expected_fetch_to_dispatch[1].PC  = starting_pc + 4;
		expected_fetch_to_dispatch[1].NPC = starting_pc + 8;
		expected_fetch_to_dispatch[2].PC  = starting_pc + 8;
		expected_fetch_to_dispatch[2].NPC = starting_pc + 12;

		expected_fetch_to_dispatch[0].valid = 1;
		expected_fetch_to_dispatch[1].valid = 1;
		expected_fetch_to_dispatch[2].valid = 1;
	end endtask

	task set_dispatch_expected_pcs;
		input [`XLEN-1:0] starting_pc;
	begin
		expected_dispatch_rs_out[0].PC  = starting_pc;
		expected_dispatch_rs_out[0].NPC = starting_pc + 4;
		expected_dispatch_rs_out[1].PC  = starting_pc + 4;
		expected_dispatch_rs_out[1].NPC = starting_pc + 8;
		expected_dispatch_rs_out[2].PC  = starting_pc + 8;
		expected_dispatch_rs_out[2].NPC = starting_pc + 12;

		expected_dispatch_rs_out[0].valid = 1;
		expected_dispatch_rs_out[1].valid = 1;
		expected_dispatch_rs_out[2].valid = 1;

		expected_dispatch_rob_out[0].valid = 1;
		expected_dispatch_rob_out[1].valid = 1;
		expected_dispatch_rob_out[2].valid = 1;
	end endtask
endmodule  // dispatch_fetch_testbench