//TESTBENCH FOR fu
//Class:    EECS470
//Specific:  Project 4
//Description:

module fu_testbench;

	logic clock, reset;
	ISSUE_FU_PACKET [2:0] fu_issue_in;
	FU_COMPLETE_PACKET [2:0] fu_complete_out, expected_fu_complete_out;
	FU_RS_PACKET fu_rs_out, expected_fu_rs_out;
	FU_PRF_PACKET [6:0] fu_prf_out, expected_fu_prf_out;

	`ifdef TEST_MODE 
	ISSUE_FU_PACKET fu_issue_in_mult1_check;
	logic [31:0] mult1_a_check, mult1_b_check;
	logic [31:0] mult1_result_check;
	logic [4:0] mult1_finish_check;
	logic [2:0] count0_check, count1_check, count2_check, count3_check, count4_check, count5_check, count6_check, count7_check;
	logic pc21_compare_check, pc20_compare_check, pc10_compare_check;
	logic br_done_check, mult1_done_check, mult2_done_check, alu1_done_check, alu2_done_check, alu3_done_check;
	logic alu2_reg_has_value_check, alu2_reg_has_value_pre_check;
	FU_COMPLETE_PACKET alu2_reg_packet_check;
	FU_COMPLETE_PACKET fu_complete_out_br_check, fu_complete_out_alu2_check;
	ISSUE_FU_PACKET fu_issue_in_br_check;
	logic [1:0] if_state_check;
	`endif

    logic correct;
    int test;
	logic busy_use_correct;

	fu fu_tb (.clock(clock), .reset(reset),
		.fu_issue_in(fu_issue_in),
		.fu_complete_out(fu_complete_out),
		.fu_rs_out(fu_rs_out),
		.fu_prf_out(fu_prf_out)
	
		`ifdef TEST_MODE 
		,.fu_issue_in_mult1_check(fu_issue_in_mult1_check)
		,.mult1_a_check(mult1_a_check)
		,.mult1_b_check(mult1_b_check)
		,.mult1_result_check(mult1_result_check)
		,.mult1_finish_check(mult1_finish_check)
		,.count0_check(count0_check)
		,.count1_check(count1_check)
		,.count2_check(count2_check)
		,.count3_check(count3_check)
		,.count4_check(count4_check)
		,.count5_check(count5_check)
		,.count6_check(count6_check)
		,.count7_check(count7_check)
		,.pc21_compare_check(pc21_compare_check)
		,.pc20_compare_check(pc20_compare_check)
		,.pc10_compare_check(pc10_compare_check)
		,.br_done_check(br_done_check)
		,.mult1_done_check(mult1_done_check)
		,.mult2_done_check(mult2_done_check)
		,.alu1_done_check(alu1_done_check)
		,.alu2_done_check(alu2_done_check)
		,.alu3_done_check(alu3_done_check)
		,.alu2_reg_has_value_check(alu2_reg_has_value_check)
		,.alu2_reg_has_value_pre_check(alu2_reg_has_value_pre_check)
		,.alu2_reg_packet_check(alu2_reg_packet_check)
		,.fu_complete_out_br_check(fu_complete_out_br_check)
		,.fu_complete_out_alu2_check(fu_complete_out_alu2_check)
		,.fu_issue_in_br_check(fu_issue_in_br_check)
		,.if_state_check(if_state_check)
		`endif
	);

	assign correct = (fu_complete_out == expected_fu_complete_out) & 
					 (fu_rs_out == expected_fu_rs_out) &
					 (fu_prf_out == expected_fu_prf_out);

	assign busy_use_correct = (fu_rs_out == expected_fu_rs_out);
	
	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);

        $display("INITIALIZING fu TESTBENCH");
		test = 0; clock = 0; reset = 1;
        fu_issue_in = 0;
		expected_fu_complete_out = 0; expected_fu_rs_out = 0; expected_fu_prf_out = 0;

		$display("@@@ Test %d: Reset the fu", test);
		verify_answer();


		$display("@@@ Test %d: Dispatch single mult", test);
		reset = 0;
		@(negedge clock);

		fu_issue_in[0].NPC = 32'd4;
		fu_issue_in[0].PC = 32'd0;
		fu_issue_in[0].rs1_value = 32'd2;
		fu_issue_in[0].rs2_value = 32'd10;
		fu_issue_in[0].opa_select = OPA_IS_RS1;
		fu_issue_in[0].opb_select = OPB_IS_RS2;
		fu_issue_in[0].pr_idx = 6'd1;
		fu_issue_in[0].ar_idx = 5'd3;
		fu_issue_in[0].rob_idx = 5'd4;
		fu_issue_in[0].op_sel = mult;
		fu_issue_in[0].fu_select = MULT_1;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b0;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {7'd1, 5'd1, 5'd2, 3'd0, 5'd3, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode
		
		expected_fu_complete_out[0].pr_idx = 6'd1;
		expected_fu_complete_out[0].ar_idx = 5'd3;
		expected_fu_complete_out[0].rob_idx = 5'd4;
		expected_fu_complete_out[0].target_pc = 32'd0;
		expected_fu_complete_out[0].dest_value = 32'd20;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b0;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b0;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b1;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[5].idx = 6'd1;
		expected_fu_prf_out[5].value = 32'd20;

		check_multiply_result();
		@(negedge clock);
		// verify_fu_busy_use();
		check_multiply_result();
		fu_issue_in[0].fu_select = 0;
		expected_fu_rs_out.mult_1 = 1'b0;
		@(negedge clock);
		check_multiply_result();
		@(negedge clock);
		check_multiply_result();

		verify_answer();

		$display("@@@ Test %d: Dispatch single add", test);

		fu_issue_in[0].NPC = 32'd8;
		fu_issue_in[0].PC = 32'd4;
		fu_issue_in[0].rs1_value = 32'd5;
		fu_issue_in[0].rs2_value = 32'd7;
		fu_issue_in[0].opa_select = OPA_IS_RS1;
		fu_issue_in[0].opb_select = OPB_IS_RS2;
		fu_issue_in[0].pr_idx = 6'd2;
		fu_issue_in[0].ar_idx = 5'd3;
		fu_issue_in[0].rob_idx = 5'd4;
		fu_issue_in[0].op_sel = alu;
		fu_issue_in[0].fu_select = ALU_2;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b0;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {7'd0, 5'd1, 5'd2, 3'd0, 5'd3, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode
		
		expected_fu_complete_out[0].pr_idx = 6'd2;
		expected_fu_complete_out[0].ar_idx = 5'd3;
		expected_fu_complete_out[0].rob_idx = 5'd4;
		expected_fu_complete_out[0].target_pc = 32'd0;
		expected_fu_complete_out[0].dest_value = 32'd12;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b0;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b0;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b0;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[5].idx = 6'd0;
		expected_fu_prf_out[5].value = 32'd0;
		expected_fu_prf_out[3].idx = 6'd2;
		expected_fu_prf_out[3].value = 32'd12;

		verify_answer();

		$display("@@@ Test %d: Dispatch single branch", test);
		fu_issue_in[0].NPC = 32'd12;
		fu_issue_in[0].PC = 32'd8;
		fu_issue_in[0].rs1_value = 32'd5;
		fu_issue_in[0].rs2_value = 32'd5;
		fu_issue_in[0].opa_select = OPA_IS_PC;
		fu_issue_in[0].opb_select = OPB_IS_B_IMM;
		fu_issue_in[0].pr_idx = 6'd2;
		fu_issue_in[0].ar_idx = 5'd3;
		fu_issue_in[0].rob_idx = 5'd4;
		fu_issue_in[0].op_sel = br;
		fu_issue_in[0].fu_select = BRANCH;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b1;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {1'd0, 6'd0, 5'd1, 5'd2, 3'd0, 4'd8, 1'd0, 7'b1100011};
								// offset[12], offset[10:5], rs2, rs1, funct3, offset[4:1], offset[11], opcode
		
		expected_fu_complete_out[0].pr_idx = 6'd2;
		expected_fu_complete_out[0].ar_idx = 5'd3;
		expected_fu_complete_out[0].rob_idx = 5'd4;
		expected_fu_complete_out[0].target_pc = 32'd24;
		expected_fu_complete_out[0].dest_value = 32'd24;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b1;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b0;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b0;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[3].idx = 6'd0;
		expected_fu_prf_out[3].value = 32'd0;

		verify_answer();

		fu_issue_in = 0;
		expected_fu_complete_out = 0; expected_fu_rs_out = 0; expected_fu_prf_out = 0;

		verify_answer();

		
		$display("@@@ Test %d: 4 unit done in the same cycle", test);
		@(negedge clock);

		fu_issue_in[0].NPC = 32'd4;
		fu_issue_in[0].PC = 32'd0;
		fu_issue_in[0].rs1_value = 32'd2;
		fu_issue_in[0].rs2_value = 32'd10;
		fu_issue_in[0].opa_select = OPA_IS_RS1;
		fu_issue_in[0].opb_select = OPB_IS_RS2;
		fu_issue_in[0].pr_idx = 6'd1;
		fu_issue_in[0].ar_idx = 5'd3;
		fu_issue_in[0].rob_idx = 5'd4;
		fu_issue_in[0].op_sel = mult;
		fu_issue_in[0].fu_select = MULT_1;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b0;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {7'd1, 5'd1, 5'd2, 3'd0, 5'd3, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode
		
		expected_fu_complete_out[0].pr_idx = 6'd1;
		expected_fu_complete_out[0].ar_idx = 5'd3;
		expected_fu_complete_out[0].rob_idx = 5'd4;
		expected_fu_complete_out[0].target_pc = 32'd0;
		expected_fu_complete_out[0].dest_value = 32'd20;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b0;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b0;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b1;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[5].idx = 6'd1;
		expected_fu_prf_out[5].value = 32'd20;
		@(negedge clock);

		//not important
		fu_issue_in[0].NPC = 32'd8;
		fu_issue_in[0].PC = 32'd4;
		fu_issue_in[0].rs1_value = 32'd5;
		fu_issue_in[0].rs2_value = 32'd7;
		fu_issue_in[0].opa_select = OPA_IS_RS1;
		fu_issue_in[0].opb_select = OPB_IS_RS2;
		fu_issue_in[0].pr_idx = 6'd2;
		fu_issue_in[0].ar_idx = 5'd4;
		fu_issue_in[0].rob_idx = 5'd5;
		fu_issue_in[0].op_sel = alu;
		fu_issue_in[0].fu_select = ALU_1;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b0;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {7'd0, 5'd1, 5'd2, 3'd0, 5'd4, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode

		@(negedge clock);
		@(negedge clock);

		fu_issue_in[0].NPC = 32'd8;
		fu_issue_in[0].PC = 32'd4;
		fu_issue_in[0].rs1_value = 32'd5;
		fu_issue_in[0].rs2_value = 32'd7;
		fu_issue_in[0].opa_select = OPA_IS_RS1;
		fu_issue_in[0].opb_select = OPB_IS_RS2;
		fu_issue_in[0].pr_idx = 6'd2;
		fu_issue_in[0].ar_idx = 5'd4;
		fu_issue_in[0].rob_idx = 5'd5;
		fu_issue_in[0].op_sel = alu;
		fu_issue_in[0].fu_select = ALU_1;
		fu_issue_in[0].alu_func = ALU_ADD;
		fu_issue_in[0].mult_func = ALU_MUL;
		fu_issue_in[0].rd_mem = 1'b0;
		fu_issue_in[0].wr_mem = 1'b0;
		fu_issue_in[0].cond_branch = 1'b0;
		fu_issue_in[0].uncond_branch = 1'b0;
		fu_issue_in[0].halt = 1'b0;
		fu_issue_in[0].csr_op = 1'b0;
		fu_issue_in[0].valid = 1'b1;
		fu_issue_in[0].inst = {7'd0, 5'd1, 5'd2, 3'd0, 5'd4, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode

		fu_issue_in[1].NPC = 32'd12;
		fu_issue_in[1].PC = 32'd8;
		fu_issue_in[1].rs1_value = 32'd6;
		fu_issue_in[1].rs2_value = 32'd8;
		fu_issue_in[1].opa_select = OPA_IS_RS1;
		fu_issue_in[1].opb_select = OPB_IS_RS2;
		fu_issue_in[1].pr_idx = 6'd3;
		fu_issue_in[1].ar_idx = 5'd5;
		fu_issue_in[1].rob_idx = 5'd6;
		fu_issue_in[1].op_sel = alu;
		fu_issue_in[1].fu_select = ALU_2;
		fu_issue_in[1].alu_func = ALU_ADD;
		fu_issue_in[1].mult_func = ALU_MUL;
		fu_issue_in[1].rd_mem = 1'b0;
		fu_issue_in[1].wr_mem = 1'b0;
		fu_issue_in[1].cond_branch = 1'b0;
		fu_issue_in[1].uncond_branch = 1'b0;
		fu_issue_in[1].halt = 1'b0;
		fu_issue_in[1].csr_op = 1'b0;
		fu_issue_in[1].valid = 1'b1;
		fu_issue_in[1].inst = {7'd0, 5'd1, 5'd2, 3'd0, 5'd5, 7'b0110011};
								// funct7, rs2, rs1, funct3, rd, opcode

		fu_issue_in[2].NPC = 32'd16;
		fu_issue_in[2].PC = 32'd12;
		fu_issue_in[2].rs1_value = 32'd5;
		fu_issue_in[2].rs2_value = 32'd5;
		fu_issue_in[2].opa_select = OPA_IS_PC;
		fu_issue_in[2].opb_select = OPB_IS_B_IMM;
		fu_issue_in[2].pr_idx = 6'd4;
		fu_issue_in[2].ar_idx = 5'd16;
		fu_issue_in[2].rob_idx = 5'd7;
		fu_issue_in[2].op_sel = br;
		fu_issue_in[2].fu_select = BRANCH;
		fu_issue_in[2].alu_func = ALU_ADD;
		fu_issue_in[2].mult_func = ALU_MUL;
		fu_issue_in[2].rd_mem = 1'b0;
		fu_issue_in[2].wr_mem = 1'b0;
		fu_issue_in[2].cond_branch = 1'b1;
		fu_issue_in[2].uncond_branch = 1'b0;
		fu_issue_in[2].halt = 1'b0;
		fu_issue_in[2].csr_op = 1'b0;
		fu_issue_in[2].valid = 1'b1;
		fu_issue_in[2].inst = {1'd0, 6'd0, 5'd1, 5'd2, 3'd0, 4'd8, 1'd0, 7'b1100011};
								// offset[12], offset[10:5], rs2, rs1, funct3, offset[4:1], offset[11], opcode

		expected_fu_complete_out[0].pr_idx = 6'd1;
		expected_fu_complete_out[0].ar_idx = 5'd3;
		expected_fu_complete_out[0].rob_idx = 5'd4;
		expected_fu_complete_out[0].target_pc = 32'd0;
		expected_fu_complete_out[0].dest_value = 32'd20;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b0;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b1;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b0;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[5].idx = 6'd1;
		expected_fu_prf_out[5].value = 32'd20;


		expected_fu_complete_out[1].pr_idx = 6'd2;
		expected_fu_complete_out[1].ar_idx = 5'd4;
		expected_fu_complete_out[1].rob_idx = 5'd5;
		expected_fu_complete_out[1].target_pc = 32'd0;
		expected_fu_complete_out[1].dest_value = 32'd12;
		expected_fu_complete_out[1].rd_mem = 1'b0;
		expected_fu_complete_out[1].wr_mem = 1'b0;
		expected_fu_complete_out[1].halt = 1'b0;
		expected_fu_complete_out[1].take_branch = 1'b0;
		expected_fu_complete_out[1].valid = 1'b1;

		expected_fu_prf_out[2].idx = 6'd2;
		expected_fu_prf_out[2].value = 32'd12;

		expected_fu_prf_out[3].idx = 6'd3;
		expected_fu_prf_out[3].value = 32'd14;


		expected_fu_complete_out[2].pr_idx = 6'd4;
		expected_fu_complete_out[2].ar_idx = 5'd16;
		expected_fu_complete_out[2].rob_idx = 5'd7;
		expected_fu_complete_out[2].target_pc = 32'd28;
		expected_fu_complete_out[2].dest_value = 32'd28;
		expected_fu_complete_out[2].rd_mem = 1'b0;
		expected_fu_complete_out[2].wr_mem = 1'b0;
		expected_fu_complete_out[2].halt = 1'b0;
		expected_fu_complete_out[2].take_branch = 1'b1;
		expected_fu_complete_out[2].valid = 1'b1;

		verify_answer();

		$display("@@@ Test %d: the second cycle", test);

		fu_issue_in = 0;

		expected_fu_complete_out[1] = 0;
		expected_fu_complete_out[2] = 0;

		expected_fu_complete_out[0].pr_idx = 6'd3;
		expected_fu_complete_out[0].ar_idx = 5'd5;
		expected_fu_complete_out[0].rob_idx = 5'd6;
		expected_fu_complete_out[0].target_pc = 32'd0;
		expected_fu_complete_out[0].dest_value = 32'd14;
		expected_fu_complete_out[0].rd_mem = 1'b0;
		expected_fu_complete_out[0].wr_mem = 1'b0;
		expected_fu_complete_out[0].halt = 1'b0;
		expected_fu_complete_out[0].take_branch = 1'b0;
		expected_fu_complete_out[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b0;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b0;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;

		expected_fu_prf_out[2].idx = 6'd0;
		expected_fu_prf_out[2].value = 32'd0;
		expected_fu_prf_out[3].idx = 6'd0;
		expected_fu_prf_out[3].value = 32'd0;
		expected_fu_prf_out[5].idx = 6'd0;
		expected_fu_prf_out[5].value = 32'd0;

		verify_answer();

		





		
        $display("\nENDING fu TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial


    task verify_answer; begin
        @(negedge clock);
		$display("@@@ time %4.0f", $time);
		// check_multiply_result();
		show_count();
		show_done();
		show_reg_has_value();
		show_alu2_reg();
		show_alu2_fu_complete();
		show_br_fu_complete();
		show_fu_issue_in_br();
		show_if_state();
		// show_compare();
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:\n\treset:%b", reset);

            // Print dispatch_rob_packet input
            for (int i = 0; i < 3; i = i + 1)
                $display("\t fu_issue_in[%d]: NPC:%d PC:%d rs1_value:%b rs2_value:%b opa_select:%b opb_select:%b pr_idx:%b ar_idx:%b rob_idx:%b op_sel:%b fu_select:%b alu_func:%b mult_func:%b rd_mem:%b wr_mem:%b cond_branch:%b uncond_branch:%b halt:%b illegal:%b csr_op:%b valid:%b inst:%b", i,
                    fu_issue_in[i].NPC, fu_issue_in[i].PC, fu_issue_in[i].rs1_value, fu_issue_in[i].rs2_value, fu_issue_in[i].opa_select, fu_issue_in[i].opb_select, fu_issue_in[i].pr_idx, fu_issue_in[i].ar_idx, fu_issue_in[i].rob_idx, fu_issue_in[i].op_sel, fu_issue_in[i].fu_select, fu_issue_in[i].alu_func, fu_issue_in[i].mult_func, fu_issue_in[i].rd_mem, fu_issue_in[i].wr_mem, fu_issue_in[i].cond_branch, fu_issue_in[i].uncond_branch, fu_issue_in[i].halt, fu_issue_in[i].illegal, fu_issue_in[i].csr_op, fu_issue_in[i].valid, fu_issue_in[i].inst);

			$display("@@@ Outputs:");
            // Print fu_complete_out output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\tfu_complete_out[%d]: pr_idx:%b ar_idx:%b rob_idx:%b target_pc:%b dest_value:%b rd_mem:%b wr_mem:%b halt:%b take_branch:%b valid:%b ", i,
                    fu_complete_out[i].pr_idx, fu_complete_out[i].ar_idx, fu_complete_out[i].rob_idx, fu_complete_out[i].target_pc, fu_complete_out[i].dest_value, fu_complete_out[i].rd_mem, fu_complete_out[i].wr_mem, fu_complete_out[i].halt, fu_complete_out[i].take_branch, fu_complete_out[i].valid);

			$display("\t fu_rs_out alu_1 alu_2 alu_3 mult_1 mult_2 branch_1 ",
                fu_rs_out.alu_1, fu_rs_out.alu_2, fu_rs_out.alu_3, fu_rs_out.mult_1, fu_rs_out.mult_2, fu_rs_out.branch_1);

			for (int i = 0; i < 7; i = i + 1)
				$display("\t fu_prf_out[%d]: idx:%b value:%b", i,
					fu_prf_out[i].idx, fu_prf_out[i].value);


			$display("@@@ Expected outputs:");
			for (int i = 0; i < 3; i = i + 1)
			    $display("\t expected_fu_complete_out[%d]: pr_idx:%b ar_idx:%b rob_idx:%b target_pc:%b dest_value:%b rd_mem:%b wr_mem:%b halt:%b take_branch:%b valid:%b ", i,
                    expected_fu_complete_out[i].pr_idx, expected_fu_complete_out[i].ar_idx, expected_fu_complete_out[i].rob_idx, expected_fu_complete_out[i].target_pc, expected_fu_complete_out[i].dest_value, expected_fu_complete_out[i].rd_mem, expected_fu_complete_out[i].wr_mem, expected_fu_complete_out[i].halt, expected_fu_complete_out[i].take_branch, expected_fu_complete_out[i].valid);

			$display("\t expected_fu_rs_out alu_1 alu_2 alu_3 mult_1 mult_2 branch_1 ",
                expected_fu_rs_out.alu_1, expected_fu_rs_out.alu_2, expected_fu_rs_out.alu_3, expected_fu_rs_out.mult_1, expected_fu_rs_out.mult_2, expected_fu_rs_out.branch_1);

			for (int i = 0; i < 7; i = i + 1)
				$display("\t expected_fu_prf_out[%d]: idx:%b value:%b", i,
					expected_fu_prf_out[i].idx, expected_fu_prf_out[i].value);

            $display("ENDING ROB TESTBENCH: ERROR!");
			$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer

	task verify_fu_busy_use; begin
		if (!busy_use_correct) begin
			$display("@@@ Outputs:");
			$display("\t fu_rs_out alu_1 alu_2 alu_3 mult_1 mult_2 branch_1 ",
                fu_rs_out.alu_1, fu_rs_out.alu_2, fu_rs_out.alu_3, fu_rs_out.mult_1, fu_rs_out.mult_2, fu_rs_out.branch_1);
			$display("@@@ Expected outputs:");
			$display("\t expected_fu_rs_out alu_1 alu_2 alu_3 mult_1 mult_2 branch_1 ",
                expected_fu_rs_out.alu_1, expected_fu_rs_out.alu_2, expected_fu_rs_out.alu_3, expected_fu_rs_out.mult_1, expected_fu_rs_out.mult_2, expected_fu_rs_out.branch_1);
			$display("ENDING ROB TESTBENCH: ERROR!");

			$display("@@@ input_issue_packet:");
			$display("\t fu_issue_in_mult1_check: NPC: PC: rs1_value: rs2_value: opa_select: opb_select: pr_idx: ar_idx: rob_idx: op_sel: fu_select: alu_func: mult_func: rd_mem: wr_mem: cond_branch: uncond_branch: halt: illegal: csr_op: valid: inst: ",
                    fu_issue_in[0].NPC, fu_issue_in[0].PC, fu_issue_in[0].rs1_value, fu_issue_in[0].rs2_value, fu_issue_in[0].opa_select, fu_issue_in[0].opb_select, fu_issue_in[0].pr_idx, fu_issue_in[0].ar_idx, fu_issue_in[0].rob_idx, fu_issue_in[0].op_sel, fu_issue_in[0].fu_select, fu_issue_in[0].alu_func, fu_issue_in[0].mult_func, fu_issue_in[0].rd_mem, fu_issue_in[0].wr_mem, fu_issue_in[0].cond_branch, fu_issue_in[0].uncond_branch, fu_issue_in[0].halt, fu_issue_in[0].illegal, fu_issue_in[0].csr_op, fu_issue_in[0].valid, fu_issue_in[0].inst);


			$display("@@@ issue_packet:");
			$display("\t fu_issue_in_mult1_check: NPC: PC: rs1_value: rs2_value: opa_select: opb_select: pr_idx: ar_idx: rob_idx: op_sel: fu_select: alu_func: mult_func: rd_mem: wr_mem: cond_branch: uncond_branch: halt: illegal: csr_op: valid: inst: ",
                    fu_issue_in_mult1_check.NPC, fu_issue_in_mult1_check.PC, fu_issue_in_mult1_check.rs1_value, fu_issue_in_mult1_check.rs2_value, fu_issue_in_mult1_check.opa_select, fu_issue_in_mult1_check.opb_select, fu_issue_in_mult1_check.pr_idx, fu_issue_in_mult1_check.ar_idx, fu_issue_in_mult1_check.rob_idx, fu_issue_in_mult1_check.op_sel, fu_issue_in_mult1_check.fu_select, fu_issue_in_mult1_check.alu_func, fu_issue_in_mult1_check.mult_func, fu_issue_in_mult1_check.rd_mem, fu_issue_in_mult1_check.wr_mem, fu_issue_in_mult1_check.cond_branch, fu_issue_in_mult1_check.uncond_branch, fu_issue_in_mult1_check.halt, fu_issue_in_mult1_check.illegal, fu_issue_in_mult1_check.csr_op, fu_issue_in_mult1_check.valid, fu_issue_in_mult1_check.inst);

			$display("\t mult1_a mult1_b ",
                mult1_a_check, mult1_b_check);

			$finish;
		end
	end endtask	//verify_fu_busy_use

	task check_multiply_result; begin
		$display("@@@ mult1_result:");
		$display(mult1_result_check);
		$display("@@@ mult1_finish:");
		$display(mult1_finish_check);

	end endtask

	task show_count; begin
		$display("@@@ count0:%d  count1:%d  count2:%d  count3:%d  count4:%d  count5:%d  count6:%d  count7:%d",
		count0_check, count1_check, count2_check, count3_check, count4_check, count5_check, count6_check, count7_check);
	end endtask

	
	task show_compare; begin
		$display("@@@ pc21_compare_check:%d  pc20_compare_check:%d  pc10_compare_check:%d",
		pc21_compare_check, pc20_compare_check, pc10_compare_check);
	end endtask

	task show_done; begin
		$display("@@@ br_done_check:%d  mult1_done_check:%d  mult2_done_check:%d alu1_done_check:%d alu2_done_check:%d alu3_done_check:%d",
		br_done_check, mult1_done_check, mult2_done_check, alu1_done_check, alu2_done_check, alu3_done_check);
	end endtask

	task show_reg_has_value; begin
		$display("@@@ alu2_reg_has_value_check:%d  alu2_reg_has_value_pre_check:%d",
		alu2_reg_has_value_check, alu2_reg_has_value_pre_check);
	end endtask

	task show_alu2_reg; begin
		$display("\t alu2_reg_packet_check: pr_idx:%b ar_idx:%b rob_idx:%b target_pc:%b dest_value:%b rd_mem:%b wr_mem:%b halt:%b take_branch:%b valid:%b ",
                    alu2_reg_packet_check.pr_idx, alu2_reg_packet_check.ar_idx, alu2_reg_packet_check.rob_idx, alu2_reg_packet_check.target_pc, alu2_reg_packet_check.dest_value, alu2_reg_packet_check.rd_mem, alu2_reg_packet_check.wr_mem, alu2_reg_packet_check.halt, alu2_reg_packet_check.take_branch, alu2_reg_packet_check.valid);
	end endtask

	task show_alu2_fu_complete; begin
		$display("\t fu_complete_out_alu2_check: pr_idx:%b ar_idx:%b rob_idx:%b target_pc:%b dest_value:%b rd_mem:%b wr_mem:%b halt:%b take_branch:%b valid:%b ",
            fu_complete_out_alu2_check.pr_idx, fu_complete_out_alu2_check.ar_idx, fu_complete_out_alu2_check.rob_idx, fu_complete_out_alu2_check.target_pc, fu_complete_out_alu2_check.dest_value, fu_complete_out_alu2_check.rd_mem, fu_complete_out_alu2_check.wr_mem, fu_complete_out_alu2_check.halt, fu_complete_out_alu2_check.take_branch, fu_complete_out_alu2_check.valid);
	end endtask

	task show_br_fu_complete; begin
		$display("\t fu_complete_out_br_check: pr_idx:%b ar_idx:%b rob_idx:%b target_pc:%b dest_value:%b rd_mem:%b wr_mem:%b halt:%b take_branch:%b valid:%b ",
            fu_complete_out_br_check.pr_idx, fu_complete_out_br_check.ar_idx, fu_complete_out_br_check.rob_idx, fu_complete_out_br_check.target_pc, fu_complete_out_br_check.dest_value, fu_complete_out_br_check.rd_mem, fu_complete_out_br_check.wr_mem, fu_complete_out_br_check.halt, fu_complete_out_br_check.take_branch, fu_complete_out_br_check.valid);
	end endtask

	task show_fu_issue_in_br; begin
		$display("\t fu_issue_in_br_check: NPC:%d PC:%d rs1_value:%b rs2_value:%b opa_select:%b opb_select:%b pr_idx:%b ar_idx:%b rob_idx:%b op_sel:%b fu_select:%b alu_func:%b mult_func:%b rd_mem:%b wr_mem:%b cond_branch:%b uncond_branch:%b halt:%b illegal:%b csr_op:%b valid:%b inst:%b",
            fu_issue_in_br_check.NPC, fu_issue_in_br_check.PC, fu_issue_in_br_check.rs1_value, fu_issue_in_br_check.rs2_value, fu_issue_in_br_check.opa_select, fu_issue_in_br_check.opb_select, fu_issue_in_br_check.pr_idx, fu_issue_in_br_check.ar_idx, fu_issue_in_br_check.rob_idx, fu_issue_in_br_check.op_sel, fu_issue_in_br_check.fu_select, fu_issue_in_br_check.alu_func, fu_issue_in_br_check.mult_func, fu_issue_in_br_check.rd_mem, fu_issue_in_br_check.wr_mem, fu_issue_in_br_check.cond_branch, fu_issue_in_br_check.uncond_branch, fu_issue_in_br_check.halt, fu_issue_in_br_check.illegal, fu_issue_in_br_check.csr_op, fu_issue_in_br_check.valid, fu_issue_in_br_check.inst);
	end endtask

	task show_if_state; begin
		$display("@@@ if_state_check:", if_state_check);
	end endtask

endmodule