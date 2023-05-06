/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  rob.sv                                              //
//                                                                     //
//  Description :  re-order buffer                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module rob (
    input                                              clock, 
    input                                              reset,
    input  DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_dispatch_in,
    input  COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] rob_complete_in,
    input  ['SUPERSCALAR_WAYS]                         sq_stall,          // stall signal from d_cache

    output ROB_DISPATCH_PACKET                         rob_dispatch_out,  // stalls and new entry indices from ROB
    output ROB_PACKET          [`SUPERSCALAR_WAYS-1:0] rob_retire_out

`ifdef TEST_MODE
  , output ROB_PACKET          [`N_ROB_ENTRIES-1:0]    rob_table
`endif
);
    ROB_PACKET [`N_ROB_ENTRIES-1:0]                        rob;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        head_idx;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        next_head_idx;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        tail_idx;
    logic [`N_ROB_ENTRIES_BITS-1:0]                        next_tail_idx;
    logic [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] d_idx;
    logic [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] c_idx;
    logic [`SUPERSCALAR_WAYS-1:0][`N_ROB_ENTRIES_BITS-1:0] r_idx; 
    logic [`SUPERSCALAR_WAYS-1:0]                          dispatch_en;
    logic [`SUPERSCALAR_WAYS-1:0]                          retire_en; 
    logic                                                  empty;
    logic                                                  next_empty;

`ifdef TEST_MODE
    assign rob_table  = rob;
`endif

    always_ff @(posedge clock) begin        
        if (reset) begin
            rob      <= `SD 0;
            head_idx <= `SD 0;
            tail_idx <= `SD 0;
            empty    <= `SD `TRUE;
        end  // if (reset)
        else begin
            head_idx <= `SD next_head_idx;
            tail_idx <= `SD next_tail_idx;
            empty    <= `SD next_empty;

            // Complete
            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (rob_complete_in[i].complete) begin
                    rob[c_idx[i]].complete             <= `SD `TRUE;
                    rob[c_idx[i]].dest_value           <= `SD rob_complete_in[i].dest_value;
                    rob[c_idx[i]].precise_state_enable <= `SD rob_complete_in[i].precise_state_enable;
                    rob[c_idx[i]].target_pc            <= `SD rob_complete_in[i].target_pc;
                end  // if (rob_complete_in[i].valid)
            end  // for Complete

            // Dispatch new instructions
            for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
                if (dispatch_en[i]) begin
                    // Add the instruction in at the tail
                    rob[d_idx[i]].t_idx    <= `SD rob_dispatch_in[i].t_idx;
                    rob[d_idx[i]].told_idx <= `SD rob_dispatch_in[i].told_idx;
                    rob[d_idx[i]].ar_idx   <= `SD rob_dispatch_in[i].ar_idx;
                    rob[d_idx[i]].halt     <= `SD rob_dispatch_in[i].halt;
                    rob[d_idx[i]].NPC      <= `SD rob_dispatch_in[i].NPC;
                    rob[d_idx[i]].wr_mem   <= `SD rob_dispatch_in[i].wr_mem;

                    // Mark the instruction as uncompleted and not a taken branch
                    rob[d_idx[i]].complete             <= `SD `FALSE;
                    rob[d_idx[i]].precise_state_enable <= `SD `FALSE;
                    rob[d_idx[i]].dest_value           <= `SD 0;
                    rob[d_idx[i]].target_pc            <= `SD 0;
                end  // if (dispatch_en[i])
            end  // for Dispatch
        end  // if (~reset)
    end  // always_ff @(posedge clock)

    always_comb begin
        next_empty = (next_head_idx === next_tail_idx);
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (dispatch_en[i])
                next_empty = `FALSE;
        end  // for each dispatched instruction
    end  // always_comb  // next_empty

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            c_idx[i] = rob_complete_in[i].rob_idx;
    end  // always_comb  // c_idx

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
            r_idx[i] = head_idx + i;
    end  // always_comb  // r_idx

    always_comb begin
        retire_en[0] = ~empty;
        for (int i = 1; i < `SUPERSCALAR_WAYS; i++)
            retire_en[i] = ((r_idx[i] < tail_idx) | (tail_idx < head_idx));
    end  // always_comb  // retire_en

    always_comb begin
        next_head_idx = head_idx + `SUPERSCALAR_WAYS;
        
        for (int i = `SUPERSCALAR_WAYS; i != 0; i--) begin
            if (retire_en[i - 1] & rob[r_idx[i - 1]].complete) begin
                // If a taken branch is being retired, don't retire any following instructions
                if (rob[r_idx[i - 1]].precise_state_enable)
                    rob_retire_out = 0;

                // Set output to Retire Stage according to the current head of the ROB
                rob_retire_out[i - 1] = rob[r_idx[i - 1]];
            end  // if the instruction is in the ROB and complete
            else begin
                rob_retire_out = 0;
                next_head_idx  = r_idx[i - 1];
            end  // if the instruction is not in the ROB or not complete
        end  // for Retire
    end  // always_comb  // rob_retire_out

    always_comb begin
        next_tail_idx = tail_idx;
        dispatch_en   = 0;

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (~rob_dispatch_in[i].valid) begin
                rob_dispatch_out.stall[i] = `FALSE;
                dispatch_en[i]            = `FALSE;

            end  // if the instruction is invalid, ignore it
            else if ((next_tail_idx + 1 == next_head_idx) |
                     ((next_tail_idx == `N_ROB_ENTRIES - 1) & (next_head_idx == 0))) begin

                rob_dispatch_out.stall[i] = `TRUE;
                dispatch_en[i]            = `FALSE;
            end  // if the ROB doesn't have room for the next instruction, stall it in dispatch
            else if (~rob_dispatch_in[i].enable) begin
                rob_dispatch_out.stall[i] = `FALSE;
                dispatch_en[i]            = `FALSE;
            end  // if ROB dispatch is disabled, don't do anything
            else begin
                d_idx[i]                          = next_tail_idx;
                rob_dispatch_out.new_entry_idx[i] = d_idx[i];

                // Increment the tail pointer iff the ROB isn't empty
                if (~next_empty)
                    next_tail_idx++;

                rob_dispatch_out.stall[i] = `FALSE;
                dispatch_en[i]            = `TRUE;
            end  // else add the instruction to the ROB 
        end  // for Dispatch
    end  // always_comb  // rob_dispatch_out
endmodule  // rob
