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

    wire [11:0] imm12 = ins[11:0];
    wire [3:0] rd = ins[15:12];
    wire [3:0] op1 = ins[19:16];
    wire s = ins[20];
    wire [7:0] func = ins[27:21];
    wire [3:0] cond = ins[31:28];
 
    always @(posedge clk) begin
        if (!reset_n) pc <= 0;

        ins <= r.mem[pc];
        $display("ins: %h", ins, ", pc: %h", pc);
        $display("%b", cond, " %b", func, " %b", s, " %b", op1, " %b", rd, " %b", imm12);
        $display("\n");
    end
endmodule
