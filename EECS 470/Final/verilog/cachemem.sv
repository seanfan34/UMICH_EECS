`timescale 1ns/100ps

module cachemem(
        input clock, reset, icache_data_write_enable,             
        input  [4:0] icache_write_index,                   
        input  [2:0][4:0] icache_read_index,              
        input  [7:0] icache_write_tag,                   
        input  [2:0][7:0] icache_read_tag,            
        input  [63:0] memory_data,               

        output [2:0][63:0] icache_cachemem_data,           
        output [2:0] icache_cachemem_valid                 
);

  logic [31:0] [63:0] data;
  logic [31:0] [7:0]  tags;
  logic [31:0]        valids;

  assign icache_cachemem_data[0] = data[icache_read_index[0]];
  assign icache_cachemem_data[1] = data[icache_read_index[1]];
  assign icache_cachemem_data[2] = data[icache_read_index[2]];
  assign icache_cachemem_valid[0] = valids[icache_read_index[0]] && (tags[icache_read_index[0]] == icache_read_tag[0]);
  assign icache_cachemem_valid[1] = valids[icache_read_index[1]] && (tags[icache_read_index[1]] == icache_read_tag[1]);
  assign icache_cachemem_valid[2] = valids[icache_read_index[2]] && (tags[icache_read_index[2]] == icache_read_tag[2]);

  always_ff @(posedge clock) begin
    if(reset)
      valids <= `SD 32'b0;
    else if(icache_data_write_enable) 
      valids[icache_write_index] <= `SD 1;
  end
  
  always_ff @(posedge clock) begin
    if(icache_data_write_enable) begin
      data[icache_write_index] <= `SD memory_data;
      tags[icache_write_index] <= `SD icache_write_tag;
    end
  end

endmodule
