// =============================================================================
// File        : apb_driver.sv
// Description : APB Driver
// =============================================================================

class apb_driver extends uvm_driver #(apb_transaction);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;
    apb_transaction apb_tr;

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_DRV", "Failed to get virtual interface from config_db")
    endfunction

    // ----------------------------------------------------------------
    // APB WRITE Transaction
    // APB Spec: SETUP (T1): psel=1, penable=0, pwrite=1, paddr/pwdata valid
    // ----------------------------------------------------------------
    virtual task apb_write();
        // SETUP phase
        @(vif.driver_cb);
        vif.driver_cb.paddr   <= apb_tr.paddr;
        vif.driver_cb.pwdata  <= apb_tr.pwdata;
        vif.driver_cb.pwrite  <= 1'b1;
        vif.driver_cb.psel    <= 1'b1;
        vif.driver_cb.penable <= 1'b0;

        // ACCESS phase
        @(vif.driver_cb);
        vif.driver_cb.penable <= 1'b1;
        `uvm_info("APB_DRV", $sformatf("WRITE -> ADDR=0x%0h DATA=0x%0h",
                   apb_tr.paddr, apb_tr.pwdata), UVM_MEDIUM)

        // End of access - deassert
        @(vif.driver_cb);
        vif.driver_cb.psel    <= 1'b0;
        vif.driver_cb.penable <= 1'b0;
        vif.driver_cb.pwrite  <= 1'b0;
    endtask

    // ----------------------------------------------------------------
    // APB READ Transaction
    // ----------------------------------------------------------------
    virtual task apb_read();
        // SETUP phase
        @(vif.driver_cb);
        vif.driver_cb.paddr   <= apb_tr.paddr;
        vif.driver_cb.pwrite  <= 1'b0;
        vif.driver_cb.psel    <= 1'b1;
        vif.driver_cb.penable <= 1'b0;

        // ACCESS phase
        @(vif.driver_cb);
        vif.driver_cb.penable <= 1'b1;

        @(vif.driver_cb);
        apb_tr.prdata = vif.driver_cb.prdata;
        `uvm_info("APB_DRV", $sformatf("READ  -> ADDR=0x%0h DATA=0x%0h",
                   apb_tr.paddr, apb_tr.prdata), UVM_MEDIUM)

        // Deassert
        vif.driver_cb.psel    <= 1'b0;
        vif.driver_cb.penable <= 1'b0;
    endtask

    // ----------------------------------------------------------------
    // Run Phase
    // ----------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        // Initialize all signals
        vif.driver_cb.presetn <= 1'b0;
        vif.driver_cb.psel    <= 1'b0;
        vif.driver_cb.penable <= 1'b0;
        vif.driver_cb.pwrite  <= 1'b0;
        vif.driver_cb.paddr   <= 32'h0;
        vif.driver_cb.pwdata  <= 32'h0;

        repeat(5) @(vif.driver_cb);
        vif.driver_cb.presetn <= 1'b1;
        `uvm_info("APB_DRV", "Reset deasserted", UVM_LOW)

        forever begin
            seq_item_port.get_next_item(apb_tr);
            if (apb_tr.pwrite)
                apb_write();
            else
                apb_read();
            seq_item_port.item_done();
        end
    endtask

endclass
