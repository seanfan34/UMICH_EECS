//verdi_cov: Score:62.56; Line: 84.38; Toggle: 3.31; Branch: 100
// minimun slack: 5.67 with clock = 10
//TESTBENCH FOR PRF
//Class:    EECS470
//Specific:  Project 4
//Description:

module prf_testbench;
	logic clock, reset;
	FU_PRF_PACKET [6:0] prf_fu_in;
    logic [63:0][31:0] physical_register, expected_physical_register;
	int a;
	logic [5:0]test_idx;
	logic [31:0] test_value;

    logic correct;
    int test;

	prf PRF(.clock(clock), .reset(reset),
    .prf_fu_in(prf_fu_in),
    .physical_register(physical_register));


	assign correct = (physical_register == expected_physical_register);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);

        $display("INITIALIZING PRF TESTBENCH");
		test = 0; clock = 0; reset = 1;
        prf_fu_in[6:0] = 0;
		expected_physical_register = 0;

		$display("@@@ Test %d: Reset the PRF", test);
		verify_answer();

		reset = 0;

		$display("@@@ Test %d: Single input from execute", test);

		a=1;
		for (int i=0; i<7; i++)begin
			prf_fu_in[i].idx = a;
			prf_fu_in[i].value = a;
			expected_physical_register[a] = a;
			a = a+1;
			verify_answer();
			prf_fu_in[i].idx = 0;
		end

		$display("@@@ Test %d: write to reg0", test);
		prf_fu_in[1].idx = 0;
		prf_fu_in[1].value = 100;
		verify_answer();

		$display("@@@ Test %d: cover old value", test);
		for (int i=0; i<7; i++)begin
			prf_fu_in[i].idx = a;
			prf_fu_in[i].value = a;
			expected_physical_register[a] = a;
			a = a+1;
			verify_answer();
			prf_fu_in[i].idx = 0;
		end

		$display("@@@ Test %d: Multi input with random", test);
		for (int i=0; i<7; i++)begin
			test_idx = $random%64;
			test_value = $random;
			prf_fu_in[i].idx = test_idx;
			prf_fu_in[i].value = test_value;
			expected_physical_register[test_idx] = test_value;
		end
		verify_answer();

		$display("\nENDING ROB TESTBENCH: SUCCESS!\n");
        $finish;
		
	end  // initial

    task verify_answer; begin
        @(negedge clock);
		if (!correct) begin
			$display("@@@ Incorrect at time %4.0f", $time);
			$display("@@@ Inputs:\n\treset:%b", reset);

            // Print prf_fu_in input
            for (int i = 0; i < 3; i = i + 1)
                $display("\tprf_fu_in[%d]: idx:%d value:%b", i,
                    prf_fu_in[i].idx, prf_fu_in[i].value);

			$display("@@@ Outputs:");
			$display("\tphysical_register:%h",physical_register);

			$display("@@@ Expected outputs:");
			$display("\tphysical_register:%h",expected_physical_register);

            $display("ENDING PRF TESTBENCH: ERROR!");
			$finish;
		end

        $display("@@@ Passed Test %d!", test);
        test = test + 1;
    end endtask  // verify_answer
endmodule