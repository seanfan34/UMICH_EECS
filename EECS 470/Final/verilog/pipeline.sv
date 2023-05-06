/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module pipeline (
	input clock,  // System clock
	input reset,  // System reset
	input /*[`SUPERSCALAR_WAYS-1:0]*/[3:0]  					mem2proc_response,  // Tag from memory about current request
	input [63:0] 											mem2proc_data,  	// Data coming back from memory
	input /*[`SUPERSCALAR_WAYS-1:0]*/[3:0]  					mem2proc_tag,       // Tag from memory about current reply
   // input /*[`SUPERSCALAR_WAYS-1:0]*/[63:0]	                    Imem2proc_data,
	
	output logic [1:0]  									proc2mem_command,    // command sent to memory
	output logic [`XLEN-1:0] 								proc2mem_addr,      // Address sent to memory
	output logic [63:0] 									proc2mem_data,      // Data sent to memory

    output logic        									halt,
    output logic [2:0]  									inst_count,


	// testing hooks (these must be exported so we can test
	// the synthesized version) data is tested by looking at
	// the final values in memory
	
	// Outputs from Fetch-Stage 
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		fetch_pc_out,
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		fetch_NPC_out,
	output logic [`SUPERSCALAR_WAYS-1:0][31:0] 				fetch_IR_out,
	output logic [`SUPERSCALAR_WAYS-1:0] 					fetch_valid_inst_out,
	
	// Outputs from Fetch/Dispatch Pipeline Register
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		fetch_dispatch_NPC_out,
	output logic [`SUPERSCALAR_WAYS-1:0][31:0] 				fetch_dispatch_IR_out,
	output logic [`SUPERSCALAR_WAYS-1:0] 					fetch_dispatch_valid_inst_out,
	
	// Outputs from Dispatch-Stage
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		dispatch_NPC_out,
	output logic [`SUPERSCALAR_WAYS-1:0][31:0] 				dispatch_IR_out,
	output logic [`SUPERSCALAR_WAYS-1:0] 					dispatch_valid_inst_out,

	// Outputs from Issue-Stage
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		issue_NPC_out,
	output logic [`SUPERSCALAR_WAYS-1:0][31:0] 				issue_IR_out,
	output logic [`SUPERSCALAR_WAYS-1:0] 					issue_valid_inst_out,
	
	// Outputs from Issue/Execute Pipeline Register
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		issue_execute_NPC_out,
	output logic [`SUPERSCALAR_WAYS-1:0][31:0] 				issue_execute_IR_out,
	output logic [`SUPERSCALAR_WAYS-1:0] 					issue_execute_valid_inst_out,


	// Outputs of FETCH stage
    output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 		proc2Imem_addr,
    output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] 	fetch_packet,
    output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]    fetch_dispatch_packet,

	// Outputs of the DISPATCH stage
    output DISPATCH_FETCH_PACKET 							dispatch_fetch_packet,
    output DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] 		dispatch_rs_packet,
    output DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] 		dispatch_rob_packet,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_packet,
    output DISPATCH_FREELIST_PACKET /*[`SUPERSCALAR_WAYS-1:0]*/ dispatch_freelist_packet,

	// Outputs of the ISSUE stage
    // output RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] 				rs_issue_packet,
    output ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0] 			issue_packet,
    output ISSUE_FU_PACKET [`SUPERSCALAR_WAYS-1:0]          issue_fu_packet,

	// Outputs of the EXECUTE stage
    output FU_RS_PACKET 								    fu_rs_packet,
    output FU_PRF_PACKET [6:0]                              fu_prf_packet,
    output FU_COMPLETE_PACKET [`SUPERSCALAR_WAYS-1:0] 		fu_packet,
    output FU_COMPLETE_PACKET [`SUPERSCALAR_WAYS-1:0]       fu_complete_packet,

	// Outputs of the COMPLETE stage
    output logic 											branch_flush_en,
	output COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] 		complete_rob_packet,
    output COMPLETE_PRF_PACKET [`SUPERSCALAR_WAYS-1:0] 		complete_prf_packet,
    output CDB_PACKET 										cdb_packet,

	// Outputs of the RETIRE stage
	output logic 											br_recover_enable,
    output MAPTABLE_PACKET 									recovery_maptable,
    output RETIRE_PACKET [`SUPERSCALAR_WAYS-1:0] 			retire_packet,
    output RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0] 	retire_freelist_packet,
    output logic   [`XLEN-1:0]                              target_pc, // target_pc pc for precise state
    output logic                                            retire_wfi_halt

    
    `ifdef TEST_MODE
    , output ROB_PACKET [`N_ROB_ENTRIES-1:0]                rob_table_display
	, output ROB_PACKET [`SUPERSCALAR_WAYS-1:0] 			rob_retire_packet_display

	, output ROB_DISPATCH_PACKET 							rob_dispatch_packet_display
	, output DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0]       	rs_table_display
	, output RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] 		rs_issue_packet_display
	, output MAPTABLE_PACKET				                maptable_packet_display
    , output [`N_PHYS_REG-1:0][`XLEN-1:0]					physical_register_display
    `endif

);
	// Outputs of the ROB module
	ROB_PACKET 	[`SUPERSCALAR_WAYS-1:0]						rob_retire_packet;
	ROB_DISPATCH_PACKET 									rob_dispatch_packet;

	// Outputs of the RS module
	RS_DISPATCH_PACKET 										rs_dispatch_packet;
	RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] 				rs_issue_packet;

	//output cache
	logic hit_or_stall;
	logic [1:0] choose_address;
    	logic data_write_enable;
	logic [4:0] cache_write_index;
	logic [`SUPERSCALAR_WAYS-1:0][4:0]  cache_read_index;
	logic [7:0] cache_write_tag;
	logic [`SUPERSCALAR_WAYS-1:0][7:0]  cache_read_tag;
	logic [`SUPERSCALAR_WAYS-1:0][(2*`XLEN)-1:0] cachemem_data;
	logic [`SUPERSCALAR_WAYS-1:0] cachemem_valid;

	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] Icache_data_out;  
	logic [`SUPERSCALAR_WAYS-1:0] Icache_valid_out;
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Icache_addr; 


	// Outputs of the FREELIST module
	FREELIST_DISPATCH_PACKET 								freelist_dispatch_packet;

	// Outputs of the MAPTABLE module
	MAPTABLE_PACKET 										maptable_packet;

	// Outputs of the PRF module
	logic [63:0][31:0] 										physical_register;

	// Outputs of the ARCH module
	logic [`N_ARCH_REG-1:0][`N_PHYS_REG_BITS-1:0] 			arch_maptable;

	// Precise State Logic
	logic branch_enable ; // from retire.br_recover_enable
    assign  branch_enable =  br_recover_enable;

	// Display output
	`ifdef TEST_MODE
	assign rob_retire_packet_display = rob_retire_packet;
	assign rob_dispatch_packet_display = rob_dispatch_packet;
	assign rs_issue_packet_display = rs_issue_packet;
	assign maptable_packet_display = maptable_packet;
    assign physical_register_display = physical_register;
	`endif

	//////////////////////////////////////////////////
	//                                              //
	//               ICACHE-Module                  //
	//                                              //
	//////////////////////////////////////////////////

	icache icache_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
        	.take_branch(br_recover_enable), 
        	.Imem2proc_response(mem2proc_response),
		.Imem2proc_data(mem2proc_data),
		.Imem2proc_tag(mem2proc_tag),
		//.dcache_request(dcache_request),
		.choose_address(choose_address),
		.proc2Icache_addr(proc2Icache_addr),
		.cachemem_data(cachemem_data),
		.cachemem_valid(cachemem_valid),
		.hit_but_stall(hit_but_stall),

		// Outputs
		.proc2Imem_command(proc2mem_command),
		.proc2Imem_addr(proc2mem_addr),
		.Icache_data_out(Icache_data_out),
		.Icache_valid_out(Icache_valid_out),
		.cache_read_index(cache_read_index),
		.cache_read_tag(cache_read_tag),
		.cache_write_index(cache_write_index),
		.cache_write_tag(cache_write_tag),
		.data_write_enable(data_write_enable)
		
	);

	//////////////////////////////////////////////////
	//                                              //
	//               CACHEMEM-Module                //
	//                                              //
	//////////////////////////////////////////////////

	cachemem cachemem_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
        	.icache_data_write_enable(data_write_enable), 
        	.icache_write_index(cache_write_index),
		.icache_read_index(cache_read_index),
		.icache_write_tag(cache_write_tag),
		.icache_read_tag(cache_read_tag),
		.memory_data(mem2proc_data),
		
		// Outputs
		.icache_cachemem_data(cachemem_data),
		.icache_cachemem_valid(cachemem_valid)

		
	);

        //////////////////////////////////////////////////
	//                                              //
	//                 ROB-Module                   //
	//                                              //
	//////////////////////////////////////////////////

	rob rob_0 (
		// Inputs
		.clock(clock), 
		.reset(reset | br_recover_enable),
		.rob_dispatch_in(dispatch_rob_packet),
		.rob_complete_in(complete_rob_packet), 
		// Outputs
		.rob_dispatch_out(rob_dispatch_packet), 
		.rob_retire_out(rob_retire_packet)
`ifdef TEST_MODE
        , .rob_table(rob_table_display)
`endif
	);


	//////////////////////////////////////////////////
	//                                              //
	//                  RS-Module                   //
	//                                              //
	//////////////////////////////////////////////////

	rs rs_0 (
		// Inputs
		.clock(clock), 
		.reset(reset | br_recover_enable),
		.rs_cdb_in(cdb_packet),
		.rs_dispatch_in(dispatch_rs_packet),
		.rs_fu_in(fu_rs_packet),

		// Outputs
		.rs_issue_out(rs_issue_packet),
		.rs_dispatch_out(rs_dispatch_packet)

		`ifdef TEST_MODE
		,.rs_table(rs_table_display)
		`endif
	);


	//////////////////////////////////////////////////
	//                                              //
	//               FREELIST-Module                //
	//                                              //
	//////////////////////////////////////////////////

	freelist freelist_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
        .freelist_dispatch_in(dispatch_freelist_packet), 
        .freelist_retire_in(retire_freelist_packet),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),

		// Outputs
		.freelist_dispatch_out(freelist_dispatch_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//               MAPTABLE-Module                //
	//                                              //
	//////////////////////////////////////////////////

	maptable maptable_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		.maptable_cdb_in(cdb_packet),
		.maptable_dispatch_in(dispatch_maptable_packet),

		// Outputs
		.maptable_out(maptable_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//                  PRF-Module                  //
	//                                              //
	//////////////////////////////////////////////////

	prf prf_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
		.prf_fu_in(fu_prf_packet), 

		// Outputs
		.physical_register(physical_register)
	);


	//////////////////////////////////////////////////
	//                                              //
	//                 ARCH-Module                  //
	//                                              //
	//////////////////////////////////////////////////
	
	arch arch_0 (
		// Inputs
		.clock(clock), 
		.reset(reset ),
		.arch_retire_in(retire_packet), 

		// Outputs
		.arch_maptable(arch_maptable)
	);


	//////////////////////////////////////////////////
	//                                              //
	//                 Fetch-Stage                  //
	//                                              //
	//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			fetch_NPC_out[i]        = fetch_packet[i].NPC;
			fetch_IR_out[i]         = fetch_packet[i].inst;
			fetch_valid_inst_out[i] = fetch_packet[i].valid;
		end
	end

	fetch fetch_0 (
		// Inputs
		.clock(clock), 
		.reset(reset), 
		.branch_flush_en(br_recover_enable),
		.target_pc(target_pc), 
		.fetch_dispatch_in(dispatch_fetch_packet), 
		.cache_data(Icache_data_out),  
		.cache_valid(Icache_valid_out),
		// Outputs
		.hit_but_stall(hit_but_stall),
		.choose_address(choose_address),
		.PC_out(fetch_pc_out),
		.proc2Imem_addr(proc2Icache_addr), 
		.fetch_dispatch_out(fetch_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//       Fetch/Dispatch Pipeline Register       //
	//                                              //
	//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			fetch_dispatch_NPC_out[i]		 = fetch_dispatch_packet[i].NPC;
			fetch_dispatch_IR_out[i]		 = fetch_dispatch_packet[i].inst;
			fetch_dispatch_valid_inst_out[i] = fetch_dispatch_packet[i].valid;
		end
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset | br_recover_enable ) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				fetch_dispatch_packet[i].inst  <= `SD `NOP;
				fetch_dispatch_packet[i].valid <= `SD `FALSE;
				fetch_dispatch_packet[i].NPC   <= `SD 0;
				fetch_dispatch_packet[i].PC    <= `SD 0;
			end
		end  // if (reset)
		else if (/*dispatch_to_fetch*/dispatch_fetch_packet.enable) begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (i < (`SUPERSCALAR_WAYS - dispatch_fetch_packet.first_stall_idx))
				    fetch_dispatch_packet[i] <=
						`SD fetch_dispatch_packet[i + dispatch_fetch_packet.first_stall_idx];
                else
                    fetch_dispatch_packet[i] <=
						`SD fetch_packet[i + dispatch_fetch_packet.first_stall_idx - `SUPERSCALAR_WAYS];
            end
		end  // if (~reset & dispatch_fetch_out.enable)
        else fetch_dispatch_packet <= `SD fetch_packet;
	end // always


	//////////////////////////////////////////////////
	//                                              //
	//                Dispatch-Stage                //
	//                                              //
	//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			dispatch_NPC_out[i]        = dispatch_rs_packet[i].NPC;
			dispatch_IR_out[i]         = dispatch_rs_packet[i].inst;
			dispatch_valid_inst_out[i] = dispatch_rs_packet[i].valid;
		end
	end

    dispatch dispatch_0 (
		// Inputs
        .dispatch_maptable_in(maptable_packet),
        .dispatch_rs_in(rs_dispatch_packet),
        .dispatch_rob_in(rob_dispatch_packet),
        .dispatch_freelist_in(freelist_dispatch_packet),
        .dispatch_fetch_in(fetch_dispatch_packet),
        .branch_flush_en(br_recover_enable),
    	.cdb_in(cdb_packet),

		// Outputs
        .dispatch_rs_out(dispatch_rs_packet),
        .dispatch_rob_out(dispatch_rob_packet),
        .dispatch_maptable_out(dispatch_maptable_packet),
        .dispatch_fetch_out(dispatch_fetch_packet),
        .dispatch_freelist_out(dispatch_freelist_packet)
    );


	//////////////////////////////////////////////////
	//                                              //
	//                  Issue-Stage                 //
	//                                              //
	//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			issue_NPC_out[i]        = issue_packet[i].NPC;
			issue_IR_out[i]         = issue_packet[i].inst;
			issue_valid_inst_out[i] = issue_packet[i].valid;
		end
	end

	issue issue_0 (
		// Inputs
        .issue_rs_in(rs_issue_packet),
        .physical_register(physical_register), 

		// Outputs
		.issue_fu_out(issue_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//        Issue/Execute Pipeline Register       //
	//                                              //
	//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			issue_execute_NPC_out[i]        = issue_fu_packet[i].NPC;
			issue_execute_IR_out[i]         = issue_fu_packet[i].inst;
			issue_execute_valid_inst_out[i] = issue_fu_packet[i].valid;
		end
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset | br_recover_enable ) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				issue_fu_packet[i].inst  <= `SD `NOP;
				issue_fu_packet[i].valid <= `SD `FALSE;
				issue_fu_packet[i].NPC   <= `SD 0;
				issue_fu_packet[i].PC    <= `SD 0;
			end
		end  // if (reset)
		else begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
                issue_fu_packet[i] <= `SD issue_packet[i];
            end  // if (~reset)
	end // always


	//////////////////////////////////////////////////
	//                                              //
	//                 Execute-Stage                //
	//                                              //
	//////////////////////////////////////////////////

	fu fu_0 (
		// Inputs
		.clock(clock),
		.reset(reset | br_recover_enable),
		.fu_issue_in(issue_fu_packet),

		// Outputs
		.fu_rs_out(fu_rs_packet),
		.fu_complete_out(fu_packet),
		.fu_prf_out(fu_prf_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//      Execute/Complete Pipeline Register      //
	//                                              //
	//////////////////////////////////////////////////

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset | br_recover_enable ) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				fu_complete_packet[i].rd_mem 		 <= `SD 0;
				fu_complete_packet[i].wr_mem 		 <= `SD 0;
				fu_complete_packet[i].ar_idx	 <= `SD `ZERO_REG;
				fu_complete_packet[i].dest_value <= `SD 0;
			end
		end  // if (reset)
		else begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				fu_complete_packet[i] <= `SD fu_packet[i]; 
		end  // if (~reset)
	end // always


	//////////////////////////////////////////////////
	//                                              //
	//                Complete-Stage                //
	//                                              //
	//////////////////////////////////////////////////

	complete complete_0 (
		// Inputs
        .complete_fu_in(fu_complete_packet),

		// Outputs
		.complete_rob_out(complete_rob_packet),
		.complete_prf_out(complete_prf_packet),
		.cdb_out(cdb_packet)
	);


	//////////////////////////////////////////////////
	//                                              //
	//                 Retire-Stage                 //
	//                                              //
	//////////////////////////////////////////////////
    assign halt = retire_wfi_halt;


	retire retire_0 (
		// Inputs 
        .retire_rob_in(rob_retire_packet),
        .arch_maptable(arch_maptable),

		// Outputs
        .recovery_maptable(recovery_maptable),
        .retire_out(retire_packet),
        .retire_freelist_out(retire_freelist_packet),
        .br_recover_enable(br_recover_enable),
        .target_pc(target_pc),
        .wfi_halt(retire_wfi_halt)
    );
endmodule  // module verisimple
