// =============================================================================
// File        : apb_agent.sv
// Description : UVM Agent
// =============================================================================

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver                       drv;
    uvm_sequencer #(apb_transaction) sequencer;
    apb_monitor                      mon;

    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = apb_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            drv       = apb_driver::type_id::create("drv", this);
            sequencer = uvm_sequencer #(apb_transaction)::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
