// ARM32 CPU 

module decode(
    input [31:0] inst,
    output [31:0] outM,
    output [31:0] writeM,
    output [31:0] addressM
    );

    assign outM = 0;
    assign writeM = 0;
    assign addressM = 0;
endmodule

module processor
    #(parameter ARCH = 32,
      parameter RAM_SIZE = 4096
    )(
    input clk, 
    input reset_n,
    input [31:0] inst,
    output [31:0] pc,
    output [31:0] outM,
    output [31:0] writeM,
    output [31:0] addressM
    );

    reg [31:0] dout;
    ram #(.DEPTH(4096)) r (
        .clk(clk)
    );

    initial begin
        $display("arm32 cpu");
    end
 
    always @(posedge clk) begin
    end
endmodule
