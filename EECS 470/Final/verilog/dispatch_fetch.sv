/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  dispatch_fetch.sv                                    //
//                                                                     //
//  Description :  "pipeline" connecting the dispatch stage and the    // 
//                 fetch stage                                         //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __DISPATCH_FETCH_SV__
`define __DISPATCH_FETCH_SV__

module dispatch_fetch (
    // Inputs for fetch
	input clock, reset,
	input [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data,

    // Inputs for dispatch
    input MAPTABLE_PACKET dispatch_maptable_in,          
    input RS_DISPATCH_PACKET dispatch_rs_in,     
    input ROB_DISPATCH_PACKET dispatch_rob_in,    
    input FREELIST_DISPATCH_PACKET dispatch_freelist_in, 

    // Inputs for both
	input branch_flush_en,
	input [`XLEN-1:0] target_pc,

	// Outputs from fetch
	output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] proc2Imem_addr,

    // Outputs from dispatch   
    output DISPATCH_FREELIST_PACKET dispatch_freelist_out, 
    output DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out,
    output DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out,
    output DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out,

    // Connections between fetch and dispatch
	output DISPATCH_FETCH_PACKET dispatch_to_fetch,
    output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_to_dispatch
);
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] fetch_dispatch_out;

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
        .dispatch_maptable_in(dispatch_maptable_in),
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(dispatch_freelist_in),
        .dispatch_fetch_in(fetch_to_dispatch),

        // Outputs
        .dispatch_fetch_out(dispatch_to_fetch),
        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
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
endmodule  // dispatch_fetch

`endif  // __DISPATCH_FETCH_SV__