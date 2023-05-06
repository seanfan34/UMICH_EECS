module dispatch_rs_testbench;
    int test;
	logic skip_rs, skip_dispatch, skip_internal;
	logic rs_correct, dispatch_correct, internal_correct, rs_d_correct, correct;

	// Inputs for rs
    logic clock, reset;
    CDB_PACKET                                      	rs_cdb_in;
    FU_RS_PACKET                              	rs_fu_in;

    // Inputs for dispatch
	logic branch_flush_en;
    MAPTABLE_PACKET                                 	dispatch_maptable_in;
    ROB_DISPATCH_PACKET                             	dispatch_rob_in;
    FREELIST_DISPATCH_PACKET                        	dispatch_freelist_in;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]   	dispatch_fetch_in;

	// Outputs from rs
    RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0]         	rs_issue_out, expected_rs_issue_out;

    // Outputs from dispatch
    DISPATCH_FETCH_PACKET                           	dispatch_fetch_out, expected_dispatch_fetch_out;
    DISPATCH_FREELIST_PACKET                        	dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0]    dispatch_maptable_out, expected_dispatch_maptable_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0]     	dispatch_rob_out, expected_dispatch_rob_out;

    // Connections between rs and dispatch
    RS_DISPATCH_PACKET                              	rs_to_dispatch, expected_rs_to_dispatch;
    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0]      	dispatch_to_rs, expected_dispatch_to_rs;

`ifdef TEST_MODE
    DISPATCH_RS_PACKET  [`N_RS_ENTRIES-1:0]    			rs_table ;
`endif

	dispatch_rs dispatch_rs_tb(
		.clock(clock),
		.reset(reset),
		.rs_cdb_in(rs_cdb_in),
		.rs_fu_in(rs_fu_in),
		.branch_flush_en(branch_flush_en),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rob_in(dispatch_rob_in),
		.dispatch_freelist_in(dispatch_freelist_in),
		.dispatch_fetch_in(dispatch_fetch_in),
		.rs_issue_out(rs_issue_out),
		.dispatch_fetch_out(dispatch_fetch_out),
		.dispatch_freelist_out(dispatch_freelist_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.dispatch_rob_out(dispatch_rob_out),
		.rs_to_dispatch(rs_to_dispatch),
		.dispatch_to_rs(dispatch_to_rs)
`ifdef TEST_MODE
        , .rs_table(rs_table)
`endif
	);

    assign dispatch_correct = (dispatch_freelist_out === expected_dispatch_freelist_out) &
							  (dispatch_fetch_out === expected_dispatch_fetch_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) &
							  (dispatch_rob_out === expected_dispatch_rob_out);
	
    assign internal_correct = rs_d_correct & (rs_to_dispatch == expected_rs_to_dispatch);

	assign correct = (skip_rs | rs_correct) & 
					 (skip_dispatch | dispatch_correct) & 
					 (skip_internal | internal_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_RS TESTBENCH\n");
		test = 0;
		clock = 0;
        @(negedge clock)
        reset = 1;
        @(negedge clock)
        reset = 0;



        // Inputs for rs
        rs_cdb_in = 0;
        rs_fu_in = 0;
        // Inputs for dispatch
        branch_flush_en = 0;
        dispatch_maptable_in = 0;
        dispatch_rob_in = 0;
        dispatch_freelist_in = 0;
        dispatch_fetch_in = 0;

            //---------------------------------------------
		$display("@@@ Test %1d Dispatch 1 Instr", test);
        // Inputs for rs
        rs_cdb_in = 0;
        rs_fu_in = 0;
        // Inputs for dispatch
        branch_flush_en = 0;
        dispatch_maptable_in.map[21] = 6'd40;
        dispatch_maptable_in.done[21] = 1'b1;
        dispatch_maptable_in.map[22] = 6'd41;
        dispatch_maptable_in.done[22] = 1'b1;
        //packet_idx;  stall; new_entry_idx;
        set_dispatch_rob_in(0,0,0);
        set_dispatch_rob_in(1,0,1);
        set_dispatch_rob_in(2,0,2);
        //packet_idx; t_idx; valid;
        set_dispatch_freelist_in(0,15,1);
        set_dispatch_freelist_in(1,16,1);
        set_dispatch_freelist_in(2,17,1);
        //packet_idx; NPC; PC; valid;
        set_dispatch_fetch_in(0,0,0,1);
        set_dispatch_fetch_in(1,0,0,0);
        set_dispatch_fetch_in(2,0,0,0);
        dispatch_fetch_in[0].inst = `RV32_ADD;
        dispatch_fetch_in[0].inst.r.rd = 5'd20;
        dispatch_fetch_in[0].inst.r.rs1 = 5'd21;
        dispatch_fetch_in[0].inst.r.rs2 = 5'd22;

        //expected output
        expected_rs_issue_out = 0; //
        expected_dispatch_to_rs = 0;
        expected_dispatch_to_rs[0].PC = 0;
        expected_dispatch_to_rs[0].NPC = 0;
        expected_dispatch_to_rs[0].valid = 1'b1;
        expected_dispatch_to_rs[0].enable = 1'b1;
        expected_dispatch_to_rs[0].inst.r.rd = 5'd20;
        expected_dispatch_to_rs[0].inst.r.rs1 = 5'd21;
        expected_dispatch_to_rs[0].inst.r.rs2 = 5'd22;
        expected_dispatch_to_rs[0].reg1_pr_idx = 6'd40;
        expected_dispatch_to_rs[0].reg2_pr_idx = 6'd41;
		expected_dispatch_to_rs[0].pr_idx = 6'd15;
		expected_dispatch_to_rs[0].reg1_ready = 1'b1;
		expected_dispatch_to_rs[0].reg2_ready = 1'b1;
		expected_dispatch_to_rs[0].rob_idx = 5'd0;
		expected_dispatch_to_rs[1].rob_idx = 5'd1;
		expected_dispatch_to_rs[2].rob_idx = 5'd2;

        expected_rs_to_dispatch = 0;
        expected_rs_to_dispatch.stall = 3'b000;

        expected_rs_issue_out[0].valid = 1'b1;
        expected_rs_issue_out[0].PC = 0;
        expected_rs_issue_out[0].NPC = 0;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd40;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd41;
        expected_rs_issue_out[0].rob_idx = 0;
    	expected_rs_issue_out[0].pr_idx = 6'd15;


		verify_answer(1, 0, 1);


		//---------------------------------------------
		$display("@@@ Test %1d Dispatch 1 Instr AND ISSUE ONE PACKET ", test);

`ifdef TEST_MODE


        for (int i = 0; i < `N_RS_ENTRIES; i = i + 1)
            $display("\RS Table [%d]: valid:%b pr_idx:%d reg1_pr_idx:%d  reg1_ready:%b  reg2_pr_idx:%d reg2_ready:%b",
                i,
                rs_table[i].valid,
                rs_table[i].pr_idx,
                rs_table[i].reg1_pr_idx,
                rs_table[i].reg1_ready,
                rs_table[i].reg2_pr_idx,
                rs_table[i].reg2_ready,
                );
`endif
        // Inputs for rs
        rs_cdb_in = 0;
        rs_fu_in = 0;
        // Inputs for dispatch
        branch_flush_en = 0;
        dispatch_maptable_in.map[20] = 6'd45;
        dispatch_maptable_in.done[20] = 1'b1;
        dispatch_maptable_in.map[22] = 6'd41;
        dispatch_maptable_in.done[22] = 1'b0;

        //packet_idx;  stall; new_entry_idx;
        set_dispatch_rob_in(0,0,3);
        set_dispatch_rob_in(1,0,4);
        set_dispatch_rob_in(2,0,5);
        //packet_idx; t_idx; valid;
        set_dispatch_freelist_in(0,15+3,1);
        set_dispatch_freelist_in(1,16+3,1);
        set_dispatch_freelist_in(2,17+3,1);
        //packet_idx; NPC; PC; valid;
        set_dispatch_fetch_in(0,0,0,1);
        set_dispatch_fetch_in(1,0,0,0);
        set_dispatch_fetch_in(2,0,0,0);
        dispatch_fetch_in[0].inst = `RV32_AND;
        dispatch_fetch_in[0].inst.r.rd = 5'd21;
        dispatch_fetch_in[0].inst.r.rs1 = 5'd20;
        dispatch_fetch_in[0].inst.r.rs2 = 5'd22;

        //expected output
        expected_rs_issue_out = 0; //
        expected_dispatch_to_rs = 0;
        expected_dispatch_to_rs[0].PC = 0;
        expected_dispatch_to_rs[0].NPC = 0;
        expected_dispatch_to_rs[0].valid = 1'b1;
        expected_dispatch_to_rs[0].enable = 1'b1;
        expected_dispatch_to_rs[0].inst.r.rd = 5'd20;
        expected_dispatch_to_rs[0].inst.r.rs1 = 5'd20;
        expected_dispatch_to_rs[0].inst.r.rs2 = 5'd22;
        expected_dispatch_to_rs[0].reg1_pr_idx = 6'd40;
        expected_dispatch_to_rs[0].reg2_pr_idx = 6'd41;
		expected_dispatch_to_rs[0].pr_idx = 6'd18;
		expected_dispatch_to_rs[0].reg1_ready = 1'b1;
		expected_dispatch_to_rs[0].reg2_ready = 1'b0;
		expected_dispatch_to_rs[0].rob_idx = 5'd3;
		expected_dispatch_to_rs[1].rob_idx = 5'd4;
		expected_dispatch_to_rs[2].rob_idx = 5'd5;

        expected_rs_to_dispatch = 0;

        expected_rs_issue_out[0].valid = 1'b1;
        expected_rs_issue_out[0].PC = 0;
        expected_rs_issue_out[0].NPC = 0;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd40;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd41;
        expected_rs_issue_out[0].rob_idx = 0;
    	expected_rs_issue_out[0].pr_idx = 6'd15;
        verify_answer(1, 0, 1);



		$display("\nENDING DISPATCH_RS TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

    task set_dispatch_rob_in; input int packet_idx; input  stall; input [`N_ROB_ENTRIES_BITS-1:0] new_entry_idx; begin
        dispatch_rob_in.stall[packet_idx] = stall;
        dispatch_rob_in.new_entry_idx[packet_idx] = new_entry_idx;
    end endtask

    task set_dispatch_freelist_in; input int packet_idx; input  [`N_PHYS_REG_BITS-1:0] t_idx; input valid; begin
        dispatch_freelist_in.t_idx[packet_idx] = t_idx;
        dispatch_freelist_in.valid[packet_idx] = valid;
    end endtask

    task set_dispatch_fetch_in; input int packet_idx; input [`XLEN-1:0] NPC; input  PC; input valid; begin
    	dispatch_fetch_in[packet_idx].NPC = NPC;
		dispatch_fetch_in[packet_idx].PC = PC;
		dispatch_fetch_in[packet_idx].valid = valid;
    end endtask


	task verify_answer; 
		input check_rs; 	 	 // check rs output other than rs_to_dispatch is as expected
		input check_dispatch;	 // check dispatch output other than dispatch_to_rs is as expected
		input check_connection;  // check rs_to_dispatch and dispatch_to_rs are as expected
	begin
		skip_rs = ~check_rs;
		skip_dispatch = ~check_dispatch;
		skip_internal = ~check_connection;

		rs_correct = 1'b1;
		rs_d_correct = 1'b1;
        @(negedge clock);
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (expected_dispatch_to_rs[i].valid)
                rs_d_correct = rs_d_correct & dispatch_to_rs[i].valid &
                               (dispatch_to_rs[i].PC === expected_dispatch_to_rs[i].PC) &
                               (dispatch_to_rs[i].NPC === expected_dispatch_to_rs[i].NPC) &
                               (dispatch_to_rs[i].enable === expected_dispatch_to_rs[i].enable) &
                               (dispatch_to_rs[i].reg1_pr_idx === expected_dispatch_to_rs[i].reg1_pr_idx) &
                               (dispatch_to_rs[i].reg2_pr_idx === expected_dispatch_to_rs[i].reg2_pr_idx) &
							   (dispatch_to_rs[i].inst.r.rs1 === expected_dispatch_to_rs[i].inst.r.rs1) &
							   (dispatch_to_rs[i].inst.r.rs2 === expected_dispatch_to_rs[i].inst.r.rs2) &
                               (dispatch_to_rs[i].reg1_ready === expected_dispatch_to_rs[i].reg1_ready) &
                               (dispatch_to_rs[i].reg2_ready === expected_dispatch_to_rs[i].reg2_ready) &
                               (dispatch_to_rs[i].rob_idx === expected_dispatch_to_rs[i].rob_idx) &
							   (dispatch_to_rs[i].inst.r.rd === expected_dispatch_to_rs[i].inst.r.rd) &
                               (dispatch_to_rs[i].pr_idx === expected_dispatch_to_rs[i].pr_idx);
            else rs_d_correct = rs_d_correct & ~dispatch_to_rs[i].valid;
            if (expected_rs_issue_out[i].valid)
				rs_correct = rs_correct & expected_rs_issue_out[i].valid &
                               (rs_issue_out[i].PC === expected_rs_issue_out[i].PC) &
                               (rs_issue_out[i].NPC === expected_rs_issue_out[i].NPC) &
                               (rs_issue_out[i].reg1_pr_idx === expected_rs_issue_out[i].reg1_pr_idx) &
                               (rs_issue_out[i].reg2_pr_idx === expected_rs_issue_out[i].reg2_pr_idx) &
                               (rs_issue_out[i].rob_idx === expected_rs_issue_out[i].rob_idx) &
                               (rs_issue_out[i].pr_idx === expected_rs_issue_out[i].pr_idx);
			else rs_correct = rs_correct & ~rs_issue_out[i].valid;
		end

        // @(negedge clock);
	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b", reset, branch_flush_en);

		 	$display("@@@\tdone maptable entries:");
			for (int i = 0; i < `N_ARCH_REG; i++)
				if (dispatch_maptable_in.done[i])
		 			$display("@@@\t\tar_idx:%2d phys_reg_idx:%2d", i, dispatch_maptable_in.map[i]);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tdispatch_freelist_in[%1d]: t_idx:%2d valid:%b", i,
						 dispatch_freelist_in.t_idx[i], dispatch_freelist_in.valid[i]);

		 	$display("@@@\tdispatch_rob_in: new_entry_idx:%2d stall:%b", 
					 dispatch_rob_in.new_entry_idx, dispatch_rob_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				$display("@@@\tdispatch_fetch_in[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
						 i, dispatch_fetch_in[i].inst, dispatch_fetch_in[i].PC, 
						 dispatch_fetch_in[i].NPC, dispatch_fetch_in[i].valid);
			
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
							$display("@@@\t\tcorrect PCs and valid: PC:%d NPC:%d valid:%b",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC, 
									 rs_issue_out[i].valid);
						else begin
							$display("@@@\t\tincorrect PCs or valid: PC:%d NPC:%d valid:%b",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC, 
									 rs_issue_out[i].valid);
							$display("@@@\t\t              expected: PC:%d NPC:%d valid:%b",
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
							$display("@@@\t\tcorrect PCs: PC:%d NPC:%d",
									 dispatch_to_rs[i].PC, dispatch_to_rs[i].NPC);
						else begin
							$display("@@@\t\tincorrect PC(s): PC:%d NPC:%d",
									 dispatch_to_rs[i].PC, dispatch_to_rs[i].NPC);
							$display("@@@\t\t       expected: PC:%d NPC:%d",
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

						if (dispatch_to_rs[i].inst.r.rs1 === expected_dispatch_to_rs[i].inst.r.rs1 &
							dispatch_to_rs[i].inst.r.rs2 === expected_dispatch_to_rs[i].inst.r.rs2 &
							dispatch_to_rs[i].inst.r.rd === expected_dispatch_to_rs[i].inst.r.rd)
							$display("@@@\t\tcorrect inst: rs1:%2d rs2:%2d rd:%2d",
									 dispatch_to_rs[i].inst.r.rs1, dispatch_to_rs[i].inst.r.rs2, 
									 dispatch_to_rs[i].inst.r.rd);
						else begin
							$display("@@@\t\tincorrect inst: rs1:%2d rs2:%2d rd:%2d",
									 dispatch_to_rs[i].inst.r.rs1, 
									 dispatch_to_rs[i].inst.r.rs2, 
									 dispatch_to_rs[i].inst.r.rd);
							$display("@@@\t\t      expected: rs1:%2d rs2:%2d rd:%2d",
									 expected_dispatch_to_rs[i].inst.r.rs1,
									 expected_dispatch_to_rs[i].inst.r.rs2,
									 expected_dispatch_to_rs[i].inst.r.rd);
						end  // incorrect inst

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
			end  // if (~skip_internal)

            $display("\nENDING DISPATCH_RS TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer
endmodule  // dispatch_rs_testbench