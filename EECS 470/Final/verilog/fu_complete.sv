/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  fu_complete.sv                                      //
//                                                                     //
//  Description :  "pipeline" connecting the complete stage and the    // 
//                 fu module                                           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __FU_COMPLETE_SV__
`define __FU_COMPLETE_SV__

module fu_complete (
    // Inputs for fu
	input                                              clock,              // system clock
	input                                              reset,              // system reset
	input  ISSUE_FU_PACKET     [`SUPERSCALAR_WAYS-1:0] fu_issue_in,

    //Outputs from fu
    output FU_RS_PACKET                                fu_rs_out,
	output FU_PRF_PACKET       [6:0]                   fu_prf_out,

    // Outputs from complete
	output logic                                       take_branch,        // if take branch // there will be only one branch
    output logic               [`XLEN-1:0]             target_pc,          // branch destination
    output logic               [`SUPERSCALAR_WAYS-1:0] halt,               // pass
    output COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] complete_rob_out,   // [4:0] rob_idx, complete, valid
    output COMPLETE_PRF_PACKET [`SUPERSCALAR_WAYS-1:0] complete_prf_out,   // ar_idx, dest_value, rd_mem, wr_mem
    output CDB_PACKET                                  cdb_out,            // we have 3 CDB entries

    // Connections between fu and complete
    output FU_COMPLETE_PACKET  [`SUPERSCALAR_WAYS-1:0] fu_complete_packet
);

	fu fu_0 (
        // Inputs
        .clock(clock),
	    .reset(reset),
	    .fu_issue_in(fu_issue_in),

    // Outputs
	    .fu_complete_out(fu_complete_packet),
	    .fu_rs_out(fu_rs_out),
	    .fu_prf_out(fu_prf_out)

    );

    complete complete_0 (
        // Inputs
        .complete_fu_in(fu_complete_packet),

        // Outputs
        .take_branch(take_branch), // if take branch // there will be only one branch
        .target_pc(target_pc), // branch destination
        .halt(halt), // pass
        .complete_rob_out(complete_rob_out),  //[4:0] rob_idx, complete, valid
        .complete_prf_out(complete_prf_out),  //ar_idx, dest_value, rd_mem, wr_mem
        .cdb_out(cdb_out)        // we have 3 CDB entries

    );
endmodule  // fu_complete

`endif  // __FU_COMPLETE_SV__