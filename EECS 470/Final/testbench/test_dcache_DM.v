`timescale 1ns/100ps
parameter CLOCK_PERIOD = 10;

module testbench;
		//Internal Wires
		//Module Wires
		logic clock;
		logic reset;
		logic enable;

		logic [3:0]     mem2Dcache_response;
		logic [63:0]    mem2Dcache_data;
		logic [3:0]     mem2Dcache_tag;
		logic [`XLEN-1:0]   proc2Dcache_addr;
		MEM_SIZE      proc2Dcache_size;
		logic [1:0]         proc2Dcache_command; 
		logic [`XLEN-1:0]   proc2Dcache_data;
		logic               proc2Dcache_valid;
		
		logic [1:0]          Dcache2mem_command;
		logic [`XLEN-1:0]    Dcache2mem_addr;
		logic [63:0]         Dcache2mem_data;
		logic [63:0]     Dcache_data_out;
		logic            Dcache_valid_out;    
		logic [`XLEN-1:0]   Dcache_addr_evicted_VC;
		logic [63:0]	    Dcache_data_evicted_VC;
		logic               Dcache_evicted_valid_VC;
		logic Dcache_needs_memory;

		DCACHE_DM [`LINES_DM-1:0] testbench_dcache_dm;

		logic [`TAG_SIZE_DM-1:0] _current_dcache_tag, _last_dcache_tag;
        logic [`LINE_SIZE_DM-1:0] _current_dcache_line, _last_dcache_line;
        logic [`BLOCK_OFFSET_BITS_DM-1:0] _current_block_offset;
		logic [3:0] _saved_memTag;
		logic _miss_outstanding;

    dcache_DM DUT (
        .clock,
        .reset,
		.enable,
		.mem2Dcache_response,
		.mem2Dcache_data,
		.mem2Dcache_tag,
		.proc2Dcache_addr,
		.proc2Dcache_size,
		.proc2Dcache_command,
		.proc2Dcache_data,
		.proc2Dcache_valid,

		.Dcache2mem_command,
		.Dcache2mem_addr,
		.Dcache2mem_data,
		.Dcache_data_out,
		.Dcache_valid_out,
		.Dcache_addr_evicted_VC,
		.Dcache_data_evicted_VC,
		.Dcache_evicted_valid_VC,
		.Dcache_needs_memory,
		
		.testbench_dcache_dm,

		._current_dcache_tag,
		._last_dcache_tag,
		._current_dcache_line,
		._last_dcache_line,
		._current_block_offset,
		._saved_memTag,
		._miss_outstanding
    );

	
	// Instantiate the Data Memory
	mem memory (
		// Inputs
		.clk               (clock),
		.proc2mem_command  (Dcache2mem_command),
		.proc2mem_addr     (Dcache2mem_addr), // Keep this as a multiple of 8
		.proc2mem_data     (Dcache2mem_data),
`ifndef CACHE_MODE
		.proc2mem_size     (DOUBLE),
`endif

		// Outputs
		.mem2proc_response (mem2Dcache_response),
		.mem2proc_data     (mem2Dcache_data),
		.mem2proc_tag      (mem2Dcache_tag)
	);
	

	always begin 
		#(CLOCK_PERIOD/2); //clock "interval" ... AKA 1/2 the period
		clock=~clock; 
	end 

    function check_combinational_output;
		$display("-------------dcache comb----------------");
		//$display("mem2Dcache_response=%d,  mem2Dcache_data=%x, mem2Dcache_tag=%x",mem2Dcache_response, mem2Dcache_data, mem2Dcache_tag);
		//$display("proc2Dcache_addr=%x,  proc2Dcache_size=%d, proc2Dcache_command=%d",proc2Dcache_addr, proc2Dcache_command, mem2Dcache_tag);
		$display("Dcache2mem_command=%d,  Dcache2mem_addr=%x, Dcache2mem_data=%x",Dcache2mem_command, Dcache2mem_addr, Dcache2mem_data);
		$display("Dcache_data_out=%x,  Dcache_valid_out=%x",Dcache_data_out, Dcache_valid_out);
		$display("Dcache_needs_memory=%d | _saved_memTag=%d | _miss_outstanding=%d",Dcache_needs_memory,_saved_memTag, _miss_outstanding);
		$display("Dcache_evicted_valid_VC=%d,  Dcache_addr_evicted_VC=%x, Dcache_data_evicted_VC=%x",Dcache_evicted_valid_VC, Dcache_addr_evicted_VC, Dcache_data_evicted_VC);
		
		$display("mem2Dcache_response=%d,  mem2Dcache_data=%x, mem2Dcache_tag=%d",mem2Dcache_response, mem2Dcache_data, mem2Dcache_tag);
		$display("_current_dcache_tag=%d ; _last_dcache_tag=%d ; _current_dcache_line=%d ; _last_dcache_line=%d ; _current_block_offset=%d",_current_dcache_tag,_last_dcache_tag,_current_dcache_line,_last_dcache_line,_current_block_offset);
	
		
        $display("Unified_memory[%d]=%d  %x", Dcache2mem_addr,memory.unified_memory[Dcache2mem_addr[`XLEN-1:3]],memory.unified_memory[Dcache2mem_addr[`XLEN-1:3]]);

	endfunction
    
    function check_sequential_output;
		$display("-------------dcache seq----------------");
        $display("line | Tag |   data   | dirty? | Valid? |");
        for(int i=0; i<`LINES_DM; i=i+1) 
            $display("%d 	|	 %x   |	%x   |     %b     |     %b     |", i , testbench_dcache_dm[i].tag, testbench_dcache_dm[i].data, testbench_dcache_dm[i].dirty, testbench_dcache_dm[i].valid);
	endfunction
	
	initial begin 

		$display("STARTING TESTBENCH!\n");
		// /memory.unified_memory[0] = 5000;
		clock = 0;
		reset = 1;
		enable = 1;
		
		proc2Dcache_addr = 0;
		proc2Dcache_size = DOUBLE;
		proc2Dcache_command = 0;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 0;
		@(negedge clock);
        @(negedge clock); 
		reset = 0;
		
		$readmemh("program.mem", memory.unified_memory);
		//check_SH_correct();
		//check_combinational_output();
		@(posedge clock); #3;
		@(posedge clock); #3;
		//check_combinational_output();
		//check_sequential_output();
		
		$display("-------------------------CASE 1.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		#2; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 2.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 3.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 4.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 5.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 6.0------------------------------");
		proc2Dcache_addr = 4000;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 50;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 7.0------------------------------");
		proc2Dcache_addr = 00;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 40;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 8.0------------------------------");
		proc2Dcache_addr = 00;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 40;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 9.0------------------------------");
		proc2Dcache_addr = 00;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 40;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 10.0------------------------------");
		proc2Dcache_addr = 00;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 40;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();


		$display("-------------------------CASE 11.0------------------------------");
		proc2Dcache_addr = 00;
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 40;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 12.0------------------------------");
		proc2Dcache_addr = 00; //512
		proc2Dcache_size = BYTE;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 30;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();
/*
		$display("-------------------------CASE 13------------------------------");
		proc2Dcache_addr = 512; 
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 14------------------------------");
		proc2Dcache_addr = 512; 
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 15------------------------------");
		proc2Dcache_addr = 512; 
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();


		$display("-------------------------CASE 16------------------------------");
		proc2Dcache_addr = 512; 
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 17------------------------------");
		proc2Dcache_addr = 512; 
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

*/
		$display("-------------------------CASE 13.0------------------------------"); //store miss and dirty
		proc2Dcache_addr = 512;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 70;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();


		$display("-------------------------CASE 14.0------------------------------"); //store miss and dirty
		proc2Dcache_addr = 512;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 70;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();


		$display("-------------------------CASE 15.0------------------------------"); //store miss and dirty
		proc2Dcache_addr = 512;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 70;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();
		
		$display("-------------------------CASE 16.0------------------------------"); //store miss and dirty
		proc2Dcache_addr = 512;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 70;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();
		
		$display("-------------------------CASE 16.0------------------------------"); 
		proc2Dcache_addr = 512;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_STORE;
		proc2Dcache_data = 70;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 17.0------------------------------"); //load miss and dirty
		proc2Dcache_addr = 00;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 18.0------------------------------"); //load miss and dirty
		proc2Dcache_addr = 00;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 19.0------------------------------"); //load miss and dirty
		proc2Dcache_addr = 00;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

		$display("-------------------------CASE 20.0------------------------------"); //load miss and dirty
		proc2Dcache_addr = 00;
		proc2Dcache_size = HALF;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();


		$display("-------------------------CASE 21.0------------------------------"); //load miss and dirty
		proc2Dcache_addr = 00;
		proc2Dcache_size = DOUBLE;
		proc2Dcache_command = BUS_LOAD;
		proc2Dcache_data = 0;
		proc2Dcache_valid = 1;
		@(negedge clock);#3; check_combinational_output();
		@(posedge clock); #3;
		check_sequential_output();

        @(negedge clock);
        @(negedge clock);
		//SUCCESSFULLY END TESTBENCH
		$display("ENDING TESTBENCH");
		$finish;
		
	end


endmodule 
