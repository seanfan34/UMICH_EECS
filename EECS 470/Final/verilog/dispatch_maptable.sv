/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_maptable.sv                                //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage and the    // 
//                 maptable module                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_MAPTABLE_SV__
`define __DISPATCH_MAPTABLE_SV__

module dispatch_maptable (
    // Inputs for maptable
	input                                                   clock, 
    input                                                   reset,
    input                                                   br_recover_enable,
    input  MAPTABLE_PACKET                                  recovery_maptable,
    input  CDB_PACKET                                       maptable_cdb_in,

    // Inputs for dispatch
	input                                                   branch_flush_en,
    input  RS_DISPATCH_PACKET                               dispatch_rs_in,     
    input  ROB_DISPATCH_PACKET                              dispatch_rob_in,    
    input  FREELIST_DISPATCH_PACKET                         dispatch_freelist_in, 
    input  FETCH_DISPATCH_PACKET    [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in,

    // Outputs from dispatch   
	output DISPATCH_FETCH_PACKET                            dispatch_fetch_out,
    output DISPATCH_FREELIST_PACKET                         dispatch_freelist_out,
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out,
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,

    // Connections between maptable and dispatch
    output MAPTABLE_PACKET                                  maptable_to_dispatch,        
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_maptable
);
	maptable map(
        // Inputs
        .clock(clock), 
        .reset(reset),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),
        .maptable_cdb_in(maptable_cdb_in),
        .maptable_dispatch_in(dispatch_to_maptable),

        // Outputs
        .maptable_out(maptable_to_dispatch)
    );

    dispatch dispatch_0 (
        // Inputs
        .branch_flush_en(branch_flush_en),
        .dispatch_maptable_in(maptable_to_dispatch),
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(dispatch_freelist_in),
        .dispatch_fetch_in(dispatch_fetch_in),

        // Outputs
        .dispatch_fetch_out(dispatch_fetch_out),
        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_to_maptable)
    );
endmodule  // dispatch_maptable

`endif  // __DISPATCH_MAPTABLE_SV__