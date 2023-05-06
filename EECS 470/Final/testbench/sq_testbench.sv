`define TEST_MODE

module testbench;
logic                 clock, reset;
// Dispatch
logic [2:0]           dispatch_store;
logic [2:0]           dispatch_stall;
logic [2:0][2:0]      dispatch_idx;

// RS
logic [7:0]           load_tail_ready;

// alu store
logic [2:0]           alu_valid;
SQ_ENTRY_PACKET [2:0] alu_store;
logic [2:0][2:0]      alu_idx;

// fu load
LOAD_SQ_PACKET [1:0]  load_lookup;
SQ_LOAD_PACKET [1:0]  load_forward;

// Retire
logic [2:0]           retire_store;
SQ_ENTRY_PACKET [2:0] cache_wb;

// Display
SQ_ENTRY_PACKET [0:7] sq_reg_display;
logic [2:0]           head_display, tail_display;
logic [2:0]           empty_entries_num_display;
SQ_ENTRY_PACKET [7:0] older_store_display;
logic [7:0]           older_store_valid_display;
logic [1:0]           num_dispatch_store_display, num_retire_store_display;

logic [2:0]           dispatch_request;
logic [`N_LSQ_ENTRIES_BITS-1:0]                      filled_entries_num_display;


sq sq1(
    .clock(clock),
    .reset(reset),
    .dispatch_store(dispatch_store),
    .dispatch_stall(dispatch_stall),
    .dispatch_idx(dispatch_idx),
    .load_tail_ready(load_tail_ready),
    .alu_valid(alu_valid),
    .alu_store(alu_store),
    .alu_idx(alu_idx),
    .load_lookup(load_lookup),
    .load_forward(load_forward),
    .retire_store(retire_store),
    .cache_wb(cache_wb),
    .sq_reg_display(sq_reg_display),
    .head_display(head_display),
    .tail_display(tail_display),
    .empty_entries_num_display(empty_entries_num_display),
    .older_store_display(older_store_display),
    .older_store_valid_display(older_store_valid_display),
    .num_dispatch_store_display(num_dispatch_store_display),
    .num_retire_store_display(num_retire_store_display)
    // .filled_entries_num_display(filled_entries_num_display)
);

int cycle_count;
always begin 
        #(`VERILOG_CLOCK_PERIOD/2.0);
        clock = ~clock; 
end 
always@(posedge clock) begin
   cycle_count++; 
end


task show_sq;
    $display("==== show sq ===");
    $display("HEAD: %d, Tail: %d, Filled num", head_display, tail_display);
    $display("empty num: %d, dispatch num: %d, retire num: %d", empty_entries_num_display, num_dispatch_store_display, num_retire_store_display);
    $display(" |ready|   addr   |usebytes|   data   |");
    for(int i = 0; i < 8; i=i+1) begin
        $display("%1d|  %d  | %8h |  %4b  | %8h |", i, sq_reg_display[i].ready, sq_reg_display[i].addr, sq_reg_display[i].usebytes, sq_reg_display[i].data);
    end
endtask

task show_older_stores;
    $display("=== show older stores ===");
    $display("##### older stores, tail_idx at %d", load_lookup[0].tail_idx);
    $display(" |valid|ready|   addr   |usebytes|   data   |");
    for(int i = 0; i < 8; i=i+1) begin
        $display("%1d|  %d  |  %d  | %8h |  %4b  | %8h |", i, older_store_valid_display[i], older_store_display[i].ready, older_store_display[i].addr, older_store_display[i].usebytes, older_store_display[i].data);
    end
endtask

task show_load_forward;
    $display("=== show load forward ===");
    $display("LOAD forward: ");
    $display("LOAD1: stall: %b, usebyptes: %4b, data: %h", load_forward[0].stall, load_forward[0].usebytes, load_forward[0].data);
    $display("LOAD2: stall: %b, usebyptes: %4b, data: %h", load_forward[1].stall, load_forward[1].usebytes, load_forward[1].data);
endtask

always @(negedge clock) begin
    $display(" =============== cycle %d ==============", cycle_count);
    $display("reset: %b", reset);
    show_sq;
    show_older_stores;
    show_load_forward;
    $display("dispatch_store: %3b return idx: %d, %d, %d stall： %3b", dispatch_store, dispatch_idx[2], dispatch_idx[1], dispatch_idx[0], dispatch_stall);
    $display("retire_store: %3b retire addr| %h | %h | %h |", retire_store, cache_wb[2].addr, cache_wb[1].addr, cache_wb[0].addr);
    $display("");
end

always @(dispatch_request, dispatch_stall) begin
    dispatch_store = dispatch_request & ~dispatch_stall;
end

initial begin
    $dumpvars;
    clock = 0;
    reset = 1;
    cycle_count = 0;
    alu_valid = 0;
    alu_store = 0;
    retire_store = 0;
    dispatch_request = 0;
    

    @(negedge clock)
    @(negedge clock)
    #1;
    reset = 0;
    dispatch_request = 3'b101;
    load_lookup[0].tail_idx = 0;
    $display("GOLDEN: head 0, tail 0, empty_num 8");
    @(posedge clock)

    dispatch_request = 3'b101;
    $display("GOLDEN: head 0, tail 2, empty_num 6");
    @(posedge clock)

    dispatch_request = 3'b101;
    $display("GOLDEN: head 0, tail 4, empty_num 4");
    @(posedge clock)

    load_lookup[0].tail_idx = 4;
    load_lookup[0].addr = 32'hc0;
    dispatch_request = 3'b101;
    $display("GLODEN: head 0, tail 6, empty_num 2, stall: 001");
    @(posedge clock)

    dispatch_request = 3'b101;
    $display("GLODEN: head 0, tail 7, empty_num 0, stall: 111");
    @(posedge clock)

    dispatch_request = 3'b101;
    $display("GLODEN: head 0, tail 7, empty_num 0, stall: 111");
    @(posedge clock)

    dispatch_request = 3'b101;
    $display("GLODEN: head 0, tail 7, empty_num 0, stall: 111");
    #1;
    alu_valid = 3'b111;
    alu_idx[1] = 0;
    alu_idx[0] = 5;
    alu_idx[2] = 3;
    alu_store[0].usebytes = 4'b0011;
    alu_store[0].ready = 1;
    alu_store[0].addr = 32'hff;
    alu_store[0].data = 32'h00002345;
    alu_store[1].usebytes = 4'b1111;
    alu_store[1].ready = 1;
    alu_store[1].addr = 32'hbc;
    alu_store[1].data = 32'h87ffffff;
    alu_store[2].usebytes = 4'b0001;
    alu_store[2].ready = 1;
    alu_store[2].addr = 32'hc0;
    alu_store[2].data = 32'hffffff21;
    @(posedge clock)

    dispatch_request = 3'b100;
    retire_store = 3'b010;
    $display("GLODEN: head 0, tail 7, empty_num 0, stall: 111");
    #1;
    alu_store[0].addr = 32'hf1;
    alu_store[1].addr = 32'hc0;
    alu_store[2].addr = 32'hc1;
    alu_idx[1] = 1;
    alu_store[1].data = 32'hff65ffff;
    alu_store[1].usebytes = 4'b0100;
    alu_idx[0] = 2;
    alu_store[0].data = 32'hffff43ff;
    alu_store[0].usebytes = 4'b0011;
    alu_idx[2] = 4;
    alu_store[2].data = 32'hffffffff;
    @(posedge clock)

    dispatch_request = 3'b000;
    retire_store = 3'b010;
    $display("GLODEN: head 1, tail 0, empty_num 1, stall: 111");
    #1;
    alu_store[0].addr = 32'hf2;
    alu_store[1].addr = 32'hb2;
    alu_idx[1] = 6;
    alu_idx[0] = 7;
    alu_valid[2] = 0;
    @(posedge clock)

    retire_store = 3'b110;
    $display("GLODEN: head 2, tail 0, empty_num 2, stall: 001");
    #1;
    alu_valid = 0;
    @(posedge clock)

    retire_store = 3'b110;
    $display("GLODEN: head 4, tail 0, empty_num 4, stall: 000");
    @(posedge clock)

    retire_store = 3'b100;
    $display("GLODEN: head 6, tail 0, empty_num 6, stall: 000");
    #1;
    load_lookup[0].tail_idx = 0;
    @(posedge clock)

    retire_store = 3'b100;
    $display("GLODEN: head 7, tail 0, empty_num 7, stall: 000");
    @(posedge clock)

    retire_store = 3'b100;
    $display("GLODEN: head 0, tail 0, empty_num 8, stall: 000");
    @(posedge clock)

    $display("@@@@@@@@finish");
    $finish;
end

endmodule