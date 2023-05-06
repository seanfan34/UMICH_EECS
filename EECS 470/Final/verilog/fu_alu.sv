//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Module Name :  fu_alu.sv                                            //
//                                                                      //
//  Description :  fu_alu submodule of the fu module;                   //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the        // 
//                 result, and compute the condition for branches       //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module fu_alu (
	//input                     complete_stall,	   // complete stage structural hazard
	input  ISSUE_FU_PACKET    fu_issue_in,

	//output logic              fu_ready,
	output logic              want_to_complete,
	output FU_COMPLETE_PACKET fu_packet_out,

	// SQ
	output 					  is_alu_store,
	output SQ_ENTRY_PACKET	  alu_store,
	output [`N_LSQ_ENTRIES_BITS-1:0] alu_idx,
);
	logic [`XLEN-1:0] opa_mux_out;
	logic [`XLEN-1:0] opb_mux_out;
	logic [`XLEN-1:0] alu_result;
	logic 			  cond;
	ALU_SELECT alu_sel;

	assign is_alu_store = fu_issue_in.valid && fu_issue_in.op_sel.alu >= SB;
	assign alu_sel = is_alu_store ? ALU_ADD : fu_issue_in.alu_func;
	assign alu_idx = fu_issue_in.sq_tail;

	//assign fu_ready					 = `TRUE;
	assign want_to_complete			 = fu_issue_in.valid;
	assign fu_packet_out.rd_mem		 = fu_issue_in.rd_mem;
	assign fu_packet_out.wr_mem		 = fu_issue_in.wr_mem;
	assign fu_packet_out.halt		 = fu_issue_in.halt;
	assign fu_packet_out.valid		 = fu_issue_in.valid;
	assign fu_packet_out.pr_idx 	 = fu_issue_in.pr_idx;
	assign fu_packet_out.ar_idx 	 = fu_issue_in.ar_idx;
	assign fu_packet_out.rob_idx 	 = fu_issue_in.rob_idx;
	assign fu_packet_out.dest_value  = alu_result;
	assign fu_packet_out.take_branch = (fu_issue_in.uncond_branch | (fu_issue_in.cond_branch & cond));
	assign fu_packet_out.target_pc   = (fu_issue_in.cond_branch | fu_issue_in.uncond_branch) ? 
									   alu_result : 0;

	always_comb begin
		case (fu_issue_in.opa_select)
			OPA_IS_RS1:   opa_mux_out = fu_issue_in.rs1_value;
			OPA_IS_NPC:   opa_mux_out = fu_issue_in.NPC;
			OPA_IS_PC:    opa_mux_out = fu_issue_in.PC;
			OPA_IS_ZERO:  opa_mux_out = 0;
			default: 	  opa_mux_out = `XLEN'hdeadfbac;
		endcase  // case (fu_issue_in.opa_select)
	end  // always_comb  // opa_mux_out

	always_comb begin
		case (fu_issue_in.opb_select)
			OPB_IS_RS2:    opb_mux_out = fu_issue_in.rs2_value;
			OPB_IS_I_IMM:  opb_mux_out = `RV32_signext_Iimm(fu_issue_in.inst);
			OPB_IS_S_IMM:  opb_mux_out = `RV32_signext_Simm(fu_issue_in.inst);
			OPB_IS_B_IMM:  opb_mux_out = `RV32_signext_Bimm(fu_issue_in.inst);
			OPB_IS_U_IMM:  opb_mux_out = `RV32_signext_Uimm(fu_issue_in.inst);
			OPB_IS_J_IMM:  opb_mux_out = `RV32_signext_Jimm(fu_issue_in.inst);
			default:	   opb_mux_out = `XLEN'hfacefeed;						// invalid opb_select
		endcase  // case (fu_issue_in.opb_select)
	end  // always_comb  // opb_mux_out

	alu alu_0 (
		.opa(opa_mux_out),
		.opb(opb_mux_out),
		.func(alu_sel),
		.result(alu_result)
	);

	brcond brcond_0 (
		.rs1(fu_issue_in.rs1_value),
		.rs2(fu_issue_in.rs2_value),
		.func(fu_issue_in.inst.b.funct3),
		.cond(cond)
	);


	// SQ
	logic [`XLEN-1:0] store_value;
	assign store_val = fu_issue_in.r2_value;
	always_comb begin
		alu_store.addr = {alu_result['XLEN-1:2], 2'b00};
		alu_store.ready = 1'b1;
		alu_store.data = 0;
		alu_store.usebytes = 0;

		case(fu_issue_in.op_sel.alu)
		SB: case(alu_result[1:0])
			2'b00: begin
				alu_store.usebytes = 4'b0001;
				alu_store.data[7:0] = store_value[7:0];
			end
			2'b01: begin
				alu_store.usebytes = 4'b0010;
				alu_store.data[15:8] = store_value[7:0];
			end
			2'b10: begin
				alu_store.usebytes = 4'b0100;
				alu_store.data[23:16] = store_value[7:0];
			end
			2'b11: begin
				alu_store.usebytes = 4'b1000;
				alu_store.data[31:24] = store_value[7:0];
			end
			endcase
		SH: case(alu_result[1:0])
			2'b00: begin
				alu_store.usebytes = 4'b0011;
				alu_store.data[15:0] = store_value[15:0];
			end
			2'b10: begin
				alu_store.usebytes = 4'b1100;
				alu_store.data[31:16] = store_value[15:0];
			end
			endcase
		SW: begin
			alu_store.usebytes = 4'b1111;
			alu_store.data = store_value;
		end
	endcase
	end

endmodule  // fu_alu