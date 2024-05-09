export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile


GEN_TRANS_TYPE ?= i2cmb_test
TEST_SEED ?= random
CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean: 
	rm -rf work *.wlf transcript *.ucdb

comp_I2C_MB:
	vcom -cover bcesft ../rtl/iicmb_int_pkg.vhd
	vcom -cover bcesft ../rtl/iicmb_pkg.vhd
	vcom -cover bcesft ../rtl/mbyte.vhd
	vcom -cover bcesft ../rtl/mbit.vhd
	vcom -cover bcesft ../rtl/bus_state.vhd
	vcom -cover bcesft ../rtl/filter.vhd
	vcom -cover bcesft ../rtl/conditioner.vhd
	vcom -cover bcesft ../rtl/conditioner_mux.vhd
	vcom -cover bcesft ../rtl/iicmb_m.vhd
	vcom -cover bcesft ../rtl/regblock.vhd
	vcom -cover bcesft ../rtl/wishbone.vhd
	vcom -cover bcesft ../rtl/iicmb_m_wb.vhd

# add new pakage here as well
comp_bench:  comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg  comp_i2cmb_env_pkg
	vlog  -cover bcesft ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

run_cli:
	vsim  -c -coverage -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TRANS_TYPE); coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: compile optimize run_cli

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb


merge_coverage:
	xml2ucdb -format Excel ./test_plan_layered_testbench.xml ./test_plan_layered_testbench.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

############### RUN THIS TO COMPILE ALL TEST, THIS WILL MERGE AS WELL ####################################
regress:
	./testlist.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb

simulate_nogui:
	vsim -c -classdebug -msgmode both -do "run -a; quit" optimized_debug_top_tb

debug_nogui: clean compile simulate_nogui

debug: clean compile simulate
