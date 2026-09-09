
//////////////////////////////////////////////////////////////////////////////////
// Module Name : UART MODEM CONTROL RTL
// Author      : Rushikesh P. Dandgawhal
// Description : UART 16550A Modem Control and Modem Status Logic
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module uart_modem (

    input  logic       clk,
    input  logic       rst,

    // ------------------------------------------------------------
    // Register interface
    // ------------------------------------------------------------

    input  logic       wr_i,
    input  logic       rd_i,
    input  logic [2:0] addr_i,
    input  logic [7:0] din_i,

    output logic [7:0] dout_o,

    // ------------------------------------------------------------
    // Modem Control Register outputs
    // ------------------------------------------------------------

    output logic       dtr,
    output logic       rts,
    output logic       out1,
    output logic       out2,
    output logic       loopback,

    // ------------------------------------------------------------
    // External modem inputs
    // ------------------------------------------------------------

    input  logic       cts,
    input  logic       dsr,
    input  logic       ri,
    input  logic       dcd,

    // ------------------------------------------------------------
    // Modem interrupt event
    // ------------------------------------------------------------

    output logic       modem_change
);


    // ============================================================
    // MODEM CONTROL REGISTER
    //
    // Address = 4
    //
    // MCR:
    //
    // Bit 0 = DTR
    // Bit 1 = RTS
    // Bit 2 = OUT1
    // Bit 3 = OUT2
    // Bit 4 = LOOP
    // Bits 7:5 = Reserved
    // ============================================================

    logic [4:0] mcr;


    // ============================================================
    // MODEM STATUS REGISTER
    //
    // MSR:
    //
    // Bit 0 = DCTS
    // Bit 1 = DDSR
    // Bit 2 = TERI
    // Bit 3 = DDCD
    // Bit 4 = CTS
    // Bit 5 = DSR
    // Bit 6 = RI
    // Bit 7 = DCD
    //
    // Address = 6
    // ============================================================

    logic [7:0] msr;


    // ============================================================
    // PREVIOUS MODEM INPUTS
    //
    // Used to detect changes in CTS, DSR, RI and DCD.
    // ============================================================

    logic cts_prev;
    logic dsr_prev;
    logic ri_prev;
    logic dcd_prev;


    // ============================================================
    // MODEM INPUT CHANGE DETECTION
    //
    // Delta conditions:
    //
    // DCTS = CTS changed
    // DDSR = DSR changed
    // TERI = RI changed from 1 -> 0
    // DDCD = DCD changed
    // ============================================================

    logic dcts_event;
    logic ddsr_event;
    logic teri_event;
    logic ddcd_event;


    assign dcts_event = (cts != cts_prev);

    assign ddsr_event = (dsr != dsr_prev);

    assign teri_event = (ri_prev == 1'b1) &&
                        (ri      == 1'b0);

    assign ddcd_event = (dcd != dcd_prev);


    // ============================================================
    // MODEM CHANGE
    //
    // Any modem status change generates a MODEM interrupt event.
    // ============================================================

    assign modem_change =
            dcts_event |
            ddsr_event |
            teri_event |
            ddcd_event;


    // ============================================================
    // MCR REGISTER
    //
    // Address = 4
    // ============================================================

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            mcr <= 5'b00000;
        end
        else if (wr_i &&
                 (addr_i == 3'h4))
        begin
            mcr <= din_i[4:0];
        end
    end


    // ============================================================
    // MCR OUTPUTS
    // ============================================================

    assign dtr      = mcr[0];
    assign rts      = mcr[1];
    assign out1     = mcr[2];
    assign out2     = mcr[3];
    assign loopback = mcr[4];


    // ============================================================
    // PREVIOUS MODEM INPUT REGISTER
    //
    // Store the previous modem input state.
    // ============================================================

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            cts_prev <= 1'b0;
            dsr_prev <= 1'b0;
            ri_prev  <= 1'b0;
            dcd_prev <= 1'b0;
        end
        else
        begin
            cts_prev <= cts;
            dsr_prev <= dsr;
            ri_prev  <= ri;
            dcd_prev <= dcd;
        end
    end


    // ============================================================
    // MODEM STATUS REGISTER
    //
    // Current modem input levels:
    //
    // MSR[4] = CTS
    // MSR[5] = DSR
    // MSR[6] = RI
    // MSR[7] = DCD
    //
    // Delta bits are latched when a transition occurs.
    // ============================================================

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            msr <= 8'h00;
        end
        else
        begin

            // ----------------------------------------------------
            // Delta status bits
            // ----------------------------------------------------

            if (dcts_event)
                msr[0] <= 1'b1;

            if (ddsr_event)
                msr[1] <= 1'b1;

            if (teri_event)
                msr[2] <= 1'b1;

            if (ddcd_event)
                msr[3] <= 1'b1;


            // ----------------------------------------------------
            // Current modem status
            // ----------------------------------------------------

            msr[4] <= cts;
            msr[5] <= dsr;
            msr[6] <= ri;
            msr[7] <= dcd;


            // ----------------------------------------------------
            // Reading MSR clears the delta bits.
            //
            // Address = 6
            // ----------------------------------------------------

            if (rd_i &&
                (addr_i == 3'h6))
            begin
                msr[3:0] <= 4'b0000;
            end

        end
    end


    // ============================================================
    // REGISTER READ
    //
    // MCR = Address 4
    // MSR = Address 6
    // ============================================================

    always_comb
    begin

        dout_o = 8'h00;

        case (addr_i)

            // ----------------------------------------------------
            // MCR
            // ----------------------------------------------------

            3'h4:
                dout_o = {3'b000, mcr};


            // ----------------------------------------------------
            // MSR
            // ----------------------------------------------------

            3'h6:
                dout_o = msr;


            default:
                dout_o = 8'h00;

        endcase

    end

endmodule
