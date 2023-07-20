// ARM32 CPU 

module processor
    #(parameter ARCH = 32,
      parameter RAM_SIZE = 4096
    )(
    input clk, 
    input reset_n
    );

    reg [ARCH-1:0] registers [0:ARCH-1];
    reg [ARCH-1:0] ins;
    reg [ARCH-1:0] pc;

    ram #(.DEPTH(4096)) r (
        .clk(clk)
    );
 
    always @(posedge clk) begin
        if (!reset_n) pc <= 0;
        
        ins <= r.mem[pc];
        $display("ins: %h", ins, ", pc: %h", pc);
    end
endmodule
