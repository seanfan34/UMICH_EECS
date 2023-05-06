//TESTBENCH FOR ROB
//Class:    EECS470
//Specific:  Project 4
//Description:


module issue_testbench;
	RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] issue_rs_in;
	logic [63:0][31:0] physical_register;
    ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0] issue_fu_out;
	logic clock;
    
    ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0] expected_issue_fu_out;

    logic correct;
    int test;

	issue issue1(
        .issue_rs_in(issue_rs_in),
        .physical_register(physical_register), 
		.issue_fu_out(issue_fu_out)
	);

	assign correct = (issue_fu_out[0] === expected_issue_fu_out[0]);
	
	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);
        $display("test add");
		clock = 0;
		test = 0;
        // issue_rs_in[0] = {1'b1,3'd2,5'd0,32'd4,32'd0,2'd0,4'd0,{7'd0,5'd1,5'd2,3'd0,5'd3,7'b0110011},1'b0,5'd2,6'd3,6'd2,6'd1};
		issue_rs_in[0].valid = 1'b1;
		issue_rs_in[0].fu_sel = 3'd2;
		issue_rs_in[0].op_sel = 5'd0;
		issue_rs_in[0].NPC = 32'd4;
		issue_rs_in[0].PC = 32'd0;
		issue_rs_in[0].opa_select = 2'd0;
		issue_rs_in[0].opb_select = 4'd0;
		issue_rs_in[0].inst = {7'd0,5'd1,5'd2,3'd0,5'd3,7'b0110011};
		issue_rs_in[0].halt = 1'b0;
		issue_rs_in[0].rob_idx = 5'd2;
		issue_rs_in[0].pr_idx = 6'd3;
		issue_rs_in[0].ar_idx = 5'd3;
		issue_rs_in[0].reg1_pr_idx = 6'd2;
		issue_rs_in[0].reg2_pr_idx = 6'd1;
		issue_rs_in[0].csr_op = 1'b0;
		issue_rs_in[0].illegal = 1'b0;
		issue_rs_in[0].uncond_branch = 1'b0;
		issue_rs_in[0].cond_branch = 1'b0;
		issue_rs_in[0].rd_mem = 1'b0;
		issue_rs_in[0].wr_mem = 1'b0;

		//valid=1, fu_sel=2(ALU_1), op_sel=0(ALU_ADD), NPC=4, PC=0, opa_select=0(OPA_IS_RS1), opb_select=0(OPB_IS_PS2), INST=, halt=0, rob_idx=2, pr_idx=3, reg1_pr_idx=2, reg2_pr_idx=1

		physical_register = {{61{32'd0}}, 32'd8, 32'd7, 32'd0};


		expected_issue_fu_out[0].NPC = 32'd4;
		expected_issue_fu_out[0].PC = 32'd0;
		expected_issue_fu_out[0].rs1_value = 32'd8;
		expected_issue_fu_out[0].rs2_value = 32'd7;
		expected_issue_fu_out[0].opa_select = 2'd0;
		expected_issue_fu_out[0].opb_select = 4'd0;
		expected_issue_fu_out[0].inst = {7'd0,5'd1,5'd2,3'd0,5'd3,7'b0110011};
		expected_issue_fu_out[0].ar_idx = 5'd3;
		expected_issue_fu_out[0].pr_idx = 6'd3;
		expected_issue_fu_out[0].op_sel = 2'd0;
		expected_issue_fu_out[0].alu_func = 5'd0;
		expected_issue_fu_out[0].mult_func = 5'h0a;
		expected_issue_fu_out[0].fu_select = 3'd2;
		expected_issue_fu_out[0].rob_idx = 5'd2;
		expected_issue_fu_out[0].rd_mem = 1'd0;
		expected_issue_fu_out[0].wr_mem = 1'd0;
		expected_issue_fu_out[0].cond_branch = 1'd0;
		expected_issue_fu_out[0].uncond_branch = 1'd0;
		expected_issue_fu_out[0].halt = 1'd0;
		expected_issue_fu_out[0].illegal = 1'd0;
		expected_issue_fu_out[0].csr_op = 1'd0;
		expected_issue_fu_out[0].valid = 1'd1;

		// issue_fu_out[1] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		// issue_fu_out[2] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		// expected_issue_fu_out[1] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		// expected_issue_fu_out[2] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		verify_answer();

        $display("\nENDING ROB TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial

    task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);

            // Print dispatch_rob_packet input
            for (int i = 0; i < 1; i = i + 1)
				$display("\t issue_rs_in[%d]: valid:%d fu_sel:%d op_sel:%d NPC:%d PC:%d opa_select:%d opb_select:%d inst:%d  halt:%d rob_idx:%d pr_idx:%d  reg1_pr_idx:%d  reg2_pr_idx:%d", i,
                    issue_rs_in[i].valid, issue_rs_in[i].fu_sel, issue_rs_in[i].op_sel, issue_rs_in[i].NPC, issue_rs_in[i].PC, issue_rs_in[i].opa_select, issue_rs_in[i].opb_select, issue_rs_in[i].inst, issue_rs_in[i].halt, issue_rs_in[i].rob_idx, issue_rs_in[i].pr_idx, issue_rs_in[i].reg1_pr_idx, issue_rs_in[i].reg2_pr_idx);


			$display("@@@ Outputs:");
			
            // Print rob_retire_packet output
            for (int i = 0; i < 1; i = i + 1)
				$display("\t issue_fu_out[%d]: NPC:%d PC:%d rs1_value:%d rs2_value:%d opa_select:%d opb_select:%d inst:%d ar_idx:%d pr_idx:%d op_sel:%d alu_func:%d mult_func:%d fu_select:%d rob_idx:%d rd_mem:%d wr_mem:%d cond_brance:%d uncond_branch:%d halt:%d illegal:%d csr_op:%d valid:%d", i,
                    issue_fu_out[i].NPC, issue_fu_out[i].PC, issue_fu_out[i].rs1_value, issue_fu_out[i].rs2_value, issue_fu_out[i].opa_select, issue_fu_out[i].opb_select, issue_fu_out[i].inst, issue_fu_out[i].ar_idx, issue_fu_out[i].pr_idx, issue_fu_out[i].op_sel, issue_fu_out[i].alu_func, issue_fu_out[i].mult_func, issue_fu_out[i].fu_select, issue_fu_out[i].rob_idx, issue_fu_out[i].rd_mem, issue_fu_out[i].wr_mem, issue_fu_out[i].cond_branch, issue_fu_out[i].uncond_branch, issue_fu_out[i].halt, issue_fu_out[i].illegal, issue_fu_out[i].csr_op, issue_fu_out[i].valid);

			$display("@@@ Expected outputs:");
            for (int i = 0; i < 1; i = i + 1)
				$display("\t expected_issue_fu_out[%d]: NPC:%d PC:%d rs1_value:%d rs2_value:%d opa_select:%d opb_select:%d inst:%d ar_idx:%d pr_idx:%d op_sel:%d alu_func:%d mult_func:%d fu_select:%d rob_idx:%d rd_mem:%d wr_mem:%d cond_brance:%d uncond_branch:%d halt:%d illegal:%d csr_op:%d valid:%d", i,
                    expected_issue_fu_out[i].NPC, expected_issue_fu_out[i].PC, expected_issue_fu_out[i].rs1_value, expected_issue_fu_out[i].rs2_value, expected_issue_fu_out[i].opa_select, expected_issue_fu_out[i].opb_select, expected_issue_fu_out[i].inst, expected_issue_fu_out[i].ar_idx, expected_issue_fu_out[i].pr_idx, expected_issue_fu_out[i].op_sel, expected_issue_fu_out[i].alu_func, expected_issue_fu_out[i].mult_func, expected_issue_fu_out[i].fu_select, expected_issue_fu_out[i].rob_idx, expected_issue_fu_out[i].rd_mem, expected_issue_fu_out[i].wr_mem, expected_issue_fu_out[i].cond_branch, expected_issue_fu_out[i].uncond_branch, expected_issue_fu_out[i].halt, expected_issue_fu_out[i].illegal, expected_issue_fu_out[i].csr_op, expected_issue_fu_out[i].valid);
			
            $display("ENDING ROB TESTBENCH: ERROR!");
			$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer
endmodule