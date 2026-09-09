
`timescale 1ns / 1ps

import uart_types_pkg::*;

module regs_uart(

    input clk,
    input rst,

    input wr_i,
    input rd_i,

    input rx_fifo_empty_i,

    input rx_oe,
    input rx_pe,
    input rx_fe,
    input rx_bi,

    input [2:0] addr_i,
    input [7:0] din_i,

    output tx_push_o,
    output rx_pop_o,

    output baud_out,

    output tx_rst,
    output rx_rst,

    output [3:0] rx_fifo_threshold,

    output reg [7:0] dout_o,

    output csr_t csr_o,

    output ier_t ier_o,

    input [7:0] rx_fifo_in,

    input [7:0] modem_dout_i

);

    csr_t csr;

    wire tx_fifo_wr;

    assign tx_fifo_wr =
        wr_i &&
        (addr_i == 3'b000) &&
        (csr.lcr.dlab == 1'b0);

    assign tx_push_o = tx_fifo_wr;

    wire rx_fifo_rd;

    assign rx_fifo_rd =
        rd_i &&
        (addr_i == 3'b000) &&
        (csr.lcr.dlab == 1'b0);

    assign rx_pop_o = rx_fifo_rd;

    reg [7:0] rx_data;

    always @(posedge clk)
    begin
        if (rx_pop_o)
            rx_data <= rx_fifo_in;
    end

    div_t dl;

    always @(posedge clk)
    begin
        if (wr_i &&
            (addr_i == 3'b000) &&
            (csr.lcr.dlab == 1'b1))
        begin
            dl.dlsb <= din_i;
        end
    end

    always @(posedge clk)
    begin
        if (wr_i &&
            (addr_i == 3'b001) &&
            (csr.lcr.dlab == 1'b1))
        begin
            dl.dmsb <= din_i;
        end
    end

    reg update_baud;
    reg [15:0] baud_cnt = 16'h0000;
    reg baud_pulse = 1'b0;

    always @(posedge clk)
    begin
        update_baud <=
            wr_i &&
            (csr.lcr.dlab == 1'b1) &&
            ((addr_i == 3'b000) ||
             (addr_i == 3'b001));
    end

    always @(posedge clk or posedge rst)
    begin
        if (rst)
            baud_cnt <= 16'h0000;

        else if (update_baud ||
                 baud_cnt == 16'h0000)
            baud_cnt <= dl;

        else
            baud_cnt <= baud_cnt - 1'b1;
    end

    always @(posedge clk)
    begin
        baud_pulse <= (|dl) && (~|baud_cnt);
    end

    assign baud_out = baud_pulse;

    ier_t ier;

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            ier <= 8'h00;
        end

        else if (wr_i &&
                 (addr_i == 3'h1) &&
                 (csr.lcr.dlab == 1'b0))
        begin
            ier.modem_status              <= din_i[3];
            ier.receiver_line_status      <= din_i[2];
            ier.tx_holding_register_empty <= din_i[1];
            ier.received_data_available   <= din_i[0];

            ier.reserved_7_4 <= 4'b0000;
        end
    end

    assign ier_o = ier;

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            csr.fcr <= 8'h00;
        end

        else if (wr_i &&
                 (addr_i == 3'h2))
        begin
            csr.fcr.rx_trigger <= din_i[7:6];
            csr.fcr.dma_mode   <= din_i[3];
            csr.fcr.tx_rst     <= din_i[2];
            csr.fcr.rx_rst     <= din_i[1];
            csr.fcr.ena        <= din_i[0];
        end

        else
        begin
            csr.fcr.tx_rst <= 1'b0;
            csr.fcr.rx_rst <= 1'b0;
        end
    end

    assign tx_rst = csr.fcr.tx_rst;
    assign rx_rst = csr.fcr.rx_rst;

    reg [3:0] rx_fifo_th_count;

    always_comb
    begin

        if (csr.fcr.ena == 1'b0)
        begin
            rx_fifo_th_count = 4'd0;
        end

        else
        begin

            case (csr.fcr.rx_trigger)

                2'b00:
                    rx_fifo_th_count = 4'd1;

                2'b01:
                    rx_fifo_th_count = 4'd4;

                2'b10:
                    rx_fifo_th_count = 4'd8;

                2'b11:
                    rx_fifo_th_count = 4'd14;

                default:
                    rx_fifo_th_count = 4'd1;

            endcase

        end

    end

    assign rx_fifo_threshold = rx_fifo_th_count;

    always @(posedge clk or posedge rst)
    begin

        if (rst)
            csr.lcr <= 8'h00;

        else if (wr_i &&
                 (addr_i == 3'h3))
            csr.lcr <= din_i;

    end

    reg [7:0] lcr_temp;

    wire read_lcr;

    assign read_lcr =
        rd_i &&
        (addr_i == 3'h3);

    always @(posedge clk)
    begin

        if (read_lcr)
            lcr_temp <= csr.lcr;

    end

    always @(posedge clk or posedge rst)
    begin

        if (rst)
        begin
            csr.lsr <= 8'h60;
        end

        else
        begin
            csr.lsr.dr <= ~rx_fifo_empty_i;
            csr.lsr.oe <= rx_oe;
            csr.lsr.pe <= rx_pe;
            csr.lsr.fe <= rx_fe;
            csr.lsr.bi <= rx_bi;
        end

    end

    reg [7:0] lsr_temp;

    wire read_lsr;

    assign read_lsr =
        rd_i &&
        (addr_i == 3'h5);

    always @(posedge clk)
    begin

        if (read_lsr)
            lsr_temp <= csr.lsr;

    end

    always @(posedge clk or posedge rst)
    begin

        if (rst)
            csr.scr <= 8'h00;

        else if (wr_i &&
                 (addr_i == 3'h7))
            csr.scr <= din_i;

    end

    reg [7:0] scr_temp;

    wire read_scr;

    assign read_scr =
        rd_i &&
        (addr_i == 3'h7);

    always @(posedge clk)
    begin

        if (read_scr)
            scr_temp <= csr.scr;

    end

    always @(posedge clk)
    begin

        case (addr_i)

            3'h0:
                dout_o <= csr.lcr.dlab ?
                          dl.dlsb :
                          rx_fifo_in;

            3'h1:
                dout_o <= csr.lcr.dlab ?
                          dl.dmsb :
                          ier;

            3'h2:
                dout_o <= 8'h00;

            3'h3:
                dout_o <= csr.lcr;

            3'h4:
                dout_o <= modem_dout_i;

            3'h5:
                dout_o <= lsr_temp;

            3'h6:
                dout_o <= modem_dout_i;

            3'h7:
                dout_o <= scr_temp;

            default:
                dout_o <= 8'h00;

        endcase

    end

    assign csr_o = csr;

endmodule

