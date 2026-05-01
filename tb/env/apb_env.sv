// =============================================================================
// File        : apb_env.sv
// Description : UVM Environment
// =============================================================================

class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent                              agent_inst;
    apb_reg_block                          regmodel;
    apb_reg_adapter                        adapter_inst;
    uvm_reg_predictor #(apb_transaction)   predictor_inst;
    apb_scoreboard                         scoreboard;

    function new(string name = "apb_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent_inst     = apb_agent::type_id::create("agent_inst", this);
        scoreboard     = apb_scoreboard::type_id::create("scoreboard", this);

        regmodel       = apb_reg_block::type_id::create("regmodel", this);
        regmodel.build();

        predictor_inst = uvm_reg_predictor #(apb_transaction)::type_id::create("predictor_inst", this);

        adapter_inst   = apb_reg_adapter::type_id::create("adapter_inst", this);

        uvm_config_db #(apb_reg_block)::set(this, "*", "regmodel", regmodel);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Scoreboard connection
        agent_inst.mon.mon_ap.connect(scoreboard.recv);

        // Predictor connection (explicit predictor updates RAL mirror)
        agent_inst.mon.mon_ap.connect(predictor_inst.bus_in);

        // RAL map <-> sequencer/adapter binding
        regmodel.default_map.set_sequencer(
            .sequencer(agent_inst.sequencer),
            .adapter(adapter_inst)
        );
        regmodel.default_map.set_base_addr(0);

        // Predictor needs map and adapter references
        predictor_inst.map     = regmodel.default_map;
        predictor_inst.adapter = adapter_inst;
    endfunction

endclass
