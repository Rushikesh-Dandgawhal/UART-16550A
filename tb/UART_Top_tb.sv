`timescale 1ns / 1ps

module all_mod_tb;

reg clk, rst, wr, rd;
reg rx;
reg [2:0] addr;
reg [7:0] din;

reg cts;
reg dsr;
reg ri;
reg dcd;

wire tx;
wire [7:0] dout;

wire dtr;
wire rts;
wire out1;
wire out2;
wire loopback;

wire irq;
wire [7:0] iir;


// =====================================================
// DUT
// =====================================================

all_mod dut (
    .clk       (clk),
    .rst       (rst),
    .wr        (wr),
    .rd        (rd),
    .rx        (rx),
    .addr      (addr),
    .din       (din),

    .cts       (cts),
    .dsr       (dsr),
    .ri        (ri),
    .dcd       (dcd),

    .tx        (tx),
    .dout      (dout),

    .dtr       (dtr),
    .rts       (rts),
    .out1      (out1),
    .out2      (out2),
    .loopback  (loopback),

    .irq       (irq),
    .iir       (iir)
);


// =====================================================
// CLOCK
// =====================================================

always #5 clk = ~clk;


// =====================================================
// INITIAL VALUES
// =====================================================

initial begin

    clk  = 0;
    rst  = 0;

    wr   = 0;
    rd   = 0;

    addr = 0;
    din  = 0;

    rx   = 1;

    cts  = 0;
    dsr  = 0;
    ri   = 0;
    dcd  = 0;

end


// =====================================================
// WRITE REGISTER TASK
// =====================================================

task write_reg;

    input [2:0] address;
    input [7:0] data;

    begin

        @(negedge clk);

        wr   = 1;
        rd   = 0;
        addr = address;
        din  = data;

        @(negedge clk);

        wr   = 0;
        addr = 0;
        din  = 0;

    end

endtask


// =====================================================
// READ REGISTER TASK
// =====================================================

task read_reg;

    input [2:0] address;

    begin

        @(negedge clk);

        wr   = 0;
        rd   = 1;
        addr = address;

        @(negedge clk);

        rd   = 0;
        addr = 0;

        #1;

    end

endtask


// =====================================================
// WAIT BAUD
// =====================================================

task wait_baud;

    input integer n;
    integer i;

    begin

        for (i = 0; i < n; i = i + 1)
            @(posedge dut.uart_rx_inst.baud_pulse);

    end

endtask


// =====================================================
// SEND ODD PARITY FRAME
// =====================================================

task send_odd_frame;

    input [7:0] data;
    integer i;

    begin

        // Start bit
        rx = 1'b0;
        wait_baud(16);

        // Data bits
        for (i = 0; i < 8; i = i + 1) begin

            rx = data[i];
            wait_baud(16);

        end

        // Odd parity
        rx = ~(^data);
        wait_baud(16);

        // Stop bit
        rx = 1'b1;
        wait_baud(16);

        // Extra idle time
        rx = 1'b1;
        wait_baud(20);

    end

endtask


// =====================================================
// SEND WRONG PARITY FRAME
// =====================================================

task send_wrong_parity_frame;

    input [7:0] data;
    integer i;

    begin

        // Start bit
        rx = 1'b0;
        wait_baud(16);

        // Data bits
        for (i = 0; i < 8; i = i + 1) begin

            rx = data[i];
            wait_baud(16);

        end

        // Wrong parity
        rx = ^data;
        wait_baud(16);

        // Stop bit
        rx = 1'b1;
        wait_baud(16);

        // Extra idle time
        rx = 1'b1;
        wait_baud(20);

    end

endtask


// =====================================================
// SEND BAD STOP FRAME
// =====================================================

task send_bad_stop_frame;

    input [7:0] data;
    integer i;

    begin

        // Start bit
        rx = 1'b0;
        wait_baud(16);

        // Data bits
        for (i = 0; i < 8; i = i + 1) begin

            rx = data[i];
            wait_baud(16);

        end

        // Correct odd parity
        rx = ~(^data);
        wait_baud(16);

        // BAD stop bit
        rx = 1'b0;
        wait_baud(16);

        // Return to idle
        rx = 1'b1;
        wait_baud(20);

    end

endtask


// =====================================================
// MAIN VERIFICATION
// =====================================================

initial begin

    // -------------------------------------------------
    // RESET
    // -------------------------------------------------

    rst = 1;

    @(negedge clk);

    rst = 0;


    $display("==============================================");
    $display("UART 16550A FINAL TOP-LEVEL VERIFICATION");
    $display("==============================================");


    // =================================================
    // TEST 1: RESET
    // =================================================

    $display("TEST 1: RESET");

    if ((dtr == 0) &&
        (rts == 0) &&
        (out1 == 0) &&
        (out2 == 0) &&
        (loopback == 0) &&
        (irq == 0))

        $display("TEST 1 PASS");

    else

        $display("TEST 1 FAIL");


    // =================================================
    // TEST 2: DLAB + DLL/DLM
    // =================================================

    $display("TEST 2: DLAB + DLL/DLM");

    write_reg(3'h3, 8'h80);

    write_reg(3'h0, 8'h08);

    write_reg(3'h1, 8'h01);


    read_reg(3'h0);

    if (dout == 8'h08)

        $display("DLL READ PASS");

    else

        $display("DLL READ FAIL: dout = %h", dout);


    read_reg(3'h1);

    if (dout == 8'h01)

        $display("DLM READ PASS");

    else

        $display("DLM READ FAIL: dout = %h", dout);


    $display("TEST 2 COMPLETE");


    // =================================================
    // TEST 3: LCR + FCR
    // =================================================

    $display("TEST 3: LCR + FCR UART CONFIGURATION");

    write_reg(3'h3, 8'h0F);

    write_reg(3'h2, 8'h01);

    read_reg(3'h3);

    if (dout == 8'h0F)

        $display("LCR READ PASS");

    else

        $display("LCR READ FAIL: dout = %h", dout);


    $display("TEST 3 COMPLETE");


    // =================================================
    // TEST 4: IER
    // =================================================

    $display("TEST 4: IER READ + RESERVED BITS");

    write_reg(3'h1, 8'hFF);

    read_reg(3'h1);

    if (dout == 8'h0F)

        $display("TEST 4 PASS: IER = %h", dout);

    else

        $display("TEST 4 FAIL: IER = %h", dout);


    // =================================================
    // TEST 5: MCR
    // =================================================

    $display("TEST 5: MCR WRITE / READ");

    write_reg(3'h4, 8'h1F);


    if ((dtr == 1) &&
        (rts == 1) &&
        (out1 == 1) &&
        (out2 == 1) &&
        (loopback == 1))

        $display("MCR OUTPUT PASS");

    else

        $display("MCR OUTPUT FAIL");


    read_reg(3'h4);

    if (dout == 8'h1F)

        $display("MCR READ PASS");

    else

        $display("MCR READ FAIL: dout = %h", dout);


    $display("TEST 5 COMPLETE");


    // =================================================
    // TEST 6: MSR STATUS + DELTA DETECTION
    // =================================================

    $display("TEST 6: MSR STATUS + DELTA DETECTION");

    write_reg(3'h1, 8'h00);

    cts = 1;
    dsr = 1;
    dcd = 1;

    @(posedge clk);

    ri = 1;

    @(posedge clk);

    ri = 0;

    @(posedge clk);

    #1;

    read_reg(3'h6);


    if ((dout[0] == 1) &&
        (dout[1] == 1) &&
        (dout[2] == 1) &&
        (dout[3] == 1) &&
        (dout[4] == 1) &&
        (dout[5] == 1) &&
        (dout[6] == 0) &&
        (dout[7] == 1))

        $display("TEST 6 PASS: MSR = %h", dout);

    else

        $display("TEST 6 FAIL: MSR = %h", dout);


    // =================================================
    // TEST 7: MSR DELTA CLEAR
    // =================================================

    $display("TEST 7: MSR DELTA CLEAR");

    read_reg(3'h6);

    if (dout[3:0] == 4'b0000)

        $display("TEST 7 PASS: MSR = %h", dout);

    else

        $display("TEST 7 FAIL: MSR = %h", dout);


    // =================================================
    // TEST 8: RX ODD PARITY
    // =================================================

    $display("TEST 8: RX ODD PARITY");

    write_reg(3'h3, 8'h0F);

    write_reg(3'h1, 8'h00);

    send_odd_frame(8'h55);

    read_reg(3'h0);


    if (dout == 8'h55)

        $display("RX DATA PASS: dout = %h", dout);

    else

        $display("RX DATA FAIL: dout = %h", dout);


    if (dut.r_pe == 0)

        $display("ODD PARITY PASS");

    else

        $display("ODD PARITY FAIL");


    $display("TEST 8 COMPLETE");


    // =================================================
    // TEST 9: RX PARITY ERROR + RLS INTERRUPT
    // =================================================

    $display("TEST 9: RX PARITY ERROR + RLS INTERRUPT");

    write_reg(3'h1, 8'h04);

    send_wrong_parity_frame(8'h55);

    #1;


    if (dut.r_pe == 1)

        $display("PARITY ERROR PASS");

    else

        $display("PARITY ERROR FAIL");


    if ((irq == 1) && (iir == 8'h06))

        $display("RLS INTERRUPT PASS");

    else

        $display("RLS INTERRUPT FAIL: irq=%b iir=%h",
                 irq, iir);


    $display("TEST 9 COMPLETE");


    // =================================================
    // TEST 10: RX FRAMING ERROR
    // =================================================

    $display("TEST 10: RX FRAMING ERROR");

    write_reg(3'h1, 8'h04);

    send_bad_stop_frame(8'hA5);

    #1;


    if (dut.r_fe == 1)

        $display("FRAMING ERROR PASS");

    else

        $display("FRAMING ERROR FAIL");


    if ((irq == 1) && (iir == 8'h06))

        $display("FRAMING RLS INTERRUPT PASS");

    else

        $display("FRAMING RLS INTERRUPT FAIL: irq=%b iir=%h",
                 irq, iir);


    $display("TEST 10 COMPLETE");


// =================================================
// TEST 11: MODEM INTERRUPT
// =================================================

$display("TEST 11: MODEM INTERRUPT");


// Enable modem-status interrupt
write_reg(3'h1, 8'h08);


// Force known modem input state
cts = 0;
dsr = 0;
ri  = 0;
dcd = 0;


// Allow modem logic to sample the initial 0 state
@(posedge clk);

#1;

$display("INITIALIZED: cts=%b cts_prev=%b dcts_event=%b modem_change=%b irq=%b iir=%h",
         cts,
         dut.uart_modem_inst.cts_prev,
         dut.uart_modem_inst.dcts_event,
         dut.uart_modem_inst.modem_change,
         irq,
         iir);


// =================================================
// Generate intentional CTS 0 -> 1 transition
// =================================================

cts = 1;

#1;

$display("AFTER CTS CHANGE: cts=%b cts_prev=%b dcts_event=%b modem_change=%b irq=%b iir=%h",
         cts,
         dut.uart_modem_inst.cts_prev,
         dut.uart_modem_inst.dcts_event,
         dut.uart_modem_inst.modem_change,
         irq,
         iir);


// =================================================
// Check modem interrupt
// =================================================

if ((irq == 1) && (iir == 8'h00))

    $display("MODEM INTERRUPT PASS");

else

    $display("MODEM INTERRUPT FAIL: irq=%b iir=%h",
             irq, iir);


// Observe next clock
@(posedge clk);

#1;

$display("NEXT CLOCK: cts=%b cts_prev=%b dcts_event=%b modem_change=%b irq=%b iir=%h",
         cts,
         dut.uart_modem_inst.cts_prev,
         dut.uart_modem_inst.dcts_event,
         dut.uart_modem_inst.modem_change,
         irq,
         iir);


$display("TEST 11 COMPLETE");


    // =================================================
    // TEST 12: INTERRUPT PRIORITY
    // =================================================

    $display("TEST 12: INTERRUPT PRIORITY");


    // Enable RDA + THRE + RLS
    // Disable modem interrupt
    write_reg(3'h1, 8'h07);


    // Generate parity error
    send_wrong_parity_frame(8'h55);

    #1;


    if ((irq == 1) && (iir == 8'h06))

        $display("TEST 12 PASS: RLS HAS HIGHEST PRIORITY");

    else

        $display("TEST 12 FAIL: irq=%b iir=%h",
                 irq, iir);


    // =================================================
    // FINAL
    // =================================================

    $display("==============================================");
    $display("FINAL VERIFICATION COMPLETE");
    $display("==============================================");


    #100;

    $stop;

end

endmodule