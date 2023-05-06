// TESTBENCH FOR MAPTABLE
// Class:    	EECS470
// Specific:  	Project 4
// Description:

module maptable_testbench;
    int test;
    logic correct;

	// Inputs
	logic 											 clock;
	logic 											 reset;
    logic                                       	 br_recover_enable;
    MAPTABLE_PACKET                                  recovery_maptable;
    CDB_PACKET              						 maptable_cdb_in;
	DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] maptable_dispatch_in;

	// Outputs
    MAPTABLE_PACKET                                  maptable_out, expected_maptable_out;

	maptable maptable_tb (
		.clock(clock), 
		.reset(reset),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),
        .maptable_dispatch_in(maptable_dispatch_in),
        .maptable_cdb_in(maptable_cdb_in),
        .maptable_out(maptable_out)
    );

	assign correct = (maptable_out === expected_maptable_out);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end  // always

    initial begin
        $dumpvars;

        $display("\nINITIALIZING MAPTABLE TESTBENCH\n");
		test  = 0; 
		clock = 0;
		clear_input();

		$display("@@@ Test %1d: Reset the Map", test);
		reset = 1;
		for (int i = 0; i < `N_ARCH_REG; i++) 
			expected_maptable_out.map[i] = i; 
		expected_maptable_out.done = { `XLEN{1'b1} };
		verify_answer();

		$display("@@@ Test %1d: Dispatch to reg0 with packet[0]", test);
		reset = 0;
		set_dispatch_in(0, 6'd40, 5'd00);
		verify_answer();

		$display("@@@ Test %1d: Dispatch to reg0 with packet[1]", test);
		reset = 0;
		set_dispatch_in(1, 6'd40, 5'd00);
		verify_answer();

		$display("@@@ Test %1d: Dispatch to reg0 with packet[2]", test);
		reset = 0;
		set_dispatch_in(2, 6'd40, 5'd00);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 1 with packet[0]", test);
		set_dispatch(0, 6'd54, 5'd01);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 1 with packet[1]", test);
		set_dispatch(1, 6'd40, 5'd30);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 1 with packet[2]", test);
		set_dispatch(2, 6'd02, 5'd13);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with packet[0] and packet[1]", test);
		set_dispatch(0, 6'd05, 5'd05);
		set_dispatch(1, 6'd60, 5'd17);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with packet[0] and packet[2]", test);
		set_dispatch(0, 6'd06, 5'd08);
		set_dispatch(2, 6'd01, 5'd02);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with packet[1] and packet[2]", test);
		set_dispatch(1, 6'd27, 5'd23);
		set_dispatch(2, 6'd26, 5'd24);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3", test);
		set_dispatch(0, 6'd33, 5'd22);
		set_dispatch(1, 6'd08, 5'd18);
		set_dispatch(2, 6'd32, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Complete 1 with packet[0]", test);
		set_cdb_in(0, 6'd60, 5'd17);
		verify_answer();

		$display("@@@ Test %1d: Complete 1 with packet[1]", test);
		set_cdb_in(1, 6'd05, 5'd05);
		verify_answer();

		$display("@@@ Test %1d: Complete 1 with packet[2]", test);
		set_cdb_in(2, 6'd40, 5'd30);
		verify_answer();

		$display("@@@ Test %1d: Complete 2 with packet[0] and packet[1]", test);
		set_cdb_in(0, 6'd33, 5'd22);
		set_cdb_in(1, 6'd32, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Complete 2 with packet[0] and packet[2]", test);
		set_cdb_in(0, 6'd54, 5'd01);
		set_cdb_in(2, 6'd01, 5'd02);
		verify_answer();

		$display("@@@ Test %1d: Complete 2 with packet[1] and packet[2]", test);
		set_cdb_in(1, 6'd26, 5'd24);
		set_cdb_in(2, 6'd02, 5'd13);
		verify_answer();

		$display("@@@ Test %1d: Complete 3", test);
		set_cdb_in(0, 6'd06, 5'd08);
		set_cdb_in(1, 6'd27, 5'd23);
		set_cdb_in(2, 6'd08, 5'd18);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with (packet[0].ar_idx === packet[1].ar_idx)", test);
		set_dispatch(0, 6'd33, 5'd22);
		set_dispatch(1, 6'd08, 5'd22);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with (packet[0].ar_idx === packet[2].ar_idx)", test);
		set_dispatch(0, 6'd08, 5'd06);
		set_dispatch(2, 6'd06, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 2 with (packet[1].ar_idx === packet[2].ar_idx)", test);
		set_dispatch(1, 6'd19, 5'd28);
		set_dispatch(2, 6'd60, 5'd28);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3 with (packet[0].ar_idx === packet[1].ar_idx)", test);
		set_dispatch(0, 6'd42, 5'd21);
		set_dispatch(1, 6'd09, 5'd21);
		set_dispatch(2, 6'd56, 5'd20);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3 with (packet[0].ar_idx === packet[2].ar_idx)", test);
		set_dispatch(0, 6'd30, 5'd30);
		set_dispatch(1, 6'd30, 5'd17);
		set_dispatch(2, 6'd10, 5'd30);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3 with (packet[1].ar_idx === packet[2].ar_idx)", test);
		set_dispatch(0, 6'd28, 5'd11);
		set_dispatch(1, 6'd01, 5'd14);
		set_dispatch(2, 6'd03, 5'd14);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3 with (packet[1].ar_idx === packet[2].ar_idx === packet[3].ar_idx)", test);
		set_dispatch(0, 6'd45, 5'd01);
		set_dispatch(1, 6'd19, 5'd01);
		set_dispatch(2, 6'd42, 5'd01);
		verify_answer();

		$display("@@@ Test %1d: Complete t_idx not in the map with packet[0]", test);
		maptable_cdb_in.t_idx[0] = 6'd13;
		verify_answer();

		$display("@@@ Test %1d: Complete t_idx not in the map with packet[1]", test);
		maptable_cdb_in.t_idx[1] = 6'd13;
		verify_answer();

		$display("@@@ Test %1d: Complete t_idx not in the map with packet[2]", test);
		maptable_cdb_in.t_idx[2] = 6'd13;
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[0].ar_idx === cdb[0].ar_idx)", test);
		set_cdb_in(0, 6'd06, 5'd06);
		set_dispatch(0, 6'd01, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[0].ar_idx === cdb[1].ar_idx)", test);
		set_cdb_in(1, 6'd09, 5'd21);
		set_dispatch(0, 6'd09, 5'd21);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[0].ar_idx === cdb[2].ar_idx)", test);
		set_cdb_in(2, 6'd01, 5'd06);
		set_dispatch(0, 6'd06, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[1].ar_idx === cdb[0].ar_idx)", test);
		set_cdb_in(0, 6'd03, 5'd14);
		set_dispatch(1, 6'd40, 5'd14);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[1].ar_idx === cdb[1].ar_idx)", test);
		set_cdb_in(1, 6'd42, 5'd01);
		set_dispatch(1, 6'd63, 5'd01);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[1].ar_idx === cdb[2].ar_idx)", test);
		set_cdb_in(2, 6'd60, 5'd28);
		set_dispatch(1, 6'd26, 5'd28);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2].ar_idx === cdb[0].ar_idx)", test);
		set_cdb_in(0, 6'd56, 5'd20);
		set_dispatch(2, 6'd52, 5'd20);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2].ar_idx === cdb[1].ar_idx)", test);
		set_cdb_in(1, 6'd06, 5'd06);
		set_dispatch(2, 6'd22, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2].ar_idx === cdb[2].ar_idx)", test);
		set_cdb_in(2, 6'd22, 5'd06);
		set_dispatch(2, 6'd04, 5'd06);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2:0].ar_idx === cdb[0].ar_idx)", test);
		set_cdb_in(0, 6'd10, 5'd30);
		set_dispatch(0, 6'd04, 5'd30);
		set_dispatch(1, 6'd20, 5'd30);
		set_dispatch(2, 6'd19, 5'd30);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2:0].ar_idx === cdb[1].ar_idx)", test);
		set_cdb_in(1, 6'd28, 5'd11);
		set_dispatch(0, 6'd13, 5'd11);
		set_dispatch(1, 6'd33, 5'd11);
		set_dispatch(2, 6'd62, 5'd11);
		verify_answer();

		$display("@@@ Test %1d: Dispatch and complete with (dispatch[2:0].ar_idx === cdb[2].ar_idx)", test);
		set_cdb_in(2, 6'd62, 5'd11);
		set_dispatch(0, 6'd13, 5'd11);
		set_dispatch(1, 6'd33, 5'd11);
		set_dispatch(2, 6'd28, 5'd11);
		verify_answer();

		$display("@@@ Test %1d: Complete 3", test);
		set_cdb_in(0, 6'd30, 5'd17);
		set_cdb_in(1, 6'd52, 5'd20);
		set_cdb_in(2, 6'd09, 5'd21);
		verify_answer();

		$display("@@@ Test %1d: Dispatch 3", test);
		set_dispatch(0, 6'd09, 5'd08);
		set_dispatch(1, 6'd30, 5'd02);
		set_dispatch(2, 6'd52, 5'd15);
		verify_answer();

		$display("@@@ Test %1d: Complete 3 when t_idx appears multiple times", test);
		set_cdb_in(0, 6'd09, 5'd08);
		set_cdb_in(1, 6'd52, 5'd15);
		set_cdb_in(2, 6'd30, 5'd02);
		verify_answer();

        $display("@@@ Test %1d: Precise State Handling", test);
        br_recover_enable 	  = 1'b1;
        expected_maptable_out = 0;
		for (int i = 0; i < 32; i++)
			set_recovery({$random}[5:0], {$random}[4:0]);
		expected_maptable_out.done = { `XLEN{1'b1} };
        verify_answer();

        $display("\nENDING MAPTABLE TESTBENCH: SUCCESS!\n");
        $finish;
    end  // initial

	task clear_input;
        br_recover_enable 	 = 0;
        recovery_maptable 	 = 0;
		maptable_cdb_in   	 = 0;
		maptable_dispatch_in = 0;
	endtask

    task set_dispatch_in; 
		input int 						 packet_idx; 
		input [`N_PHYS_REG_BITS-1:0] pr_idx; 
		input [`N_ARCH_REG_BITS-1:0] 	 ar_idx; 
	begin
        maptable_dispatch_in[packet_idx].pr_idx = pr_idx;
        maptable_dispatch_in[packet_idx].ar_idx = ar_idx;
        maptable_dispatch_in[packet_idx].enable = 1'd1;
    end endtask  // task set_dispatch

    task set_dispatch; 
		input int 						 packet_idx; 
		input [`N_PHYS_REG_BITS-1:0] pr_idx; 
		input [`N_ARCH_REG_BITS-1:0] 	 ar_idx; 
	begin
		set_dispatch_in(packet_idx, pr_idx, ar_idx);
		expected_maptable_out.map[ar_idx]  = pr_idx;
		expected_maptable_out.done[ar_idx] = 1'd0;
    end endtask  // task set_dispatch

	task set_cdb_in;
		input int 						 packet_idx;
		input [`N_PHYS_REG_BITS-1:0] pr_idx;
		input [`N_ARCH_REG_BITS-1:0] 	 ar_idx;
	begin
		maptable_cdb_in.t_idx[packet_idx]  = pr_idx;
		expected_maptable_out.done[ar_idx] = 1'b1;
	end endtask  // task set_cdb_in

	task set_recovery;
		input [`N_PHYS_REG_BITS-1:0] pr_idx;
		input [`N_ARCH_REG_BITS-1:0] 	 ar_idx;
	begin
        recovery_maptable.map[ar_idx] 	  = pr_idx;
        expected_maptable_out.map[ar_idx] = pr_idx;
	end endtask  // task set_recovery

    task verify_answer;
        @(negedge clock);
		if (~correct) begin
        	$display("@@@ Failed Test %1d!", test);
			$display("@@@ Incorrect at time %4.0f", $time);

			$display("@@@ Inputs:");

			$display("@@@\treset:%b br_recover_enable:%b", reset, br_recover_enable);

			if (br_recover_enable) begin
                $display("@@@\trecovery_maptable: ar_idx:%2d pr_idx:%2d done:%b",
                         0, recovery_maptable.map[0], recovery_maptable.done[0]);
                for (int i = 1; i < `N_ARCH_REG; i++)
					$display("@@@\t                   ar_idx:%2d pr_idx:%2d done:%b",
							 i, recovery_maptable.map[i], recovery_maptable.done[i]);
			end  // if (br_recover_enable)

            for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                $display("@@@\tmaptable_dispatch_in[%1d]: ar_idx:%d pr_idx:%d enable:%b", i,
                         maptable_dispatch_in[i].ar_idx, maptable_dispatch_in[i].pr_idx,
                         maptable_dispatch_in[i].enable);

            for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                $display("@@@\tmaptable_cdb_in[%1d]: t_idx:%2d", i, maptable_cdb_in.t_idx[i]);

			$display("@@@ Outputs:");
                
			for (int i = 0; i < `N_ARCH_REG; i++) begin
				if ((maptable_out.map[i]  === expected_maptable_out.map[i]) &
					(maptable_out.done[i] === expected_maptable_out.done[i])) 
					$display("@@@\tcorrect maptable_out[%2d]: map:%2d done:%b",
							 i, maptable_out.map[i], maptable_out.done[i]);
				else begin
					$display("@@@\tincorrect maptable_out[%2d]: map:%2d done:%b",
							 i, maptable_out.map[i], maptable_out.done[i]);
					$display("@@@\t                  expected: map:%2d done:%b",
							 expected_maptable_out.map[i], expected_maptable_out.done[i]);
				end  // incorrect maptable_out[i]
			end  // for each maptable entry

            $display("\nENDING MAPTABLE TESTBENCH: ERROR!\n");
			$finish;
		end  // if (~correct)

        $display("@@@ Passed Test %1d!", test);
		clear_input();
        test++;
    endtask  // task verify_answer
endmodule  // maptable_testbench