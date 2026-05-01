// =============================================================================
// File        : apb_transaction.sv
// Description : APB Transaction Item
// =============================================================================

class apb_transaction extends uvm_sequence_item;
    `uvm_object_utils(apb_transaction)

    // APB signals
    rand bit [31:0] paddr;
    rand bit [31:0] pwdata;
         bit [31:0] prdata;   // output - not randomized
    rand bit        pwrite;

    // ------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------
    // Valid APB register addresses
    typedef enum bit [31:0] {
        ADDR_CNTRL = 32'h00,
        ADDR_REG1  = 32'h04,
        ADDR_REG2  = 32'h08,
        ADDR_REG3  = 32'h0C,
        ADDR_REG4  = 32'h10
    } apb_addr_e;

    constraint c_paddr {
        paddr inside {32'h00, 32'h04, 32'h08, 32'h0C, 32'h10};
    }

    constraint c_cntrl_data {
        (paddr == 32'h00) -> (pwdata[31:4] == 28'h0);
    }

    constraint c_pwrite_dist {
        pwrite dist {1'b1 := 50, 1'b0 := 50};
    }

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction


    function void do_copy(uvm_object rhs);
        apb_transaction rhs_;
        super.do_copy(rhs);
        assert($cast(rhs_, rhs));
        paddr  = rhs_.paddr;
        pwdata = rhs_.pwdata;
        prdata = rhs_.prdata;
        pwrite = rhs_.pwrite;
    endfunction


    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        apb_transaction rhs_;
        assert($cast(rhs_, rhs));
        return (super.do_compare(rhs, comparer) &&
                (paddr  == rhs_.paddr)           &&
                (pwdata == rhs_.pwdata)           &&
                (prdata == rhs_.prdata)           &&
                (pwrite == rhs_.pwrite));
    endfunction


    function string convert2string();
        return $sformatf("pwrite=%0b paddr=0x%0h pwdata=0x%0h prdata=0x%0h",
                          pwrite, paddr, pwdata, prdata);
    endfunction

endclass
