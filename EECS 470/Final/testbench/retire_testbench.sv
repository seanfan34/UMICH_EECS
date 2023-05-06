module retire_testbench;
    logic                                               clock, reset;
    ROB_PACKET [`SUPERSCALAR_WAYS-1:0]                   retire_rob_in;

    RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0]               retire_out, expected_retire_out;
    RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]      retire_freelist_out, expected_retire_freelist_out;

    logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0]   arch_maptable;
    MAPTABLE_PACKET                                     recovery_maptable, expected_recovery_maptable;

    logic                                               br_recover_enable, expected_br_recover_enable;
    logic   [`XLEN-1:0]                                 target_pc, expected_target_pc;
    logic                                               correct;
    int                                                 test;
    

	retire retire_tb(
        .retire_rob_in(retire_rob_in),
        .retire_out(retire_out),
        .retire_freelist_out(retire_freelist_out),
        .arch_maptable(arch_maptable),
        .recovery_maptable(recovery_maptable),
        .br_recover_enable(br_recover_enable),
        .target_pc(target_pc)
    );


    assign correct = ( retire_out === expected_retire_out &
                       br_recover_enable === expected_br_recover_enable &
                        recovery_maptable === expected_recovery_maptable
        );



	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    	initial begin
        $dumpvars;

        $display("INITIALIZING RETIRE STAGE TESTBENCH");
		clock = 0; 
		reset = 1;
        retire_rob_in = 0;
        arch_maptable = 0;
        expected_recovery_maptable = 0;


	    $display("@@@ Test 0: Reset the retire");
                

	    $display("@@@ Test %1d: Retire 3 instructions", test);
		reset = 0;

        //Set up input
        //   idx     t_idx, told_idx, ar_idx, complete, precise_state_enable
        rob_retire(0, 6'd5, 6'd7,5'd1,1'b1, 1'b0 );
        rob_retire(1, 6'd6, 6'd8,5'd2,1'b1, 1'b0 );
        rob_retire(2, 6'd7, 6'd9,5'd3,1'b1, 1'b0 );

        //Set up output
        // idx t_idx ar_idx complete
        expected_retire(0, 6'd5,5'd1,1'b1 );
        expected_retire(1, 6'd6,5'd2,1'b1);
        expected_retire(2, 6'd7,5'd3,1'b1 );
        //idx told_idx valid
        expected_retire_freelist(0,6'd7,1'b1);
        expected_retire_freelist(1,6'd8,1'b1);
        expected_retire_freelist(2,6'd9,1'b1);

        expected_recovery_maptable.done = 32'hffff_ffff;
        expected_recovery_maptable.map[1] = 6'd5;
        expected_recovery_maptable.done[1] = 1'b1;
        expected_recovery_maptable.map[2] = 6'd6;
        expected_recovery_maptable.done[2] = 1'b1;
        // expected_recovery_maptable.map[3] = 6'd7;
        // expected_recovery_maptable.done[3] = 1'b1;
        expected_br_recover_enable = 1'b0;

        verify_answer();



	$display("@@@ Test %1d: Retire 2 instructions", test);
        expected_recovery_maptable = 0;
        //Set up input
        //   idx     t_idx, told_idx, ar_idx, complete, precise_state_enable
        rob_retire(0, 6'd13, 6'd16,5'd11,1'b1, 1'b1 );
        rob_retire(1, 6'd14, 6'd17,5'd12,1'b1, 1'b0 );
        rob_retire(2, 6'd15, 6'd18,5'd13,1'b0, 1'b1 );

        arch_maptable[5] = 6'd1;

        //Set up output
        // idx t_idx ar_idx complete
        expected_retire(0, 6'd13,5'd11,1'b1 );
        expected_retire(1, 6'd14,5'd12,1'b1);
        expected_retire(2, 6'd15,5'd13,1'b1);
        //idx told_idx valid
        expected_retire_freelist(0,6'd16,1'b1);
        expected_retire_freelist(1,6'd17,1'b1);
        expected_retire_freelist(2,6'd18,1'b1);

        expected_recovery_maptable.done = 32'hffff_ffff;
        expected_recovery_maptable.map[5] = 6'd1;
        expected_recovery_maptable.map[11] = 6'd13;
        expected_recovery_maptable.done[11] = 1'b1;

        expected_br_recover_enable = 1'b1;
        verify_answer();



    $display("@@@ Test %1d: No Complete ", test);
        expected_recovery_maptable = 0;
        expected_recovery_maptable.done = 32'hffff_ffff;
        //Set up input
        //        idx,t_idx,told_idx,ar_idx, complete, precise_state_enable
        rob_retire(0, 6'd13, 6'd16,5'd11,1'b0, 1'b0 );
        rob_retire(1, 6'd14, 6'd17,5'd12,1'b0, 1'b1 );
        rob_retire(2, 6'd15, 6'd18,5'd13,1'b0, 1'b1 );

        arch_maptable = 0;

        //Set up output
        //              idx t_idx ar_idx complete
        expected_retire(0, 6'd13,5'd11,1'b0 );
        expected_retire(1, 6'd14,5'd12,1'b0);
        expected_retire(2, 6'd15,5'd13,1'b0);
        //                  idx told_idx valid
        expected_retire_freelist(0,6'd16,1'b0);
        expected_retire_freelist(1,6'd17,1'b0);
        expected_retire_freelist(2,6'd18,1'b0);

        expected_br_recover_enable = 1'b0;

        verify_answer();

    $display("@@@ Test %1d: Second Complete Third precise state ", test);
        expected_recovery_maptable = 0;
        expected_recovery_maptable.done = 32'hffff_ffff;
        //Set up input
        //        idx,t_idx,told_idx,ar_idx, complete, precise_state_enable
        rob_retire(0, 6'd13, 6'd16,5'd11,1'b1, 1'b0 );
        rob_retire(1, 6'd14, 6'd17,5'd12,1'b1, 1'b0 );
        rob_retire(2, 6'd15, 6'd18,5'd13,1'b1, 1'b1 );

        arch_maptable = 0;

        //Set up output
        //              idx t_idx ar_idx complete
        expected_retire(0, 6'd13,5'd11,1'b1 );
        expected_retire(1, 6'd14,5'd12,1'b1);
        expected_retire(2, 6'd15,5'd13,1'b1);
        //                  idx told_idx valid
        expected_retire_freelist(0,6'd16,1'b1);
        expected_retire_freelist(1,6'd17,1'b1);
        expected_retire_freelist(2,6'd18,1'b1);

        expected_br_recover_enable = 1'b1;

        expected_recovery_maptable.map[11] = 6'd13;
        expected_recovery_maptable.done[11] = 1'b1;
        expected_recovery_maptable.map[12] = 6'd14;
        expected_recovery_maptable.done[12] = 1'b1;
        expected_recovery_maptable.map[13] = 6'd15;
        expected_recovery_maptable.done[13] = 1'b1;

        verify_answer();

    $display("@@@ Test %1d: Second Complete Second precise state ", test);
            expected_recovery_maptable = 0;
            expected_recovery_maptable.done = 32'hffff_ffff;
            //Set up input
            //        idx,t_idx,told_idx,ar_idx, complete, precise_state_enable
            rob_retire(0, 6'd13, 6'd16,5'd11,1'b1, 1'b0 );
            rob_retire(1, 6'd14, 6'd17,5'd12,1'b1, 1'b1 );
            rob_retire(2, 6'd15, 6'd18,5'd13,1'b1, 1'b1 );

            arch_maptable = 0;

            //Set up output
            //              idx t_idx ar_idx complete
            expected_retire(0, 6'd13,5'd11,1'b1 );
            expected_retire(1, 6'd14,5'd12,1'b1);
            expected_retire(2, 6'd15,5'd13,1'b1);
            //                  idx told_idx valid
            expected_retire_freelist(0,6'd16,1'b1);
            expected_retire_freelist(1,6'd17,1'b1);
            expected_retire_freelist(2,6'd18,1'b1);

            expected_br_recover_enable = 1'b1;

            expected_recovery_maptable.map[11] = 6'd13;
            expected_recovery_maptable.done[11] = 1'b1;
            expected_recovery_maptable.map[12] = 6'd14;
            expected_recovery_maptable.done[12] = 1'b1;
            verify_answer();

    $display("@@@ Test %1d: Second Complete Third not compleete but precise_state ", test);
            expected_recovery_maptable = 0;
            expected_recovery_maptable.done = 32'hffff_ffff;
            //Set up input
            //        idx,t_idx,told_idx,ar_idx, complete, precise_state_enable
            rob_retire(0, 6'd13, 6'd16,5'd11,1'b1, 1'b0 );
            rob_retire(1, 6'd14, 6'd17,5'd12,1'b1, 1'b0 );
            rob_retire(2, 6'd15, 6'd18,5'd13,1'b0, 1'b1 );

            arch_maptable = 0;

            //Set up output
            //              idx t_idx ar_idx complete
            expected_retire(0, 6'd13,5'd11,1'b1 );
            expected_retire(1, 6'd14,5'd12,1'b1);
            expected_retire(2, 6'd15,5'd13,1'b0);
            //                  idx told_idx valid
            expected_retire_freelist(0,6'd16,1'b1);
            expected_retire_freelist(1,6'd17,1'b1);
            expected_retire_freelist(2,6'd18,1'b0);

            expected_br_recover_enable = 1'b0;

            expected_recovery_maptable.map[11] = 6'd13;
            expected_recovery_maptable.done[11] = 1'b1;
            expected_recovery_maptable.map[12] = 6'd14;
            expected_recovery_maptable.done[12] = 1'b1;
            verify_answer();

        /*
        //Hsiang-Yang's code
	$display("@@@ Test %1d: Retire 2 instructions", test);

        retire_rob_in[0].precise_state_enable = 1'b0;
        retire_rob_in[1].precise_state_enable = 1'b0;
        retire_rob_in[2].precise_state_enable = 1'b0;

        retire_rob_in[0].complete = 1'b1;
		retire_rob_in[1].complete = 1'b0;
		retire_rob_in[2].complete = 1'b1;

		retire_rob_in[0].ar_idx = 5'd11;
        retire_rob_in[1].ar_idx = 5'd12;
		retire_rob_in[2].ar_idx = 5'd13;
		            
		retire_rob_in[0].t_idx = 6'd13;
		retire_rob_in[1].t_idx = 6'd14;
        retire_rob_in[2].t_idx = 6'd15;

		retire_rob_in[0].told_idx = 6'd16;
		retire_rob_in[1].told_idx = 6'd17;
		retire_rob_in[2].told_idx = 6'd18;

		 
        expected_retire_out[0].complete = 1'b1;
		expected_retire_out[1].complete = 1'b0;
		expected_retire_out[2].complete = 1'b1;
		expected_retire_freelist_out[0].valid = 1'b1;
		expected_retire_freelist_out[1].valid = 1'b0;
		expected_retire_freelist_out[2].valid = 1'b0;

		expected_retire_out[0].ar_idx = 5'd11;
        expected_retire_out[1].ar_idx = 5'd12;
        expected_retire_out[2].ar_idx = 5'd13;

		expected_retire_out[0].t_idx = 6'd13;
		expected_retire_out[1].t_idx = 6'd14;
		expected_retire_out[2].t_idx = 6'd15;


		expected_retire_freelist_out[0].told_idx = 6'd16;
		expected_retire_freelist_out[1].told_idx = 6'd17;
		expected_retire_freelist_out[2].told_idx = 6'd18;
        expected_br_recover_enable = 1'b0;
        	verify_answer();

       	$display("@@@ Test %1d: Reset the retire again",test);
		reset = 1;
                retire_rob_in = 0;
		
		expected_retire_out[0].complete = 1'b0;
		expected_retire_out[1].complete = 1'b0;
		expected_retire_out[2].complete = 1'b0;
		expected_retire_freelist_out[0].valid = 1'b0;
		expected_retire_freelist_out[1].valid = 1'b0;
		expected_retire_freelist_out[2].valid = 1'b0;

		expected_retire_out[0].ar_idx = 5'd0;
                expected_retire_out[1].ar_idx = 5'd0;
                expected_retire_out[2].ar_idx = 5'd0;

		expected_retire_out[0].t_idx = 6'd0;
		expected_retire_out[1].t_idx = 6'd0;
		expected_retire_out[2].t_idx = 6'd0;


		expected_retire_freelist_out[0].told_idx = 6'd0;
		expected_retire_freelist_out[1].told_idx = 6'd0;
		expected_retire_freelist_out[2].told_idx = 6'd0;

		verify_answer();

	$display("@@@ Test %1d: Retire 2 instructions", test);
                reset = 0;
                retire_rob_in[0].complete = 1'b0;
		retire_rob_in[1].complete = 1'b1;
		retire_rob_in[2].complete = 1'b1;

		retire_rob_in[0].ar_idx = 5'd11;
                retire_rob_in[1].ar_idx = 5'd12;
		retire_rob_in[2].ar_idx = 5'd13;
		            
		retire_rob_in[0].t_idx = 6'd13;
		retire_rob_in[1].t_idx = 6'd14;
                retire_rob_in[2].t_idx = 6'd15;

		retire_rob_in[0].told_idx = 6'd16;
		retire_rob_in[1].told_idx = 6'd17;
		retire_rob_in[2].told_idx = 6'd18;

		 
	        expected_retire_out[0].complete = 1'b0;
		expected_retire_out[1].complete = 1'b1;
		expected_retire_out[2].complete = 1'b1;
		expected_retire_freelist_out[0].valid = 1'b0;
		expected_retire_freelist_out[1].valid = 1'b1;
		expected_retire_freelist_out[2].valid = 1'b1;

		expected_retire_out[0].ar_idx = 5'd11;
                expected_retire_out[1].ar_idx = 5'd12;
                expected_retire_out[2].ar_idx = 5'd13;

		expected_retire_out[0].t_idx = 6'd13;
		expected_retire_out[1].t_idx = 6'd14;
		expected_retire_out[2].t_idx = 6'd15;


		expected_retire_freelist_out[0].told_idx = 6'd16;
		expected_retire_freelist_out[1].told_idx = 6'd17;
		expected_retire_freelist_out[2].told_idx = 6'd18;

        	verify_answer();

	$display("@@@ Test %1d: Retire 1 instruction", test);
               
                retire_rob_in[0].complete = 1'b0;
		retire_rob_in[1].complete = 1'b0;
		retire_rob_in[2].complete = 1'b1;

		retire_rob_in[0].ar_idx = 5'd21;
                retire_rob_in[1].ar_idx = 5'd22;
		retire_rob_in[2].ar_idx = 5'd23;
		            
		retire_rob_in[0].t_idx = 6'd24;
		retire_rob_in[1].t_idx = 6'd25;
                retire_rob_in[2].t_idx = 6'd26;

		retire_rob_in[0].told_idx = 6'd27;
		retire_rob_in[1].told_idx = 6'd28;
		retire_rob_in[2].told_idx = 6'd29;

		 
	        expected_retire_out[0].complete = 1'b0;
		expected_retire_out[1].complete = 1'b0;
		expected_retire_out[2].complete = 1'b1;
		expected_retire_freelist_out[0].valid = 1'b0;
		expected_retire_freelist_out[1].valid = 1'b0;
		expected_retire_freelist_out[2].valid = 1'b1;

		expected_retire_out[0].ar_idx = 5'd21;
                expected_retire_out[1].ar_idx = 5'd22;
                expected_retire_out[2].ar_idx = 5'd23;

		expected_retire_out[0].t_idx = 6'd24;
		expected_retire_out[1].t_idx = 6'd25;
		expected_retire_out[2].t_idx = 6'd26;


		expected_retire_freelist_out[0].told_idx = 6'd27;
		expected_retire_freelist_out[1].told_idx = 6'd28;
		expected_retire_freelist_out[2].told_idx = 6'd29;

        	verify_answer();

	$display("@@@ Test %1d: Retire 0 instruction", test);
               
                retire_rob_in[0].complete = 1'b0;
		retire_rob_in[1].complete = 1'b0;
		retire_rob_in[2].complete = 1'b0;

		retire_rob_in[0].ar_idx = 5'd29;
                retire_rob_in[1].ar_idx = 5'd30;
		retire_rob_in[2].ar_idx = 5'd31;
		            
		retire_rob_in[0].t_idx = 6'd32;
		retire_rob_in[1].t_idx = 6'd33;
                retire_rob_in[2].t_idx = 6'd34;

		retire_rob_in[0].told_idx = 6'd35;
		retire_rob_in[1].told_idx = 6'd36;
		retire_rob_in[2].told_idx = 6'd37;

		 
	        expected_retire_out[0].complete = 1'b0;
		expected_retire_out[1].complete = 1'b0;
		expected_retire_out[2].complete = 1'b0;
		expected_retire_freelist_out[0].valid = 1'b0;
		expected_retire_freelist_out[1].valid = 1'b0;
		expected_retire_freelist_out[2].valid = 1'b0;

		expected_retire_out[0].ar_idx = 5'd29;
                expected_retire_out[1].ar_idx = 5'd30;
                expected_retire_out[2].ar_idx = 5'd31;

		expected_retire_out[0].t_idx = 6'd32;
		expected_retire_out[1].t_idx = 6'd33;
		expected_retire_out[2].t_idx = 6'd34;


		expected_retire_freelist_out[0].told_idx = 6'd35;
		expected_retire_freelist_out[1].told_idx = 6'd36;
		expected_retire_freelist_out[2].told_idx = 6'd37;

        	verify_answer();
        */

	$display("\nENDING RETIRE TESTBENCH: SUCCESS!\n");
        $finish;
    	end // initial

    task rob_retire; input int packet_idx; input [`N_PHYS_REG_BITS-1:0] t_idx;
                    input [`N_PHYS_REG_BITS-1:0] told_idx; input [`N_ARCH_REG_BITS-1:0] ar_idx;
                    input complete; input precise_state_enable; begin

        retire_rob_in[packet_idx].t_idx = t_idx;
        retire_rob_in[packet_idx].told_idx = told_idx;
        retire_rob_in[packet_idx].ar_idx = ar_idx;
        retire_rob_in[packet_idx].complete = complete;
        retire_rob_in[packet_idx].precise_state_enable = precise_state_enable;

    end
    endtask

    task expected_retire; input int packet_idx; input [`N_PHYS_REG_BITS-1:0] t_idx; input [`N_ARCH_REG_BITS-1:0] ar_idx; input complete; begin
        expected_retire_out[packet_idx].t_idx = t_idx;
        expected_retire_out[packet_idx].ar_idx = ar_idx;
        expected_retire_out[packet_idx].complete = complete;
    end endtask

    task expected_retire_freelist; input int packet_idx; input [`N_PHYS_REG_BITS-1:0] told_idx; input valid; begin
        expected_retire_freelist_out[packet_idx].told_idx = told_idx;
        expected_retire_freelist_out[packet_idx].valid = valid;
    end endtask



	task verify_answer; begin
        @(negedge clock);
	     if (~correct) begin
		 $display("@@@ Incorrect at time %4.0f", $time);
         $display("@@@ Inputs:");
             // Print retire_out output
             for (int i = 0; i < 3; i = i + 1) begin
                 $display("\tretire_rob_in[%d]: t_idx:%d told_idx:%d ar_idx:%d complete:%b precise_state_enable:%b", i,
                     retire_rob_in[i].t_idx, retire_rob_in[i].told_idx,
                     retire_rob_in[i].ar_idx, retire_rob_in[i].complete,
                     retire_rob_in[i].precise_state_enable
                     );
            end

        $display("@@@ Outputs:");

            for(int i = 0; i < 3 ; i +=1 ) begin
                $display("\tretire_out[%d]: t_idx:%d ar_idx:%d complete:%b ", i,
                    retire_out[i].t_idx, retire_out[i].ar_idx, retire_out[i].complete
                    );
            end

            for(int i = 0; i < 3 ; i +=1 ) begin
                $display("\tretire_freelist_out[%d]: told_idx:%d valid:%b", i,
                    retire_freelist_out[i].told_idx, retire_freelist_out[i].valid
                     );
            end


            $display("\tbr_recover_enable:%b", br_recover_enable );


        $display("@@@ Expected outputs:");
             for(int i = 0; i < 3 ; i +=1 ) begin
                 $display("\texpected_retire_out[%d]: t_idx:%d ar_idx:%d complete:%b ", i,
                     expected_retire_out[i].t_idx, expected_retire_out[i].ar_idx, expected_retire_out[i].complete
                     );
             end

             for(int i = 0; i < 3 ; i +=1 ) begin
                 $display("\texpected_retire_freelist_out[%d]: told_idx:%d valid:%b", i,
                     expected_retire_freelist_out[i].told_idx, expected_retire_freelist_out[i].valid
                     );
             end

            $display("\texpected_br_recover_enable:%b", expected_br_recover_enable );



         //print diff
        $display("retire_out === expected_retire_out:%b", retire_out === expected_retire_out);
        $display("retire_freelist_out === expected_retire_freelist_out:%b", retire_freelist_out === expected_retire_freelist_out);
        $display("br_recover_enable === expected_br_recover_enable:%b", br_recover_enable === expected_br_recover_enable);
        $display("recovery_maptable === expected_recovery_maptable:%b", recovery_maptable === expected_recovery_maptable);

         for(int i = 0; i < `N_ARCH_REG ; i +=1 ) begin
             $display("\recovery_maptable[%d]: PR:%d done:%b <-> expected_recovery_maptable[%d]: PR:%d done:%b",
                 i,recovery_maptable.map[i], recovery_maptable.done[i],
                 i,expected_recovery_maptable.map[i], expected_recovery_maptable.done[i]
                 );
         end


        $display("ENDING RETIRE TESTBENCH: ERROR!");
	    //$finish;
            end

            $display("@@@ Passed Test!");
       test = test + 1;
       
       end endtask  // verify_answer

endmodule
