module ps2(
        input [1:0]req,en,
        output logic [1:0]gnt,req_up); 
    assign req_up =req[1]|req[0];
    assign gnt[1]=en&req[1];
    assign gnt[0]=en&req[0]&~req[1];
 
endmodule

module ps4(
        input [3:0]req,en,
        output logic [3:0]gnt,req_up); 

    logic [3:0]tmp;
    ps2 ps2_right( req[1:0],tmp[2],gnt[1:0],tmp[0]);
    ps2 ps2_left( req[3:2],tmp[3],gnt[3:2],tmp[1]);
    ps2 ps2_top( tmp[1:0],en,tmp[3:2],req_up);
endmodule

module ps8(
        input [7:0]req,en,
        output logic [7:0]gnt,req_up);
    
    logic [3:0]tmp;
    ps4 ps4_right( req[3:0],tmp[2],gnt[3:0],tmp[0]);
    ps4 ps4_left( req[7:4],tmp[3],gnt[7:4],tmp[1]);
    ps2 ps2_top( tmp[1:0],en,tmp[3:2],req_up);
endmodule





    

