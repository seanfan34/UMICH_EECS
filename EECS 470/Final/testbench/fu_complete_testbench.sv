module fu_complete_testbench;
    int test;
	logic correct;

	// Inputs for fu
	logic clock, reset;
    ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0] fu_issue_in;

    //Outputs from fu
    FU_RS_PACKET fu_rs_out;
	FU_RS_PACKET [6:0] fu_prf_out;

    // Outputs from complete
	logic take_branch, expected_take_branch; // if take branch // there will be only one branch
    logic [`XLEN-1:0] target_pc, expected_target_pc; // branch destination
    logic [`SUPERSCALAR_WAYS-1:0] halt, expected_halt; // pass
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] complete_rob_out, expected_complete_rob_out;  //[4:0] rob_idx, complete, valid
    COMPLETE_PRF_PACKET [`SUPERSCALAR_WAYS-1:0] complete_prf_out, expected_complete_prf_out;  //ar_idx, dest_value, rd_mem, wr_mem
    CDB_PACKET cdb_out, expected_cdb_out;        // we have 3 CDB entries

    // Connections between fu and complete
    FU_COMPLETE_PACKET  [`SUPERSCALAR_WAYS-1:0] fu_complete_packet;
    
	fu_complete fu_complete(
		.clock(clock),
		.reset(reset),
		.fu_issue_in(fu_issue_in),
    	.fu_rs_out(fu_rs_out),
		.fu_prf_out(fu_prf_out),
		.take_branch(take_branch),
		.target_pc(target_pc),
		.halt(halt),
		.complete_rob_out(complete_rob_out),
		.complete_prf_out(complete_prf_out),
		.cdb_out(cdb_out),
		.fu_complete_packet(fu_complete_packet)

	);

	assign correct = (take_branch == expected_take_branch)
					& (target_pc == expected_target_pc)
					& (halt == expected_halt)
					& (complete_rob_out == expected_complete_rob_out)
					& (complete_prf_out == expected_complete_prf_out)
					& (cdb_out == expected_cdb_out);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
    	$dumpvars;

        $display("\nINITIALIZING TESTBENCH\n");
		test = 0;
		clock = 0; 
		reset = 1;
		fu_issue_in = 0;

		$display("@@@ Test reset %d: ", test);

		expected_complete_rob_out = 0;
		expected_complete_prf_out = 0;
		expected_cdb_out = 0;
		expected_take_branch = 0; expected_halt = 0;
		expected_target_pc = 0;

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
		
		expected_complete_rob_out[0].rob_idx = 5'd4;
		expected_complete_rob_out[0].complete = 1;
		expected_complete_rob_out[0].valid = 1;
		expected_complete_rob_out[0].precise_state_enable = 0;

		
		expected_complete_prf_out[0].pr_idx = 6'd1;
		expected_complete_prf_out[0].ar_idx = 5'd3;
		expected_complete_prf_out[0].dest_value = 32'20;
		expected_complete_prf_out[0].rd_mem = 0;
		expected_complete_prf_out[0].wr_mem = 0;

		expected_complete_rob_out[1].rob_idx = 0;
		expected_complete_rob_out[1].complete = 0;
		expected_complete_rob_out[1].valid = 0;
		expected_complete_rob_out[1].precise_state_enable = 0;

		expected_complete_prf_out[1].pr_idx = 0;
		expected_complete_prf_out[1].ar_idx = 0;
		expected_complete_prf_out[1].dest_value = 0;
		expected_complete_prf_out[1].rd_mem = 0;
		expected_complete_prf_out[1].wr_mem = 0;

		expected_complete_rob_out[2].rob_idx = 0;
		expected_complete_rob_out[2].complete = 0;
		expected_complete_rob_out[2].valid = 0;
		expected_complete_rob_out[2].precise_state_enable = 0;

		expected_complete_prf_out[2].pr_idx = 0;
		expected_complete_prf_out[2].ar_idx = 0;
		expected_complete_prf_out[2].dest_value = 0;
		expected_complete_prf_out[2].rd_mem = 0;
		expected_complete_prf_out[2].wr_mem = 0;


		expected_cdb_out.t0 = 6'd1;
		expected_cdb_out.t1 = 0;
		expected_cdb_out.t2 = 0;

		expected_take_branch = 0;

		expected_halt[0] = 0;
		expected_halt[1] = 0;
		expected_halt[2] = 0;

		expected_target_pc[0] = 0;
		expected_target_pc[1] = 0;
		expected_target_pc[2] = 0;


		@(negedge clock);
		@(negedge clock);
		@(negedge clock);

		verify_answer();
		/*

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
		
		expected_fu_complete_packet[0].pr_idx = 6'd2;
		expected_fu_complete_packet[0].ar_idx = 5'd3;
		expected_fu_complete_packet[0].rob_idx = 5'd4;
		expected_fu_complete_packet[0].target_pc = 32'd0;
		expected_fu_complete_packet[0].dest_value = 32'd12;
		expected_fu_complete_packet[0].rd_mem = 1'b0;
		expected_fu_complete_packet[0].wr_mem = 1'b0;
		expected_fu_complete_packet[0].halt = 1'b0;
		expected_fu_complete_packet[0].take_branch = 1'b0;
		expected_fu_complete_packet[0].valid = 1'b1;


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
		
		expected_fu_complete_packet[0].pr_idx = 6'd2;
		expected_fu_complete_packet[0].ar_idx = 5'd3;
		expected_fu_complete_packet[0].rob_idx = 5'd4;
		expected_fu_complete_packet[0].target_pc = 32'd24;
		expected_fu_complete_packet[0].dest_value = 32'd24;
		expected_fu_complete_packet[0].rd_mem = 1'b0;
		expected_fu_complete_packet[0].wr_mem = 1'b0;
		expected_fu_complete_packet[0].halt = 1'b0;
		expected_fu_complete_packet[0].take_branch = 1'b1;
		expected_fu_complete_packet[0].valid = 1'b1;


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
		expected_fu_complete_packet = 0; expected_fu_rs_out = 0; expected_fu_prf_out = 0;

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
		
		expected_fu_complete_packet[0].pr_idx = 6'd1;
		expected_fu_complete_packet[0].ar_idx = 5'd3;
		expected_fu_complete_packet[0].rob_idx = 5'd4;
		expected_fu_complete_packet[0].target_pc = 32'd0;
		expected_fu_complete_packet[0].dest_value = 32'd20;
		expected_fu_complete_packet[0].rd_mem = 1'b0;
		expected_fu_complete_packet[0].wr_mem = 1'b0;
		expected_fu_complete_packet[0].halt = 1'b0;
		expected_fu_complete_packet[0].take_branch = 1'b0;
		expected_fu_complete_packet[0].valid = 1'b1;


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

		expected_fu_complete_packet[0].pr_idx = 6'd1;
		expected_fu_complete_packet[0].ar_idx = 5'd3;
		expected_fu_complete_packet[0].rob_idx = 5'd4;
		expected_fu_complete_packet[0].target_pc = 32'd0;
		expected_fu_complete_packet[0].dest_value = 32'd20;
		expected_fu_complete_packet[0].rd_mem = 1'b0;
		expected_fu_complete_packet[0].wr_mem = 1'b0;
		expected_fu_complete_packet[0].halt = 1'b0;
		expected_fu_complete_packet[0].take_branch = 1'b0;
		expected_fu_complete_packet[0].valid = 1'b1;


		expected_fu_rs_out.alu_1 = 1'b0;
		expected_fu_rs_out.alu_2 = 1'b1;
		expected_fu_rs_out.alu_3 = 1'b0;
		expected_fu_rs_out.mult_1 = 1'b0;
		expected_fu_rs_out.mult_2 = 1'b0;
		expected_fu_rs_out.branch_1 = 1'b0;


		expected_fu_prf_out[5].idx = 6'd1;
		expected_fu_prf_out[5].value = 32'd20;


		expected_fu_complete_packet[1].pr_idx = 6'd2;
		expected_fu_complete_packet[1].ar_idx = 5'd4;
		expected_fu_complete_packet[1].rob_idx = 5'd5;
		expected_fu_complete_packet[1].target_pc = 32'd0;
		expected_fu_complete_packet[1].dest_value = 32'd12;
		expected_fu_complete_packet[1].rd_mem = 1'b0;
		expected_fu_complete_packet[1].wr_mem = 1'b0;
		expected_fu_complete_packet[1].halt = 1'b0;
		expected_fu_complete_packet[1].take_branch = 1'b0;
		expected_fu_complete_packet[1].valid = 1'b1;

		expected_fu_prf_out[2].idx = 6'd2;
		expected_fu_prf_out[2].value = 32'd12;

		expected_fu_prf_out[3].idx = 6'd3;
		expected_fu_prf_out[3].value = 32'd14;


		expected_fu_complete_packet[2].pr_idx = 6'd4;
		expected_fu_complete_packet[2].ar_idx = 5'd16;
		expected_fu_complete_packet[2].rob_idx = 5'd7;
		expected_fu_complete_packet[2].target_pc = 32'd28;
		expected_fu_complete_packet[2].dest_value = 32'd28;
		expected_fu_complete_packet[2].rd_mem = 1'b0;
		expected_fu_complete_packet[2].wr_mem = 1'b0;
		expected_fu_complete_packet[2].halt = 1'b0;
		expected_fu_complete_packet[2].take_branch = 1'b1;
		expected_fu_complete_packet[2].valid = 1'b1;

		verify_answer();

		$display("@@@ Test %d: the second cycle", test);

		fu_issue_in = 0;

		expected_fu_complete_packet[1] = 0;
		expected_fu_complete_packet[2] = 0;

		expected_fu_complete_packet[0].pr_idx = 6'd3;
		expected_fu_complete_packet[0].ar_idx = 5'd5;
		expected_fu_complete_packet[0].rob_idx = 5'd6;
		expected_fu_complete_packet[0].target_pc = 32'd0;
		expected_fu_complete_packet[0].dest_value = 32'd14;
		expected_fu_complete_packet[0].rd_mem = 1'b0;
		expected_fu_complete_packet[0].wr_mem = 1'b0;
		expected_fu_complete_packet[0].halt = 1'b0;
		expected_fu_complete_packet[0].take_branch = 1'b0;
		expected_fu_complete_packet[0].valid = 1'b1;


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
		*/

		





		
        $display("\nENDING fu TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial

	task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:");
            // Print fu_complete_packet input
            for (int i = 0; i < 3; i = i + 1)
                $display("\t fu_issue_in[%d]: NPC:%d PC:%d rs1_value:%b rs2_value:%b opa_select:%b opb_select:%b pr_idx:%b ar_idx:%b rob_idx:%b op_sel:%b fu_select:%b alu_func:%b mult_func:%b rd_mem:%b wr_mem:%b cond_branch:%b uncond_branch:%b halt:%b illegal:%b csr_op:%b valid:%b inst:%b", i,
                    fu_issue_in[i].NPC, fu_issue_in[i].PC, fu_issue_in[i].rs1_value, fu_issue_in[i].rs2_value, fu_issue_in[i].opa_select, fu_issue_in[i].opb_select, fu_issue_in[i].pr_idx, fu_issue_in[i].ar_idx, fu_issue_in[i].rob_idx, fu_issue_in[i].op_sel, fu_issue_in[i].fu_select, fu_issue_in[i].alu_func, fu_issue_in[i].mult_func, fu_issue_in[i].rd_mem, fu_issue_in[i].wr_mem, fu_issue_in[i].cond_branch, fu_issue_in[i].uncond_branch, fu_issue_in[i].halt, fu_issue_in[i].illegal, fu_issue_in[i].csr_op, fu_issue_in[i].valid, fu_issue_in[i].inst);
			
			$display("@@@ Outputs:");
            // Print COMPLETE_ROB_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\tcomplete_rob_out[%d]: valid:%d rob_idx:%d complete:%b precise_state_enable:%b", i,
                    complete_rob_out[i].valid, complete_rob_out[i].rob_idx, complete_rob_out[i].complete
                    ,complete_rob_out[i].precise_state_enable
                    );

            // Print COMPLETE_PRF_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\tcomplete_prf_out[%d]: ar_idx:%d dest_value:%d rd_mem:%b wr_mem:%b", i,
                    complete_prf_out[i].ar_idx, complete_prf_out[i].dest_value, complete_prf_out[i].rd_mem, complete_prf_out[i].wr_mem);

			// Print CDB_PACKET output
			$display("\tcdb_out: t0:%d t1:%d t2:%d",
             	cdb_out.t0, cdb_out.t1, cdb_out.t2);

			// Print else output
			$display("\ttake_branch:%d target_pc:%d halt0:%d halt1:%d halt2:%d",
             	take_branch, target_pc, halt[0], halt[1], halt[2]);

	
			$display("@@@ Expected outputs:");
            // Print expected freelist_dispatch_packet output
            // Print COMPLETE_ROB_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\texpected_complete_rob_out[%d]: valid:%d rob_idx:%d complete:%d precise_state_enable:%b", i,
                    expected_complete_rob_out[i].valid, expected_complete_rob_out[i].rob_idx,
                    expected_complete_rob_out[i].complete,expected_complete_rob_out[i].precise_state_enable);

            // Print COMPLETE_PRF_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\texpected_complete_prf_out[%d]: ar_idx:%d dest_value:%d rd_mem:%b wr_mem:%b", i,
                    expected_complete_prf_out[i].ar_idx, expected_complete_prf_out[i].dest_value, expected_complete_prf_out[i].rd_mem, expected_complete_prf_out[i].wr_mem);

			// Print CDB_PACKET output
			$display("\texpected_cdb_out: t0:%d t1:%d t2:%d",
             	expected_cdb_out.t0, expected_cdb_out.t1, expected_cdb_out.t2);

			// Print else output
			$display("\texpected_take_branch:%d expected_target_pc:%d expected_halt0:%d expected_halt1:%d expected_halt2:%d",
             	expected_take_branch, expected_target_pc, expected_halt[0], expected_halt[1], expected_halt[2]);

			// Print difference
			$display("complete_rob_out === expected_complete_rob_out:%b", complete_rob_out === expected_complete_rob_out);
			$display("complete_prf_out === expected_complete_prf_out:%b", complete_prf_out === expected_complete_prf_out);
			$display("cdb_out 		  === expected_cdb_out:%b", cdb_out 		  === expected_cdb_out);
			$display("take_branch		  === expected_take_branch:%b", take_branch		  === expected_take_branch);
			$display("target_pc			  === expected_target_pc:%b", target_pc			  === expected_target_pc);
			$display("halt				  === expected_halt:%b", halt				  === expected_halt);

            $display("ENDING COMPLETE TESTBENCH: ERROR!");
			$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer
endmodule  // dispatch_maptable_testbench