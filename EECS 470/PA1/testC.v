module testbench;
    logic [7:0] req;
    logic  en;
    logic [7:0] gnt;
    logic [7:0] tb_gnt;
    logic req_up;
    //logic correct;

  
    ps8 pe8(req, en, gnt,req_up);
    assign tb_gnt=gnt;
    assign correct=(tb_gnt==gnt);

    always @(correct)
    begin
        #2
        if(!correct)
        begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ gnt=%b, en=%b, req=%b",gnt,en,req);
            $display("@@@ expected result=%b", tb_gnt);
            $finish;
        end
    end
    

    initial 
    begin
		$dumpvars;
        $monitor("Time:%4.0f req:%b en:%b gnt:%b", $time, req, en, gnt);

        req=8'b00000000;
        en=1'b1;
        #5    
        req=8'b10000000;
        #5
        req=8'b01000000;
        #5
        req=8'b00100000;
        #5
        req=8'b00010000;
        #5
        req=8'b00001000;
        #5
        req=8'b00000100;
        #5
        req=8'b00000010;
        #5
        req=8'b00000001;
        #5
        req=8'b01010000;
        #5
        req=8'b01001000;
        #5
        req=8'b10000010;
        #5
	req=8'b11100010;
        #5
	req=8'b00111010;
        #5
        req=8'b11111111;
        #5
        en=0;
        #5
        req=8'b01100000;
        #5
        $finish;
     end // initial
endmodule


    
 

