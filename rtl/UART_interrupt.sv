//////////////////////////////////////////////////////////////////////////////////
// Module Name : UART Interrupt Controller
// Author      : Rushikesh P. Dandgawhal
// Description : 16550A-style interrupt controller
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module uart_interrupt (

    input  logic       clk,
    input  logic       rst,

    // Interrupt Enable Register bits
    input  logic       ier_rls,       // Receiver Line Status enable
    input  logic       ier_rda,       // Received Data Available enable
    input  logic       ier_thre,      // THR Empty enable
    input  logic       ier_modem,     // Modem Status enable

    // UART interrupt sources
    input  logic       rx_oe,
    input  logic       rx_pe,
    input  logic       rx_fe,
    input  logic       rx_bi,

    input  logic       rx_data_ready,
    input  logic       thre_empty,

    input  logic       modem_change,

    // Interrupt outputs
    output logic       irq,
    output logic [7:0] iir

);

    logic line_status_pending;
    logic rda_pending;
    logic thre_pending;
    logic modem_pending;

    //--------------------------------------------------------------------------
    // Interrupt source generation
    //--------------------------------------------------------------------------

    assign line_status_pending =
            rx_oe |
            rx_pe |
            rx_fe |
            rx_bi;

    assign rda_pending   = rx_data_ready;
    assign thre_pending  = thre_empty;
    assign modem_pending = modem_change;

    //--------------------------------------------------------------------------
    // Interrupt request generation
    //
    // Priority:
    // RLS > RDA > THRE > MODEM
    //--------------------------------------------------------------------------

    always_comb
    begin

        irq = 1'b0;

        if (ier_rls && line_status_pending)
            irq = 1'b1;

        else if (ier_rda && rda_pending)
            irq = 1'b1;

        else if (ier_thre && thre_pending)
            irq = 1'b1;

        else if (ier_modem && modem_pending)
            irq = 1'b1;

    end

    //--------------------------------------------------------------------------
    // Interrupt Identification Register
    //
    // IIR:
    // bit 0 = 0 -> interrupt pending
    // bit 0 = 1 -> no interrupt pending
    //
    // bit [3:1]:
    // 011 = Receiver Line Status
    // 010 = Received Data Available
    // 001 = THR Empty
    // 000 = Modem Status
    //--------------------------------------------------------------------------

    always_comb
    begin

        // Default = No interrupt pending
        iir = 8'b0000_0001;

        if (ier_rls && line_status_pending)
        begin
            iir = 8'b0000_0110;
        end

        else if (ier_rda && rda_pending)
        begin
            iir = 8'b0000_0100;
        end

        else if (ier_thre && thre_pending)
        begin
            iir = 8'b0000_0010;
        end

        else if (ier_modem && modem_pending)
        begin
            iir = 8'b0000_0000;
        end

    end

endmodule