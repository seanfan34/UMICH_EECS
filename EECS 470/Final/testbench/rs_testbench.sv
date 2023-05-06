//TESTBENCH FOR reservation station
//Class:    EECS470
//Specific:  Project 4
//Description:

module rs_testbench;
    logic clock, reset;

    DISPATCH_RS_PACKET [`SUPERSCALAR_WAYS-1:0]                      rs_dispatch_in;
    CDB_PACKET                                                      rs_cdb_in;
    FU_RS_PACKET                                              rs_fu_in;
    RS_ISSUE_PACKET     [`SUPERSCALAR_WAYS-1:0]                     rs_issue_out;
    RS_DISPATCH_PACKET                                              rs_dispatch_out;
`ifdef TEST_MODE
    DISPATCH_RS_PACKET [`N_RS_ENTRIES-1:0]                          rs_table ;
`endif

    RS_ISSUE_PACKET     [`SUPERSCALAR_WAYS-1:0]                     expected_rs_issue_out;
    // logic               [`SUPERSCALAR_WAYS-1:0]                     expected_stall;

    logic correct;
    int test;
    bit [`SUPERSCALAR_WAYS-1:0] random_num;

    rs rs_tb( .clock(clock), .reset(reset),
        .rs_dispatch_in(rs_dispatch_in),
        .rs_cdb_in(rs_cdb_in),
        .rs_fu_in(rs_fu_in),
        .rs_issue_out(rs_issue_out),
        .rs_dispatch_out(rs_dispatch_out)
`ifdef TEST_MODE
        , .rs_table(rs_table)
`endif
    );


    // assign correct = (freelist_dispatch_packet === expected_freelist_dispatch_packet);

    always begin
        #(`VERILOG_CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    initial begin
        $dumpvars;
        //$monitor("MONITOR:\ttail:%d n_tail:%d", tail, n_tail);
`ifdef TEST_MODE
        $display("\nTEST Mode Enabled \n");
`endif
        $display("INITIALIZING FREELIST TESTBENCH");
        test = 0;
        clock = 0;
        reset = 1;
        correct = 1;
        rs_dispatch_in = 0;
        rs_cdb_in = 0;
        rs_fu_in = 0;
        expected_rs_issue_out = 0;

        @(negedge clock)
        reset = 0;

        $display("@@@ Test %1d: Reset the ROB", test);
        verify_answer();

        run_single_packet_tests(0);

        @(negedge clock)
        reset = 1;
        @(negedge clock)
        reset = 0;

        run_multi_packet_tests;

        $display("\nENDING RS TESTBENCH: SUCCESS!\n");
        $finish;
    end


    task run_single_packet_tests; input int packet_idx; begin
        $display("RUNNING SINGLE INPUT TESTS WITH PACKET %d", packet_idx);
        $display("@@@ Test %1d: Dispatch valid instruction to empty ROB", test);

        //Test 1 Valid & both sources are ready --------------------
        rs_dispatch_in[packet_idx].valid = 1;
        rs_dispatch_in[packet_idx].fu_sel = ALU_1;
        rs_dispatch_in[packet_idx].pr_idx = 6'd1;
        rs_dispatch_in[packet_idx].reg1_pr_idx = 6'd2;
        rs_dispatch_in[packet_idx].reg1_ready = 1'b1;
        rs_dispatch_in[packet_idx].reg2_pr_idx = 6'd3;
        rs_dispatch_in[packet_idx].reg2_ready = 1'b1;

        //Expected

        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd1;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd2;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd3;

        // expected_stall = 0;

        @(negedge clock);
        correct = ( rs_issue_out[2] == expected_rs_issue_out[2]);

        verify_answer();

        //Test 2 Valid & both sources are ready --------------------
        rs_dispatch_in[packet_idx].valid = 1;
        rs_dispatch_in[packet_idx].fu_sel = ALU_1;
        rs_dispatch_in[packet_idx].pr_idx = 6'd4;

        rs_dispatch_in[packet_idx].reg1_pr_idx = 6'd5;
        rs_dispatch_in[packet_idx].reg1_ready = 1'b1;

        rs_dispatch_in[packet_idx].reg2_pr_idx = 6'd6;
        rs_dispatch_in[packet_idx].reg2_ready = 1'b1;

        //Expected

        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd4;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd5;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd6;

        @(negedge clock);
        correct = ( rs_issue_out[2] == expected_rs_issue_out[2]) ;
        verify_answer();

        //Test 3 Valid but onㄍ source are not ready --------------------
        rs_dispatch_in[packet_idx].valid = 1;
        rs_dispatch_in[packet_idx].fu_sel = ALU_1;
        rs_dispatch_in[packet_idx].pr_idx = 6'd7;

        rs_dispatch_in[packet_idx].reg1_pr_idx = 6'd8;
        rs_dispatch_in[packet_idx].reg1_ready = 1'b0;

        rs_dispatch_in[packet_idx].reg2_pr_idx = 6'd9;
        rs_dispatch_in[packet_idx].reg2_ready = 1'b1;

        //Expected
        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd7;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd8;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd9;

        @(negedge clock);
        correct = ( rs_issue_out[packet_idx] != expected_rs_issue_out[0]
        `ifdef TEST_MODE
            && rs_dispatch_in[packet_idx] == rs_table[13]
        `endif
            ) ;
        verify_answer();

        //Test 4 folllowed by CDB

        rs_cdb_in.t_idx[0] = 6'd8;
        //Expected
        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd7;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd8;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd9;
        @(negedge clock);
        correct = ( rs_issue_out[0] == expected_rs_issue_out[0]) ;
        verify_answer();

        @(negedge clock);
        rs_cdb_in = 0;
        @(negedge clock);

        //Test 5 if FU units are full
        rs_fu_in.alu_1 = 1'b1;

        rs_dispatch_in[packet_idx].valid = 1;
        rs_dispatch_in[packet_idx].fu_sel = ALU_1;
        rs_dispatch_in[packet_idx].pr_idx = 6'd10;
        rs_dispatch_in[packet_idx].reg1_pr_idx = 6'd11;
        rs_dispatch_in[packet_idx].reg1_ready = 1'b1;
        rs_dispatch_in[packet_idx].reg2_pr_idx = 6'd12;
        rs_dispatch_in[packet_idx].reg2_ready = 1'b1;

        //Expected
        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd10;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd11;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd12;
        // ALthough it is ALU_1, in the FU stage it will be fed to alu2


        @(negedge clock);
        correct = ( rs_issue_out[0] == expected_rs_issue_out[0]
            ) ;
        verify_answer();

        @(negedge clock);
        rs_fu_in = 0;
        @(negedge clock);


    end
    endtask

    task run_multi_packet_tests; begin
        $display("RUNNING multi INPUT TESTS",);

        correct = 1;
        rs_dispatch_in = 0;
        rs_cdb_in = 0;
        rs_fu_in = 0;
        expected_rs_issue_out = 0;
        // expected_stall = 0;

        @(negedge clock);


        //Test 5 Normal Test
        rs_dispatch_in[0].valid = 1;
        rs_dispatch_in[0].fu_sel = ALU_1;
        rs_dispatch_in[0].pr_idx = 6'd1;
        rs_dispatch_in[0].reg1_pr_idx = 6'd10;
        rs_dispatch_in[0].reg1_ready = 1'b1;
        rs_dispatch_in[0].reg2_pr_idx = 6'd11;
        rs_dispatch_in[0].reg2_ready = 1'b1;

        rs_dispatch_in[1].valid = 1;
        rs_dispatch_in[1].fu_sel = ALU_1;
        rs_dispatch_in[1].pr_idx = 6'd2;
        rs_dispatch_in[1].reg1_pr_idx = 6'd20;
        rs_dispatch_in[1].reg1_ready = 1'b1;
        rs_dispatch_in[1].reg2_pr_idx = 6'd21;
        rs_dispatch_in[1].reg2_ready = 1'b1;

        rs_dispatch_in[2].valid = 1;
        rs_dispatch_in[2].fu_sel = ALU_1;
        rs_dispatch_in[2].pr_idx = 6'd3;
        rs_dispatch_in[2].reg1_pr_idx = 6'd40;
        rs_dispatch_in[2].reg1_ready = 1'b1;
        rs_dispatch_in[2].reg2_pr_idx = 6'd40;
        rs_dispatch_in[2].reg2_ready = 1'b1;


        //Expected

        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd1;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd10;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd11;

        expected_rs_issue_out[1].valid = 1;
        expected_rs_issue_out[1].fu_sel = ALU_1;
        expected_rs_issue_out[1].pr_idx = 6'd2;
        expected_rs_issue_out[1].reg1_pr_idx = 6'd20;
        expected_rs_issue_out[1].reg2_pr_idx = 6'd21;

        expected_rs_issue_out[2].valid = 1;
        expected_rs_issue_out[2].fu_sel = ALU_1;
        expected_rs_issue_out[2].pr_idx = 6'd3;
        expected_rs_issue_out[2].reg1_pr_idx = 6'd40;
        expected_rs_issue_out[2].reg2_pr_idx = 6'd40;


        // expected_stall = 0;

        @(negedge clock);
        correct = ( rs_issue_out[0] == expected_rs_issue_out[0] &&
                    rs_issue_out[1] == expected_rs_issue_out[1] &&
                    rs_issue_out[2] == expected_rs_issue_out[2]
            ) ;
`ifdef TEST_MODE


        for (int i = 0; i < `N_RS_ENTRIES; i = i + 1)
            $display("\RS Table [%d]: valid:%b pr_idx:%d reg1_pr_idx:%d  reg1_ready:%b  reg2_pr_idx:%d reg2_ready:%b",
                i,
                rs_table[i].valid,
                rs_table[i].pr_idx,
                rs_table[i].reg1_pr_idx,
                rs_table[i].reg1_ready,
                rs_table[i].reg2_pr_idx,
                rs_table[i].reg2_ready,
                );
`endif

        verify_answer();


        @(negedge clock);
        reset = 1'b1;
        @(negedge clock);
        reset = 1'b0;

        //Test 6 alu_2 is not full but mult_1 and mult_2 are busy
        rs_fu_in.alu_2 = 1'b0;
        rs_fu_in.mult_1 = 1'b1;
        rs_fu_in.mult_2 = 1'b1;

        rs_dispatch_in[0].valid = 1;
        rs_dispatch_in[0].fu_sel = ALU_1;
        rs_dispatch_in[0].pr_idx = 6'd1;
        rs_dispatch_in[0].reg1_pr_idx = 6'd10;
        rs_dispatch_in[0].reg1_ready = 1'b1;
        rs_dispatch_in[0].reg2_pr_idx = 6'd11;
        rs_dispatch_in[0].reg2_ready = 1'b1;

        rs_dispatch_in[1].valid = 1;
        rs_dispatch_in[1].fu_sel = MULT_1;
        rs_dispatch_in[1].pr_idx = 6'd2;
        rs_dispatch_in[1].reg1_pr_idx = 6'd20;
        rs_dispatch_in[1].reg1_ready = 1'b1;
        rs_dispatch_in[1].reg2_pr_idx = 6'd21;
        rs_dispatch_in[1].reg2_ready = 1'b1;

        rs_dispatch_in[2].valid = 1;
        rs_dispatch_in[2].fu_sel = MULT_1;
        rs_dispatch_in[2].pr_idx = 6'd3;
        rs_dispatch_in[2].reg1_pr_idx = 6'd40;
        rs_dispatch_in[2].reg1_ready = 1'b1;
        rs_dispatch_in[2].reg2_pr_idx = 6'd40;
        rs_dispatch_in[2].reg2_ready = 1'b1;


        //Expected

        expected_rs_issue_out[0].valid = 1;
        expected_rs_issue_out[0].fu_sel = ALU_1;
        expected_rs_issue_out[0].pr_idx = 6'd1;
        expected_rs_issue_out[0].reg1_pr_idx = 6'd10;
        expected_rs_issue_out[0].reg2_pr_idx = 6'd11;

        expected_rs_issue_out[1].valid = 1;
        expected_rs_issue_out[1].fu_sel = MULT_1;
        expected_rs_issue_out[1].pr_idx = 6'd2;
        expected_rs_issue_out[1].reg1_pr_idx = 6'd20;
        expected_rs_issue_out[1].reg2_pr_idx = 6'd21;

        expected_rs_issue_out[2].valid = 1;
        expected_rs_issue_out[2].fu_sel = MULT_1;
        expected_rs_issue_out[2].pr_idx = 6'd3;
        expected_rs_issue_out[2].reg1_pr_idx = 6'd40;
        expected_rs_issue_out[2].reg2_pr_idx = 6'd40;


        // expected_stall = 0;

        @(negedge clock);
        correct = ( rs_issue_out[0] == expected_rs_issue_out[0] &&
            rs_issue_out[1].valid == 0 &&
            rs_issue_out[2].valid == 0
            ) ;
        verify_answer();

        @(negedge clock);
        rs_fu_in = 0;
        @(negedge clock);

    end
    endtask



    task verify_answer; begin
        // @(negedge clock);
        if (!correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ Inputs:\n\treset:%b", reset);

            // Print Dispatch RS packet input
            for (int i = 0; i < 3; i = i + 1)
                $display("\trs_dispatch_in[%d]: valid:%b pr_idx:%d reg1_pr_idx:%d  reg1_ready:%b  reg2_pr_idx:%d reg2_ready:%b ",
                            i,
                            rs_dispatch_in[i].valid,
                            rs_dispatch_in[i].pr_idx,
                            rs_dispatch_in[i].reg1_pr_idx,
                            rs_dispatch_in[i].reg1_ready,
                            rs_dispatch_in[i].reg2_pr_idx,
                            rs_dispatch_in[i].reg2_ready
                        );

            // Print CDB packet input

            $display("\trs_cdb_in: t0:%d  t1:%d t2:%d ",
                    rs_cdb_in.t_idx[0],
                    rs_cdb_in.t_idx[1],
                    rs_cdb_in.t_idx[2]
            );

            // Print FU_IN_USE_PACKET input

            $display("\tfu_in_use_packet alu_1:%b  alu_2:%b alu_2:%b mult_1:%b mult_2:%b branch_1:%b ",
                rs_fu_in.alu_1,
                rs_fu_in.alu_2,
                rs_fu_in.alu_3,
                rs_fu_in.mult_1,
                rs_fu_in.mult_2,
                rs_fu_in.branch_1,
                );




            $display("@@@ Outputs:");

            // Print rs_issue_out output
            for (int i = 0; i < 3; i = i + 1)
                $display("\trs_issue_out[%d]: valid:%b pr_idx:%d reg1_pr_idx:%d reg2_pr_idx:%d ",
                    i,
                    rs_issue_out[i].valid,
                    rs_issue_out[i].pr_idx,
                    rs_issue_out[i].reg1_pr_idx,
                    rs_issue_out[i].reg2_pr_idx,
                    );

            $display("@@@ Expected outputs:");
            // Print rs_issue_out output
            for (int i = 0; i < 3; i = i + 1)
                $display("\texpected_rs_issue_out[%d]: valid:%b pr_idx:%d reg1_pr_idx:%d reg2_pr_idx:%d ",
                    i,
                    expected_rs_issue_out[i].valid,
                    expected_rs_issue_out[i].pr_idx,
                    expected_rs_issue_out[i].reg1_pr_idx,
                    expected_rs_issue_out[i].reg2_pr_idx,
                    );

            //Print rs_dispatch_out
            $display("\trs_dispatch_out.stall:%b", rs_dispatch_out);

            // for(int i=0;i < 3; i++)
            //     $display("\texpected_stall[%d]: stall:%b",i, expected_stall[i]);


            //Print RS TABLE
`ifdef TEST_MODE


            for (int i = 0; i < `N_RS_ENTRIES; i = i + 1)
                $display("\RS Table [%d]: valid:%b pr_idx:%d reg1_pr_idx:%d  reg1_ready:%b  reg2_pr_idx:%d reg2_ready:%b",
                i,
                    rs_table[i].valid,
                    rs_table[i].pr_idx,
                    rs_table[i].reg1_pr_idx,
                    rs_table[i].reg1_ready,
                    rs_table[i].reg2_pr_idx,
                    rs_table[i].reg2_ready,
                );
`endif

        end
        else
            $display("@@@ Passed Test %1d!", test);
        test = test + 1;
    end
    endtask

endmodule
