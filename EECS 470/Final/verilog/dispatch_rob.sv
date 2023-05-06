/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_rob.sv                                     //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage and the    // 
//                 rob module                                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_ROB_SV__
`define __DISPATCH_ROB_SV__

module dispatch_rob (
    // Inputs for rob
	input                                                   clock, 
    input                                                   reset,
    input  COMPLETE_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] rob_complete_in,

    // Inputs for dispatch
	input                                                   branch_flush_en,
    input  MAPTABLE_PACKET                                  dispatch_maptable_in,        
    input  RS_DISPATCH_PACKET                               dispatch_rs_in,      
    input  FREELIST_DISPATCH_PACKET                         dispatch_freelist_in, 
    input  FETCH_DISPATCH_PACKET    [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in,

    // Outputs from rob
    output ROB_PACKET                [`SUPERSCALAR_WAYS-1:0] rob_retire_out,

    // Outputs from dispatch   
	output DISPATCH_FETCH_PACKET                            dispatch_fetch_out,
    output DISPATCH_FREELIST_PACKET                         dispatch_freelist_out,
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out,

    // Connections between rob and dispatch  
    output ROB_DISPATCH_PACKET                              rob_to_dispatch, 
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] dispatch_to_rob
);

	rob rob_0(
        // Inputs
		.clock(clock), 
        .reset(reset),
        .rob_dispatch_in(dispatch_to_rob),
        .rob_complete_in(rob_complete_in), 

        // Outputs
		.rob_dispatch_out(rob_to_dispatch),
        .rob_retire_out(rob_retire_out)
	);
        
    dispatch dispatch_0 (
        // Inputs
        .branch_flush_en(branch_flush_en),
        .dispatch_maptable_in(dispatch_maptable_in),
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(rob_to_dispatch),
        .dispatch_freelist_in(dispatch_freelist_in),
        .dispatch_fetch_in(dispatch_fetch_in),

        // Outputs
        .dispatch_fetch_out(dispatch_fetch_out),
        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_to_rob),
        .dispatch_maptable_out(dispatch_maptable_out)
    );
endmodule  // dispatch_rob

`endif  // __DISPATCH_ROB_SV__
