module icache_testbench;
    logic clock, reset, take_branch;
    logic [3:0]  Imem2proc_response;
    logic [63:0] Imem2proc_data;
    logic [3:0]  Imem2proc_tag;
    logic dcache_request;
    logic  [1:0] choose_address;   
    // from fetch stage
    logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Icache_addr;
    logic [`SUPERSCALAR_WAYS-1:0][63:0] cachemem_data;           // <- cache.rd1_data
    logic [`SUPERSCALAR_WAYS-1:0] cachemem_valid; 
    logic hit_but_stall;
    // to memory
    logic [1:0] proc2Imem_command, expected_proc2Imem_command;
    logic [`XLEN-1:0] proc2Imem_addr, expected_proc2Imem_addr;

    // to fetch stage
    logic [`SUPERSCALAR_WAYS-1:0][31:0] Icache_data_out, expected_Icache_data_out; // value is memory[proc2Icache_addr]
    logic [`SUPERSCALAR_WAYS-1:0] Icache_valid_out, expected_Icache_valid_out;        // when this is high
    
//    logic  [3:0]      current_mem_tag;
    logic  [2:0][4:0] cache_read_index, expected_cache_read_index;     
    logic  [2:0][7:0] cache_read_tag, expected_cache_read_tag;
    logic  [4:0] cache_write_index, expected_cache_write_index;     
    logic  [7:0] cache_write_tag, expected_cache_write_tag;

//    logic [`XLEN-1:0] fetch_addr;

    logic  data_write_enable, expected_data_write_enable;
//    logic  changed_addr;
//    logic  update_mem_tag;
//    logic  miss_outstanding;
//    logic  unanswered_miss, expected_unanswered_miss;
    

    logic correct;
    int test;
    

	icache icache_tb(.clock(clock), .reset(reset), .take_branch(take_branch)
	, .Imem2proc_response(Imem2proc_response), .Imem2proc_data(Imem2proc_data)
	, .Imem2proc_tag(Imem2proc_tag), .dcache_request(dcache_request), .choose_address(choose_address), .proc2Icache_addr(proc2Icache_addr)
	, .cachemem_data(cachemem_data), .cachemem_valid(cachemem_valid), .hit_but_stall(hit_but_stall)
	, .proc2Imem_command(proc2Imem_command), .proc2Imem_addr(proc2Imem_addr)
	, .Icache_data_out(Icache_data_out), .Icache_valid_out(Icache_valid_out)
	, .cache_read_index(cache_read_index), .cache_read_tag(cache_read_tag)
	, .cache_write_index(cache_write_index), .cache_write_tag(cache_write_tag)
	, .data_write_enable(data_write_enable));

        
        assign correct = (Icache_data_out === expected_Icache_data_out) && (Icache_valid_out === expected_Icache_valid_out) && (data_write_enable === expected_data_write_enable) && (proc2Imem_command === expected_proc2Imem_command) && (proc2Imem_addr === expected_proc2Imem_addr) && (cache_read_index === expected_cache_read_index) && (cache_read_tag === expected_cache_read_tag) && (cache_write_index === expected_cache_write_index) && (cache_write_tag === expected_cache_write_tag);

	always begin 
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock; 
	end 

    	initial begin
        $dumpvars;

        $display("INITIALIZING ICACHE STAGE TESTBENCH");
		clock = 0; 
		reset = 1;
		take_branch = 0;
		dcache_request = 1;
   		Imem2proc_response = 0;
    		Imem2proc_data = 0;
    		Imem2proc_tag = 0;
		choose_address = 0;
		
		proc2Icache_addr = 0;
		cachemem_data = 0;
		cachemem_valid = 0;
		hit_but_stall = 0;
		expected_proc2Imem_command = 0;
		expected_proc2Imem_addr = 0;
		expected_Icache_data_out[0] = 0;
		expected_Icache_data_out[1] = 0;
		expected_Icache_data_out[2] = 0;
		expected_Icache_valid_out[0] = 0;
		expected_Icache_valid_out[1] = 0;
		expected_Icache_valid_out[2] = 0;
		expected_cache_read_index[0] = 0;
		expected_cache_read_index[1] = 0;
		expected_cache_read_index[2] = 0;
		expected_cache_read_tag[0] = 0;
		expected_cache_read_tag[1] = 0;
		expected_cache_read_tag[2] = 0;
		expected_data_write_enable = 0;
		expected_cache_write_index = 0;
		expected_cache_write_tag = 0;
		verify_answer();

	//$display("@@@ Test 0: Reset the retire");
                

	$display("@@@ Test %1d: 3 instructions change address", test);
		reset = 0;
		
		take_branch = 0;
   		Imem2proc_response = 4'd4;
    		Imem2proc_data ={ 32'd15, 32'd16 };
    		Imem2proc_tag = 4'd4;
 		dcache_request = 0;
		choose_address = 2'd1;
		proc2Icache_addr[0] = 32'd32;
		proc2Icache_addr[1] = 32'd44;
		proc2Icache_addr[2] = 32'd40;

		cachemem_data[0] = { 32'd15, 32'd16 };
		cachemem_data[1] = { 32'd25, 32'd26 };;
		cachemem_data[2] = { 32'd35, 32'd36 };
		cachemem_valid[0] = 1;
		cachemem_valid[1] = 1;
		cachemem_valid[2] = 1;
		hit_but_stall = 0;

		expected_proc2Imem_command = 1;
		expected_proc2Imem_addr = 32'd40;
		expected_Icache_data_out[0] = 32'd16;
		expected_Icache_data_out[1] = 32'd25;
		expected_Icache_data_out[2] = 32'd36;
		expected_Icache_valid_out[0] = 1;
		expected_Icache_valid_out[1] = 1;
		expected_Icache_valid_out[2] = 1;
		expected_cache_read_index[0] = 4;
		expected_cache_read_index[1] = 5;
		expected_cache_read_index[2] = 5;
		expected_cache_read_tag[0] = 0;
		expected_cache_read_tag[1] = 0;
		expected_cache_read_tag[2] = 0;
		expected_data_write_enable = 1;
		expected_cache_write_index = 5;
		expected_cache_write_tag = 0;
        	verify_answer();



	$display("@@@ Test %1d: take branch", test);
		reset = 0;
		
		take_branch = 1;
   		Imem2proc_response = 4'd6;
    		Imem2proc_data = { 32'd25, 32'd26 };
    		Imem2proc_tag = 4'd6;
		dcache_request = 0;
		choose_address = 2'd2;
		proc2Icache_addr[0] = 32'd88;
		proc2Icache_addr[1] = 32'd92;
		proc2Icache_addr[2] = 32'd96;
		
		cachemem_data[0] = { 32'd15, 32'd16 };
		cachemem_data[1] = { 32'd25, 32'd26 };
		cachemem_data[2] = { 32'd35, 32'd36 };
		cachemem_valid[0] = 1;
		cachemem_valid[1] = 1;
		cachemem_valid[2] = 1;
		hit_but_stall = 0;
        	
		expected_proc2Imem_command = 1;
		expected_proc2Imem_addr = 32'd96;
		expected_Icache_data_out[0] = 32'd16;
		expected_Icache_data_out[1] = 32'd25;
		expected_Icache_data_out[2] = 32'd36;
		expected_Icache_valid_out[0] = 1;
		expected_Icache_valid_out[1] = 1;
		expected_Icache_valid_out[2] = 1;
		expected_cache_read_index[0] = 11;
		expected_cache_read_index[1] = 11;
		expected_cache_read_index[2] = 12;
		expected_cache_read_tag[0] = 0;
		expected_cache_read_tag[1] = 0;
		expected_cache_read_tag[2] = 0;
		expected_data_write_enable = 0;
		expected_cache_write_index = 0;
		expected_cache_write_tag = 0;
		verify_answer();

	$display("@@@ Test %1d: response not equal with tag", test);
		
		
		take_branch = 0;
   		Imem2proc_response = 4'd15;
    		Imem2proc_data = 64'd80;
    		Imem2proc_tag = 4'd16;
		choose_address = 2'd0;
		dcache_request = 0;
		proc2Icache_addr[0] = 32'd100;
		proc2Icache_addr[1] = 32'd110;
		proc2Icache_addr[2] = 32'd120;
		cachemem_data[0] = { 32'd45, 32'd66 };
		cachemem_data[1] = { 32'd55, 32'd76 };
		cachemem_data[2] = { 32'd65, 32'd86 };
		cachemem_valid[0] = 1;
		cachemem_valid[1] = 1;
		cachemem_valid[2] = 1;
		hit_but_stall = 0;
        	
		expected_proc2Imem_command = 1;
		expected_proc2Imem_addr = 32'd96;
		expected_Icache_data_out[0] = 32'd45;
		expected_Icache_data_out[1] = 32'd55;
		expected_Icache_data_out[2] = 32'd86;
		expected_Icache_valid_out[0] = 1;
		expected_Icache_valid_out[1] = 1;
		expected_Icache_valid_out[2] = 1;
		expected_cache_read_index[0] = 12;
		expected_cache_read_index[1] = 13;
		expected_cache_read_index[2] = 15;
		expected_cache_read_tag[0] = 0;
		expected_cache_read_tag[1] = 0;
		expected_cache_read_tag[2] = 0;
		expected_data_write_enable = 0;
		expected_cache_write_index = 0;
		expected_cache_write_tag = 0;
		verify_answer();



	$display("\nENDING ICACHE TESTBENCH: SUCCESS!\n");
        $finish;
    	end // initial

	task verify_answer; begin
        @(negedge clock);
	     if (~correct) begin
		 $display("@@@ Incorrect at time %4.0f", $time);
		 $display("@@@ Inputs:\n\treset:%b", reset);

		 $display("\tproc2Imem_command : %d",proc2Imem_command);
		 //$display("\tcurrent_mem_tag : %d",current_mem_tag);
	
		 $display("\tdata_write_enable : %d",data_write_enable);
		 /*$display("\tchanged_addr : %d",changed_addr);
		 $display("\tupdate_mem_tag : %d",update_mem_tag);
	 	 $display("\tmiss_outstanding : %d",miss_outstanding);
		 $display("\tunanswered_miss: %d",unanswered_miss);*/
		 $display("\tcache_write_index: %d", cache_write_index);
		 $display("\tcache_write_tag: %d", cache_write_tag);
		 //$display("\tfetch_addr: %d", fetch_addr);
	
		 $display("\tproc2Imem_addr: %d", proc2Imem_addr);

            	 // Print retire_packet output
           	 for (int i = 0; i < 3; i = i + 1) begin
		
			$display("\tIcache_data_out[%1d]: %d", i, Icache_data_out[i]);
			$display("\tIcache_valid_out[%1d]: %d", i, Icache_valid_out[i]);
			$display("\tcache_read_index[%1d]: %d", i, cache_read_index[i]);
			$display("\tcache_read_tag[%1d]: %d", i, cache_read_tag[i]);	
           	end

            $display("@@@ Expected outputs:");
		$display("\texpected_proc2Imem_command : %d",expected_proc2Imem_command);
		$display("\texpected_proc2Imem_addr: %d", expected_proc2Imem_addr);
		$display("\texpected_data_write_enable:%d", expected_data_write_enable);	   
		$display("\texpected_write_index: %d", expected_cache_write_index);
		$display("\texpected_write_tag: %d", expected_cache_write_tag);

            // Print expected retire_packet output
            for (int j = 0; j < 3; j = j + 1) begin 
		$display("\texpected_Icache_data_out[%1d]:%d", j, expected_Icache_data_out[j]);	   
		$display("\texpected_Icache_valid_out[%1d]:%d", j, expected_Icache_valid_out[j]);
		$display("\texpected_current_index[%1d]: %d", j, expected_cache_read_index[j]);
		$display("\texpected_current_tag[%1d]: %d", j, expected_cache_read_tag[j]);
		
            end

            $display("ENDING ICACHE TESTBENCH: ERROR!");
	    $finish;
            end

            $display("@@@ Passed Test!");
       test = test + 1;
       
       end endtask  // verify_answer

endmodule
