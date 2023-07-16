// Single port Random Access Memory (RAM)

module single_port_ram 
    #(parameter BLOCK_SIZE=1024,
      parameter D_BITS=32,
      parameter ADDR_W=5
    )(
    input clk, 
    input [ADDR_W - 1:0] addr,
    input [D_BITS - 1:0] din,
    input we,
    output [D_BITS - 1:0] dout
);    
    reg [D_BITS - 1:0] dout;
    reg [D_BITS - 1:0] mem [0:BLOCK_SIZE];
    
    always @ (posedge clk) begin 
        if (we) 
            mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule


module ram 
    #(parameter DEPTH=4096,
      parameter D_BITS=32,
      parameter ADDR_W=5
    )(
    input clk 
    ); 

    reg [D_BITS - 1:0] mem [0:DEPTH - 1];

endmodule
