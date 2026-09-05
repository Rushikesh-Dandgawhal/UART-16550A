
//////////////////////////////////////////////////////////////////////////////////
// Module Name : UART Rx RTL
// Author      : Rushikesh P. Dandgawhal
// Email       : rushikeshdandgawhal@gmail.com
// Date        : 25/08/2026
// Description : UART 16550A Receiver (RX) RTL
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module uart_rx_top(
    input clk,
    input rst,
    input baud_pulse,
    input rx,
    input sticky_parity,
    input eps,
    input pen,
    input [1:0] wls,
    output reg push,
    output reg pe,
    output reg fe,
    output reg bi,
    output reg [7:0] dout
);

typedef enum logic [2:0] {
    idle   = 3'b000,
    start  = 3'b001,
    read   = 3'b010,
    parity = 3'b011,
    stop   = 3'b100
} state_t;

state_t state = idle;

reg rx_reg = 1'b1;
wire fall_edge;

always @(posedge clk)
begin
    rx_reg <= rx;
end

assign fall_edge = rx_reg;

reg [2:0] bitcnt;
reg [3:0] count = 0;
reg pe_reg;

always @(posedge clk, posedge rst)
begin
    if(rst)
    begin
        state <= idle;
        push <= 1'b0;
        pe <= 1'b0;
        fe <= 1'b0;
        bi <= 1'b0;
        bitcnt <= 3'b000;
    end
    else
    begin
        push <= 1'b0;

        if(baud_pulse)
        begin
            case(state)

                idle:
                begin
                    if(!fall_edge)
                    begin
                        state <= start;
                        count <= 5'd15;
                    end
                    else
                    begin
                        state <= idle;
                    end
                end

                start:
                begin
                    count <= count - 1;

                    if(count == 5'd7)
                    begin
                        if(rx == 1'b1)
                        begin
                            state <= idle;
                            count <= 5'd15;
                        end
                        else
                        begin
                            state <= start;
                        end
                    end
                    else if(count == 0)
                    begin
                        state <= read;
                        count <= 5'd15;
                        bitcnt <= {1'b1, wls};
                    end
                end

                read:
                begin
                    count <= count - 1;

                    if(count == 5'd7)
                    begin
                        case(wls)

                            2'b00:
                                dout <= {3'b000, rx, dout[4:1]};

                            2'b01:
                                dout <= {2'b00, rx, dout[5:1]};

                            2'b10:
                                dout <= {1'b0, rx, dout[6:1]};

                            2'b11:
                                dout <= {rx, dout[7:1]};

                        endcase

                        state <= read;
                    end
                    else if(count == 0)
                    begin
                        if(bitcnt == 0)
                        begin
                            case({sticky_parity, eps})

                                2'b00:
                                    pe_reg <= ~^{rx, dout};

                                2'b01:
                                    pe_reg <= ^{rx, dout};

                                2'b10:
                                    pe_reg <= ~rx;

                                2'b11:
                                    pe_reg <= rx;

                            endcase

                            if(pen == 1'b1)
                            begin
                                state <= parity;
                                count <= 5'd15;
                            end
                            else
                            begin
                                state <= stop;
                                count <= 5'd15;
                            end
                        end
                        else
                        begin
                            bitcnt <= bitcnt - 1;
                            state <= read;
                            count <= 5'd15;
                        end
                    end
                end

                parity:
                begin
                    count <= count - 1;

                    if(count == 5'd7)
                    begin
                        pe <= pe_reg;
                        state <= parity;
                    end
                    else if(count == 0)
                    begin
                        state <= stop;
                        count <= 5'd15;
                    end
                end

                stop:
                begin
                    count <= count - 1;

                    if(count == 5'd7)
                    begin
                        fe <= ~rx;
                        push <= 1'b1;
                        state <= stop;
                    end
                    else if(count == 0)
                    begin
                        state <= idle;
                        count <= 5'd15;
                    end
                end

                default:
                    ;

            endcase
        end
    end
end

endmodule

