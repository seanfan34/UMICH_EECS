/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  complete.sv                                         //
//                                                                     //
//  Description :  instruction complete stage of the pipeline;         // 
//                 send out the CBD tags for any completed             //
//                 instructions and pass a complete signal to ROB      //
//                 if a branch was taken, it sends out a true (`TRUE)  // 
//                 take_branch signal and the branch_branch_target_pc  // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module complete (
    input  FU_COMPLETE_PACKET  [`SUPERSCALAR_WAYS-1:0] complete_fu_in,
    output COMPLETE_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] complete_rob_out,  // [4:0] rob_idx, complete, valid
    output COMPLETE_PRF_PACKET [`SUPERSCALAR_WAYS-1:0] complete_prf_out,  // ar_idx, dest_value, rd_mem, wr_mem
    output CDB_PACKET                                  cdb_out            // we have 3 CDB entries
);
    logic [`SUPERSCALAR_WAYS-1:0]                      valid_non_branch;  // true iff the inst is valid and not a branch

    always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            valid_non_branch[i] = complete_fu_in[i].valid & ~complete_fu_in[i].take_branch;
            cdb_out.t_idx[i]    = valid_non_branch[i] ? complete_fu_in[i].pr_idx : 0;
        end
    end  // always_comb  // cdb_out

    // Set complete_rob_out
    always_comb begin
        complete_rob_out = 0;

        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            if (complete_fu_in[i].valid) begin
                complete_rob_out[i].complete             = `TRUE;
                complete_rob_out[i].rob_idx              = complete_fu_in[i].rob_idx;
                complete_rob_out[i].dest_value           = complete_fu_in[i].dest_value;
                complete_rob_out[i].precise_state_enable = complete_fu_in[i].take_branch;
                complete_rob_out[i].target_pc            = complete_fu_in[i].target_pc;
            end  // if (complete_fu_in[i].valid)
        end  // for each complete_rob_out
    end  // always_comb  // ROB

    // set complete_prf_out  // this might be redundant
    /*always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
            complete_prf_out[i].ar_idx = 0;
            complete_prf_out[i].dest_value = 0;
            complete_prf_out[i].rd_mem = `FALSE;
            complete_prf_out[i].wr_mem = `FALSE;

            if (valid_non_branch[i]) begin
                complete_prf_out[i].ar_idx     = complete_fu_in[i].pr_idx;
                complete_prf_out[i].dest_value = complete_fu_in[i].dest_value;
                complete_prf_out[i].rd_mem     = complete_fu_in[i].rd_mem;
                complete_prf_out[i].wr_mem     = complete_fu_in[i].wr_mem;
            end  // if (valid_non_branch[i])
        end  // for each complete_prf_out
    end  // always_comb  // PRF*/
endmodule  // complete