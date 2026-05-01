// =============================================================================
// File        : apb_seq_lib.sv
// Description : Per-register RAL sequences with frontdoor & backdoor access
// =============================================================================

// =============================================================================
// Base class for common RAL sequence utilities
// =============================================================================
class base_reg_seq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(base_reg_seq)

    apb_reg_block regmodel;

    function new(string name = "base_reg_seq");
        super.new(name);
    endfunction

    // ----------------------------------------------------------------
    // Helper: Print RAL register state (mirrored, desired, actual via frontdoor)
    // ----------------------------------------------------------------
    task print_reg_state(uvm_reg rg, string reg_name);
        uvm_status_e status;
        uvm_reg_data_t mirror_val, desired_val, actual_val;

        mirror_val  = rg.get_mirrored_value();
        desired_val = rg.get();
        rg.read(status, actual_val, UVM_FRONTDOOR);

        `uvm_info("RAL_SEQ", $sformatf(
            "[%s] Desired=0x%0h  Mirrored=0x%0h  Actual(DUT)=0x%0h",
            reg_name, desired_val, mirror_val, actual_val), UVM_NONE)
    endtask

    // ----------------------------------------------------------------
    // Helper: Check reset value
    // ----------------------------------------------------------------
    task check_reset_value(uvm_reg rg, string reg_name, uvm_reg_data_t exp_reset);
        uvm_status_e   status;
        uvm_reg_data_t actual;

        rg.read(status, actual, UVM_FRONTDOOR);
        if (actual === exp_reset)
            `uvm_info("RAL_SEQ", $sformatf("[%s] RESET CHECK PASS: value=0x%0h",
                       reg_name, actual), UVM_NONE)
        else
            `uvm_error("RAL_SEQ", $sformatf("[%s] RESET CHECK FAIL: exp=0x%0h got=0x%0h",
                        reg_name, exp_reset, actual))
    endtask

endclass

// =============================================================================
// ctrl_reg_seq - Sequence for CNTRL register
// =============================================================================
class ctrl_reg_seq extends base_reg_seq;
    `uvm_object_utils(ctrl_reg_seq)

    function new(string name = "ctrl_reg_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info("RAL_SEQ", "\n=== CNTRL Register Sequence ===", UVM_NONE)

        // ---- 1. Check reset value (frontdoor) ----
        `uvm_info("RAL_SEQ", "[CNTRL] Step 1: Checking reset value via frontdoor", UVM_NONE)
        check_reset_value(regmodel.cntrl_inst, "CNTRL", 32'h00000000);

        // ---- 2. Write via FRONTDOOR ----
        wdata = 32'h0000000A;  // ctrl bits: 1010
        `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Step 2: FRONTDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.cntrl_inst.write(status, wdata, UVM_FRONTDOOR);
        if (status != UVM_IS_OK)
            `uvm_error("RAL_SEQ", "[CNTRL] Frontdoor write failed")

        // ---- 3. Read via FRONTDOOR and print state ----
        `uvm_info("RAL_SEQ", "[CNTRL] Step 3: FRONTDOOR READ", UVM_NONE)
        regmodel.cntrl_inst.read(status, rdata, UVM_FRONTDOOR);
        // cntrl is 4-bit: mask upper bits for comparison
        if ((rdata & 32'hF) === (wdata & 32'hF))
            `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Frontdoor READ PASS: 0x%0h", rdata), UVM_NONE)
        else
            `uvm_error("RAL_SEQ", $sformatf("[CNTRL] Frontdoor READ FAIL: exp=0x%0h got=0x%0h",
                        wdata & 32'hF, rdata & 32'hF))

        // ---- 4. Print mirrored/desired/actual ----
        print_reg_state(regmodel.cntrl_inst, "CNTRL");

        // ---- 5. Write different value, then check mirror ----
        wdata = 32'h00000005;  // ctrl bits: 0101
        `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Step 5: FRONTDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.cntrl_inst.write(status, wdata, UVM_FRONTDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Mirrored after write = 0x%0h",
                   regmodel.cntrl_inst.get_mirrored_value()), UVM_NONE)

        // ---- 6. Backdoor write (poke) ----
        wdata = 32'h0000000F;  // all ctrl bits set
        `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Step 6: BACKDOOR WRITE (poke) = 0x%0h", wdata), UVM_NONE)
        regmodel.cntrl_inst.write(status, wdata, UVM_BACKDOOR);
        // Note: backdoor write bypasses bus - mirror may not auto-update
        // Must call mirror() or explicit_predict() to re-sync
        regmodel.cntrl_inst.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

        // ---- 7. Backdoor read (peek) ----
        `uvm_info("RAL_SEQ", "[CNTRL] Step 7: BACKDOOR READ (peek)", UVM_NONE)
        regmodel.cntrl_inst.read(status, rdata, UVM_BACKDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[CNTRL] Backdoor read value = 0x%0h", rdata), UVM_NONE)

        // ---- 8. Sample coverage ----
        regmodel.sample_reg_access(32'h00, 1'b1);  // write
        regmodel.sample_reg_access(32'h00, 1'b0);  // read
        regmodel.sample_cntrl_value(4'hA);
        regmodel.sample_cntrl_value(4'h5);
        regmodel.sample_cntrl_value(4'hF);

        `uvm_info("RAL_SEQ", "=== CNTRL Register Sequence DONE ===\n", UVM_NONE)
    endtask

endclass

// =============================================================================
// reg1_reg_seq - Sequence for REG1
// =============================================================================
class reg1_reg_seq extends base_reg_seq;
    `uvm_object_utils(reg1_reg_seq)

    function new(string name = "reg1_reg_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info("RAL_SEQ", "\n=== REG1 Register Sequence ===", UVM_NONE)

        // Check reset
        check_reset_value(regmodel.reg1_inst, "REG1", 32'h00000000);

        // Frontdoor Write
        wdata = 32'hDEAD_BEEF;
        `uvm_info("RAL_SEQ", $sformatf("[REG1] FRONTDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg1_inst.write(status, wdata, UVM_FRONTDOOR);

        // Frontdoor Read
        regmodel.reg1_inst.read(status, rdata, UVM_FRONTDOOR);
        if (rdata === wdata)
            `uvm_info("RAL_SEQ", $sformatf("[REG1] Frontdoor READ PASS: 0x%0h", rdata), UVM_NONE)
        else
            `uvm_error("RAL_SEQ", $sformatf("[REG1] READ FAIL: exp=0x%0h got=0x%0h", wdata, rdata))

        // Print full RAL state
        print_reg_state(regmodel.reg1_inst, "REG1");

        // Backdoor write a new value
        wdata = 32'hCAFEBABE;
        `uvm_info("RAL_SEQ", $sformatf("[REG1] BACKDOOR WRITE (poke) = 0x%0h", wdata), UVM_NONE)
        regmodel.reg1_inst.write(status, wdata, UVM_BACKDOOR);

        // Frontdoor read to verify backdoor took effect in DUT
        regmodel.reg1_inst.read(status, rdata, UVM_FRONTDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[REG1] After backdoor write, frontdoor read = 0x%0h", rdata), UVM_NONE)

        // Use mirror() to check DUT matches mirror
        regmodel.reg1_inst.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

        // Coverage
        regmodel.sample_reg_access(32'h04, 1'b1);
        regmodel.sample_reg_access(32'h04, 1'b0);

        `uvm_info("RAL_SEQ", "=== REG1 Register Sequence DONE ===\n", UVM_NONE)
    endtask

endclass

// =============================================================================
// reg2_reg_seq - Sequence for REG2
// =============================================================================
class reg2_reg_seq extends base_reg_seq;
    `uvm_object_utils(reg2_reg_seq)

    function new(string name = "reg2_reg_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info("RAL_SEQ", "\n=== REG2 Register Sequence ===", UVM_NONE)

        check_reset_value(regmodel.reg2_inst, "REG2", 32'h00000000);

        // Write max value (all 1s)
        wdata = 32'hFFFF_FFFF;
        `uvm_info("RAL_SEQ", $sformatf("[REG2] FRONTDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg2_inst.write(status, wdata, UVM_FRONTDOOR);
        print_reg_state(regmodel.reg2_inst, "REG2");

        // Randomize and write
        if (!regmodel.reg2_inst.randomize())
            `uvm_error("RAL_SEQ", "[REG2] Randomization failed")
        wdata = regmodel.reg2_inst.get();  // get desired (post-randomize)
        `uvm_info("RAL_SEQ", $sformatf("[REG2] RANDOMIZED WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg2_inst.update(status, UVM_FRONTDOOR);  // write desired to DUT

        regmodel.reg2_inst.read(status, rdata, UVM_FRONTDOOR);
        if (rdata === wdata)
            `uvm_info("RAL_SEQ", $sformatf("[REG2] Randomized write READ PASS: 0x%0h", rdata), UVM_NONE)
        else
            `uvm_error("RAL_SEQ", $sformatf("[REG2] READ FAIL: exp=0x%0h got=0x%0h", wdata, rdata))

        // Backdoor read
        `uvm_info("RAL_SEQ", "[REG2] BACKDOOR READ (peek)", UVM_NONE)
        regmodel.reg2_inst.read(status, rdata, UVM_BACKDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[REG2] Backdoor peek = 0x%0h", rdata), UVM_NONE)

        regmodel.sample_reg_access(32'h08, 1'b1);
        regmodel.sample_reg_access(32'h08, 1'b0);

        `uvm_info("RAL_SEQ", "=== REG2 Register Sequence DONE ===\n", UVM_NONE)
    endtask

endclass

// =============================================================================
// reg3_reg_seq - Sequence for REG3
// =============================================================================
class reg3_reg_seq extends base_reg_seq;
    `uvm_object_utils(reg3_reg_seq)

    function new(string name = "reg3_reg_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info("RAL_SEQ", "\n=== REG3 Register Sequence ===", UVM_NONE)

        check_reset_value(regmodel.reg3_inst, "REG3", 32'h00000000);

        // Walking 1s pattern
        for (int i = 0; i < 4; i++) begin
            wdata = (32'h1 << (i * 8));
            `uvm_info("RAL_SEQ", $sformatf("[REG3] WALKING 1s WRITE [iter=%0d] = 0x%0h", i, wdata), UVM_NONE)
            regmodel.reg3_inst.write(status, wdata, UVM_FRONTDOOR);
            regmodel.reg3_inst.read(status, rdata, UVM_FRONTDOOR);
            if (rdata === wdata)
                `uvm_info("RAL_SEQ", $sformatf("[REG3] Walking 1s PASS iter=%0d", i), UVM_NONE)
            else
                `uvm_error("RAL_SEQ", $sformatf("[REG3] Walking 1s FAIL iter=%0d exp=0x%0h got=0x%0h",
                            i, wdata, rdata))
        end

        print_reg_state(regmodel.reg3_inst, "REG3");

        // Backdoor write
        wdata = 32'hA5A5_A5A5;
        `uvm_info("RAL_SEQ", $sformatf("[REG3] BACKDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg3_inst.write(status, wdata, UVM_BACKDOOR);

        // Backdoor read
        regmodel.reg3_inst.read(status, rdata, UVM_BACKDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[REG3] BACKDOOR READ = 0x%0h", rdata), UVM_NONE)

        regmodel.sample_reg_access(32'h0C, 1'b1);
        regmodel.sample_reg_access(32'h0C, 1'b0);

        `uvm_info("RAL_SEQ", "=== REG3 Register Sequence DONE ===\n", UVM_NONE)
    endtask

endclass

// =============================================================================
// reg4_reg_seq - Sequence for REG4
// =============================================================================
class reg4_reg_seq extends base_reg_seq;
    `uvm_object_utils(reg4_reg_seq)

    function new(string name = "reg4_reg_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t rdata;
        uvm_reg_data_t wdata;

        `uvm_info("RAL_SEQ", "\n=== REG4 Register Sequence ===", UVM_NONE)

        check_reset_value(regmodel.reg4_inst, "REG4", 32'h00000000);

        // Write a pattern
        wdata = 32'h1234_5678;
        `uvm_info("RAL_SEQ", $sformatf("[REG4] FRONTDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg4_inst.write(status, wdata, UVM_FRONTDOOR);

        // Frontdoor read verify
        regmodel.reg4_inst.read(status, rdata, UVM_FRONTDOOR);
        if (rdata === wdata)
            `uvm_info("RAL_SEQ", $sformatf("[REG4] Frontdoor READ PASS: 0x%0h", rdata), UVM_NONE)
        else
            `uvm_error("RAL_SEQ", $sformatf("[REG4] READ FAIL: exp=0x%0h got=0x%0h", wdata, rdata))

        print_reg_state(regmodel.reg4_inst, "REG4");

        // Backdoor write
        wdata = 32'h5A5A_5A5A;
        `uvm_info("RAL_SEQ", $sformatf("[REG4] BACKDOOR WRITE = 0x%0h", wdata), UVM_NONE)
        regmodel.reg4_inst.write(status, wdata, UVM_BACKDOOR);

        // Use mirror() with UVM_CHECK to auto-compare DUT vs mirror
        `uvm_info("RAL_SEQ", "[REG4] Calling mirror(UVM_CHECK) - RAL will verify DUT matches mirror", UVM_NONE)
        regmodel.reg4_inst.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

        // Backdoor read
        regmodel.reg4_inst.read(status, rdata, UVM_BACKDOOR);
        `uvm_info("RAL_SEQ", $sformatf("[REG4] BACKDOOR READ = 0x%0h", rdata), UVM_NONE)

        regmodel.sample_reg_access(32'h10, 1'b1);
        regmodel.sample_reg_access(32'h10, 1'b0);

        `uvm_info("RAL_SEQ", "=== REG4 Register Sequence DONE ===\n", UVM_NONE)
    endtask

endclass
