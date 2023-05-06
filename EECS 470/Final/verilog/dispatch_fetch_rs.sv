/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_fetch_rs.sv                                //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage, the       // 
//                 fetch stage, and the rs module                      //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_FETCH_RS_SV__
`define __DISPATCH_FETCH_RS_SV__

module dispatch_fetch_rs (
    // Inputs for rs and fetch
	input clock, reset,

    // Inputs for fetch and dispatch
	input branch_flush_en,

    // Inputs for rs
    input CDB_PACKET rs_cdb_in,
    input FU_RS_PACKET fu_rs_in,
    
    // Inputs for fetch
	input [`XLEN-1:0] target_pc,
	input [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data,

    // Inputs for dispatch
    input MAPTABLE_PACKET dispatch_maptable_in,            
    input ROB_DISPATCH_PACKET dispatch_rob_in,    
    input FREELIST_DISPATCH_PACKET dispatch_freelist_in, 

    // Outputs from rs
    output RS_ISSUE_PACKET [`SUPERSCALAR_WAYS-1:0] rs_issue_out,

	// Outputs from fetch
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr,

    // Outputs from dispatch   
    output DISPATCH_FREELIST_PACKET dispatch_freelist_out, 
    output DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out,

    // Connections between rs, fetch, and dispatch  
    output RS_DISPATCH_PACKET rs_to_dispatch, 
    output DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_rs,
	output DISPATCH_FETCH_PACKET dispatch_to_fetch,
    output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch
);
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

    rs rs_0( 
        // Inputs
        .clock(clock), 
        .reset(reset),
        .rs_cdb_in(rs_cdb_in),
        .fu_rs_in(fu_rs_in),
        .rs_dispatch_in(dispatch_to_rs),

        // Outputs
        .rs_issue_out(rs_issue_out),
        .rs_dispatch_out(rs_to_dispatch)
    );

    fetch fetch_0 (
        // Inputs
	    .clock(clock), 
        .reset(reset),
        .branch_flush_en(branch_flush_en),
        .target_pc(target_pc),
        .fetch_dispatch_in(dispatch_to_fetch),
        .Imem2proc_data(Imem2proc_data),

        // Outputs
        .proc2Imem_addr(proc2Imem_addr),
        .fetch_dispatch_out(fetch_to_dispatch)
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
        .dispatch_fetch_out(dispatch_to_fetch),
        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_rs_out(dispatch_to_rs),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
    );

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset | branch_flush_en) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				dispatch_fetch_in[i].inst  <= `SD `NOP;
				dispatch_fetch_in[i].valid <= `SD `FALSE;
				dispatch_fetch_in[i].NPC   <= `SD 0;
				dispatch_fetch_in[i].PC    <= `SD 0;
			end
		end  // if (reset | branch_flush_en)
		else if (dispatch_to_fetch.enable) begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (i < (`SUPERSCALAR_WAYS - dispatch_to_fetch.first_stall_idx))
				    dispatch_fetch_in[i] <= 
                        `SD dispatch_fetch_in[i + dispatch_to_fetch.first_stall_idx];
                else 
                    dispatch_fetch_in[i] <= 
                        `SD fetch_to_dispatch[i + dispatch_to_fetch.first_stall_idx - `SUPERSCALAR_WAYS];
            end
		end  // if (~reset & ~branch_flush_en & dispatch_fetch_out.enable)
        else dispatch_fetch_in <= `SD fetch_to_dispatch;
	end // always
endmodule  // dispatch_fetch_rs

`endif  // __DISPATCH_FETCH_RS_SV__