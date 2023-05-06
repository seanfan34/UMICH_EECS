module dispatch_pipe_testbench;
    int test;
	logic skip_fetch, skip_rob, skip_rs;
	logic fetch_correct, rob_correct, rs_correct, correct;

	// Inputs
	logic clock, reset, branch_flush_en, br_recover_enable;
	MAPTABLE_PACKET recovery_maptable;
    CDB_PACKET rs_cdb_in;
    FU_RS_PACKET rs_fu_in;
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in;
	RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0] freelist_retire_in;
    logic [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0] cdb_tag;
	logic [`XLEN-1:0] target_pc;
	logic [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data;

    // Outputs
    RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] rs_issue_out, expected_rs_issue_out;
    ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_retire_out, expected_rob_retire_out;
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr, expected_proc2Imem_addr;

	// "Pipeline" connecting the dispatch and fetch stages and the modules
	dispatch_pipe dispatch_pipe_0 (
		.clock(clock),
		.reset(reset),
		.branch_flush_en(branch_flush_en),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		.rs_cdb_in(rs_cdb_in),
		.rs_fu_in(rs_fu_in),
		.rob_complete_in(rob_complete_in),
		.freelist_retire_in(freelist_retire_in),
		.cdb_tag(cdb_tag),
		.target_pc(target_pc),
		.Imem2proc_data(Imem2proc_data),
		.rs_issue_out(rs_issue_out),
		.rob_retire_out(rob_retire_out),
		.proc2Imem_addr(proc2Imem_addr)
	);

    assign fetch_correct = (proc2Imem_addr === expected_proc2Imem_addr);
	assign correct = (skip_fetch | fetch_correct) & (skip_rob | rob_correct) & (skip_rs | rs_correct);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING DISPATCH_PIPE TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;
		clear();
		
		$display("@@@ Test %1d: Reset", test);
		verify_answer(0, 0, 0);

		$display("\nENDING DISPATCH_PIPE TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_fetch;  // check fetch output is as expected
		input check_rob;	// check rob output is as expected
		input check_rs;  	// check rs outpt is as expected
	begin
        @(negedge clock);
		skip_fetch = ~check_fetch;
		skip_rob = ~check_rob;
		skip_rs = ~check_rs;

		rs_correct = 1'b1;
		rob_correct = 1'b1;
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (expected_rs_issue_out[i].valid)
                rs_correct = rs_correct & rs_issue_out[i].valid &
                             (rs_issue_out[i].inst === expected_rs_issue_out[i].inst) &
                             (rs_issue_out[i].PC === expected_rs_issue_out[i].PC) &
                             (rs_issue_out[i].NPC === expected_rs_issue_out[i].NPC) &
                             (rs_issue_out[i].reg1_pr_idx === expected_rs_issue_out[i].reg1_pr_idx) &
                             (rs_issue_out[i].reg2_pr_idx === expected_rs_issue_out[i].reg2_pr_idx) &
                             (rs_issue_out[i].rob_idx === expected_rs_issue_out[i].rob_idx) &
                             (rs_issue_out[i].ar_idx === expected_rs_issue_out[i].ar_idx) &
                             (rs_issue_out[i].pr_idx === expected_rs_issue_out[i].pr_idx);
            else rs_correct = rs_correct & ~rs_issue_out[i].valid;

			rob_correct = rob_correct & 
						  (rob_retire_out[i].t_idx === expected_rob_retire_out[i].t_idx) &
						  (rob_retire_out[i].told_idx === expected_rob_retire_out[i].told_idx) &
						  (rob_retire_out[i].ar_idx === expected_rob_retire_out[i].ar_idx) &
						  (rob_retire_out[i].complete === expected_rob_retire_out[i].complete);
		end

        #1;
	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b target_pc:%2d",
					 reset, branch_flush_en, target_pc);

		 	$display("@@@\trs_cdb_in: t0:%2d t1:%2d t2:%2d",
					 rs_cdb_in.t0, rs_cdb_in.t1, rs_cdb_in.t2);

		 	$display("@@@\trs_fu_in: alu_1:%b alu_2:%b alu_3:%b mult_1:%b mult_2:%b branch_1:%b",
					 rs_fu_in.alu_1, rs_fu_in.alu_2, rs_fu_in.alu_3,
					 rs_fu_in.mult_1, rs_fu_in.mult_2, rs_fu_in.branch_1);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\trob_complete_in[%1d]: rob_idx:%2d valid:%b complete:%b", 
						 i, rob_complete_in[i].rob_idx, rob_complete_in[i].valid, 
						 rob_complete_in[i].complete);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tfreelist_retire_in[%1d]: told_idx:%2d valid:%b", 
						 i, freelist_retire_in[i].told_idx, freelist_retire_in[i].valid);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tcdb_tag[%1d]:%2d", i, cdb_tag[i]);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tImem2proc_data[%1d]:%h", i, Imem2proc_data[i]);

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

			if (~skip_rob) begin
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					if (rob_retire_out[i] === expected_rob_retire_out[i])
						$display("@@@\tcorrect rob_retire_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b",
								 i, rob_retire_out[i].t_idx, rob_retire_out[i].told_idx, 
								 rob_retire_out[i].ar_idx, rob_retire_out[i].complete);
					else begin
						$display("@@@\tincorrect rob_retire_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b",
								 i, rob_retire_out[i].t_idx, rob_retire_out[i].told_idx, 
								 rob_retire_out[i].ar_idx, rob_retire_out[i].complete);
						$display("@@@\t                   expected: t_idx:%2d told_idx:%2d ar_idx:%2d complete:%b",
								 i, expected_rob_retire_out[i].t_idx, expected_rob_retire_out[i].told_idx, 
								 expected_rob_retire_out[i].ar_idx, expected_rob_retire_out[i].complete);
					end  // incorrect rob_retire_out
				end  // for each rob_retire_out
			end  // if (~skip_rob)

			if (~skip_rs) begin
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\trs_issue_out[%1d]:", i);

					if (rs_issue_out[i].valid & ~expected_rs_issue_out[i].valid)
						$display("@@@\t\tincorrect valid:1\n\t\t       expected:0");
					else begin
						if (rs_issue_out[i].valid === expected_rs_issue_out[i].valid &
							rs_issue_out[i].inst === expected_rs_issue_out[i].inst)
							$display("@@@\t\tcorrect inst: inst:%h valid:%b",
									 rs_issue_out[i].inst, rs_issue_out[i].valid);
						else begin
							$display("@@@\t\tincorrect inst: inst:%h valid:%b",
									 rs_issue_out[i].inst, rs_issue_out[i].valid);
							$display("@@@\t\t      expected: inst:%h valid:%b",
									 expected_rs_issue_out[i].inst, expected_rs_issue_out[i].valid);
						end  // incorrect inst or valid

						if (rs_issue_out[i].PC === expected_rs_issue_out[i].PC &
							rs_issue_out[i].NPC === expected_rs_issue_out[i].NPC)
							$display("@@@\t\tcorrect PCs: PC:%d NPC:%d",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC);
						else begin
							$display("@@@\t\tincorrect PC(s): PC:%d NPC:%d",
									 rs_issue_out[i].PC, rs_issue_out[i].NPC);
							$display("@@@\t\t       expected: PC:%d NPC:%d",
									 expected_rs_issue_out[i].PC, expected_rs_issue_out[i].NPC);
						end  // incorrect PC or NPC

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
						
						if (rs_issue_out[i].ar_idx === expected_rs_issue_out[i].ar_idx)
							$display("@@@\t\tcorrect ar_idx:%2d", rs_issue_out[i].ar_idx);
						else begin
							$display("@@@\t\tincorrect ar_idx:%2d", rs_issue_out[i].ar_idx);
							$display("@@@\t\t               expected:%2d", expected_rs_issue_out[i].ar_idx);
						end  // incorrect ar_idx
					end  // if (~rs_issue_out.valid | expected_rs_issue_out.valid)
				end  // for rs_issue_out
			end  // if (~skip_rs)

            $display("\nENDING DISPATCH_FETCH TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer

	task clear;
		branch_flush_en = 0;
		br_recover_enable = 0;
		recovery_maptable = 0;
		rs_cdb_in = 0;
		rs_fu_in = 0;
		rob_complete_in = 0;
		freelist_retire_in = 0;
		cdb_tag = 0;
		target_pc = 0;
		Imem2proc_data = 0;
		expected_rs_issue_out = 0;
		expected_rob_retire_out = 0;
		expected_proc2Imem_addr = 0;
	endtask
endmodule  // dispatch_fetch_testbench