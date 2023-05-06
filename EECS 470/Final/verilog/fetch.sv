/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Module Name :  fetch.sv                                           //
//                                                                     //
//   Description :  instruction fetch stage of the pipeline;      	   // 
//                  fetch instruction, compute next PC location, and   //
//                  send them down the pipeline.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __FETCH_SV__
`define __FETCH_SV__

`timescale 1ns/100ps

module fetch (
	input  																clock, 
	input  																reset,
	input  																branch_flush_en,   	// taken-branch signal

	input  						 [`XLEN-1:0] 							target_pc,  		// target pc: use if branch_flush_en is TRUE
	input  DISPATCH_FETCH_PACKET 										fetch_dispatch_in,  // stall data from dispatch stage
	//input  						 [`SUPERSCALAR_WAYS-1:0][(`XLEN*2)-1:0] Imem2proc_data,  	// Data coming from instruction-memory
 	input   [`SUPERSCALAR_WAYS-1:0][31:0]         												      cache_data,         
    	input   [`SUPERSCALAR_WAYS-1:0]               												      cache_valid,
 
	output  logic               hit_but_stall,      // -> icache.hit_but_stall
    	output  logic [1:0]         choose_address,              // -> icache.shift
	output logic 				 [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	PC_out,     		// PC currently being fetch from memory
	output logic 				 [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] 	proc2Imem_addr,     // Address sent to Instruction memory
	output FETCH_DISPATCH_PACKET [`SUPERSCALAR_WAYS-1:0] 				fetch_dispatch_out  // for Dispatch
);
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] PC_reg;
	logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0] next_PC;

	assign PC_out = PC_reg;

	assign choose_address = branch_flush_en ? 2'd0 :
                    fetch_dispatch_in.enable ? fetch_dispatch_in.first_stall_idx : 
                    ~cache_valid[0] ? 2'd0 :
                    ~cache_valid[1] ? 2'd1 :
                    ~cache_valid[2] ? 2'd2 :
                    2'd0;

        assign hit = cache_valid[0] ? 2'd0 :
                       cache_valid[1] ? 2'd1 :
                       cache_valid[2] ? 2'd2 :
                       2'd3;

        assign stall = fetch_dispatch_in.enable  ? fetch_dispatch_in.first_stall_idx : 2'd3;

        assign hit_but_stall = first_hit == 2'd2 && first_stall != 2'd3 && PC_reg[first_hit][`XLEN-1:3] == PC_reg[first_stall][`XLEN-1:3];

        assign fetch_dispatch_out[0].valid = cache_valid[0] ? 1'b1 : 1'b0;
        assign fetch_dispatch_out[1].valid = ~fetch_dispatch_out[0].valid ? 1'b0 : cache_valid[1] ? 1'b1 : 1'b0;
        assign fetch_dispatch_out[2].valid = ~fetch_dispatch_out[1].valid ? 1'b0 : cache_valid[2] ? 1'b1 : 1'b0;

    	assign fetch_dispatch_out[0].inst  = ~cache_valid[0] ? 32'b0 : cache_data[0];
    	assign fetch_dispatch_out[1].inst  = ~cache_valid[1] ? 32'b0 : cache_data[1];
    	assign fetch_dispatch_out[2].inst  = ~cache_valid[2] ? 32'b0 : cache_data[2];

	always_ff @(posedge clock) begin
		if (reset) begin
			for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
				PC_reg[i] <= `SD (i * `XLEN'd4);
		end
		else PC_reg <= `SD next_PC;
	end  // always_ff @(posedge clock)

	always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++)
			proc2Imem_addr[i] = PC_reg[i]/*{ PC_reg[i][`XLEN-1:3], 3'b0 }*/;
	end  // always_comb  // proc2Imem_addr

	always_comb begin
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			fetch_dispatch_out[i].PC    = PC_reg[i];
			fetch_dispatch_out[i].NPC   = PC_reg[i] + `XLEN'd4;
			//fetch_dispatch_out[i].valid = ~branch_flush_en; 

			// this mux is because the Imem gives us 64 bits not 32 bits
			//fetch_dispatch_out[i].inst  = PC_reg[i][2] ? Imem2proc_data[i][(2*`XLEN)-1:`XLEN] : 
										  //Imem2proc_data[i][`XLEN:0];
        end  // for each instruction
	end  // always_comb  // fetch_dispatch_out

	always_comb begin
		// if there's a taken branch, set next_PC according to its target
		// else, increment the PC by 4*(SUPERSCALAR_WAYS-num_stalls)
        for (int i = 0; i < `SUPERSCALAR_WAYS; i++) begin
			next_PC[i] = branch_flush_en		  ? (target_pc + (i * 4)) : 
						 fetch_dispatch_in.enable ? (PC_reg[fetch_dispatch_in.first_stall_idx] + (i * `XLEN'd4)) :
						 PC_reg[i] + (`SUPERSCALAR_WAYS * `XLEN'd4);
        end  // for each instruction
	end  // always_comb  // next_PC
endmodule  // fetch

`endif  // __FETCH_SV__
