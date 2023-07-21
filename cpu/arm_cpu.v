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
    wire [3:0] rs = ins[19:16];
    wire s = ins[20];
    wire [7:0] ops = ins[27:21];
    wire [3:0] cond = ins[31:28];
 
    always @(posedge clk) begin
        if (!reset_n) pc <= 0;

        ins <= r.mem[pc];
        $display("ins: %h", ins, ", pc: %h", pc);
        $display("%b", cond, " %b", ops, " %b", s, " %b", rs, " %b", rd, " %b", imm12);
        $display("\n");

        case (ops)   
            8'b0000000: begin
            end
            8'b0000001: begin
            end
            8'b0000010: begin
            end
            8'b0000011: begin
            end
            8'b0000100: begin
            end
            8'b0000101: begin
            end
            8'b0000110: begin
            end
            8'b0000111: begin
            end
            8'b0001000: begin
            end
            8'b0001001: begin
            end
            8'b0001010: begin
            end
            8'b0001011: begin
            end
            8'b0001100: begin
            end
            8'b0001101: begin
            end
            8'b0001110: begin
            end
            8'b0001111: begin
            end
            8'b0010000: begin
            end
            8'b0010001: begin
            end
            8'b0010010: begin
            end
            8'b0010011: begin
            end
            8'b0010100: begin
            end
            8'b0010101: begin
            end
            8'b0010110: begin
            end
            8'b0010111: begin
            end

            8'b0101001: begin
                // STR (immediat):
                // offset_addr = if add (ins[23]) then (R[n] + imm32) else (R[n] - imm32);
                // address = if index then offset_addr else R[n];
                // MemU[address,4] = if t == 15 then PCStoreValue() else R[t];
                // if wback then R[n] = offset_addr;
            end
        endcase
    end
endmodule
