/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_freelist.sv                                //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage and the    // 
//                 freelist module                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_FREELIST_SV__
`define __DISPATCH_FREELIST_SV__

module dispatch_freelist (
    // Inputs for freelist
	input                                                   clock, 
    input                                                   reset,
    input                                                   br_recover_enable,
    input  MAPTABLE_PACKET                                  recovery_maptable,
	input  RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]   freelist_retire_in,

    // Inputs for dispatch
	input                                                   branch_flush_en,
    input  MAPTABLE_PACKET                                  dispatch_maptable_in,          
    input  RS_DISPATCH_PACKET                               dispatch_rs_in,     
    input  ROB_DISPATCH_PACKET                              dispatch_rob_in,    
    input  FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]    dispatch_fetch_in,

    // Outputs from dispatch   
	output DISPATCH_FETCH_PACKET                            dispatch_fetch_out,
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out,
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out,

    // Connections between freelist and dispatch
    output FREELIST_DISPATCH_PACKET                         freelist_to_dispatch, 
    output DISPATCH_FREELIST_PACKET                         dispatch_to_freelist

`ifdef TEST_MODE
    , output FREELIST               [`N_PHYS_REG-1:0]       freelist_display
    , output logic                                          logic_display
`endif
);
	freelist freelist_0(
        // Inputs
        .clock(clock),
        .reset(reset),
        .freelist_dispatch_in(dispatch_to_freelist),
        .freelist_retire_in(freelist_retire_in),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),

        // Outputs
		.freelist_dispatch_out(freelist_to_dispatch)
        `ifdef TEST_MODE
        ,.freelist_display(freelist_display)
        `endif
    );

    dispatch dispatch_0 (
        // Inputs
        .branch_flush_en(branch_flush_en),
        .dispatch_maptable_in(dispatch_maptable_in),
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(freelist_to_dispatch),
        .dispatch_fetch_in(dispatch_fetch_in),

        // Outputs
        .dispatch_fetch_out(dispatch_fetch_out),
        .dispatch_freelist_out(dispatch_to_freelist),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
        `ifdef TEST_MODE
        ,.logic_display(logic_display)
        `endif
    );
endmodule  // dispatch_freelist

`endif  // __DISPATCH_FREELIST_SV__