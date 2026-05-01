// =============================================================================
// File        : apb_register_bank.sv
// Description : APB Peripheral DUT - Register Bank
// Registers   : cntrl (4-bit), reg1-reg4 (32-bit each)
// =============================================================================

module apb_register_bank
(
    input               pclk,
    input               presetn,
    input   [31 : 0]    paddr,
    input   [31 : 0]    pwdata,
    input               psel,
    input               pwrite,
    input               penable,
    output  [31 : 0]    prdata
);

  reg [3:0]  cntrl; // cntrl : [ctrl3 ctrl2 ctrl1 ctrl0]
  reg [31:0] reg1;  // data input 1
  reg [31:0] reg2;  // data input 2
  reg [31:0] reg3;  // data input 3
  reg [31:0] reg4;  // data input 4

  reg [31:0] rdata_tmp;

  // Register write/read logic
  always @ (posedge pclk) begin
    if (!presetn) begin
      cntrl     <= 4'b0000;
      reg1      <= 32'h00000000;
      reg2      <= 32'h00000000;
      reg3      <= 32'h00000000;
      reg4      <= 32'h00000000;
      rdata_tmp <= 32'h00000000;
    end
    // Write: occurs in ACCESS phase (psel & penable & pwrite)
    else if (psel && penable && pwrite) begin
      case (paddr)
        'h00 : cntrl <= pwdata[3:0];
        'h04 : reg1  <= pwdata;
        'h08 : reg2  <= pwdata;
        'h0C : reg3  <= pwdata;
        'h10 : reg4  <= pwdata;
      endcase
    end
    else if (psel && penable && !pwrite) begin
      case (paddr)
        'h00 : rdata_tmp <= {28'h0000000, cntrl};
        'h04 : rdata_tmp <= reg1;
        'h08 : rdata_tmp <= reg2;
        'h0C : rdata_tmp <= reg3;
        'h10 : rdata_tmp <= reg4;
        default : rdata_tmp <= 32'h00000000;
      endcase
    end
  end

  assign prdata = rdata_tmp;

endmodule
