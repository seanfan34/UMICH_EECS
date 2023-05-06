/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_fetch_freelist.sv                          //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage, the       // 
//                 fetch stage, and the freelist module                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_FETCH_FREELIST_SV__
`define __DISPATCH_FETCH_FREELIST_SV__

module dispatch_fetch_freelist (
    // Inputs for freelist and fetch
	input                                                                  clock, 
    input                                                                  reset,

    // Inputs for fetch and dispatch
	input                                                                  branch_flush_en,
	input                           [`XLEN-1:0]                            target_pc,

    // Inputs for freelist
    input                                                                  br_recover_enable,
    input  MAPTABLE_PACKET                                                 recovery_maptable,
	input  RETIRE_FREELIST_PACKET   [`SUPERSCALAR_WAYS-1:0]                freelist_retire_in,

    // Inputs for fetch
	input                           [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data,

    // Inputs for dispatch
    input  MAPTABLE_PACKET                                                 dispatch_maptable_in,
    input  RS_DISPATCH_PACKET                                              dispatch_rs_in,
    input  ROB_DISPATCH_PACKET                                             dispatch_rob_in,

	// Outputs from fetch
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0]                        proc2Imem_addr,

    // Outputs from dispatch   
    output DISPATCH_RS_PACKET       [`SUPERSCALAR_WAYS-1:0]                dispatch_rs_out,
    output DISPATCH_ROB_PACKET      [`SUPERSCALAR_WAYS-1:0]                dispatch_rob_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0]                dispatch_maptable_out,

    // Connections between freelist, fetch, and dispatch
    output FREELIST_DISPATCH_PACKET                                        freelist_to_dispatch,
    output DISPATCH_FREELIST_PACKET                                        dispatch_to_freelist,
	output DISPATCH_FETCH_PACKET                                           dispatch_to_fetch,
    output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0]                   fetch_to_dispatch
);
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

	freelist freelist_0 (
        // Inputs
		.clock(clock),
		.reset(reset),
        .br_recover_enable(br_recover_enable),
        .recovery_maptable(recovery_maptable),
        .freelist_dispatch_in(dispatch_to_freelist),
        .retire_freelist_packet(freelist_retire_in),

        // Outputs
		.freelist_dispatch_out(freelist_to_dispatch)
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
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(freelist_to_dispatch),
        .dispatch_fetch_in(dispatch_fetch_in),

        // Outputs
        .dispatch_fetch_out(dispatch_to_fetch),
        .dispatch_freelist_out(dispatch_to_freelist),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
    );

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset) begin 
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
				dispatch_fetch_in[i].inst  <= `SD `NOP;
				dispatch_fetch_in[i].valid <= `SD `FALSE;
				dispatch_fetch_in[i].NPC   <= `SD 0;
				dispatch_fetch_in[i].PC    <= `SD 0;
			end
		end  // if (reset)
		else if (dispatch_to_fetch.enable & ~branch_flush_en) begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (i < (`SUPERSCALAR_WAYS - dispatch_to_fetch.first_stall_idx))
				    dispatch_fetch_in[i] <= 
                        `SD dispatch_fetch_in[i + dispatch_to_fetch.first_stall_idx];
                else 
                    dispatch_fetch_in[i] <= 
                        `SD fetch_to_dispatch[i + dispatch_to_fetch.first_stall_idx - `SUPERSCALAR_WAYS];
            end
		end  // if (~reset & dispatch_fetch_freelist_out.enable)
        else dispatch_fetch_in <= `SD fetch_to_dispatch;
	end // always
endmodule  // dispatch_fetch_freelist

`endif  // __DISPATCH_FETCH_FREELIST_SV__