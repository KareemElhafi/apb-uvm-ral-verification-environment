// =============================================================================
// File        : tb_top.sv
// Description : Testbench Top Module
// =============================================================================

`timescale 1ns/1ps

`include "apb_pkg.sv"

import uvm_pkg::*;
import apb_pkg::*;

module tb_top;

    // Clock signal
    logic pclk;

    // Clock generation: 20ns period = 50 MHz
    initial pclk = 1'b0;
    always #10 pclk = ~pclk;

    apb_if vif(.pclk(pclk));

    // Instantiate DUT
    apb_register_bank dut (
        .pclk    (vif.pclk),
        .presetn (vif.presetn),
        .paddr   (vif.paddr),
        .pwdata  (vif.pwdata),
        .psel    (vif.psel),
        .pwrite  (vif.pwrite),
        .penable (vif.penable),
        .prdata  (vif.prdata)
    );

    initial begin
        // Set virtual interface in config DB (wildcard "*" reaches all components)
        uvm_config_db #(virtual apb_if)::set(null, "*", "vif", vif);

        // Run the test
        run_test("apb_reg_test");
    end

    // Simulation timeout guard - prevent infinite loops
    initial begin
        #1_000_000;
        `uvm_fatal("TB_TOP", "SIMULATION TIMEOUT - test did not complete in time")
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
