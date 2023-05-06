/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_rs.sv                                      //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage and the    // 
//                 rs module                                           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_RS_SV__
`define __DISPATCH_RS_SV__

module dispatch_rs (
    // Inputs for rs
	input                                                   clock, 
    input                                                   reset,
    input  CDB_PACKET                                       rs_cdb_in,
    input  FU_RS_PACKET                                     rs_fu_in,

    // Inputs for dispatch
	input                                                   branch_flush_en,
    input  MAPTABLE_PACKET                                  dispatch_maptable_in,         
    input  ROB_DISPATCH_PACKET                              dispatch_rob_in,    
    input  FREELIST_DISPATCH_PACKET                         dispatch_freelist_in, 
    input  FETCH_DISPATCH_PACKET    [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in,

    // Outputs from rs
    output RS_ISSUE_PACKET          [`SUPERSCALAR_WAYS-1:0] rs_issue_out,

    // Outputs from dispatch   
	output DISPATCH_FETCH_PACKET                            dispatch_fetch_out,
    output DISPATCH_FREELIST_PACKET                         dispatch_freelist_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out,
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,

    // Connections between rs and dispatch   
    output RS_DISPATCH_PACKET                               rs_to_dispatch, 
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0] dispatch_to_rs

    //RS Table
`ifdef TEST_MODE
    , output DISPATCH_RS_PACKET     [`N_RS_ENTRIES-1:0]     rs_table
`endif
);
    rs rs_0( 
        // Inputs
        .clock(clock), 
        .reset(reset),
        .rs_cdb_in(rs_cdb_in),
        .rs_fu_in(rs_fu_in),
        .rs_dispatch_in(dispatch_to_rs),

        // Outputs
        .rs_issue_out(rs_issue_out),
        .rs_dispatch_out(rs_to_dispatch)
`ifdef TEST_MODE
        , .rs_table(rs_table)
`endif
    );

    dispatch dispatch_0 (
        // Inputs
        .branch_flush_en(branch_flush_en),
        .dispatch_maptable_in(dispatch_maptable_in),
        .dispatch_rs_in(rs_to_dispatch),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(dispatch_freelist_in),
        .dispatch_fetch_in(dispatch_fetch_in),

        // Outputs
        .dispatch_fetch_out(dispatch_fetch_out),
        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_rs_out(dispatch_to_rs),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
    );
endmodule  // dispatch_rs

`endif  // __DISPATCH_RS_SV__