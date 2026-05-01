// =============================================================================
// File        : apb_test.sv
// Description : UVM Test - Launches all 5 register sequences
// =============================================================================

class apb_reg_test extends uvm_test;
    `uvm_component_utils(apb_reg_test)

    apb_env e;

    // One instance per register sequence
    ctrl_reg_seq  cntrl_seq;
    reg1_reg_seq  r1_seq;
    reg2_reg_seq  r2_seq;
    reg3_reg_seq  r3_seq;
    reg4_reg_seq  r4_seq;

    function new(string name = "apb_reg_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        e = apb_env::type_id::create("e", this);

        // Create all 5 register sequences
        cntrl_seq = ctrl_reg_seq::type_id::create("cntrl_seq");
        r1_seq    = reg1_reg_seq::type_id::create("r1_seq");
        r2_seq    = reg2_reg_seq::type_id::create("r2_seq");
        r3_seq    = reg3_reg_seq::type_id::create("r3_seq");
        r4_seq    = reg4_reg_seq::type_id::create("r4_seq");
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (!uvm_config_db #(apb_reg_block)::get(this, "e", "regmodel", cntrl_seq.regmodel))
            // Fallback: direct handle if config_db not populated
            cntrl_seq.regmodel = e.regmodel;

        r1_seq.regmodel = e.regmodel;
        r2_seq.regmodel = e.regmodel;
        r3_seq.regmodel = e.regmodel;
        r4_seq.regmodel = e.regmodel;
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info("APB_TEST", "\n\n========== TEST STARTED ==========\n", UVM_NONE)

        // ---- CNTRL Register ----
        `uvm_info("APB_TEST", "--- Starting CNTRL register sequence ---", UVM_NONE)
        cntrl_seq.start(e.agent_inst.sequencer);

        // ---- REG1 ----
        `uvm_info("APB_TEST", "--- Starting REG1 register sequence ---", UVM_NONE)
        r1_seq.start(e.agent_inst.sequencer);

        // ---- REG2 ----
        `uvm_info("APB_TEST", "--- Starting REG2 register sequence ---", UVM_NONE)
        r2_seq.start(e.agent_inst.sequencer);

        // ---- REG3 ----
        `uvm_info("APB_TEST", "--- Starting REG3 register sequence ---", UVM_NONE)
        r3_seq.start(e.agent_inst.sequencer);

        // ---- REG4 ----
        `uvm_info("APB_TEST", "--- Starting REG4 register sequence ---", UVM_NONE)
        r4_seq.start(e.agent_inst.sequencer);

        `uvm_info("APB_TEST", "\n\n========== TEST COMPLETED ==========\n", UVM_NONE)

        phase.drop_objection(this);
    endtask

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
        // Print RAL model for verification
        `uvm_info("APB_TEST", $sformatf("RAL Model:\n%s", e.regmodel.sprint()), UVM_HIGH)
    endfunction

endclass
