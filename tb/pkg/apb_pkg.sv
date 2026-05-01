// =============================================================================
// File        : apb_pkg.sv
// Description : UVM Package - includes all TB files in correct order
// =============================================================================

package apb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 1. Base transaction (no dependencies)
    `include "apb_transaction.sv"

    // 2. RAL model (no component dependencies)
    `include "apb_reg_block.sv"

    // 3. Sequences (depend on apb_reg_block and apb_transaction)
    `include "apb_seq_lib.sv"

    // 4. Driver and Monitor (depend on apb_transaction and interface)
    `include "apb_driver.sv"
    `include "apb_monitor.sv"

    // 5. Scoreboard (depends on apb_transaction)
    `include "apb_scoreboard.sv"

    // 6. Adapter (depends on apb_transaction and apb_reg_block)
    `include "apb_reg_adapter.sv"

    // 7. Agent (depends on apb_driver, apb_monitor, sequencer)
    `include "apb_agent.sv"

    // 8. Environment (depends on apb_agent, apb_reg_block, apb_reg_adapter)
    `include "apb_env.sv"

    // 9. Test (depends on apb_env and sequences)
    `include "apb_test.sv"

endpackage
