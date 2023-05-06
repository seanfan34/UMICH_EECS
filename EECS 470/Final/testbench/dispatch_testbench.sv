module dispatch_testbench;
    logic clock, correct, branch_flush_en;
    logic [`SUPERSCALAR_WAYS-1:0] rs_correct;
    MAPTABLE_PACKET dispatch_maptable_in;
    RS_DISPATCH_PACKET dispatch_rs_in;
    ROB_DISPATCH_PACKET dispatch_rob_in;
    FREELIST_DISPATCH_PACKET dispatch_freelist_in;
    FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_fetch_in;

    DISPATCH_FETCH_PACKET dispatch_fetch_out, expected_dispatch_fetch_out;
    DISPATCH_FREELIST_PACKET dispatch_freelist_out, expected_dispatch_freelist_out;
    DISPATCH_RS_PACKET  [`SUPERSCALAR_WAYS-1:0] dispatch_rs_out, expected_dispatch_rs_out;
    DISPATCH_ROB_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_rob_out, expected_dispatch_rob_out;
    DISPATCH_MAPTABLE_PACKET [`SUPERSCALAR_WAYS-1:0] dispatch_maptable_out, expected_dispatch_maptable_out;

    dispatch dispatch_tb(
        .dispatch_fetch_in(dispatch_fetch_in),
        .dispatch_rs_in(dispatch_rs_in),
        .dispatch_rob_in(dispatch_rob_in),
        .dispatch_freelist_in(dispatch_freelist_in),
        .dispatch_maptable_in(dispatch_maptable_in),
        .branch_flush_en(branch_flush_en),

        .dispatch_freelist_out(dispatch_freelist_out),
        .dispatch_fetch_out(dispatch_fetch_out),
        .dispatch_rs_out(dispatch_rs_out),
        .dispatch_rob_out(dispatch_rob_out),
        .dispatch_maptable_out(dispatch_maptable_out)
    );

    int test;

    assign correct = (dispatch_freelist_out === expected_dispatch_freelist_out &
                      dispatch_fetch_out === expected_dispatch_fetch_out &
                      dispatch_rob_out === expected_dispatch_rob_out &
                      dispatch_maptable_out === expected_dispatch_maptable_out &
                      (rs_correct === 3'b111));

    always begin
        #(`VERILOG_CLOCK_PERIOD/2.0);
            clock = ~clock;
    end

    initial begin
        $dumpvars;

        $display("INITIALIZING DISPATCH TESTBENCH");
        test = 0;
        clock = 0;

        run_single_packet_tests(0);
        run_single_packet_tests(1);
        run_single_packet_tests(2);

        $display("@@@ Test %1d: Reset dispatch", test);
        clear();
        branch_flush_en = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: 2 free registers", test);
        branch_flush_en = 1'b0;
        for (int i = 0; i < 3; i++) begin
            dispatch_fetch_in[i].valid = 1'b1;
            dispatch_fetch_in[i].inst = `RV32_ADD;
            dispatch_fetch_in[i].inst.r.rs1 = 8;
            dispatch_fetch_in[i].inst.r.rs2 = 4;
            dispatch_fetch_in[i].inst.r.rd  = 2;
            expected_dispatch_rs_out[i].valid  = 1'b1;
            expected_dispatch_rs_out[i].inst = `RV32_ADD;
            expected_dispatch_rs_out[i].inst.r.rs1 = 4'd8;
            expected_dispatch_rs_out[i].inst.r.rs2 = 4'd4;
            expected_dispatch_rs_out[i].inst.r.rd  = 4'd2;
            expected_dispatch_rob_out[i].valid = 1'b1;
            expected_dispatch_rob_out[i].ar_idx = 2;
            expected_dispatch_maptable_out[i].ar_idx = 2;
        end
        for (int i = 0; i < 2; i++) begin
            dispatch_freelist_in.valid[i] = 1;
            expected_dispatch_freelist_out.new_pr_en[i] = 1'b1;
            expected_dispatch_rs_out[i].enable  = 1'b1;
            expected_dispatch_rob_out[i].enable = 1'b1;
            expected_dispatch_maptable_out[i].enable = 1'b1;
        end
        expected_dispatch_fetch_out.enable = 1'b1;
        expected_dispatch_fetch_out.first_stall_idx = 2'd2;
        verify_answer();

        $display("\nENDING DISPATCH TESTBENCH: SUCCESS!\n");
        $finish;

    end

    task clear; 
        dispatch_fetch_in = 0;
        dispatch_rs_in = 0;
        dispatch_rob_in = 0;
        dispatch_maptable_in = 0;
        dispatch_freelist_in = 0;
        branch_flush_en = 0;
        expected_dispatch_freelist_out = 0;
        expected_dispatch_fetch_out = 0;
        expected_dispatch_rob_out = 0;
        expected_dispatch_maptable_out = 0;
        expected_dispatch_rs_out = 0;
        for (int i = 0; i < 3; i++) begin
            dispatch_fetch_in[i].inst.r.rs1 = 0;
            dispatch_fetch_in[i].inst.r.rs2 = 0;
            dispatch_fetch_in[i].inst.r.rd  = 0;

            expected_dispatch_rs_out[i].inst.r.rs1 = 0;
            expected_dispatch_rs_out[i].inst.r.rs2 = 0;
            expected_dispatch_rs_out[i].inst.r.rd  = 0;
        end
    endtask

    task run_single_packet_tests; input int packet_idx; begin
        $display("RUNNING SINGLE INPUT TESTS WITH PACKET %1d", packet_idx);
        clear();

        $display("@@@ Test %1d: Reset dispatch", test);
        branch_flush_en = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: No free registers", test);
        branch_flush_en = 1'b0;

        dispatch_fetch_in[packet_idx].valid = 1'b1;
        for (int i = 0; i < 3; i++) begin
            dispatch_fetch_in[i].inst = `RV32_ADD;
            expected_dispatch_rs_out[i].inst = `RV32_ADD;
        end

        dispatch_freelist_in.t_idx[0] = 1;
        dispatch_maptable_in.map[3] = 4;
        dispatch_maptable_in.map[7] = 2;
        dispatch_fetch_in[packet_idx].inst.r.rs1 = 7;
        dispatch_fetch_in[packet_idx].inst.r.rs2 = 4;
        dispatch_fetch_in[packet_idx].inst.r.rd  = 3;
        expected_dispatch_rs_out[packet_idx].reg1_pr_idx = 2;
        expected_dispatch_rs_out[packet_idx].inst.r.rs1 = 7;
        expected_dispatch_rs_out[packet_idx].inst.r.rs2 = 4;
        expected_dispatch_rs_out[packet_idx].inst.r.rd  = 3;
        expected_dispatch_rs_out[packet_idx].pr_idx = 1;
        expected_dispatch_rob_out[packet_idx].t_idx = 1;
        expected_dispatch_maptable_out[packet_idx].pr_idx = 1;

        expected_dispatch_fetch_out.enable = 1'b1;
        expected_dispatch_fetch_out.first_stall_idx = packet_idx;
        for (int i = 0; i < packet_idx; i++) begin
            expected_dispatch_rs_out[i].enable  = 1'b1;
            expected_dispatch_rob_out[i].enable = 1'b1;
            expected_dispatch_maptable_out[i].enable = 1'b1;
        end
        expected_dispatch_rs_out[packet_idx].valid = 1'b1;
        expected_dispatch_rob_out[packet_idx].valid = 1'b1;
        expected_dispatch_rob_out[packet_idx].told_idx = 4;
        expected_dispatch_rob_out[packet_idx].ar_idx = 3;
        expected_dispatch_maptable_out[packet_idx].ar_idx = 3;

        verify_answer();

        $display("@@@ Test %1d: No free registers and ROB stall", test);
        dispatch_rob_in.stall[packet_idx] = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: All stalls", test);
        dispatch_rs_in.stall[packet_idx] = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: No free registers and RS stall", test);
        dispatch_rob_in.stall[packet_idx] = 1'b0;
        verify_answer();

        $display("@@@ Test %1d: RS and ROB stall", test);
        dispatch_rob_in.stall[packet_idx] = 1'b1;
        dispatch_freelist_in.valid[0] = 1;
        verify_answer();

        $display("@@@ Test %1d: RS stall", test);
        dispatch_rob_in.stall[packet_idx] = 1'b0;
        verify_answer();

        $display("@@@ Test %1d: ROB stall", test);
        dispatch_rs_in.stall[packet_idx] = 1'b0;
        dispatch_rob_in.stall[packet_idx] = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: No stalls", test);
        dispatch_rob_in.stall[packet_idx] = 1'b0;
        expected_dispatch_freelist_out.new_pr_en[packet_idx] = 1'b1;
        for (int i = packet_idx; i < 3; i++) begin
            expected_dispatch_rs_out[i].enable  = 1'b1;
            expected_dispatch_rob_out[i].enable = 1'b1;
            expected_dispatch_maptable_out[i].enable = 1'b1;
        end
        expected_dispatch_fetch_out = 0;
        verify_answer();

        $display("@@@ Test %1d: r2 is ready", test);
        dispatch_maptable_in.done[4] = 1'b1;
        expected_dispatch_rs_out[packet_idx].reg2_ready = 1'b1;
        verify_answer();

        $display("@@@ Test %1d: both sources are ready", test);
        dispatch_maptable_in.done[7] = 1'b1;
        dispatch_rob_in.new_entry_idx[packet_idx] = 4'd4;
        expected_dispatch_rs_out[packet_idx].reg1_ready = 1'b1;
        expected_dispatch_rs_out[packet_idx].rob_idx = 4'd4;
        verify_answer();
    end endtask

    task verify_answer;
        @(negedge clock);
        for (int i = 0; i < 3; i++)
            if (expected_dispatch_rs_out[i].valid)
                rs_correct[i] = (dispatch_rs_out[i].inst.r.rs1 == expected_dispatch_rs_out[i].inst.r.rs1 &
                                 dispatch_rs_out[i].inst.r.rs2 == expected_dispatch_rs_out[i].inst.r.rs2 &
                                 dispatch_rs_out[i].inst.r.rd == expected_dispatch_rs_out[i].inst.r.rd &
                                 dispatch_rs_out[i].reg1_pr_idx == expected_dispatch_rs_out[i].reg1_pr_idx &
                                 dispatch_rs_out[i].reg2_pr_idx == expected_dispatch_rs_out[i].reg2_pr_idx &
                                 dispatch_rs_out[i].reg1_ready == expected_dispatch_rs_out[i].reg1_ready &
                                 dispatch_rs_out[i].reg2_ready == expected_dispatch_rs_out[i].reg2_ready &
                                 dispatch_rs_out[i].pr_idx == expected_dispatch_rs_out[i].pr_idx &
                                 dispatch_rs_out[i].rob_idx == expected_dispatch_rs_out[i].rob_idx &
                                 dispatch_rs_out[i].valid == expected_dispatch_rs_out[i].valid &
                                 dispatch_rs_out[i].enable == expected_dispatch_rs_out[i].enable);
            else rs_correct[i] = ~dispatch_rs_out[i].valid;
        #1;

        if (~correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);

            $display("Inputs:");

            $display("\tvalid instructions from fetch:");
            for (int i = 0; i < 3; i++)
                if (dispatch_fetch_in[i].valid)
                    $display("\t\tdispatch_fetch_in[%1d]: inst:%h rs1:%2d rs2:%2d rd:%2d",
                        i, dispatch_fetch_in[i].inst, dispatch_fetch_in[i].inst.r.rs1, 
                        dispatch_fetch_in[i].inst.r.rs2, dispatch_fetch_in[i].inst.r.rd);

            $display("\tdispatch_rob_in.stall:%b dispatch_rs_in.stall:%b branch_flush_en:%b", 
                dispatch_rob_in.stall, dispatch_rs_in.stall, branch_flush_en);

            for (int i = 0; i < 3; i++)
                $display("\tdispatch_rob_in.new_entry_idx[%1d]:%2d", i, dispatch_rob_in.new_entry_idx[i]);

            $display("\tvalid freelist registers:");
            for (int i = 0; i < 3; i++)
                if (dispatch_freelist_in.valid[i])
                    $display("\tdispatch_freelist_in.t_idx[%1d]:%2d", i, dispatch_freelist_in.t_idx[i]);

            $display("\tdone maptable entries:");
            for (int i = 0; i < `N_ARCH_REG; i++)
                if (dispatch_maptable_in.done[i])
                    $display("\tdispatch_maptable_in[%1d].map: %2d", i, dispatch_maptable_in.map[i]);

            $display("Outputs:");

            if (dispatch_freelist_out === expected_dispatch_freelist_out)
                $display("\tcorrect dispatch_freelist_out: new_pr_en:%b", dispatch_freelist_out.new_pr_en);
            else begin
                $display("\tincorrect dispatch_freelist_out: new_pr_en:%b", dispatch_freelist_out.new_pr_en);
                $display("\t\texpected:%b", expected_dispatch_freelist_out.new_pr_en);
            end

            if (dispatch_fetch_out === expected_dispatch_fetch_out) 
                $display("\tcorrect dispatch_fetch_out: first_stall_idx:%2d enable:%b",
                    dispatch_fetch_out.first_stall_idx, dispatch_fetch_out.enable);
            else begin
                $display("\tincorrect dispatch_fetch_out: first_stall_idx:%2d enable:%b",
                    dispatch_fetch_out.first_stall_idx, dispatch_fetch_out.enable);
                $display("\t\texpected: first_stall_idx:%2d enable:%b",
                    expected_dispatch_fetch_out.first_stall_idx, expected_dispatch_fetch_out.enable);
            end

            for (int i = 0; i < 3; i++) begin
                if (dispatch_rob_out[i] === expected_dispatch_rob_out[i]) 
                    $display("\tcorrect dispatch_rob_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d enable:%b valid:%b", 
                        i, dispatch_rob_out[i].t_idx, dispatch_rob_out[i].told_idx,
                        dispatch_rob_out[i].ar_idx, dispatch_rob_out[i].enable,
                        dispatch_rob_out[i].valid);
                else begin
                    $display("\tincorrect dispatch_rob_out[%1d]: t_idx:%2d told_idx:%2d ar_idx:%2d enable:%b valid:%b", 
                        i, dispatch_rob_out[i].t_idx, dispatch_rob_out[i].told_idx,
                        dispatch_rob_out[i].ar_idx, dispatch_rob_out[i].enable,
                        dispatch_rob_out[i].valid);
                    $display("\t\texpected: t_idx:%2d told_idx:%2d ar_idx:%2d enable:%b valid:%b", 
                        expected_dispatch_rob_out[i].t_idx, expected_dispatch_rob_out[i].told_idx,
                        expected_dispatch_rob_out[i].ar_idx, expected_dispatch_rob_out[i].enable,
                        expected_dispatch_rob_out[i].valid);
                end
            end

            for (int i = 0; i < 3; i++) begin
                if (dispatch_maptable_out[i] === expected_dispatch_maptable_out[i]) 
                    $display("\tcorrect dispatch_maptable_out[%1d]: pr_idx:%2d ar_idx:%2d enable:%b", 
                        i, dispatch_maptable_out[i].pr_idx, dispatch_maptable_out[i].ar_idx, 
                        dispatch_maptable_out[i].enable);
                else begin
                    $display("\tincorrect dispatch_maptable_out[%1d]: pr_idx:%2d ar_idx:%2d enable:%b", 
                        i, dispatch_maptable_out[i].pr_idx, dispatch_maptable_out[i].ar_idx, 
                        dispatch_maptable_out[i].enable);
                    $display("\t\texpected: pr_idx:%2d ar_idx:%2d enable:%b", 
                        expected_dispatch_maptable_out[i].pr_idx, expected_dispatch_maptable_out[i].ar_idx, 
                        expected_dispatch_maptable_out[i].enable);
                end
            end

            for (int i = 0; i < 3; i++) begin
                if (dispatch_rs_out[i].inst === expected_dispatch_rs_out[i].inst)
                    $display("\tcorrect dispatch_rs_out[%1d].inst: rs1:%2d rs2:%2d rd:%2d", 
                        i, dispatch_rs_out[i].inst.r.rs1,
                        dispatch_rs_out[i].inst.r.rs2, dispatch_rs_out[i].inst.r.rd);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].inst: rs1:%2d rs2:%2d rd:%2d", 
                        i, dispatch_rs_out[i].inst.r.rs1,
                        dispatch_rs_out[i].inst.r.rs2, dispatch_rs_out[i].inst.r.rd);
                    $display("\t\texpected: rs1:%2d rs2:%2d rd:%2d", 
                        expected_dispatch_rs_out[i].inst.r.rs1,
                        expected_dispatch_rs_out[i].inst.r.rs2, expected_dispatch_rs_out[i].inst.r.rd);
                end
                if (dispatch_rs_out[i].reg1_pr_idx === expected_dispatch_rs_out[i].reg1_pr_idx)
                    $display("\tcorrect dispatch_rs_out[%1d].reg1_pr_idx:%2d", i, dispatch_rs_out[i].reg1_pr_idx);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].reg1_pr_idx:%2d", i, dispatch_rs_out[i].reg1_pr_idx);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].reg1_pr_idx);
                end
                if (dispatch_rs_out[i].reg2_pr_idx === expected_dispatch_rs_out[i].reg2_pr_idx)
                    $display("\tcorrect dispatch_rs_out[%1d].reg2_pr_idx:%2d", i, dispatch_rs_out[i].reg2_pr_idx);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].reg2_pr_idx:%2d", i, dispatch_rs_out[i].reg2_pr_idx);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].reg2_pr_idx);
                end
                if (dispatch_rs_out[i].reg1_ready === expected_dispatch_rs_out[i].reg1_ready)
                    $display("\tcorrect dispatch_rs_out[%1d].reg1_ready:%b", i, dispatch_rs_out[i].reg1_ready);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].reg1_ready:%b", i, dispatch_rs_out[i].reg1_ready);
                    $display("\t\texpected:%b", expected_dispatch_rs_out[i].reg1_ready);
                end
                if (dispatch_rs_out[i].reg2_ready === expected_dispatch_rs_out[i].reg2_ready)
                    $display("\tcorrect dispatch_rs_out[%1d].reg2_ready:%b", i, dispatch_rs_out[i].reg2_ready);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].reg2_ready:%b", i, dispatch_rs_out[i].reg2_ready);
                    $display("\t\texpected:%b", expected_dispatch_rs_out[i].reg2_ready);
                end
                if (dispatch_rs_out[i].pr_idx === expected_dispatch_rs_out[i].pr_idx)
                    $display("\tcorrect dispatch_rs_out[%1d].pr_idx:%2d", i, dispatch_rs_out[i].pr_idx);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].pr_idx:%2d", i, dispatch_rs_out[i].pr_idx);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].pr_idx);
                end
                if (dispatch_rs_out[i].rob_idx === expected_dispatch_rs_out[i].rob_idx)
                    $display("\tcorrect dispatch_rs_out[%1d].rob_idx:%2d", i, dispatch_rs_out[i].rob_idx);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].rob_idx:%2d", i, dispatch_rs_out[i].rob_idx);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].rob_idx);
                end
                if (dispatch_rs_out[i].valid === expected_dispatch_rs_out[i].valid)
                    $display("\tcorrect dispatch_rs_out[%1d].valid:%b", i, dispatch_rs_out[i].valid);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].valid:%b", i, dispatch_rs_out[i].valid);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].valid);
                end    
                if (dispatch_rs_out[i].enable === expected_dispatch_rs_out[i].enable)
                    $display("\tcorrect dispatch_rs_out[%1d].enable:%b", i, dispatch_rs_out[i].enable);
                else begin
                    $display("\tincorrect dispatch_rs_out[%1d].enable:%b", i, dispatch_rs_out[i].enable);
                    $display("\t\texpected:%2d", expected_dispatch_rs_out[i].enable);
                end    
            end 
            //$finish;
        end

        $display("@@@ Passed Test %1d!", test);
        test++;
    endtask : verify_answer

endmodule  // dispatch_testbench