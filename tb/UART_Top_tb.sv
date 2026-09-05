`timescale 1ns / 1ps

module all_mod_tb;

reg clk, rst, wr, rd;
reg rx;
reg [2:0] addr;
reg [7:0] din;

wire tx;
wire [7:0] dout;

all_mod dut (
    .clk  (clk),
    .rst  (rst),
    .wr   (wr),
    .rd   (rd),
    .rx   (rx),
    .addr (addr),
    .din  (din),
    .tx   (tx),
    .dout (dout)
);

initial begin
    clk  = 0;
    rst  = 0;
    wr   = 0;
    rd   = 0;
    addr = 0;
    din  = 0;
    rx   = 1;
end

always #5 clk = ~clk;

initial begin

   // DLAB = 1
@(negedge clk);
wr   = 1;
addr = 3'h3;
din  = 8'b1000_0000;

// DLL = 08
@(negedge clk);
addr = 3'h0;
din  = 8'b0000_1000;

// DLM = 01
@(negedge clk);
addr = 3'h1;
din  = 8'b0000_0001;

// DLAB = 0
// 8-bit, parity enabled, even parity, 1 stop bit
@(negedge clk);
addr = 3'h3;
din  = 8'b0000_1011;   // LCR = 0B

// // Write data to THR
// @(negedge clk);
// addr = 3'h0;
// din  = 8'b0101_0101;   // THR = 55

//     // End write
//     @(negedge clk);
//     wr = 0;

    // // Wait for transmission
    // repeat(200) @(posedge dut.uart_tx_inst.baud_pulse);
// -------------------------
// TEST 5: ODD PARITY
// -------------------------

// End register configuration
@(negedge clk);
wr = 0;

// START BIT
rx = 1'b0;
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

// DATA = 8'h55, LSB first

rx = 1'b1;  // D0
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b0;  // D1
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b1;  // D2
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b0;  // D3
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b1;  // D4
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b0;  // D5
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b1;  // D6
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

rx = 1'b0;  // D7
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

// ODD PARITY
// 55 has four 1s, so odd parity = 1
rx = 1'b1;
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

// STOP BIT
rx = 1'b1;
repeat(16) @(posedge dut.uart_rx_inst.baud_pulse);

// IDLE
rx = 1'b1;
repeat(20) @(posedge dut.uart_rx_inst.baud_pulse);

$stop;

end

endmodule