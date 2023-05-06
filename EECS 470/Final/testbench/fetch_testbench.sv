module fetch_testbench;
    logic clock, reset, correct;
    logic branch_flush_en;
    logic [31:0] target_pc;
    logic [2:0][63:0] Imem2proc_data;
	DISPATCH_FETCH_PACKET fetch_dispatch_in;

    logic [2:0][31:0] proc2Imem_addr, expected_proc2Imem_addr;
    FETCH_DISPATCH_PACKET [2:0] fetch_dispatch_out, expected_fetch_dispatch_out;

    fetch fetch_tb(
		.clock(clock), 
		.reset(reset), 
		.branch_flush_en(branch_flush_en), 
		.target_pc(target_pc), 
		.Imem2proc_data(Imem2proc_data), 
		.fetch_dispatch_in(fetch_dispatch_in),

		.proc2Imem_addr(proc2Imem_addr), 
		.fetch_dispatch_out(fetch_dispatch_out)
	);
        
   	assign correct = (fetch_dispatch_out === expected_fetch_dispatch_out);

    int test;

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    initial begin
        $dumpvars;

        $display("INITIALIZING FETCH STAGE TESTBENCH");
		test = 0;
		clock = 0; 
		reset = 1;
		fetch_dispatch_in = 0;
        Imem2proc_data = 0;
		branch_flush_en = 0;
		target_pc = 0;
		branch_flush_en = 0;
		target_pc = 0;
		
		$display("@@@ Test 0: Reset fetch stage");
		expected_proc2Imem_addr[0] = 64'd0;
		expected_proc2Imem_addr[1] = 64'd0;
		expected_proc2Imem_addr[2] = 64'd8;
	    expected_fetch_dispatch_out[0].valid = 1'b1;	
		expected_fetch_dispatch_out[1].valid = 1'b1;	
		expected_fetch_dispatch_out[2].valid = 1'b1;		
	    expected_fetch_dispatch_out[0].inst = 32'd0;	
		expected_fetch_dispatch_out[1].inst = 32'd0;	
		expected_fetch_dispatch_out[2].inst = 32'd0;	
		expected_fetch_dispatch_out[0].NPC = 32'd4;
		expected_fetch_dispatch_out[1].NPC = 32'd8;
		expected_fetch_dispatch_out[2].NPC = 32'd12;
        expected_fetch_dispatch_out[0].PC = 32'd0;
		expected_fetch_dispatch_out[1].PC = 32'd4;
		expected_fetch_dispatch_out[2].PC = 32'd8;
        verify_answer();
                
		$display("@@@ Test %1d: No dispatch stalls, first_stall_idx = 0", test);
		reset = 0;
		target_pc = 32'd76;
		target_pc = 32'd20;
		Imem2proc_data[0] = { 32'hc, 32'h1 };
		Imem2proc_data[1] = { 32'hc, 32'h1 };
		Imem2proc_data[2] = { 32'he, 32'h3 };
		expected_proc2Imem_addr[0] = 64'd8;
		expected_proc2Imem_addr[1] = 64'd16;
		expected_proc2Imem_addr[2] = 64'd16;
		expected_fetch_dispatch_out[0].inst = 32'hc;	
		expected_fetch_dispatch_out[1].inst = 32'h1;	
		expected_fetch_dispatch_out[2].inst = 32'he;	
		increment_expected_pcs(12);
        	
		verify_answer();
                
		$display("@@@ Test %1d: No dispatch stalls, first_stall_idx = 1", test);
		fetch_dispatch_in.first_stall_idx = 1;
		expected_proc2Imem_addr[0] = 64'd24;
		expected_proc2Imem_addr[1] = 64'd24;
		expected_proc2Imem_addr[2] = 64'd32;
		expected_fetch_dispatch_out[0].inst = 32'h1;	
		expected_fetch_dispatch_out[1].inst = 32'hc;	
		expected_fetch_dispatch_out[2].inst = 32'h3;	
		increment_expected_pcs(12);
		verify_answer();
                
		$display("@@@ Test %1d: No dispatch stalls, first_stall_idx = 2", test);
		fetch_dispatch_in.first_stall_idx = 2;
		expected_proc2Imem_addr[0] = 64'd32;
		expected_proc2Imem_addr[1] = 64'd40;
		expected_proc2Imem_addr[2] = 64'd40;
		expected_fetch_dispatch_out[0].inst = 32'hc;	
		expected_fetch_dispatch_out[1].inst = 32'h1;	
		expected_fetch_dispatch_out[2].inst = 32'he;	
		increment_expected_pcs(12);
		verify_answer();

		$display("@@@ Test %1d: 1 dispatch stall", test);
		fetch_dispatch_in.enable = 1;
		fetch_dispatch_in.first_stall_idx = 2;
		Imem2proc_data[0] = { 32'ha0, 32'h20 };
		Imem2proc_data[1] = { 32'hb0, 32'h20 };
		Imem2proc_data[2] = { 32'h01, 32'h00 };
		expected_proc2Imem_addr[0] = 64'd40;
		expected_proc2Imem_addr[1] = 64'd48;
		expected_proc2Imem_addr[2] = 64'd48;	
		expected_fetch_dispatch_out[0].inst = 32'ha0;	
		expected_fetch_dispatch_out[1].inst = 32'h20;	
		expected_fetch_dispatch_out[2].inst = 32'h01;
		increment_expected_pcs(8);
        verify_answer();

		$display("@@@ Test %1d: 2 dispatch stalls", test);
		fetch_dispatch_in.first_stall_idx = 1;
		expected_fetch_dispatch_out[0].inst = 32'h20;	
		expected_fetch_dispatch_out[1].inst = 32'hb0;	
		expected_fetch_dispatch_out[2].inst = 32'h00;
		expected_proc2Imem_addr[1] = 64'd48;
		expected_proc2Imem_addr[2] = 64'd56;	
		increment_expected_pcs(4);
       	verify_answer();

		$display("@@@ Test %1d: 3 dispatch stalls", test);
		fetch_dispatch_in.first_stall_idx = 0;
       	verify_answer();

		$display("@@@ Test %1d: branch flush", test);
		branch_flush_en = 1;
		fetch_dispatch_in.enable = 0;
		target_pc = 32'd20;
		Imem2proc_data[0] = { 32'ha0, 32'h20 };
		Imem2proc_data[1] = { 32'hb0, 32'h23 };
		Imem2proc_data[2] = { 32'h04, 32'h80 };
		expected_proc2Imem_addr[0] = 64'd16;
		expected_proc2Imem_addr[1] = 64'd24;
		expected_proc2Imem_addr[2] = 64'd24;	
		expected_fetch_dispatch_out[0].valid = 1'b0;
		expected_fetch_dispatch_out[1].valid = 1'b0;
		expected_fetch_dispatch_out[2].valid = 1'b0;
	    expected_fetch_dispatch_out[0].inst = 32'ha0;	
		expected_fetch_dispatch_out[1].inst = 32'h23;	
		expected_fetch_dispatch_out[2].inst = 32'h04;	
		expected_fetch_dispatch_out[0].NPC = 32'd24;
		expected_fetch_dispatch_out[1].NPC = 32'd28;
		expected_fetch_dispatch_out[2].NPC = 32'd32;
        expected_fetch_dispatch_out[0].PC = 32'd20;
		expected_fetch_dispatch_out[1].PC = 32'd24;
		expected_fetch_dispatch_out[2].PC = 32'd28;
        verify_answer();

		$display("@@@ Test %1d: branch flush with stalls", test);
		fetch_dispatch_in.enable = 1;
		fetch_dispatch_in.first_stall_idx = 1;
		branch_flush_en = 1;
        verify_answer();

		$display("@@@ Test %1d: TAKE BRANCH 0", test);
		branch_flush_en = 0;
		fetch_dispatch_in.enable = 1;
		fetch_dispatch_in.first_stall_idx = 1;	
		expected_proc2Imem_addr[0] = 64'd24;
		expected_proc2Imem_addr[1] = 64'd24;
		expected_proc2Imem_addr[2] = 64'd32;	
		expected_fetch_dispatch_out[0].valid = 1'b1;
		expected_fetch_dispatch_out[1].valid = 1'b1;
		expected_fetch_dispatch_out[2].valid = 1'b1;
	    expected_fetch_dispatch_out[0].inst = 32'h20;	
		expected_fetch_dispatch_out[1].inst = 32'hb0;	
		expected_fetch_dispatch_out[2].inst = 32'h80;	
		increment_expected_pcs(4);
        verify_answer();

		$display("@@@ Test %1d: TAKE BRANCH 0", test);
		expected_proc2Imem_addr[0] = 64'd24;
		expected_proc2Imem_addr[1] = 64'd32;
		expected_proc2Imem_addr[2] = 64'd32;	
	    expected_fetch_dispatch_out[0].inst = 32'ha0;	
		expected_fetch_dispatch_out[1].inst = 32'h23;	
		expected_fetch_dispatch_out[2].inst = 32'h04;	
		increment_expected_pcs(4);
        verify_answer();

		$display("@@@ Test %1d: branch_flush_en", test);
		branch_flush_en = 1'b1;
		fetch_dispatch_in.enable = 1'b0;
		target_pc = 32'd0;
		expected_proc2Imem_addr[0] = 64'd0;
		expected_proc2Imem_addr[1] = 64'd0;
		expected_proc2Imem_addr[2] = 64'd8;
	    expected_fetch_dispatch_out[0].valid = 1'b0;	
		expected_fetch_dispatch_out[1].valid = 1'b0;	
		expected_fetch_dispatch_out[2].valid = 1'b0;		
	    expected_fetch_dispatch_out[0].inst = 32'h20;	
		expected_fetch_dispatch_out[1].inst = 32'hb0;	
		expected_fetch_dispatch_out[2].inst = 32'h80;	
		expected_fetch_dispatch_out[0].NPC = 32'd4;
		expected_fetch_dispatch_out[1].NPC = 32'd8;
		expected_fetch_dispatch_out[2].NPC = 32'd12;
        expected_fetch_dispatch_out[0].PC = 32'd0;
		expected_fetch_dispatch_out[1].PC = 32'd4;
		expected_fetch_dispatch_out[2].PC = 32'd8;
        verify_answer();

		$display("@@@ Test %1d: TAKE BRANCH 1", test);
		branch_flush_en = 0;
		Imem2proc_data[0] = { 32'hc, 32'h1 };
		Imem2proc_data[1] = { 32'hc, 32'h1 };
		Imem2proc_data[2] = { 32'he, 32'h3 };
		expected_proc2Imem_addr[0] = 64'd8;
		expected_proc2Imem_addr[1] = 64'd16;
		expected_proc2Imem_addr[2] = 64'd16;
	    expected_fetch_dispatch_out[0].valid = 1'b1;	
		expected_fetch_dispatch_out[1].valid = 1'b1;	
		expected_fetch_dispatch_out[2].valid = 1'b1;	
		expected_fetch_dispatch_out[0].inst = 32'hc;	
		expected_fetch_dispatch_out[1].inst = 32'h1;	
		expected_fetch_dispatch_out[2].inst = 32'he;	
		increment_expected_pcs(12);
        verify_answer();

		$display("\nENDING FETCH TESTBENCH: SUCCESS!\n");
        $finish;
    end // initial

	task increment_expected_pcs; input int increment; begin
		for (int i = 0; i < 3; i++) begin
        	expected_fetch_dispatch_out[i].PC += increment;
			expected_fetch_dispatch_out[i].NPC += increment;
		end
	end endtask

	task verify_answer;
        @(negedge clock);
	    if (~correct) begin
		 	$display("@@@ Incorrect at time %4.0f", $time);

		 	$display("@@@ Inputs:");
		 	$display("@@@ \treset:%b branch_flush_en:%b target_pc:%2d",
				reset, branch_flush_en, branch_flush_en, target_pc);
		 	$display("@@@ \tfetch_dispatch_in: first_stall_idx:%d enable:%d",
				fetch_dispatch_in.first_stall_idx, fetch_dispatch_in.enable);
			for (int i = 0; i < 3; i++)
		 		$display("@@@ \tImem2proc_data[%1d]:%h", i, Imem2proc_data[i]);

		 	$display("@@@ Outputs:");
			for (int i = 0; i < 3; i++) begin
				if (proc2Imem_addr[i] === expected_proc2Imem_addr[i])
					$display("\tcorrect proc2Imem_addr[%1d]:%d", i, proc2Imem_addr[i]);
				else begin
					$display("\tincorrect proc2Imem_addr[%1d]:%d", i, proc2Imem_addr[i]);
					$display("\t\texpected:%d", expected_proc2Imem_addr[i]);
				end
				if (fetch_dispatch_out[i] === expected_fetch_dispatch_out[i])
					$display("\tcorrect fetch_dispatch_out[%1d]: inst:%h PC:%2d NPC:%2d valid:%b", 
						i, fetch_dispatch_out[i].inst, fetch_dispatch_out[i].PC, 
						fetch_dispatch_out[i].NPC, fetch_dispatch_out[i].valid);
				else begin
					$display("\tincorrect fetch_dispatch_out[%1d]:", i);
					if (fetch_dispatch_out[i].inst === expected_fetch_dispatch_out[i].inst)
						$display("\t\tcorrect inst:%h", fetch_dispatch_out[i].inst);
					else begin
						$display("\t\tincorrect inst:%h", fetch_dispatch_out[i].inst);
						$display("\t\t\texpected:%h", expected_fetch_dispatch_out[i].inst);
					end
					if (fetch_dispatch_out[i].PC === expected_fetch_dispatch_out[i].PC)
						$display("\t\tcorrect PC:%2d", fetch_dispatch_out[i].PC);
					else begin
						$display("\t\tincorrect PC:%2d", fetch_dispatch_out[i].PC);
						$display("\t\t\texpected:%2d", expected_fetch_dispatch_out[i].PC);
					end
					if (fetch_dispatch_out[i].NPC === expected_fetch_dispatch_out[i].NPC)
						$display("\t\tcorrect NPC:%2d", fetch_dispatch_out[i].NPC);
					else begin
						$display("\t\tincorrect NPC:%2d", fetch_dispatch_out[i].NPC);
						$display("\t\t\texpected:%2d", expected_fetch_dispatch_out[i].NPC);
					end
					if (fetch_dispatch_out[i].valid === expected_fetch_dispatch_out[i].valid)
						$display("\t\tcorrect valid:%b", fetch_dispatch_out[i].valid);
					else begin
						$display("\t\tincorrect valid:%b", fetch_dispatch_out[i].valid);
						$display("\t\t\texpected:%b", expected_fetch_dispatch_out[i].valid);
					end
				end
			end

            $display("ENDING FETCH TESTBENCH: ERROR!");
	    	$finish;
        end
	   
        $display("@@@ Passed Test %1d!", test);
       	test++;
    endtask  // verify_answer
endmodule  // fetch_testbench