# Tiny Tapeout Cocotb testbench

SIM ?= icarus
FST ?= -fst

TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../src


PROJECT_SOURCES = \
	project.v \
	alu_clock_gated_4d.v \
	alu_partitioned_datapath_4d.v \
	alu_decode.v \
	alu_addsub.v \
	adder_select_32.v \
	adder_behavioral_32.v \
	clz32_tree.v \
	icg_cell.v


ifneq ($(GATES),yes)

# ------------------------------------------------------------
# RTL simulation
# ------------------------------------------------------------

SIM_BUILD = sim_build/rtl

# Enable behavioral models for technology-specific cells.
COMPILE_ARGS += -DCOCOTB_SIM

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))


else

# ------------------------------------------------------------
# Gate-level simulation
# ------------------------------------------------------------

SIM_BUILD = sim_build/gl

COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUNIT_DELAY=\#1

# SKY130 simulation models
VERILOG_SOURCES += \
	$(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v

VERILOG_SOURCES += \
	$(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# Added automatically by the Tiny Tapeout GDS action
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif


# Allow source files to use `include files in src/
COMPILE_ARGS += -I$(SRC_DIR)


# Testbench
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb

COCOTB_TEST_MODULES = test


include $(shell cocotb-config --makefiles)/Makefile.sim
