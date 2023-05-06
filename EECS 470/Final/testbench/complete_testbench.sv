//TESTBENCH FOR COMPLETE_STAGE
//Class:    EECS470
//Specific:  Project 4
//Description:

module complete_testbench;
	// Input
	logic clock;
    FU_COMPLETE_PACKET [`SUPERSCALAR_WAYS-1:0] complete_fu_in;

	// Output
    COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] complete_rob_out, expected_complete_rob_out;
	COMPLETE_PRF_PACKET [`SUPERSCALAR_WAYS-1:0] complete_prf_out, expected_complete_prf_out;
	CDB_PACKET 	cdb_out, expected_cdb_out;
	logic take_branch, expected_take_branch;
	logic [`XLEN-1:0] target_pc, expected_target_pc;
	logic [`SUPERSCALAR_WAYS-1:0] halt, expected_halt;

    logic correct;
    int test;

	complete complete1(
        .complete_fu_in(complete_fu_in),
        //.take_branch(take_branch),
		//.target_pc(target_pc),
		//.halt(halt),
		.complete_rob_out(complete_rob_out),
		.complete_prf_out(complete_prf_out),
		.cdb_out(cdb_out));

	assign correct = (complete_rob_out === expected_complete_rob_out) &&
					 (complete_prf_out === expected_complete_prf_out) &&
					 (cdb_out 		  === expected_cdb_out) &&
					 (take_branch		  === expected_take_branch) &&
					 (target_pc			  === expected_target_pc) &&
					 (halt				  === expected_halt);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);

        $display("INITIALIZING COMPLETE TESTBENCH");
		test = 0; clock = 0;
        complete_fu_in = 0;
		expected_complete_rob_out = 0;
		expected_complete_prf_out = 0;
		expected_cdb_out = 0;
		expected_take_branch = 0; expected_halt = 0;
		expected_target_pc = 0;
		verify_answer();


		$display("@@@ Test %d: One valid instruction. No branch. No read write memory.", test);
		// idx, take_branch, valid, 32bit target_pc, 6bit ar_idx, 32bit dest_value, 5bit rob_idx, halt, rd_mem, wr_mem
		fu_complete(0, 1'b0, 1'b1, 32'b0, 6'd2, 32'd50, 5'd3, 1'b0, 1'b0, 1'b0);
		fu_complete(1, 1'b0, 1'b0, 32'b0, 6'd3, 32'd51, 5'd11, 1'b0, 1'b0, 1'b0);
		fu_complete(2, 1'b0, 1'b0, 32'b0, 6'd4, 32'd52, 5'd12, 1'b0, 1'b0, 1'b0);
		// 5bit rob_idx, complete, valid
		expected_complete_rob_out[0] = {5'd3, 1'b1, 1'b1,1'b0};
		expected_complete_rob_out[1] = {5'd0, 1'b0, 1'b0,1'b0};
		expected_complete_rob_out[2] = {5'd0, 1'b0, 1'b0,1'b0};
		// 6bit ar_idx, 32bit dest_value, rd_mem, wr_mem
		expected_complete_prf_out[0] = {6'd2, 32'd50, 1'b0, 1'b0};
		expected_complete_prf_out[1] = {6'd0, 32'd0, 1'b0, 1'b0};
		expected_complete_prf_out[2] = {6'd0, 32'd0, 1'b0, 1'b0};
		// 6bit t0, t1, t2
		expected_cdb_out = {6'd2, 6'd0, 6'd0};
		// 1bit
		expected_take_branch = 0;
		// 1bit
		expected_halt = {1'b0, 1'b0, 1'b0};
		// 32bit
		expected_target_pc = 0;
		verify_answer();

		$display("@@@ Test %d: two valid instruction. No branch. No read write memory.", test);
		// idx, take_branch, valid, 32bit target_pc, 6bit ar_idx, 32bit dest_value, 5bit rob_idx, halt, rd_mem, wr_mem
		fu_complete(0, 1'b0, 1'b1, 32'b0, 6'd5, 32'd22, 5'd23, 1'b0, 1'b0, 1'b0);
		fu_complete(1, 1'b0, 1'b0, 32'b0, 6'd6, 32'd33, 5'd31, 1'b0, 1'b0, 1'b0);
		fu_complete(2, 1'b0, 1'b1, 32'b0, 6'd7, 32'd44, 5'd30, 1'b0, 1'b0, 1'b0);
		// 5bit rob_idx, complete, valid
		expected_complete_rob_out[0] = {5'd23, 1'b1, 1'b1,1'b0};
		expected_complete_rob_out[1] = {5'd0, 1'b0, 1'b0,1'b0};
		expected_complete_rob_out[2] = {5'd30, 1'b1, 1'b1,1'b0};
		// 6bit ar_idx, 32bit dest_value, rd_mem, wr_mem
		expected_complete_prf_out[0] = {6'd5, 32'd22, 1'b0, 1'b0};
		expected_complete_prf_out[1] = {6'd0, 32'd0, 1'b0, 1'b0};
		expected_complete_prf_out[2] = {6'd7, 32'd44, 1'b0, 1'b0};
		// 6bit t0, t1, t2
		expected_cdb_out = {6'd5, 6'd0, 6'd7};
		// 1bit
		expected_take_branch = 0;
		// 1bit
		expected_halt = {1'b0, 1'b0, 1'b0};
		// 32bit
		expected_target_pc = 0;
		verify_answer();

		$display("@@@ Test %d: three valid instruction. One branch. One read memory.", test);
		// idx, take_branch, valid, 32bit target_pc, 6bit ar_idx, 32bit dest_value, 5bit rob_idx, halt, rd_mem, wr_mem
		fu_complete(0, 1'b0, 1'b1, 32'd30, 6'd8, 32'd23, 5'd29, 1'b0, 1'b1, 1'b0);
		fu_complete(1, 1'b1, 1'b1, 32'd45, 6'd9, 32'd34, 5'd11, 1'b0, 1'b0, 1'b0);
		fu_complete(2, 1'b0, 1'b1, 32'b0, 6'd10, 32'd45, 5'd12, 1'b0, 1'b0, 1'b0);
		// 5bit rob_idx, complete, valid
		expected_complete_rob_out[0] = {5'd29, 1'b1, 1'b1,1'b0};
		expected_complete_rob_out[1] = {5'd11, 1'b1, 1'b1,1'b1};
		expected_complete_rob_out[2] = {5'd12, 1'b1, 1'b1,1'b0};
		// 6bit ar_idx, 32bit dest_value, rd_mem, wr_mem
		expected_complete_prf_out[0] = {6'd8, 32'd23, 1'b1, 1'b0};
		expected_complete_prf_out[1] = {6'd0, 32'd0, 1'b0, 1'b0};
		expected_complete_prf_out[2] = {6'd10, 32'd45, 1'b0, 1'b0};
		// 6bit t0, t1, t2
		expected_cdb_out = {6'd8, 6'd0, 6'd10};
		// 1bit
		expected_take_branch = 1;
		// 1bit
		expected_halt = {1'b0, 1'b0, 1'b0};
		// 32bit
		expected_target_pc = 32'd45;
		verify_answer();

        $display("\nENDING COMPLETE TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial

	task fu_complete; input int packet_idx; input take_branch, valid; input[31:0] target_pc; input[5:0] ar_idx; input[31:0] dest_value; input[4:0] rob_idx; input halt, rd_mem, wr_mem; begin
		complete_fu_in[packet_idx].take_branch = take_branch;
		complete_fu_in[packet_idx].valid = valid;
		complete_fu_in[packet_idx].target_pc = target_pc;
		complete_fu_in[packet_idx].ar_idx = ar_idx;
		complete_fu_in[packet_idx].dest_value = dest_value;
		complete_fu_in[packet_idx].rob_idx = rob_idx;
		complete_fu_in[packet_idx].halt = halt;
		complete_fu_in[packet_idx].rd_mem = rd_mem;
		complete_fu_in[packet_idx].wr_mem = wr_mem;
	end endtask

    task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:");
            // Print complete_fu_in input
            for (int i = 0; i < 3; i = i + 1)
                $display("\tcomplete_fu_in[%d]: take_branch:%b valid:%b target_pc:%d ar_idx:%d dest_value:%d rob_idx:%d halt:%b rd_mem:%b wr_mem:%b", i,
                    complete_fu_in[i].take_branch, complete_fu_in[i].valid, 
					complete_fu_in[i].target_pc, complete_fu_in[i].ar_idx,
					complete_fu_in[i].dest_value, complete_fu_in[i].rob_idx, complete_fu_in[i].halt,
					complete_fu_in[i].rd_mem, complete_fu_in[i].wr_mem);
			
			$display("@@@ Outputs:");
            // Print COMPLETE_ROB_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\tcomplete_rob_out[%d]: rob_idx:%d complete:%b precise_state_enable:%b", i,
                    complete_rob_out[i].rob_idx, complete_rob_out[i].complete
                    ,complete_rob_out[i].precise_state_enable
                    );

            // Print COMPLETE_PRF_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\tcomplete_prf_out[%d]: ar_idx:%d dest_value:%d rd_mem:%b wr_mem:%b", i,
                    complete_prf_out[i].ar_idx, complete_prf_out[i].dest_value, complete_prf_out[i].rd_mem, complete_prf_out[i].wr_mem);

			// Print CDB_PACKET output
			$display("\tcdb_out: t0:%d t1:%d t2:%d",
             	cdb_out.t_idx[0], cdb_out.t_idx[1], cdb_out.t_idx[2]);

			// Print else output
			$display("\ttake_branch:%d target_pc:%d halt0:%d halt1:%d halt2:%d",
             	take_branch, target_pc, halt[0], halt[1], halt[2]);

	
			$display("@@@ Expected outputs:");
            // Print expected freelist_dispatch_packet output
            // Print COMPLETE_ROB_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\texpected_complete_rob_out[%d]: rob_idx:%d complete:%d precise_state_enable:%b", i,
                    expected_complete_rob_out[i].rob_idx,
                    expected_complete_rob_out[i].complete,expected_complete_rob_out[i].precise_state_enable);

            // Print COMPLETE_PRF_PACKET output
            for (int i = 0; i < 3; i = i + 1)
			    $display("\texpected_complete_prf_out[%d]: ar_idx:%d dest_value:%d rd_mem:%b wr_mem:%b", i,
                    expected_complete_prf_out[i].ar_idx, expected_complete_prf_out[i].dest_value, expected_complete_prf_out[i].rd_mem, expected_complete_prf_out[i].wr_mem);

			// Print CDB_PACKET output
			$display("\texpected_cdb_out: t0:%d t1:%d t2:%d",
             	expected_cdb_out.t_idx[0], expected_cdb_out.t_idx[1], expected_cdb_out.t_idx[2]);

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
			//$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer
endmodule  // complete_testbench