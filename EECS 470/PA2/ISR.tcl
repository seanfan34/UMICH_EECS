#/***********************************************************/
#/*   FILE        : mult.tcl                                */
#/*   Description : Default Synopsys Design Compiler Script */
#/*   Usage       : dc_shell -tcl_mode -f mult.scr          */
#/*   You'll need to minimally set design_name & read files */
#/***********************************************************/

#/***********************************************************/
#/* The following lines must be updated for every           */
#/* new design                                              */
#/***********************************************************/
set search_path [ list "./" "/afs/umich.edu/class/eecs470/lib/synopsys/"]
read_file -f ddc [list "mult_stage.ddc"]
set_dont_touch mult_stage
set search_path [ list "./" "/afs/umich.edu/class/eecs470/lib/synopsys/"]
read_file -f ddc [list "mult.ddc"]
set_dont_touch mult

read_file -f sverilog [list "ISR.v"]
set design_name ISR
set clock_name clock
set reset_name reset
set CLK_PERIOD 8.5


#/***********************************************************/
#/* The rest of this file may be left alone for most small  */
#/* to moderate sized designs.  You may need to alter it    */
#/* when synthesizing your final project.                   */
#/***********************************************************/
set SYN_DIR ./
set target_library "lec25dscc25_TT.db"

set link_library [concat  "*" $target_library]

#/***********************************************************/
#/* Set some flags for optimisation */

set compile_top_all_paths "true"
set auto_wire_load_selection "false"


#/***********************************************************/
#/*  Clk Periods/uncertainty/transition                     */

set CLK_TRANSITION 0.1
set CLK_UNCERTAINTY 0.1
set CLK_LATENCY 0.1

#/* Input/output Delay values */
set AVG_INPUT_DELAY 0.1
set AVG_OUTPUT_DELAY 0.1

#/* Critical Range (ns) */
set CRIT_RANGE 1.0

#/***********************************************************/
#/* Design Constrains: Not all used                         */
set MAX_TRANSITION 1.0
set FAST_TRANSITION 0.1
set MAX_FANOUT 32
set MID_FANOUT 8
set LOW_FANOUT 1
set HIGH_DRIVE 0
set HIGH_LOAD 1.0
set AVG_LOAD 0.1
set AVG_FANOUT_LOAD 10

#/***********************************************************/
#/*BASIC_INPUT = cb18os120_tsmc_max/nd02d1/A1
#BASIC_OUTPUT = cb18os120_tsmc_max/nd02d1/ZN*/

set DRIVING_CELL dffacs1

#/* DONT_USE_LIST = {   } */

#/*************operation cons**************/
#/*OP_WCASE = WCCOM;
#OP_BCASE = BCCOM;*/
set WIRE_LOAD "tsmcwire"
set LOGICLIB lec25dscc25_TT
#/*****************************/

#/* Sourcing the file that sets the Search path and the libraries(target,link) */

set sys_clk $clock_name

set netlist_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".vg"]
set ddc_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".ddc"]
set rep_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".rep"]
set dc_shell_status [ set chk_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".chk"] ]

#/* if we didnt find errors at this point, run */
if {  $dc_shell_status != [list] } {
   current_design $design_name
  link
  set_wire_load_model -name $WIRE_LOAD -lib $LOGICLIB $design_name
  set_wire_load_mode top
  set_fix_multiple_port_nets -outputs -buffer_constants
  create_clock -period $CLK_PERIOD -name $sys_clk [find port $sys_clk]
  set_clock_uncertainty $CLK_UNCERTAINTY $sys_clk
  set_fix_hold $sys_clk
  group_path -from [all_inputs] -name input_grp
  group_path -to [all_outputs] -name output_grp
  set_driving_cell  -lib_cell $DRIVING_CELL [all_inputs]
  remove_driving_cell [find port $sys_clk]
  set_fanout_load $AVG_FANOUT_LOAD [all_outputs]
  set_load $AVG_LOAD [all_outputs]
  set_input_delay $AVG_INPUT_DELAY -clock $sys_clk [all_inputs]
  remove_input_delay -clock $sys_clk [find port $sys_clk]
  set_output_delay $AVG_OUTPUT_DELAY -clock $sys_clk [all_outputs]
  set_dont_touch $reset_name
  set_resistance 0 $reset_name
  set_drive 0 $reset_name
  set_critical_range $CRIT_RANGE [current_design]
  set_max_delay $CLK_PERIOD [all_outputs]
  set MAX_FANOUT $MAX_FANOUT
  set MAX_TRANSITION $MAX_TRANSITION
  uniquify
  ungroup -all -flatten
  redirect $chk_file { check_design }
  compile -map_effort high
  write -hier -format verilog -output $netlist_file $design_name
  write -hier -format ddc -output $ddc_file $design_name
  redirect $rep_file { report_design -nosplit }
  redirect -append $rep_file { report_area }
  redirect -append $rep_file { report_timing -max_paths 2 -input_pins -nets -transition_time -nosplit }
  redirect -append $rep_file { report_constraint -max_delay -verbose -nosplit }
  remove_design -all
  read_file -format verilog $netlist_file
  current_design $design_name
  redirect -append $rep_file { report_reference -nosplit }
  quit
} else {
   quit
}


# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be
# similar to the information in those scripts but that seems hard to avoid.
#

# added "SW_VCS=2011.03 and "-full64" option -- awdeorio fall 2011
# added "-sverilog" and "SW_VCS=2012.09" option,
#	and removed deprecated Virsim references -- jbbeau fall 2013
# updated library path name -- jbbeau fall 2013

VCS = SW_VCS=2020.12-SP2-1 vcs +v2k -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

all:    simv
	./simv | tee program.out
##### 
# Modify starting here
#####

TESTBENCH = ISR_test.v
SIMFILES = pipe_mult.v ISR.v mult_stage.v
SYNFILES = ISR.vg

ISR.vg: ISR.v ISR.vg ISR.tcl
	dc_shell-t -f ./ISR.tcl | tee ISR_synth.out

mult.vg: pipe_mult.v mult_stage.vg mult.tcl
	dc_shell-t -f ./mult.tcl | tee mult_synth.out

mult_stage.vg: mult_stage.v mult_stage.tcl
	dc_shell-t -f ./mult_stage.tcl | tee mult_stage_synth.out

#####
# Should be no need to modify after here
#####
sim:	simv $(ASSEMBLED)
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv* *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
          dve *.vpd *.vcd *.dump ucli.key\
	          DVEfiles/ verdi* novas* *fsdb*

nuke:	clean
	rm -rvf *.vg *.rep *.db *.chk *.log *.out *.ddc *.svf

.PHONY: clean nuke	

