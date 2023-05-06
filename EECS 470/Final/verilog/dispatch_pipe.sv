/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_pipe.sv                                    //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage, the       // 
//                 fetch stage, and the modules they use               //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_PIPE_SV__
`define __DISPATCH_PIPE_SV__

module dispatch_pipe (
	input                                                                           clock, 
    input                                                                           reset,
	input                                                                           branch_flush_en,
    input                                                                           br_recover_enable,
    input  MAPTABLE_PACKET                                                          recovery_maptable,

    // Inputs for rs
    input  CDB_PACKET                                                               rs_cdb_in,
    input  FU_RS_PACKET                                                             rs_fu_in,

    // Inputs for rob
    input  COMPLETE_ROB_PACKET    [`SUPERSCALAR_WAYS-1:0]                           rob_complete_in,

    // Inputs for freelist
	input  RETIRE_FREELIST_PACKET [`SUPERSCALAR_WAYS-1:0]                           freelist_retire_in,
    
    // Inputs for maptable
    input                         [`SUPERSCALAR_WAYS-1:0][`N_PHYS_REG_BITS-1:0]     cdb_tag,
    
    // Inputs for fetch 
	input  [`XLEN-1:0] target_pc,
	input                         [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0]            Imem2proc_data,

    // Outputs
    output RS_ISSUE_PACKET        [`SUPERSCALAR_WAYS-1:0]                           rs_issue_out,
	output logic                  [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0]                proc2Imem_addr
    output ROB_PACKET              [`SUPERSCALAR_WAYS-1:0]                           rob_retire_out,
);
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_dispatch_out;
    MAPTABLE_PACKET maptable_to_dispatch;
    RS_DISPATCH_PACKET rs_to_dispatch; 
    ROB_DISPATCH_PACKET rob_to_dispatch;   
	DISPATCH_FETCH_PACKET dispatch_to_fetch;
    FREELIST_DISPATCH_PACKET freelist_to_dispatch;
    DISPATCH_FREELIST_PACKET dispatch_to_freelist;
    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_rs;
	DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_rob;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_to_maptable;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch;

    rs rs_0 ( 
        // Inputs
        .clock(clock), 
        .reset(reset),
        .rs_cdb_in(rs_cdb_in),
        .rs_fu_in(rs_fu_in),
        .rs_dispatch_in(dispatch_to_rs),

        // Outputs
        .rs_issue_out(rs_issue_out),
        .rs_dispatch_out(rs_to_dispatch)
    );

	rob rob_0 (
        // Inputs
		.clock(clock), 
        .reset(reset),
        .rob_dispatch_in(dispatch_to_rob),
        .rob_complete_in(rob_complete_in), 

        // Outputs
		.rob_dispatch_out(rob_to_dispatch),
        .rob_retire_out(rob_retire_out)
	);

	freelist freelist_0 (
        // Inputs
        .clock(clock),
        .reset(reset),
        .freelist_dispatch_in(dispatch_to_freelist),
        .freelist_retire_in(freelist_retire_in),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),

        // Outputs
		.freelist_dispatch_out(freelist_to_dispatch)
    );

	maptable maptable_0 (
        // Inputs
        .clock(clock), 
        .reset(reset),
        .dispatch_maptable_packet(dispatch_to_maptable),
        .cdb_tag(cdb_tag),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),

        // Outputs
        .map_packet(maptable_to_dispatch)
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
        .fetch_dispatch_out(fetch_dispatch_out)
    );

    dispatch dispatch_0 (
        // Inputs
        .branch_flush_en(branch_flush_en),
        .dispatch_maptable_in(maptable_to_dispatch),
        .dispatch_rs_in(rs_to_dispatch),
        .dispatch_rob_in(rob_to_dispatch),
        .dispatch_freelist_in(freelist_to_dispatch),
        .dispatch_fetch_in(fetch_to_dispatch),

        // Outputs
        .dispatch_fetch_out(dispatch_to_fetch),
        .dispatch_freelist_out(dispatch_to_freelist),
        .dispatch_rs_out(dispatch_to_rs),
        .dispatch_rob_out(dispatch_to_rob),
        .dispatch_maptable_out(dispatch_to_maptable)
    );

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				fetch_to_dispatch[i].inst  <= `SD `NOP;
				fetch_to_dispatch[i].valid <= `SD `FALSE;
				fetch_to_dispatch[i].NPC   <= `SD 0;
				fetch_to_dispatch[i].PC    <= `SD 0;
			end
		end  // if (reset)
		else if (dispatch_to_fetch.enable & ~branch_flush_en) begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (i < (`SUPERSCALAR_WAYS - dispatch_to_fetch.first_stall_idx))
				    fetch_to_dispatch[i] <= 
                        `SD fetch_to_dispatch[i + dispatch_to_fetch.first_stall_idx];
                else 
                    fetch_to_dispatch[i] <= 
                        `SD fetch_dispatch_out[i + dispatch_to_fetch.first_stall_idx - `SUPERSCALAR_WAYS];
            end
		end  // if (~reset & dispatch_fetch_out.enable)
        else fetch_to_dispatch <= `SD fetch_dispatch_out;
	end // always
endmodule  // dispatch_pipe

`endif  // __DISPATCH_PIPE_SV__