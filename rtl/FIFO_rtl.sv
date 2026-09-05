`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name : UART FIFO RTL
// Author      : Rushikesh P. Dandgawhal
// Email       : rushikeshdandgawhal@gmail.com
// Date        : 23/08/2026
// Description : 16-byte FIFO for UART 16550A modeling
//////////////////////////////////////////////////////////////////////////////////

module fifo_top(

    input rst,
    input clk,
    input en,
    input push_in,
    input pop_in,

    input [7:0] din,

    output [7:0] dout,

    output empty,
    output full,
    output overrun,
    output underrun,

    input [3:0] threshold,

    output thre_trigger

);

////////////////////////////////////////////////////////////
// FIFO MEMORY
////////////////////////////////////////////////////////////

reg [7:0] mem [0:15];

reg [3:0] waddr = 4'h0;

////////////////////////////////////////////////////////////
// INTERNAL PUSH / POP
////////////////////////////////////////////////////////////

logic push;
logic pop;

////////////////////////////////////////////////////////////
// EMPTY FLAG
////////////////////////////////////////////////////////////

reg empty_t;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        empty_t <= 1'b1;
    end

    else
    begin

        case({push, pop})

            // POP
            2'b01:
            begin
                empty_t <= (waddr == 4'h1);
            end

            // PUSH
            2'b10:
            begin
                empty_t <= 1'b0;
            end

            default:
            begin
                empty_t <= empty_t;
            end

        endcase

    end

end

////////////////////////////////////////////////////////////
// FULL FLAG
////////////////////////////////////////////////////////////

reg full_t;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        full_t <= 1'b0;
    end

    else
    begin

        case({push, pop})

            // PUSH
            2'b10:
            begin
                full_t <= (waddr == 4'hf);
            end

            // POP
            2'b01:
            begin
                full_t <= 1'b0;
            end

            default:
            begin
                full_t <= full_t;
            end

        endcase

    end

end

////////////////////////////////////////////////////////////
// ACTUAL PUSH / POP
////////////////////////////////////////////////////////////

assign push = push_in & ~full_t;
assign pop  = pop_in  & ~empty_t;

////////////////////////////////////////////////////////////
// FIFO OUTPUT
////////////////////////////////////////////////////////////

assign dout = mem[0];

////////////////////////////////////////////////////////////
// WRITE POINTER / FIFO COUNT UPDATE
////////////////////////////////////////////////////////////

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        waddr <= 4'h0;
    end

    else
    begin

        case({push, pop})

            // PUSH ONLY
            2'b10:
            begin

                if(waddr != 4'hf && full_t == 1'b0)
                    waddr <= waddr + 1'b1;

                else
                    waddr <= waddr;

            end

            // POP ONLY
            2'b01:
            begin

                if(waddr != 4'h0 && empty_t == 1'b0)
                    waddr <= waddr - 1'b1;

                else
                    waddr <= waddr;

            end

            default:
            begin
                waddr <= waddr;
            end

        endcase

    end

end

////////////////////////////////////////////////////////////
// MEMORY UPDATE
////////////////////////////////////////////////////////////

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin

        for(int i = 0; i < 16; i++)
        begin
            mem[i] <= 8'h00;
        end

    end

    else
    begin

        case({push, pop})

            //////////////////////////////////////////////////
            // NO OPERATION
            //////////////////////////////////////////////////

            2'b00:
            begin
                // No operation
            end

            //////////////////////////////////////////////////
            // POP ONLY
            //////////////////////////////////////////////////

            2'b01:
            begin

                for(int i = 0; i < 15; i++)
                begin
                    mem[i] <= mem[i+1];
                end

                mem[15] <= 8'h00;

            end

            //////////////////////////////////////////////////
            // PUSH ONLY
            //////////////////////////////////////////////////

            2'b10:
            begin

                mem[waddr] <= din;

            end

            //////////////////////////////////////////////////
            // PUSH + POP
            //////////////////////////////////////////////////

            2'b11:
            begin

                for(int i = 0; i < 15; i++)
                begin
                    mem[i] <= mem[i+1];
                end

                mem[15] <= 8'h00;

                mem[waddr - 1'b1] <= din;

            end

        endcase

    end

end

////////////////////////////////////////////////////////////
// UNDERRUN
// FIFO is EMPTY + POP request
////////////////////////////////////////////////////////////

reg underrun_t;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        underrun_t <= 1'b0;
    end

    else if(en && pop_in && empty_t)
    begin
        underrun_t <= 1'b1;
    end

    else
    begin
        underrun_t <= 1'b0;
    end

end

////////////////////////////////////////////////////////////
// OVERRUN
// FIFO is FULL + PUSH request
////////////////////////////////////////////////////////////

reg overrun_t;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        overrun_t <= 1'b0;
    end

    else if(en && push_in && full_t)
    begin
        overrun_t <= 1'b1;
    end

    else
    begin
        overrun_t <= 1'b0;
    end

end

////////////////////////////////////////////////////////////
// FIFO THRESHOLD
////////////////////////////////////////////////////////////

reg thre_t;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        thre_t <= 1'b0;
    end

    else if(en && (push ^ pop))
    begin

        thre_t <= (waddr >= threshold) ? 1'b1 : 1'b0;

    end

end

////////////////////////////////////////////////////////////
// OUTPUT ASSIGNMENTS
////////////////////////////////////////////////////////////

assign empty        = empty_t;
assign full         = full_t;
assign overrun      = overrun_t;
assign underrun     = underrun_t;
assign thre_trigger = thre_t;

endmodule
