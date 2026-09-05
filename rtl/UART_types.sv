`timescale 1ns / 1ps

package uart_types_pkg;

    typedef struct packed {
        logic [1:0] rx_trigger;
        logic [1:0] reserved;
        logic       dma_mode;
        logic       tx_rst;
        logic       rx_rst;
        logic       ena;
    } fcr_t;

    typedef struct packed {
        logic       dlab;
        logic       set_break;
        logic       stick_parity;
        logic       eps;
        logic       pen;
        logic       stb;
        logic [1:0] wls;
    } lcr_t;

    typedef struct packed {
        logic       rx_fifo_error;
        logic       temt;
        logic       thre;
        logic       bi;
        logic       fe;
        logic       pe;
        logic       oe;
        logic       dr;
    } lsr_t;
    

    typedef struct packed {
        fcr_t       fcr;
        lcr_t       lcr;
        lsr_t       lsr;
        logic [7:0]  scr;
    } csr_t;

    typedef struct packed {
        logic [7:0] dmsb;
        logic [7:0] dlsb;
    } div_t;

endpackage