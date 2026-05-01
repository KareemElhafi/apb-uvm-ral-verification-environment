// =============================================================================
// File        : apb_reg_adapter.sv
// Description : UVM RAL Adapter - Bridges RAL operations to APB transactions
// =============================================================================

class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)

    function new(string name = "apb_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses   = 0;  // Driver completes transaction, no separate response
    endfunction

    // ----------------------------------------------------------------
    // reg2bus: Translate RAL operation -> APB transaction
    // ----------------------------------------------------------------
    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_transaction apb_tr;
        apb_tr = apb_transaction::type_id::create("apb_tr");

        apb_tr.pwrite = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
        apb_tr.paddr  = rw.addr;
        apb_tr.pwdata = rw.data;

        `uvm_info("APB_REG_ADAPTER", $sformatf("reg2bus: %s ADDR=0x%0h DATA=0x%0h",
                   rw.kind.name(), rw.addr, rw.data), UVM_HIGH)
        return apb_tr;
    endfunction

    // ----------------------------------------------------------------
    // bus2reg: Translate APB transaction -> RAL operation result
    // ----------------------------------------------------------------
    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_transaction apb_tr;
        if (!$cast(apb_tr, bus_item))
            `uvm_fatal("APB_REG_ADAPTER", "bus2reg: Failed to cast to apb_transaction")

        rw.kind   = (apb_tr.pwrite) ? UVM_WRITE : UVM_READ;
        rw.data   = (apb_tr.pwrite) ? apb_tr.pwdata : apb_tr.prdata;
        rw.addr   = apb_tr.paddr;
        rw.status = UVM_IS_OK;

        `uvm_info("APB_REG_ADAPTER", $sformatf("bus2reg: %s ADDR=0x%0h DATA=0x%0h",
                   rw.kind.name(), rw.addr, rw.data), UVM_HIGH)
    endfunction

endclass
