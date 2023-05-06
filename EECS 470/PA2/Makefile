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
