// =============================================================================
// File        : apb_reg_block.sv
// Description : UVM RAL Register Model with Functional Coverage
// =============================================================================

// =============================================================================
// CNTRL Register (4-bit, address 0x00)
// =============================================================================
class cntrl_reg extends uvm_reg;
    `uvm_object_utils(cntrl_reg)

    rand uvm_reg_field cntrl;
    rand uvm_reg_field reserved;

    function new(string name = "cntrl_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
    endfunction

    virtual function void build();
        cntrl    = uvm_reg_field::type_id::create("cntrl");
        reserved = uvm_reg_field::type_id::create("reserved");

        // cntrl field: 4 bits at bit[3:0], RW, no hw_access, reset=0
        cntrl.configure(this, 4, 0, "RW", 0, 4'h0, 1, 1, 1);
        // reserved: upper 28 bits, read-only, always 0
        reserved.configure(this, 28, 4, "RO", 0, 28'h0, 1, 0, 0);
    endfunction

endclass

// =============================================================================
// REG1 (32-bit, address 0x04)
// =============================================================================
class reg1_reg extends uvm_reg;
    `uvm_object_utils(reg1_reg)
    rand uvm_reg_field reg1;

    function new(string name = "reg1_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
    endfunction

    virtual function void build();
        reg1 = uvm_reg_field::type_id::create("reg1");
        reg1.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction

endclass

// =============================================================================
// REG2 (32-bit, address 0x08)
// =============================================================================
class reg2_reg extends uvm_reg;
    `uvm_object_utils(reg2_reg)
    rand uvm_reg_field reg2;

    function new(string name = "reg2_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
    endfunction

    virtual function void build();
        reg2 = uvm_reg_field::type_id::create("reg2");
        reg2.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction

endclass

// =============================================================================
// REG3 (32-bit, address 0x0C)
// =============================================================================
class reg3_reg extends uvm_reg;
    `uvm_object_utils(reg3_reg)
    rand uvm_reg_field reg3;

    function new(string name = "reg3_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
    endfunction

    virtual function void build();
        reg3 = uvm_reg_field::type_id::create("reg3");
        reg3.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction

endclass

// =============================================================================
// REG4 (32-bit, address 0x10)
// =============================================================================
class reg4_reg extends uvm_reg;
    `uvm_object_utils(reg4_reg)
    rand uvm_reg_field reg4;

    function new(string name = "reg4_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
    endfunction

    virtual function void build();
        reg4 = uvm_reg_field::type_id::create("reg4");
        reg4.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction

endclass

// =============================================================================
// Register Block + Functional Coverage
// =============================================================================
class apb_reg_block extends uvm_reg_block;
    `uvm_object_utils(apb_reg_block)

    cntrl_reg cntrl_inst;
    reg1_reg  reg1_inst;
    reg2_reg  reg2_inst;
    reg3_reg  reg3_inst;
    reg4_reg  reg4_inst;

    // ------------------------------------------------------------
    // Functional Coverage for register accesses
    // ------------------------------------------------------------
    covergroup apb_reg_cg with function sample(bit [31:0] addr, bit write);
        // Which register is accessed
        cp_addr: coverpoint addr {
            bins CNTRL = {32'h00};
            bins REG1  = {32'h04};
            bins REG2  = {32'h08};
            bins REG3  = {32'h0C};
            bins REG4  = {32'h10};
        }

        // Access type
        cp_access: coverpoint write {
            bins WRITE = {1'b1};
            bins READ  = {1'b0};
        }

        // Cross: every register should be both read and written
        cx_addr_access: cross cp_addr, cp_access;
    endgroup

    // Additional covergroup for cntrl register field values
    covergroup cntrl_field_cg with function sample(bit [3:0] ctrl_val);
        cp_ctrl_bits: coverpoint ctrl_val {
            bins ALL_ZERO  = {4'b0000};
            bins ALL_ONE   = {4'b1111};
            bins WALKING_1 = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            bins OTHERS    = default;
        }
    endgroup

    function new(string name = "apb_reg_block");
        super.new(name, build_coverage(UVM_NO_COVERAGE));
        apb_reg_cg   = new();
        cntrl_field_cg = new();
    endfunction

    virtual function void build();
        cntrl_inst = cntrl_reg::type_id::create("cntrl_inst");
        cntrl_inst.build();
        cntrl_inst.configure(this, null);

        reg1_inst = reg1_reg::type_id::create("reg1_inst");
        reg1_inst.build();
        reg1_inst.configure(this, null);

        reg2_inst = reg2_reg::type_id::create("reg2_inst");
        reg2_inst.build();
        reg2_inst.configure(this, null);

        reg3_inst = reg3_reg::type_id::create("reg3_inst");
        reg3_inst.build();
        reg3_inst.configure(this, null);

        reg4_inst = reg4_reg::type_id::create("reg4_inst");
        reg4_inst.build();
        reg4_inst.configure(this, null);

        // Map: name, base_addr, n_bytes, endian, byte_addressing
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 1);

        default_map.add_reg(cntrl_inst, 'h00, "RW");
        default_map.add_reg(reg1_inst,  'h04, "RW");
        default_map.add_reg(reg2_inst,  'h08, "RW");
        default_map.add_reg(reg3_inst,  'h0C, "RW");
        default_map.add_reg(reg4_inst,  'h10, "RW");

        lock_model();
    endfunction

    // Convenience function to sample coverage from sequences
    function void sample_reg_access(bit [31:0] addr, bit write);
        apb_reg_cg.sample(addr, write);
    endfunction

    function void sample_cntrl_value(bit [3:0] val);
        cntrl_field_cg.sample(val);
    endfunction

endclass
