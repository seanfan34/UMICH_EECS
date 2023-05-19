Full paths names:
INV:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD1/CAD1_LIB/INV
NAND2:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD1/CAD1_LIB/NAND2
MUX21:
/afs/umich.edu/class/eecs427/w23/seanfan/CAD1/CAD1_LIB/MUX21

=========================================================================

Maximum Rise Delay: 0.2518ns
Between nodes: SEL & OUT
This is the critical path since the SEL signal has to go through the inverter and 2 NAND gates, while IN0 and IN1 only have to go through 2 NAND gates
Maximum Fall Delay: 0.1934ns
Between nodes: SEL & OUT
This is the critical path since the SEL signal has to go through the inverter and 2 NAND gates, while IN0 and IN1 only have to go through 2 NAND gates

Maximum Rise Time: 0.4022ns

Maximum Fall Time: 0.241ns

=========================================================================

Input for NC verilog simulation:

INV: IN = 0 => IN = 1 => IN = 0

NAND2: IN0 = 0, IN1 = 0 => IN0 = 1, IN1 = 0 => IN0 = 0, IN1 = 1 => IN0 = 1, IN1 = 1 

MUX21: IN0 = 0, IN1 = 0, SEL = 0  => IN0 = 1, IN1 = 0, SEL = 0 => IN0 = 0, IN1 = 1, SEL = 0 => IN0 = 1, IN1 = 1, SEL = 0 => IN0 = 0, IN1 = 0, SEL = 1
=> IN0 = 1, IN1 = 0, SEL = 1 => IN0 = 0, IN1 = 1, SEL = 1 => IN0 = 1, IN1 = 1, SEL = 1

=========================================================================

Input for Spice simulation:
           risetime falltime delay pulsewidth period
INV:   IN     100p     100p    1n      2n        4n
NAND2: IN0    100p     100p    1n      2n        4n
       IN1    100p     100p    1n      4n        8n
MUX21: IN0    100p     100p    1n      2n        4n
       IN1    100p     100p    1n      4n        8n 
       SEL    100p     100p    1n      10n       20n 

=========================================================================

INV Layout Area: 1.2 * 2.4 = 2.88 um^2
NAND2 Layout Area: 1.6 * 2.8 = 4.48 um^2
MUX21 Layout Area: 3.2 * 5.6 = 17.92 um^2

In my MUX21 layout, since M2 should follow the rule of 0.2 + 0.4n, the M1 layer in the inverter that is connected to VDD will violate the rule of the distance between M1 to M1 should be larger than 0.16um, so it needs to be moved right 0.2um. The NAND2 in the below MUX21 will also meet the problem above, so I shift the M1 layer that connected to VDD left for 0.1um to meet the rule above.

