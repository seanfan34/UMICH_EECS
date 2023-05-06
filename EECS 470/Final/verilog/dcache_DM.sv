// dcache sys_defs start
`define N 			  3 // Ideal - 3/4/5 3-way Superscaler width

`define BLOCK_SIZE_DM 8 //bytes FIXED
`define BLOCK_OFFSET_BITS_DM $clog2(`BLOCK_SIZE_DM)

`define CACHESIZE_DM 256 // FIXED but can do less
`define LINES_DM `CACHESIZE_DM/`BLOCK_SIZE_DM
`define LINE_SIZE_DM $clog2(`LINES_DM) // Line index

`define TAG_SIZE_DM 16-`LINE_SIZE_DM-`BLOCK_OFFSET_BITS_DM // FIXED=8 ; 16 as first 16 bits are ignored since mem is 64k

typedef struct packed {
	logic [`TAG_SIZE_DM-1:0]    tag;
	logic [63:0] 				data;
	logic 						dirty;
	logic 						valid;
} DCACHE_DM;
// dcache sys_defs end


`timescale 1ns/100ps

`define DEBUG 1

module dcache_DM ( // DM = Direct mapped
    input clock,
    input reset,
    input enable,

    // inputs from memory
    input [3:0]     mem2Dcache_response,
    input [63:0]    mem2Dcache_data,
    input [3:0]     mem2Dcache_tag,

    // inputs from pipeline
    input [`XLEN-1:0]   proc2Dcache_addr,
    input MEM_SIZE      proc2Dcache_size,
    input [1:0]         proc2Dcache_command, 
    input [`XLEN-1:0]   proc2Dcache_data, 
    input               proc2Dcache_valid,

    // output to memory
    output logic [1:0]          Dcache2mem_command,
    output logic [`XLEN-1:0]    Dcache2mem_addr,
    output logic [63:0]         Dcache2mem_data,

    // output to pipeline
    output logic [63:0]     Dcache_data_out,
    output logic            Dcache_valid_out,    

    // output to victim cache (VC) - evicted data // NOT USED
    output logic [`XLEN-1:0]   Dcache_addr_evicted_VC,
    output logic [63:0]        Dcache_data_evicted_VC,
    output logic               Dcache_evicted_valid_VC,

    // dont use memory in the same cycle if this is one // stall from PE till RS and ROB do not retire store since no new store should come in
    output logic Dcache_needs_memory,

    // to testbench as writeback cache - for program.out 
    output DCACHE_DM [`LINES_DM-1:0] testbench_dcache_dm

    // Debug signals
	`ifdef DEBUG
		,
        output logic [`TAG_SIZE_DM-1:0] _current_dcache_tag, _last_dcache_tag,
        output logic [`LINE_SIZE_DM-1:0] _current_dcache_line, _last_dcache_line,
        output logic [`BLOCK_OFFSET_BITS_DM-1:0] _current_block_offset,
        output logic [3:0] _saved_memTag,
        output logic _miss_outstanding
    `endif
);

    DCACHE_DM [`LINES_DM-1:0] dcache_dm; // 32 entries/lines, each 8 block, each block 1 byte, 8 bits tag, 1 valid, 1 dirty, 5 bits to index

    EXAMPLE_CACHE_BLOCK c;

    logic [63:0] temp_dcache_data;

    logic internal_Dcache_needs_memory, internal_Dcache2mem_command_load, internal_Dcache2mem_command_store;
    assign Dcache_needs_memory = internal_Dcache_needs_memory;

    logic [3:0] saved_memTag;

    // spliting the proc2Dcache_addr
    logic [`TAG_SIZE_DM-1:0] current_dcache_tag, last_dcache_tag;
    logic [`LINE_SIZE_DM-1:0] current_dcache_line, last_dcache_line;
    logic [`BLOCK_OFFSET_BITS_DM-1:0] current_block_offset;
    assign {current_dcache_tag, current_dcache_line, current_block_offset} = proc2Dcache_addr[15:0];
    
    // send req to mem only when new addr comes and is valid - new addrs and valid are not the same thing since it is possible that addr is old due to stall and valid is 1
    logic has_addr_changed, newReq;
    assign has_addr_changed = (current_dcache_line != last_dcache_line) || (current_dcache_tag != last_dcache_tag); // block offset will not come
    assign newReq = has_addr_changed && proc2Dcache_valid;

    // This indicates there is currently a miss that is being processed
    logic unanswered_miss, miss_outstanding, dataReceivedfromMem;
    assign unanswered_miss = newReq ? internal_Dcache_needs_memory : // there was a miss   //!Dcache_valid_out
                                        miss_outstanding && (mem2Dcache_response == 0);


    always_comb begin
        Dcache_valid_out = 0;
        Dcache_data_out = 0;
        internal_Dcache_needs_memory = 0;
        dataReceivedfromMem = 0;
        c = 0;
        Dcache_addr_evicted_VC = 0;
        Dcache_data_evicted_VC = 0;
        Dcache_evicted_valid_VC = 0;
        internal_Dcache2mem_command_load = 0;
        internal_Dcache2mem_command_store = 0;
        Dcache2mem_command = BUS_NONE;
        Dcache2mem_addr = 0;
        Dcache2mem_data = 0;
        temp_dcache_data = 0;


        if(saved_memTag == mem2Dcache_tag && mem2Dcache_tag != 0) begin
            internal_Dcache_needs_memory = 0;
            dataReceivedfromMem = 1;
            //$display("dataReceivedfromMem=%d saved_memTag=%d mem2Dcache_tag=%d internal_Dcache_needs_memory=%d",dataReceivedfromMem,saved_memTag,mem2Dcache_tag,internal_Dcache_needs_memory);
        end

        if(proc2Dcache_valid) begin

            c.byte_level     = dcache_dm[current_dcache_line].data;
            c.half_level     = dcache_dm[current_dcache_line].data;
            c.word_level     = dcache_dm[current_dcache_line].data;

            if(proc2Dcache_command == BUS_LOAD) begin
                
                // Same cycle, comb logic
                if(dcache_dm[current_dcache_line].tag == current_dcache_tag && dcache_dm[current_dcache_line].valid) begin
                    // Load hit
                    Dcache_valid_out = 1;
                    Dcache_data_out  = dcache_dm[current_dcache_line].data;

                    // dont stall or send anything to memory
                    internal_Dcache2mem_command_load = 0;
                    internal_Dcache2mem_command_store = 0;
                    internal_Dcache_needs_memory = 0;
                    //

                    case (proc2Dcache_size) 
                        BYTE: begin
                            Dcache_data_out = {56'b0, c.byte_level[proc2Dcache_addr[2:0]]};
                        end
                        HALF: begin
                            Dcache_data_out = {48'b0, c.half_level[proc2Dcache_addr[2:1]]};
                        end
                        WORD: begin
                            Dcache_data_out = {32'b0, c.word_level[proc2Dcache_addr[2]]};
                        end
                        DOUBLE:
                            Dcache_data_out = dcache_dm[current_dcache_line].data;
                    endcase
                end


                else begin
                    // Load miss

                    // stall and go to mem
                    internal_Dcache_needs_memory = 1;
                    //

                    // First evict current row to go to victim cache
                    Dcache_addr_evicted_VC = {16'b0, dcache_dm[current_dcache_line].tag, current_dcache_line, 3'b0};
                    Dcache_data_evicted_VC = dcache_dm[current_dcache_line].data;
                    Dcache_evicted_valid_VC = dcache_dm[current_dcache_line].valid;

                    if(dcache_dm[current_dcache_line].dirty && dcache_dm[current_dcache_line].valid && newReq) begin
                        // write back cache
                        internal_Dcache2mem_command_load = 0; // save tag only if command is load
                        internal_Dcache2mem_command_store = 1;
                        Dcache2mem_command = BUS_STORE;
                        Dcache2mem_addr = {16'b0, dcache_dm[current_dcache_line].tag, current_dcache_line, 3'b0};
                        Dcache2mem_data = dcache_dm[current_dcache_line].data;
                    end
                    else if(miss_outstanding) begin // if not dirty. the entry will be cleared in the next cycle so dirty will not stay
                        // send data to memory - This will send data in the next cycle, introduces one cycle delay when data is not dirty since miss_outstanding will update in the next cycle
                        internal_Dcache2mem_command_load = 1;
                        internal_Dcache2mem_command_store = 0;
                        Dcache2mem_command = BUS_LOAD;
                        Dcache2mem_addr = {16'b0, current_dcache_tag, current_dcache_line, 3'b0};
                    end
                    // get data from memory
                    // no need to write any get logic as load will hit
                end


            end


            else if(proc2Dcache_command == BUS_STORE) begin
                if(dcache_dm[current_dcache_line].tag == current_dcache_tag && dcache_dm[current_dcache_line].valid) begin
                    // store hit // no need to check for dirty
                    // mark as dirty
                    //$display("nevil");
                    internal_Dcache2mem_command_store = 1;
                    internal_Dcache_needs_memory = 0;
                    case (proc2Dcache_size) 
                        BYTE: begin
							c.byte_level[proc2Dcache_addr[2:0]] = proc2Dcache_data[7:0];
                            temp_dcache_data = c.byte_level;
                            //$display("temp_dcache_data=%x | c.byte_level=%x",temp_dcache_data,c.byte_level);
                        end
                        HALF: begin
							c.half_level[proc2Dcache_addr[2:1]] = proc2Dcache_data[15:0];
                            temp_dcache_data = c.half_level;
                        end
                        WORD: begin
							c.word_level[proc2Dcache_addr[2]] = proc2Dcache_data[31:0];
                            temp_dcache_data = c.word_level;
                        end
                        default: begin
							c.byte_level[proc2Dcache_addr[2]] = proc2Dcache_data[31:0];
                            temp_dcache_data = c.byte_level;
                        end
					endcase
                    //$display("temp_dcache_data=%d",temp_dcache_data);
                end
                else begin
                    // store misses
                    internal_Dcache_needs_memory = 1;

                    // load data // then store the value then mark dirty <- no need since it will hit

                    // First evict current row to go to victim cache
                    Dcache_addr_evicted_VC = {16'b0, dcache_dm[current_dcache_line].tag, current_dcache_line, 3'b0};
                    Dcache_data_evicted_VC = dcache_dm[current_dcache_line].data;
                    Dcache_evicted_valid_VC = dcache_dm[current_dcache_line].valid;

                    if(dcache_dm[current_dcache_line].dirty && dcache_dm[current_dcache_line].valid && newReq) begin
                        // write back cache
                        internal_Dcache2mem_command_load = 0; // save tag only if command is load
                        internal_Dcache2mem_command_store = 1;
                        Dcache2mem_command = BUS_STORE;
                        Dcache2mem_addr = {16'b0, dcache_dm[current_dcache_line].tag, current_dcache_line, 3'b0};
                        Dcache2mem_data = dcache_dm[current_dcache_line].data;
                    end
                    else if(miss_outstanding) begin // if not dirty. the entry will be cleared in the next cycle so dirty will not stay
                        // send data to memory
                        internal_Dcache2mem_command_load = 1;
                        internal_Dcache2mem_command_store = 0;
                        Dcache2mem_command = BUS_LOAD;
                        Dcache2mem_addr = {16'b0, current_dcache_tag, current_dcache_line, 3'b0};
                    end
                    // get data from memory
                    // no need to write any get logic as load will hit

                end
            end
            else if(proc2Dcache_command == BUS_NONE) begin
                // Do nothing
            end
        end

        
    end

    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if(reset) begin
            last_dcache_line    <= `SD 0; // Dcache does not need -1 since 0 addrs of first mem insn 1 seems wrong
            last_dcache_tag     <= `SD 0; 
            miss_outstanding    <= `SD 0;
            saved_memTag        <= `SD 0;
            dcache_dm           <= `SD 0;
        end 
        else if(enable) begin
            last_dcache_line    <= `SD current_dcache_line;
            last_dcache_tag     <= `SD current_dcache_tag;

            miss_outstanding    <= `SD unanswered_miss;

            if(internal_Dcache_needs_memory && mem2Dcache_response != 0 && internal_Dcache2mem_command_load)
                saved_memTag <= `SD mem2Dcache_response;

            if(internal_Dcache_needs_memory && internal_Dcache2mem_command_store) begin // if dcache needs mem but is not loading, meaning its storing then clear the entry
                dcache_dm[current_dcache_line].tag      <= `SD 0;
                dcache_dm[current_dcache_line].valid    <= `SD 0;
                dcache_dm[current_dcache_line].dirty    <= `SD 0;
                dcache_dm[current_dcache_line].data     <= `SD 0;
            end

            if(!internal_Dcache_needs_memory && internal_Dcache2mem_command_store) begin // Store hit
                dcache_dm[current_dcache_line].tag      <= `SD current_dcache_tag; // not needed since it would be a hit
                dcache_dm[current_dcache_line].valid    <= `SD 1;
                dcache_dm[current_dcache_line].dirty    <= `SD 1;
                dcache_dm[current_dcache_line].data     <= `SD temp_dcache_data;
            end

            if(dataReceivedfromMem) begin
                dcache_dm[current_dcache_line].tag      <= `SD current_dcache_tag;
                dcache_dm[current_dcache_line].valid    <= `SD 1;
                dcache_dm[current_dcache_line].dirty    <= `SD 0;
                dcache_dm[current_dcache_line].data     <= `SD mem2Dcache_data;
            end
        end
    end


    assign testbench_dcache_dm = dcache_dm;

    `ifdef DEBUG
        assign _current_dcache_tag = current_dcache_tag;
        assign _last_dcache_tag = last_dcache_tag;
        assign _current_dcache_line = current_dcache_line;
        assign _last_dcache_line = last_dcache_line;
        assign _current_block_offset = current_block_offset;
        assign _saved_memTag = saved_memTag;
        assign _miss_outstanding = miss_outstanding;
    `endif

endmodule