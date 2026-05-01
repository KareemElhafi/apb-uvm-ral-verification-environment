# =============================================================================
# File        : Makefile
# Project     : APB UVM RAL Verification Environment
# Description : Build and simulation automation for QuestaSim.
#               Supports compile, run, clean, and help targets.
#               Designed to be extensible for VCS and Xcelium.
# =============================================================================

# -----------------------------------------------------------------------------
# Simulator selection  (questa | vcs | xcelium)
# -----------------------------------------------------------------------------
SIM            ?= questa

# -----------------------------------------------------------------------------
# Simulator-specific tool binaries
# -----------------------------------------------------------------------------
ifeq ($(SIM), questa)
    COMPILER   := vlog
    ELABORATOR := vsim
else ifeq ($(SIM), vcs)
    COMPILER   := vcs
    ELABORATOR := ./simv
else ifeq ($(SIM), xcelium)
    COMPILER   := xmvlog
    ELABORATOR := xmsim
else
    $(error Unsupported simulator: $(SIM). Choose questa | vcs | xcelium)
endif

# -----------------------------------------------------------------------------
# Top-level module and UVM test name
# -----------------------------------------------------------------------------
TOP            := tb_top
UVM_TEST       ?= apb_reg_test
UVM_VERBOSITY  ?= UVM_MEDIUM

# -----------------------------------------------------------------------------
# UVM library path (must be set in environment or overridden here)
# -----------------------------------------------------------------------------
UVM_HOME       ?= $(shell echo $$UVM_HOME)

# -----------------------------------------------------------------------------
# Directory paths (relative to sim/)
# -----------------------------------------------------------------------------
RTL_DIR        := ../rtl
TB_DIR         := ../tb

# -----------------------------------------------------------------------------
# Compilation flags
# -----------------------------------------------------------------------------
VLOG_OPTS      := -sv \
                  -timescale 1ns/1ps \
                  +acc \
                  +incdir+$(UVM_HOME)/src \
                  +incdir+$(TB_DIR) \
                  +incdir+$(TB_DIR)/agents \
                  +incdir+$(TB_DIR)/env \
                  +incdir+$(TB_DIR)/interfaces \
                  +incdir+$(TB_DIR)/pkg \
                  +incdir+$(TB_DIR)/reg_model \
                  +incdir+$(TB_DIR)/scoreboard \
                  +incdir+$(TB_DIR)/sequences \
                  +incdir+$(TB_DIR)/tests

# -----------------------------------------------------------------------------
# Simulation flags
# -----------------------------------------------------------------------------
VSIM_OPTS      := -L work \
                  -timescale 1ns/1ps \
                  +acc \
                  -voptargs=+acc \
                  +UVM_TESTNAME=$(UVM_TEST) \
                  +UVM_VERBOSITY=$(UVM_VERBOSITY) \
                  +UVM_NO_RELNOTES

# Append waveform logging if WAVE=1
ifdef WAVE
    VSIM_OPTS  += -do "log -r /*; run -all; quit -f"
else
    VSIM_OPTS  += -do "run -all; quit -f"
endif

# Run in batch (no GUI) by default; set GUI=1 to open the wave viewer
ifndef GUI
    VSIM_OPTS  += -c
endif

# -----------------------------------------------------------------------------
# Source file list — ORDER MATTERS for compilation dependencies
# -----------------------------------------------------------------------------
SRCS           := \
    $(UVM_HOME)/src/uvm_pkg.sv \
    $(TB_DIR)/interfaces/apb_if.sv \
    $(TB_DIR)/pkg/apb_pkg.sv \
    $(RTL_DIR)/apb_register_bank.sv \
    $(TB_DIR)/tb_top.sv

# -----------------------------------------------------------------------------
# Default target
# -----------------------------------------------------------------------------
.DEFAULT_GOAL  := all

.PHONY: all compile run clean help

# -----------------------------------------------------------------------------
# all: compile then run
# -----------------------------------------------------------------------------
all: compile run

# -----------------------------------------------------------------------------
# compile: create library and compile all sources
# -----------------------------------------------------------------------------
compile:
	@echo ""
	@echo "============================================================"
	@echo "  [COMPILE] Creating simulation library"
	@echo "============================================================"
	@if [ -d work ]; then vdel -lib work -all; fi
	vlib work
	vmap work work
	@echo ""
	@echo "============================================================"
	@echo "  [COMPILE] Compiling source files ($(SIM))"
	@echo "============================================================"
	$(COMPILER) $(VLOG_OPTS) $(SRCS)
	@echo ""
	@echo "  Compilation complete."
	@echo ""

# -----------------------------------------------------------------------------
# run: launch simulation (assumes compile was already run)
# -----------------------------------------------------------------------------
run:
	@echo ""
	@echo "============================================================"
	@echo "  [SIMULATE] Running test: $(UVM_TEST)"
	@echo "  [SIMULATE] Verbosity : $(UVM_VERBOSITY)"
	@echo "============================================================"
	$(ELABORATOR) $(VSIM_OPTS) work.$(TOP)
	@echo ""
	@echo "  Simulation complete."
	@echo ""

# -----------------------------------------------------------------------------
# clean: remove all generated artifacts
# -----------------------------------------------------------------------------
clean:
	@echo ""
	@echo "============================================================"
	@echo "  [CLEAN] Removing generated artifacts"
	@echo "============================================================"
	@rm -rf work
	@rm -rf transcript
	@rm -rf vsim.wlf
	@rm -rf dump.vcd
	@rm -rf modelsim.ini
	@rm -rf *.log
	@rm -rf *.vstf
	@rm -rf *.ucdb
	@echo "  Clean complete."
	@echo ""

# -----------------------------------------------------------------------------
# help: print usage information
# -----------------------------------------------------------------------------
help:
	@echo ""
	@echo "  APB UVM RAL Verification Environment — Makefile Help"
	@echo "  -------------------------------------------------------"
	@echo "  Targets:"
	@echo "    make              Compile + run (default)"
	@echo "    make compile      Compile sources only"
	@echo "    make run          Run simulation (requires compile first)"
	@echo "    make clean        Remove all generated artifacts"
	@echo "    make help         Print this message"
	@echo ""
	@echo "  Overrides:"
	@echo "    UVM_TEST=<name>          UVM test class to run (default: apb_reg_test)"
	@echo "    UVM_VERBOSITY=<level>    UVM verbosity (default: UVM_MEDIUM)"
	@echo "    SIM=<questa|vcs|xcelium> Simulator selection (default: questa)"
	@echo "    GUI=1                    Open QuestaSim GUI / wave viewer"
	@echo "    WAVE=1                   Dump all signal waveforms (log -r /*)"
	@echo ""
	@echo "  Examples:"
	@echo "    make"
	@echo "    make run UVM_TEST=apb_reg_test UVM_VERBOSITY=UVM_HIGH"
	@echo "    make run WAVE=1 GUI=1"
	@echo "    make clean"
	@echo ""
