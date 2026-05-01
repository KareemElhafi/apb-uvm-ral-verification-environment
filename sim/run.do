# =============================================================================
# File        : run.do
# Project     : APB UVM RAL Verification Environment
# Description : QuestaSim simulation script
#               Compiles all sources in correct dependency order and
#               launches the UVM test with waveform logging enabled.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Create and map the simulation library
# -----------------------------------------------------------------------------
if { [file exists work] } {
    vdel -lib work -all
}
vlib work
vmap work work

# -----------------------------------------------------------------------------
# 2. Define shared compilation flags
#    +acc          : Enables full visibility for waveform access
#    -sv           : Enables SystemVerilog
#    +incdir       : Add UVM include path (adjust if needed)
# -----------------------------------------------------------------------------
set UVM_HOME $env(UVM_HOME)

set COMPILE_OPTS "-sv -timescale 1ns/1ps +acc"
set UVM_OPTS    "+incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm_pkg.sv"

# -----------------------------------------------------------------------------
# 3. Define include directories for the testbench
# -----------------------------------------------------------------------------
set TB_INCDIRS \
    "+incdir+../tb \
     +incdir+../tb/agents \
     +incdir+../tb/env \
     +incdir+../tb/interfaces \
     +incdir+../tb/pkg \
     +incdir+../tb/reg_model \
     +incdir+../tb/scoreboard \
     +incdir+../tb/sequences \
     +incdir+../tb/tests"


echo "============================================================"
echo " [COMPILE] UVM Package"
echo "============================================================"
eval vlog {*}$COMPILE_OPTS {*}$UVM_OPTS

echo "============================================================"
echo " [COMPILE] APB Interface"
echo "============================================================"
vlog $COMPILE_OPTS \
    +incdir+../tb/interfaces \
    ../tb/interfaces/apb_if.sv

echo "============================================================"
echo " [COMPILE] APB UVM Package (all TB classes)"
echo "============================================================"
vlog $COMPILE_OPTS \
    {*}$TB_INCDIRS \
    ../tb/pkg/apb_pkg.sv

echo "============================================================"
echo " [COMPILE] RTL - APB Register Bank"
echo "============================================================"
vlog $COMPILE_OPTS \
    ../rtl/apb_register_bank.sv

echo "============================================================"
echo " [COMPILE] Testbench Top"
echo "============================================================"
vlog $COMPILE_OPTS \
    {*}$TB_INCDIRS \
    ../tb/tb_top.sv

echo "============================================================"
echo " [SIMULATE] Starting UVM simulation"
echo "============================================================"

vsim -L work \
     -timescale 1ns/1ps \
     +UVM_TESTNAME=apb_reg_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     +UVM_NO_RELNOTES \
     +acc \
     -voptargs=+acc \
     work.tb_top \
     -do {

        # ------------------------------------------------------------------
        # 6. Waveform setup — log all signals to dump.vcd and add to wave
        # ------------------------------------------------------------------
        log -r /*

        add wave -divider "--- Clock & Reset ---"
        add wave /tb_top/vif/pclk
        add wave /tb_top/vif/presetn

        add wave -divider "--- APB Bus ---"
        add wave /tb_top/vif/psel
        add wave /tb_top/vif/penable
        add wave /tb_top/vif/pwrite
        add wave /tb_top/vif/paddr
        add wave /tb_top/vif/pwdata
        add wave /tb_top/vif/prdata

        add wave -divider "--- DUT Internals ---"
        add wave /tb_top/dut/cntrl
        add wave /tb_top/dut/reg1
        add wave /tb_top/dut/reg2
        add wave /tb_top/dut/reg3
        add wave /tb_top/dut/reg4

        # ------------------------------------------------------------------
        # 7. Run simulation to completion
        # ------------------------------------------------------------------
        run -all

        # ------------------------------------------------------------------
        # 8. Quit after simulation finishes
        # ------------------------------------------------------------------
        quit -f
     }
