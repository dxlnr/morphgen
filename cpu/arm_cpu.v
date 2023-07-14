// ARM32 CPU Implementation

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

module arm_cpu 
    #(parameter ARCH = 32
    )(
    input clk, 
    input resetn,
    input [31:0] inst,
    output [31:0] pc,
    output [31:0] outM,
    output [31:0] writeM,
    output [31:0] addressM
    ); 

    always @(posedge clk) begin
    end

    initial begin
        $display("arm32 cpu");
    end
endmodule
