
`timescale 1ns / 1ps

import uart_types_pkg::*;

module all_mod(
    input clk,
    input rst,
    input wr,
    input rd,
    input rx,
    input [2:0] addr,
    input [7:0] din,

    input cts,
    input dsr,
    input ri,
    input dcd,

    output tx,
    output [7:0] dout,

    output dtr,
    output rts,
    output out1,
    output out2,
    output loopback,

    output irq,
    output [7:0] iir
);

    csr_t csr;
    ier_t ier;

    wire baud_pulse;

    wire tx_fifo_pop;
    wire [7:0] tx_fifo_out;
    wire tx_fifo_push;
    wire tx_fifo_empty;

    wire r_oe;
    wire r_pe;
    wire r_fe;
    wire r_bi;

    wire rx_fifo_push;
    wire rx_fifo_pop;
    wire rx_fifo_empty;

    wire tx_rst;
    wire rx_rst;

    wire [3:0] rx_fifo_threshold;

    wire [7:0] rx_out;
    wire [7:0] rx_fifo_out;

    wire rda_pending;
    wire thre_pending;

    wire modem_change;
    wire [7:0] modem_dout;

    regs_uart uart_regs_inst (
        .clk                 (clk),
        .rst                 (rst),
        .wr_i                (wr),
        .rd_i                (rd),
        .rx_fifo_empty_i     (rx_fifo_empty),
        .rx_oe               (r_oe),
        .rx_pe               (r_pe),
        .rx_fe               (r_fe),
        .rx_bi               (r_bi),
        .addr_i              (addr),
        .din_i               (din),
        .tx_push_o           (tx_fifo_push),
        .rx_pop_o            (rx_fifo_pop),
        .baud_out            (baud_pulse),
        .tx_rst              (tx_rst),
        .rx_rst              (rx_rst),
        .rx_fifo_threshold   (rx_fifo_threshold),
        .dout_o              (dout),
        .csr_o               (csr),
        .ier_o               (ier),
        .rx_fifo_in          (rx_fifo_out),
        .modem_dout_i        (modem_dout)
    );

    uart_modem uart_modem_inst (
        .clk                 (clk),
        .rst                 (rst),
        .wr_i                (wr),
        .rd_i                (rd),
        .addr_i              (addr),
        .din_i               (din),
        .dout_o              (modem_dout),
        .dtr                 (dtr),
        .rts                 (rts),
        .out1                (out1),
        .out2                (out2),
        .loopback            (loopback),
        .cts                 (cts),
        .dsr                 (dsr),
        .ri                  (ri),
        .dcd                 (dcd),
        .modem_change        (modem_change)
    );

    uart_tx_top uart_tx_inst (
        .clk           (clk),
        .rst           (rst),
        .baud_pulse    (baud_pulse),
        .pen           (csr.lcr.pen),
        .thre          (tx_fifo_empty),
        .stb           (csr.lcr.stb),
        .sticky_parity (csr.lcr.stick_parity),
        .eps           (csr.lcr.eps),
        .set_break     (csr.lcr.set_break),
        .din           (tx_fifo_out),
        .wls           (csr.lcr.wls),
        .pop           (tx_fifo_pop),
        .sreg_empty    (),
        .tx            (tx)
    );

    fifo_top tx_fifo_inst (
        .rst           (rst | tx_rst),
        .clk           (clk),
        .en            (csr.fcr.ena),
        .push_in       (tx_fifo_push),
        .pop_in        (tx_fifo_pop),
        .din           (din),
        .dout          (tx_fifo_out),
        .empty         (tx_fifo_empty),
        .full          (),
        .overrun       (),
        .underrun      (),
        .threshold     (4'h0),
        .thre_trigger  ()
    );

    uart_rx_top uart_rx_inst (
        .clk           (clk),
        .rst           (rst),
        .baud_pulse    (baud_pulse),
        .rx            (rx),
        .sticky_parity (csr.lcr.stick_parity),
        .eps           (csr.lcr.eps),
        .pen            (csr.lcr.pen),
        .wls            (csr.lcr.wls),
        .push           (rx_fifo_push),
        .pe             (r_pe),
        .fe             (r_fe),
        .bi             (r_bi),
        .dout           (rx_out)
    );

    fifo_top rx_fifo_inst (
        .rst           (rst | rx_rst),
        .clk           (clk),
        .en            (csr.fcr.ena),
        .push_in       (rx_fifo_push),
        .pop_in        (rx_fifo_pop),
        .din           (rx_out),
        .dout          (rx_fifo_out),
        .empty         (rx_fifo_empty),
        .full          (),
        .overrun       (r_oe),
        .underrun      (),
        .threshold     (rx_fifo_threshold),
        .thre_trigger  ()
    );

    assign rda_pending  = ~rx_fifo_empty;
    assign thre_pending = tx_fifo_empty;

    uart_interrupt uart_interrupt_inst (
        .clk                 (clk),
        .rst                 (rst),
        .ier_rls             (ier.receiver_line_status),
        .ier_rda             (ier.received_data_available),
        .ier_thre            (ier.tx_holding_register_empty),
        .ier_modem           (ier.modem_status),
        .rx_oe               (r_oe),
        .rx_pe               (r_pe),
        .rx_fe               (r_fe),
        .rx_bi               (r_bi),
        .rx_data_ready       (rda_pending),
        .thre_empty          (thre_pending),
        .modem_change        (modem_change),
        .irq                 (irq),
        .iir                 (iir)
    );

endmodule
