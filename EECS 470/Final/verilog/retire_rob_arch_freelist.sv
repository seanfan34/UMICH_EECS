`ifndef __RETIRE_CONNECTION_SV__
`define __RETIRE_CONNECTION_SV__

module retire_rob_arch_freelist (
    // rob input 
    input  													  clock, 
	input  													  reset,
    input  COMPLETE_ROB_PACKET 		  [`SUPERSCALAR_WAYS-1:0] rob_complete_in,
    input  DISPATCH_ROB_PACKET 		  [`SUPERSCALAR_WAYS-1:0] rob_dispatch_in,


    // freelist input 
    input  DISPATCH_FREELIST_PACKET 						  freelist_dispatch_in,

//    input  MAPTABLE_PACKET               					    arch_maptable,	

    // rob output
    output ROB_DISPATCH_PACKET 								  rob_dispatch_out,
    
    // freelist output
    output FREELIST_DISPATCH_PACKET 						  freelist_dispatch_out,

    // retire connection   
    output RETIRE_CONNECTION_PACKET	  [`SUPERSCALAR_WAYS-1:0] retire_connect_packet,
    output FREELIST_CONNECTION_PACKET [`SUPERSCALAR_WAYS-1:0] freelist_connect_packet,
    output ROB_CONNECTION_ENTRY 	  [`SUPERSCALAR_WAYS-1:0] rob_connect_packet,
    output logic 					  [`XLEN-1:0] 			  target_pc,
    //TODO Precise State
    output MAPTABLE_PACKET                                    recovery_maptable,
    output logic                                              br_recover_enable
);
	
	retire retire_0 (
		// Inputs 

        .retire_rob_in(rob_connect_packet),
        .arch_maptable(arch_maptable),

		// Outputs
        .recovery_maptable(recovery_maptable),
        .retire_out(retire_connect_packet),
        .retire_freelist_out(freelist_connect_packet),
        .br_recover_enable(br_recover_enable),
		.target_pc(fetch_pc)
    );

	rob rob_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
		.rob_dispatch_in(rob_dispatch_in),
		.rob_complete_in(rob_complete_in), 

		// Outputs
		.rob_dispatch_out(rob_dispatch_out), 
		.rob_retire_out(rob_connect_packet)
	);

	arch arch_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
		.arch_retire_in(retire_connect_packet), 

		.arch_maptable(arch_maptable)
	);

	freelist freelist_0 (
		// Inputs
		.clock(clock), 
		.reset(reset),
        .freelist_dispatch_in(freelist_dispatch_in), 
        .freelist_retire_in(freelist_connect_packet),
		.br_recover_enable(br_recover_enable),
		.recovery_maptable(recovery_maptable),
		// Outputs
		.freelist_dispatch_out(freelist_dispatch_out)
	);
endmodule  // retire_rob_arch_freelist

`endif  // __RETIRE_CONNECTION_SV__