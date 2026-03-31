interface apb_if #(parameter APB_ADDR_WIDTH = 4)(
    input logic pclk,
    input logic presetn
);

    logic [APB_ADDR_WIDTH-1:0] paddr;
    logic                      psel;
    logic                      penable;
    logic                      pwrite;
    logic [31:0]               pwdata;
    logic [31:0]               prdata;
    logic                      pready;
    logic                      pslverr;

    clocking cb_driver @(posedge pclk);
        output  paddr, psel, penable, pwrite, pwdata;
        input   prdata, pready, pslverr;
    endclocking

    clocking cb_monitor @(posedge pclk);
        input paddr, psel, penable, pwrite, pwdata, prdata, pready, pslverr;
    endclocking

    modport mp_driver (clocking cb_driver, input presetn);
    modport mp_monitor (clocking cb_monitor, input presetn);

endinterface : apb_if