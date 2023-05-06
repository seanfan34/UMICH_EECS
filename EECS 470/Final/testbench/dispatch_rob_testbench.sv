module dispatch_rob_testbench;
    int test;
	logic skip_rob, skip_dispatch, skip_internal;
	logic rob_correct, dispatch_correct, internal_correct, rs_correct, correct;

	// Inputs for rob
    logic clock, reset;
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in;

    // Inputs for dispatch
	logic branch_flush_en;
    MAPTABLE_PACKET dispatch_maptable_in;
    RS_DISPATCH_PACKET dispatch_rs_in;  
    FREELIST_DISPATCH_PACKET dispatch_freelist_in;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

	// Outputs from rob
	ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_retire_out, expected_rob_retire_out;

    // Outputs from dispatch
    DISPATCH_FETCH_PACKET dispatch_fetch_out, expected_dispatch_fetch_out;
    DISPATCH_FREELIST_PACKET dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    // Connections between rob and dispatch
    ROB_DISPATCH_PACKET rob_to_dispatch, expected_rob_to_dispatch;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_rob, expected_dispatch_to_rob;
    
	dispatch_rob dispatch_rob_tb(
		.clock(clock),
		.reset(reset),
		.rob_complete_in(rob_complete_in),
		.branch_flush_en(branch_flush_en),
		.dispatch_maptable_in(dispatch_maptable_in),
		.dispatch_rs_in(dispatch_rs_in),
		.dispatch_freelist_in(dispatch_freelist_in),
		.dispatch_fetch_in(dispatch_fetch_in),
		.rob_retire_out(rob_retire_out),
		.dispatch_fetch_out(dispatch_fetch_out),
		.dispatch_freelist_out(dispatch_freelist_out),
		.dispatch_rs_out(dispatch_rs_out),
		.dispatch_maptable_out(dispatch_maptable_out),
		.rob_to_dispatch(rob_to_dispatch),
		.dispatch_to_rob(dispatch_to_rob)
	);

    assign rob_correct = (rob_retire_out === expected_rob_retire_out);

    assign dispatch_correct = (dispatch_freelist_out === expected_dispatch_freelist_out) &
							  (dispatch_fetch_out === expected_dispatch_fetch_out) &
							  (dispatch_maptable_out === expected_dispatch_maptable_out) & rs_correct;
	
    assign internal_correct = (rob_to_dispatch === expected_rob_to_dispatch)// &
			     // (dispatch_to_rob.t_idx === expected_dispatch_to_rob.t_idx) &
			      ;

	assign correct = (skip_internal | internal_correct);/*(skip_rob | rob_correct) & 
					 (skip_dispatch | dispatch_correct) & */
					 

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
		clear();
                $display("@@@ Test %1d: Reset", test);
			
			expected_dispatch_fetch_out.enable = 0;
			expected_dispatch_rs_out[0].enable  = 1;
			expected_dispatch_rs_out[1].enable  = 1;
			expected_dispatch_rs_out[2].enable  = 1;
			
			expected_dispatch_maptable_out[0].enable = 1;
			expected_dispatch_maptable_out[1].enable = 1;
			expected_dispatch_maptable_out[2].enable = 1;
			expected_dispatch_to_rob[0].enable = 1;
			expected_dispatch_to_rob[1].enable = 1;
			expected_dispatch_to_rob[2].enable = 1;
		
		verify_answer(0,0,1);
		


		$display("@@@ Test %1d: freelist valid send to ROB", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd13;
		rob_complete_in[1].rob_idx = 5'd25;
		rob_complete_in[2].rob_idx = 5'd28;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;
		
   		branch_flush_en = 0;
    		dispatch_maptable_in.map[3] = 6'd50;
		dispatch_maptable_in.done[3] = 0;
	
		
    		dispatch_rs_in.stall = 3'd0;      
   		dispatch_freelist_in.t_idx = { 6'd24, 6'd34, 6'd54};
		dispatch_freelist_in.valid = 3'd7;

    		dispatch_fetch_in[0].NPC = 32'd20;	
		dispatch_fetch_in[0].PC = 32'd16;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[0].inst = 32'd128;

    		dispatch_fetch_in[1].NPC = 32'd28;	
		dispatch_fetch_in[1].PC = 32'd24;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[1].inst = 32'd256;

    		dispatch_fetch_in[2].NPC = 32'd32;	
		dispatch_fetch_in[2].PC = 32'd28;
		dispatch_fetch_in[2].valid = 1;
		dispatch_fetch_in[2].inst = 32'd512;

		//output
		expected_rob_to_dispatch.new_entry_idx = 15'd5251;
		expected_rob_to_dispatch.stall = 3'd0;
		expected_dispatch_to_rob[0].t_idx = 6'd54;
		expected_dispatch_to_rob[1].t_idx = 6'd34;
		expected_dispatch_to_rob[2].t_idx = 6'd24;
		
		expected_dispatch_to_rob[0].valid = 1;
		expected_dispatch_to_rob[1].valid = 1;
		expected_dispatch_to_rob[2].valid = 1;
		verify_answer(0,0,1);

		$display("@@@ Test %1d: freelist valid send to ROB", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd13;
		rob_complete_in[1].rob_idx = 5'd25;
		rob_complete_in[2].rob_idx = 5'd28;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;
		
   		branch_flush_en = 0;
    		dispatch_maptable_in.map[3] = 6'd50;
		dispatch_maptable_in.done[3] = 0;
	
		
    		dispatch_rs_in.stall = 3'd0;      
   		dispatch_freelist_in.t_idx = { 6'd24, 6'd34, 6'd54};
		dispatch_freelist_in.valid = 3'd7;

    		dispatch_fetch_in[0].NPC = 32'd20;	
		dispatch_fetch_in[0].PC = 32'd16;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[0].inst = 32'd128;

    		dispatch_fetch_in[1].NPC = 32'd28;	
		dispatch_fetch_in[1].PC = 32'd24;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[1].inst = 32'd256;

    		dispatch_fetch_in[2].NPC = 32'd32;	
		dispatch_fetch_in[2].PC = 32'd28;
		dispatch_fetch_in[2].valid = 1;
		dispatch_fetch_in[2].inst = 32'd512;

		//output
		expected_rob_to_dispatch.new_entry_idx = 15'd8422;
		expected_rob_to_dispatch.stall = 3'd0;
		expected_dispatch_to_rob[0].t_idx = 6'd54;
		expected_dispatch_to_rob[1].t_idx = 6'd34;
		expected_dispatch_to_rob[2].t_idx = 6'd24;
		
		expected_dispatch_to_rob[0].valid = 1;
		expected_dispatch_to_rob[1].valid = 1;
		expected_dispatch_to_rob[2].valid = 1;
		verify_answer(0,0,1);

		$display("@@@ Test %1d: freelist invalid", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd14;
		rob_complete_in[1].rob_idx = 5'd26;
		rob_complete_in[2].rob_idx = 5'd31;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;
		
   		branch_flush_en = 0;
    		dispatch_maptable_in.map[3] = 6'd50;
		dispatch_maptable_in.done[3] = 0;
	
		
    		dispatch_rs_in.stall = 0;      
   		dispatch_freelist_in.t_idx = { 6'd17, 6'd27, 6'd37};
		dispatch_freelist_in.valid = 3'd0;

    		dispatch_fetch_in[0].NPC = 32'd20;	
		dispatch_fetch_in[0].PC = 32'd16;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[0].inst = 32'd128;

    		dispatch_fetch_in[1].NPC = 32'd28;	
		dispatch_fetch_in[1].PC = 32'd24;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[1].inst = 32'd256;

    		dispatch_fetch_in[2].NPC = 32'd32;	
		dispatch_fetch_in[2].PC = 32'd28;
		dispatch_fetch_in[2].valid = 1;
		dispatch_fetch_in[2].inst = 32'd512;

		//output
		expected_rob_to_dispatch.new_entry_idx = 15'd5285;
		expected_rob_to_dispatch.stall = 0;
		expected_dispatch_to_rob[0].t_idx = 6'd37;
		expected_dispatch_to_rob[1].t_idx = 6'd27;
		expected_dispatch_to_rob[2].t_idx = 6'd17;
		
		expected_dispatch_to_rob[0].valid = 1;
		expected_dispatch_to_rob[1].valid = 1;
		expected_dispatch_to_rob[2].valid = 1;

		expected_dispatch_to_rob[0].enable = 0;
		expected_dispatch_to_rob[1].enable = 0;
		expected_dispatch_to_rob[2].enable = 0;
		verify_answer(0,0,1);
		
		$display("@@@ Test %1d: branch_flush", test);
		reset = 0;
		rob_complete_in[0].rob_idx = 5'd14;
		rob_complete_in[1].rob_idx = 5'd26;
		rob_complete_in[2].rob_idx = 5'd31;
		rob_complete_in[0].complete = 1'b1;
		rob_complete_in[1].complete = 1'b1;
		rob_complete_in[2].complete = 1'b1;
		rob_complete_in[0].valid = 1'b1;
		rob_complete_in[1].valid = 1'b1;
		rob_complete_in[2].valid = 1'b1;
		
   		branch_flush_en = 1;
    		dispatch_maptable_in.map[3] = 6'd50;
		dispatch_maptable_in.done[3] = 0;
	
		
    		dispatch_rs_in.stall = 0;      
   		dispatch_freelist_in.t_idx = { 6'd28, 6'd38, 6'd48};
		dispatch_freelist_in.valid = 3'd7;

    		dispatch_fetch_in[0].NPC = 32'd20;	
		dispatch_fetch_in[0].PC = 32'd16;
		dispatch_fetch_in[0].valid = 1;
		dispatch_fetch_in[0].inst = 32'd1024;

    		dispatch_fetch_in[1].NPC = 32'd28;	
		dispatch_fetch_in[1].PC = 32'd24;
		dispatch_fetch_in[1].valid = 1;
		dispatch_fetch_in[1].inst = 32'd1125;

    		dispatch_fetch_in[2].NPC = 32'd32;	
		dispatch_fetch_in[2].PC = 32'd28;
		dispatch_fetch_in[2].valid = 1;
		dispatch_fetch_in[2].inst = 32'd2056;

		//output
		expected_rob_to_dispatch.new_entry_idx = 15'd5285;
		expected_rob_to_dispatch.stall = 0;
		expected_dispatch_to_rob[0].t_idx = 6'd28;
		expected_dispatch_to_rob[1].t_idx = 6'd38;
		expected_dispatch_to_rob[2].t_idx = 6'd48;
		
		expected_dispatch_to_rob[0].valid = 1;
		expected_dispatch_to_rob[1].valid = 1;
		expected_dispatch_to_rob[2].valid = 1;
		verify_answer(0,0,1);
		$display("\nENDING DISPATCH_ROB TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task verify_answer; 
		input check_rob;	 	 // check rob output other than rob_to_dispatch is as expected
		input check_dispatch;	 // check dispatch output other than dispatch_to_rob is as expected
		input check_connection;  // check rob_to_dispatch and dispatch_to_rob are as expected
	
		skip_rob = ~check_rob;
		skip_dispatch = ~check_dispatch;
		skip_internal = ~check_connection;
	begin
		rs_correct = 1'b1;
        @(negedge clock);
	    if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
		 	$display("@@@ Incorrect at time %4.0f", $time);

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

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
		 		$display("@@@\tdispatch_freelist_in[%1d]: t_idx:%2d valid:%b", i,
						 dispatch_freelist_in.t_idx[i], dispatch_freelist_in.valid[i]);

		 	$display("@@@\tdispatch_rs_in: stall:%b", dispatch_rs_in.stall);

			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				$display("@@@\tdispatch_fetch_in[%1d]: inst:%h PC:%d NPC:%d valid:%b", 
						 i, dispatch_fetch_in[i].inst, dispatch_fetch_in[i].PC, 
						 dispatch_fetch_in[i].NPC, dispatch_fetch_in[i].valid);
			
		 	$display("@@@ Outputs:");

			if (~skip_rob) begin
				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\trob_retire_out[%1d]:", i);

					if (rob_retire_out[i].t_idx === expected_rob_retire_out[i].t_idx &
						rob_retire_out[i].told_idx === expected_rob_retire_out[i].told_idx &
						rob_retire_out[i].ar_idx === expected_rob_retire_out[i].ar_idx)
						$display("@@@\t\tcorrect regs: t_idx:%2d told_idx:%2d ar_idx:%2d", 
								 rob_retire_out[i].t_idx, 
								 rob_retire_out[i].told_idx, 
								 rob_retire_out[i].ar_idx);
					else begin
						$display("@@@\t\tincorrect regs: t_idx:%2d told_idx:%2d ar_idx:%2d", 
								 rob_retire_out[i].t_idx, 
								 rob_retire_out[i].told_idx, 
								 rob_retire_out[i].ar_idx);
						$display("@@@\t\t      expected: t_idx:%2d told_idx:%2d ar_idx:%2d", 
								 expected_rob_retire_out[i].t_idx, 
								 expected_rob_retire_out[i].told_idx, 
								 expected_rob_retire_out[i].ar_idx);
					end  // incorrect rob_retire_out

					if (rob_retire_out[i].complete === expected_rob_retire_out[i].complete &
						rob_retire_out[i].precise_state_enable === expected_rob_retire_out[i].precise_state_enable)
						$display("@@@\t\tcorrect bits: complete:%b ", 
								 rob_retire_out[i].complete, 
								 rob_retire_out[i].precise_state_enable);
					else begin
						$display("@@@\t\tincorrect bits: complete:%b ", 
								 rob_retire_out[i].complete ,
								 rob_retire_out[i].precise_state_enable);
						$display("@@@\t\t      expected: complete:%b ", 
								 expected_rob_retire_out[i].complete ,
								 expected_rob_retire_out[i].precise_state_enable);
					end  // incorrect rob_retire_out
				end  // for each rob_retire_out
			end  // if (~skip_rob)

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


		 	$display("@@@ Inputs:");

		 	$display("@@@\treset:%b branch_flush_en:%b", reset, branch_flush_en);
			if (~skip_internal) begin
				if (rob_to_dispatch === expected_rob_to_dispatch) begin
		 			$display("@@@\tcorrect rob_to_dispatch: new_entry_idx:%2d stall:%d", 
							 rob_to_dispatch.new_entry_idx, rob_to_dispatch.stall);
		 			$display("@@@\t                 expected: new_entry_idx:%2d stall:%d", 
							 expected_rob_to_dispatch.new_entry_idx, expected_rob_to_dispatch.stall);
				end
				else begin
		 			$display("@@@\tincorrect rob_to_dispatch: new_entry_idx:%2d stall:%b", 
							 rob_to_dispatch.new_entry_idx, rob_to_dispatch.stall);
		 			$display("@@@\t                 expected: new_entry_idx:%2d stall:%b", 
							 expected_rob_to_dispatch.new_entry_idx, expected_rob_to_dispatch.stall);
				end  // incorrect rob_to_dispatch

				for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
					$display("@@@\tdispatch_to_rob[%1d]:", i);

					if (dispatch_to_rob[i].t_idx === expected_dispatch_to_rob[i].t_idx /*&
						dispatch_to_rob[i].told_idx === expected_dispatch_to_rob[i].told_idx &
						dispatch_to_rob[i].ar_idx === expected_dispatch_to_rob[i].ar_idx*/)
						$display("@@@\t\tcorrect reg idxes: t_idx:%2d",
								 dispatch_to_rob[i].t_idx, 
							);
					else begin
						$display("@@@\t\tincorrect reg idxes: t_idx:%2d",
								 dispatch_to_rob[i].t_idx
							);
						$display("@@@\t\t           expected: t_idx:%2d",
								 expected_dispatch_to_rob[i].t_idx
							);
					end  // incorrect reg index

					if (dispatch_to_rob[i].valid === expected_dispatch_to_rob[i].valid &
						dispatch_to_rob[i].enable === expected_dispatch_to_rob[i].enable)
						$display("@@@\t\tcorrect valid and enable: valid:%b enable:%b",
								 dispatch_to_rob[i].valid, dispatch_to_rob[i].enable);
					else begin
						$display("@@@\t\tincorrect valid or enable: valid:%b enable:%b",
								 dispatch_to_rob[i].valid, dispatch_to_rob[i].enable);
						$display("@@@\t\t                 expected: valid:%b enable:%b",
								 expected_dispatch_to_rob[i].valid, 
								 expected_dispatch_to_rob[i].enable);
					end  // incorrect valid or enable
				end  // for ROB output
			end  // if (~skip_internal)

            $display("\nENDING DISPATCH_ROB TESTBENCH: ERROR!\n");
	    	$finish;
        end  // if (~correct)
	end
        $display("@@@ Passed Test %1d!", test);
       	test++;
    end endtask  // verify_answer

	task clear;
		rob_complete_in = 0;

   		branch_flush_en = 0;
    		dispatch_maptable_in = 0;        
    		dispatch_rs_in = 0;
    
   		dispatch_freelist_in = 0; 
    		dispatch_fetch_in = 0;	

		expected_rob_retire_out = 0;
		expected_dispatch_fetch_out = 0;
		expected_dispatch_freelist_out = 0;
		expected_dispatch_rs_out = 0;
		expected_dispatch_maptable_out = 0;
    		expected_rob_to_dispatch = 0;
  		expected_dispatch_to_rob = 0;

	endtask
endmodule  // dispatch_rob_testbench
