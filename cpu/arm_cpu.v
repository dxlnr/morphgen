// ARM32 CPU 
//
module UInt
    #(parameter N = 32
    )(
    input wire [N-1:0] x,
    output reg [N-1:0] result
);
    always @* begin
        result = 0;
        for (integer i = 0; i < N; i = i + 1) begin
            if (x[i] == 1'b1)
                result = result + (1 << i);
        end
    end
endmodule

module AddWithCarry
    #(parameter N = 32
    )(
    input  wire [N-1:0] x,
    input  wire [N-1:0] y,
    input  wire         cin,
    output reg [N-1:0]  result,
    output wire         n,
    output wire         z,
    output wire         c,
    output wire         v
);
    integer unsigned_sum;
    always @* begin
        unsigned_sum = x + y + cin;
    end
    integer signed_sum;
    always @* begin
        signed_sum = $signed(x) + $signed(y) + cin;
    end

    assign result = unsigned_sum[N-1:0];
    assign n = result[N-1];
    assign z = (result == 0);
    assign c = (unsigned_sum > {N{1'b1}});
    assign v = (signed_sum > {N{1'b1}}) || (signed_sum < {N{1'b0}});
endmodule

module ALU
    #(parameter N = 32
    )(
    input wire [7:0]  ops,
    input wire [31:0] x,
    input wire [31:0] y,
    input  wire       cin,
    output reg [31:0] result,
    output reg        n,
    output reg        z,
    output reg        c,
    output reg        v 
);
    wire [31:0] pend;
    wire tn;
    wire tz;
    wire tc;
    wire tv;

    AddWithCarry #(.N(32)) addr_w_c (
        .x(x),
        .y(y),
        .cin(cin),
        .result(pend),
        .n(tn),
        .z(tz),
        .c(tc),
        .v(tv)
    );

    always @* begin
        case (ops[3:0])
            4'b0010: begin 
                result <= pend;
                n <= tn;
                z <= tz;
                c <= tc;
                v <= tv;
            end
        endcase
    end
endmodule

module processor
    #(parameter ARCH = 32,
      parameter RAM_SIZE = 4096
    )(
    input clk, 
    input reset_n,
    output reg trap
    );

    reg [ARCH-1:0] registers [0:16];
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


    // ALU stuff
    reg [ARCH-1:0] imm32;
    wire [ARCH-1:0] offset;
    wire cin;
    wire flag_n;
    wire flag_z;
    wire flag_c;
    wire flag_v;

    ALU alu (
        .ops(ops),
        .x(registers[rs]),
        .y(imm32),
        .cin(cin),
        .result(offset),
        .n(flag_n),
        .z(flag_z),
        .c(flag_c),
        .v(flag_v)
    );

    always @(posedge clk) begin
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<32; i=i+1) registers[i] <= 0;
            trap <= 1'b0;
        end

        ins <= r.mem[pc];
        $display("\n");
        $display("ins: %h", ins, ", pc: %h", pc);
        $display("%b", cond, " %b", ops, " %b", s, " %b", rs, " %b", rd, " %b", imm12);

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
                // ADD (immediate, to PC) & ADD, ADDS (immediate)
                imm32 <= { {20{1'b0}}, imm12 };
            end
            8'b0010101: begin
            end
            8'b0010110: begin
            end
            8'b0010111: begin
            end

            8'b0101001: begin
                // STR (immediate):
                // offset_addr = if add (ins[23]) then (R[n] + imm32) else (R[n] - imm32);
                // address = if index then offset_addr else R[n];
                // MemU[address,4] = if t == 15 then PCStoreValue() else R[t];
                // if wback then R[n] = offset_addr;
            end
        endcase
    end
endmodule
