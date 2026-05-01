// =============================================================================
// File        : apb_scoreboard.sv
// Description : APB Scoreboard - Reference model + checker
// =============================================================================

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_transaction, apb_scoreboard) recv;

    bit [31:0] ref_model [bit[31:0]];

    // Statistics
    int unsigned pass_count  = 0;
    int unsigned fail_count  = 0;
    int unsigned write_count = 0;
    int unsigned read_count  = 0;

    // Valid address set for checking
    bit [31:0] VALID_ADDRS[$] = '{32'h00, 32'h04, 32'h08, 32'h0C, 32'h10};

    function new(string name = "apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        recv = new("recv", this);
        // Initialize reference model to reset values
        ref_model[32'h00] = 32'h00000000;
        ref_model[32'h04] = 32'h00000000;
        ref_model[32'h08] = 32'h00000000;
        ref_model[32'h0C] = 32'h00000000;
        ref_model[32'h10] = 32'h00000000;
    endfunction

    virtual function void write(apb_transaction apb_tr);
        bit addr_valid;

        // Check if address is valid
        addr_valid = 0;
        foreach (VALID_ADDRS[i])
            if (VALID_ADDRS[i] == apb_tr.paddr) addr_valid = 1;

        if (!addr_valid) begin
            `uvm_error("APB_SCO", $sformatf("Invalid address received: 0x%0h", apb_tr.paddr))
            return;
        end

        if (apb_tr.pwrite) begin
            // WRITE: Update reference model
            if (apb_tr.paddr == 32'h00)
                ref_model[apb_tr.paddr] = {28'h0, apb_tr.pwdata[3:0]};
            else
                ref_model[apb_tr.paddr] = apb_tr.pwdata;

            write_count++;
            `uvm_info("APB_SCO", $sformatf("WRITE -> ADDR=0x%0h DATA=0x%0h [ref_model updated]",
                       apb_tr.paddr, ref_model[apb_tr.paddr]), UVM_MEDIUM)
        end
        else begin
            // READ: Compare DUT output with reference model
            read_count++;
            if (ref_model[apb_tr.paddr] === apb_tr.prdata) begin
                pass_count++;
                `uvm_info("APB_SCO", $sformatf("PASS -> ADDR=0x%0h EXP=0x%0h GOT=0x%0h",
                           apb_tr.paddr, ref_model[apb_tr.paddr], apb_tr.prdata), UVM_MEDIUM)
            end else begin
                fail_count++;
                `uvm_error("APB_SCO", $sformatf("FAIL -> ADDR=0x%0h EXP=0x%0h GOT=0x%0h",
                            apb_tr.paddr, ref_model[apb_tr.paddr], apb_tr.prdata))
            end
        end

        `uvm_info("APB_SCO", "----------------------------------------------------------------", UVM_HIGH)
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("APB_SCO", $sformatf(
            "\n====== SCOREBOARD SUMMARY ======\n  Writes : %0d\n  Reads  : %0d\n  PASS   : %0d\n  FAIL   : %0d\n================================",
            write_count, read_count, pass_count, fail_count), UVM_NONE)
        if (fail_count > 0)
            `uvm_error("APB_SCO", "*** TEST FAILED: One or more comparisons failed ***")
        else
            `uvm_info("APB_SCO", "*** TEST PASSED: All comparisons matched ***", UVM_NONE)
    endfunction

endclass
