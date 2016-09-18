# This makefile will build all *.sv files in the PARENT DIRECTORY using vcs. Run
# it in a subdirectory of your Quartus project. This way the mess of files from
# vcs and the mess of files from Quartus are somewhat contained.

SOURCES=$(wildcard ../*.sv) ../romA.v ../romB.v ../multiplier.v

simv: $(SOURCES) matA.mif matB.mif
	vcs -line -timescale=1ns/1ps -sverilog +verilog2001ext+.v \
	-debug -v2k_generate \
	-v /afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/altera_primitives.v \
	-v /afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/220model.v \
	-v /afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/sgate.v \
	-v /afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/altera_mf.v \
	/afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/altera_lnsim.sv \
	-v /afs/ece/support/altera/release/12.1/quartus/eda/sim_lib/cycloneiii_atoms.v \
	$(SOURCES) \
	+incdir+/afs/ece/support/altera/release/12.1/quartus/eda/sim_lib+..

%.mif: ../%.mif
	cp $< $@
