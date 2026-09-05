//////////////////////////////////////////////////////////////////////////////////
// Module Name : UART TOP RTL
// Author      : Rushikesh P. Dandgawhal
// Email       : rushikeshdandgawhal@gmail.com
// Date        : 31/08/2026
// Description : UART 16550A Receiver (TOP) RTL
//////////////////////////////////////////////////////////////////////////////////

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
    output tx,
    output [7:0] dout
);

    csr_t csr;

    wire baud_pulse;
    wire pen;
    wire thre;
    wire stb;

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

    // UART Registers
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

        .rx_fifo_in          (rx_fifo_out)
    );

    // TX Logic
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

    // TX FIFO
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

    // RX Logic
    uart_rx_top uart_rx_inst (
        .clk           (clk),
        .rst           (rst),
        .baud_pulse    (baud_pulse),

        .rx            (rx),
        .sticky_parity (csr.lcr.stick_parity),
        .eps           (csr.lcr.eps),
        .pen           (csr.lcr.pen),
        .wls           (csr.lcr.wls),

        .push          (rx_fifo_push),
        .pe            (r_pe),
        .fe            (r_fe),
        .bi            (r_bi),

        .dout          (rx_out)
    );

    // RX FIFO
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

endmodule