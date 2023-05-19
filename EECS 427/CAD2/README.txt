Full paths names:
DFF:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/CAD2_LIB/DFF

DRC file:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/Calibre/DRC

LVS file:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/Calibre/LVS

Simulation graphs:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/nc_DFF_delay.ps
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/nc_DFF_nodelay.ps
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_FallCLK-Qdelay.png
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_Fallholdtime.png
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_Fallsetuptime.png
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_RiseCLK-Qdelay.png
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_Riseholdtime.png
/afs/umich.edu/class/eecs427/w23/seanfan/CAD2/SUBMIT/spice_DFF_Risesetuptime.png

=================================================================

Rise CLK-Q Delay: 0.58ns
Fall CLK-Q Delay: 0.5904ns
Finding the CLK to Q delay is from 50% of input signal CLK to 50% of output signal Q.

Rise Setup Time: 0.145ns
Fall Setup Time: 0.045ns
Setup time is the time that sweep the input signal D before the rising edge of the CLK signal. The nominal value of my setup time is the input signal D delay td = 4.8ns. So the rise setup time of my design is 26.05 - 25.905 = 0.145ns. The fall setup time of my design is 34.05 - 34.005 = 0.045ns 

Rise Hold Time: 0.05ns
Fall Hold Time: 0.18ns
Hold time is the time that sweep the input signal D after the rising edge of the CLK signal. So the rise hold time of my design is 26.05 - 26 = 0.05ns. The fall hold time of my design is 34.23 - 34.05 = 0.18ns  

=========================================================================

Input for NC verilog simulation:

always
begin
   #5 CLK = ~CLK;
end

initial
begin 

   CLK = 1'b0;
   D = 1'b0;
   RSTn = 1'b0;
   #10 D = 1'b1;
       RSTn = 1'b0;
   #10 D = 1'b1;
       RSTn = 1'b1;
   #10 D = 1'b0;
   #10 $stop;

end 

When the input signal D and RSTn reaches 1, and the CLK signal is in the rising edge condition. The output signal without any delay will then be 1. When the input signal D goes back to 0, the CLK signal is in the rising edge condition. The output signal without any delay will then be 0. However, if the RSTn signal is 0, the output signal is then reset to 0. The description above meets the results of my NC verilog simulation.

=========================================================================

Input for Spice simulation:
           risetime falltime delay pulsewidth period
DFF: RSTn    100p     100p    1n      128n      256n
     D       100p     100p   5n+td      8n       16n
     CLK     100p     100p    2n        4n        8n

=========================================================================

DFF Layout Area: 4.8 * 7.6 = 36.48 um^2

