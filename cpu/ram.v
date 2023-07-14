
module ram
    #(parameter D_BITS=32,           // Data bits of single read and write.
                BYTE_SIZE=32         // Address bits define the size of the buffer.
    )(
    input clk,                      // Top level system clock input.
    input reset_n,                  // Asynchronous active low reset. 
    input [D_BITS - 1:0] din,       // Data in.
    input wr_en,                    // Write enable 
    input rd_en,                    // Read enable
    output [D_BITS - 1:0] dout,     // Data out
    output full,                    // Set when FIFO buffer is full.
    output empty                    // Set when FIFO buffer is empty.
);    

    always @ (posedge clk, negedge reset_n) begin 
    end
endmodule
