// =============================================================================
// File        : apb_monitor.sv
// Description : APB Monitor - Passive observation only
// =============================================================================

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    uvm_analysis_port #(apb_transaction) mon_ap;
    virtual apb_if vif;

    function new(string name = "apb_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_MON", "Failed to get virtual interface from config_db")
    endfunction

    // ----------------------------------------------------------------
    // Run Phase - Sample APB transactions
    // ----------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        apb_transaction apb_tr;

        // Wait for reset to deassert
        @(posedge vif.pclk iff vif.presetn === 1'b1);
        `uvm_info("APB_MON", "Reset deasserted - monitoring started", UVM_LOW)

        forever begin
            // Detect SETUP phase: psel=1, penable=0
            @(vif.monitor_cb);
            if (vif.monitor_cb.psel && !vif.monitor_cb.penable && vif.monitor_cb.presetn) begin
                apb_tr = apb_transaction::type_id::create("apb_tr");
                apb_tr.paddr  = vif.monitor_cb.paddr;
                apb_tr.pwrite = vif.monitor_cb.pwrite;

                // Wait for ACCESS phase: penable=1
                @(vif.monitor_cb);
                if (vif.monitor_cb.psel && vif.monitor_cb.penable) begin
                    if (vif.monitor_cb.pwrite) begin
                        // WRITE: pwdata valid during access phase
                        apb_tr.pwdata = vif.monitor_cb.pwdata;
                        `uvm_info("APB_MON", $sformatf("WRITE -> ADDR=0x%0h DATA=0x%0h",
                                   apb_tr.paddr, apb_tr.pwdata), UVM_MEDIUM)
                    end else begin
                        // READ: prdata registered - valid ONE cycle after access
                        @(vif.monitor_cb);
                        apb_tr.prdata = vif.monitor_cb.prdata;
                        `uvm_info("APB_MON", $sformatf("READ  -> ADDR=0x%0h DATA=0x%0h",
                                   apb_tr.paddr, apb_tr.prdata), UVM_MEDIUM)
                    end
                    mon_ap.write(apb_tr);
                end
            end
        end
    endtask

endclass
