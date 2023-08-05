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

module memory
    #(parameter DEPTH=4096,
      parameter N=32
    )(
    input wire         clk,
    input wire         i_mem_r_en,
    input wire         i_mem_w_en,
    input wire [N-1:0] i_mem_addr,
    input wire [N-1:0] i_mem_w_data,
    output reg [N-1:0] o_mem_r_data
);
    reg [N-1:0] mem [0:DEPTH-1];
    
    always @(posedge clk) begin
        if(i_mem_r_en == 1'b1)
            o_mem_r_data <= mem[i_mem_addr];
        else if(i_mem_w_en == 1'b1)
            mem[i_mem_addr] <= i_mem_w_data;
    end
endmodule

module ins_memory 
    #(parameter DEPTH=4096,
      parameter D_BITS=32
    )(
    input wire         clk
); 
    reg [D_BITS - 1:0] mem [0:DEPTH - 1];
endmodule
