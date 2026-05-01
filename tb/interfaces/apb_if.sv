// =============================================================================
// File        : apb_if.sv
// Description : APB Interface with clocking blocks for proper signal sampling
// =============================================================================

interface apb_if (input logic pclk);

    logic [31:0]    paddr;
    logic [31:0]    pwdata;
    logic [31:0]    prdata;
    logic           pwrite;
    logic           psel;
    logic           penable;
    logic           presetn;

    // ------------------------------------------------------------
    // Clocking block for driver (active agent)
    // ------------------------------------------------------------
    clocking driver_cb @(posedge pclk);
        default input #1step output #1;
        output paddr, pwdata, pwrite, psel, penable, presetn;
        input  prdata;
    endclocking

    // ------------------------------------------------------------
    // Clocking block for monitor (passive sampling)
    // ------------------------------------------------------------
    clocking monitor_cb @(posedge pclk);
        default input #1step;
        input paddr, pwdata, prdata, pwrite, psel, penable, presetn;
    endclocking

    // ------------------------------------------------------------
    // Modports
    // ------------------------------------------------------------
    modport DRIVER  (clocking driver_cb,  input pclk);
    modport MONITOR (clocking monitor_cb, input pclk);

endinterface
