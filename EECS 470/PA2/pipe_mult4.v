
module mult4(
				input clock, reset,
				input [63:0] mcand, mplier,
				input start,
				
				output [63:0] product,
				output done
			);

  logic [63:0] mcand_out, mplier_out;
  logic [(3*64)-1:0] internal_products, internal_mcands, internal_mpliers;
  logic [2:0] internal_dones;
  
	mult_stage mstage [3:0]  (
		.clock(clock),
		.reset(reset),
		.product_in({internal_products,64'h0}),
		.mplier_in({internal_mpliers,mplier}),
		.mcand_in({internal_mcands,mcand}),
		.start({internal_dones,start}),
		.product_out({product,internal_products}),
		.mplier_out({mplier_out,internal_mpliers}),
		.mcand_out({mcand_out,internal_mcands}),
		.done({done,internal_dones})
	);

endmodule

