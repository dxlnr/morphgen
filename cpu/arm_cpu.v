// ARM32 CPU Implementation

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
    output wire [N-1:0] result,
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

module A32ExpandImm_C
    #(parameter N = 32
    )(
    input wire [11:0]  imm12,
    input wire         cin,
    output reg [N-1:0] imm32,
    output reg         cout 
);
    reg [N-1:0] unrotated_value;
    always @* begin
        unrotated_value = {20'b0, imm12[7:0]};
    end

    reg [4:0] shift_amount;
    always @* begin
        shift_amount = 2 * $unsigned(imm12[11:8]);
    end

    reg [N-1:0] t;
    always @* begin
        {t, cout} <= unrotated_value >>> shift_amount;
    end
    assign imm32 = t;

endmodule

module ToImm32
    #(parameter N = 32
    )(
    input wire         ops,
    input wire [11:0]  imm12,
    input wire         cin,
    output reg [N-1:0] imm32,
    output reg cout
);
    wire [N-1:0] exp_imm;
    wire exp_cout;

    A32ExpandImm_C #(.N(N)) a32_expand_imm_c (
        .imm12(imm12),
        .cin(cin),
        .imm32(exp_imm),
        .cout(exp_cout)
    );

    always @* begin
        case (ops)  
            1'b0: begin
               imm32 <= { {20{1'b0}}, imm12 };
            end
            1'b1: begin
                imm32 <= exp_imm;
                cout <= exp_cout;
            end
        endcase
    end
endmodule

module ALU
    #(parameter N = 32
    )(
    input wire [6:0]  ops,
    input wire [31:0] x,
    input wire [31:0] y,
    input wire        cin,
    output reg [31:0] result,
    output reg        n,
    output reg        z,
    output reg        c,
    output reg        v 
);
    wire [N-1:0] add_w_c_result;
    wire tn;
    wire tz;
    wire tc;
    wire tv;

    AddWithCarry #(.N(N)) addr_w_c (
        .x(x),
        .y(y),
        .cin(cin),
        .result(add_w_c_result),
        .n(tn),
        .z(tz),
        .c(tc),
        .v(tv)
    );

    always @* begin
        case (ops[6:3])
            4'b0010: begin 
                result <= add_w_c_result;
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
    reg [6:0] step;

    ram #(.DEPTH(4096)) r (
        .clk(clk)
    );

    wire [11:0] imm12 = ins[11:0];
    wire [3:0] rd = ins[15:12];
    wire [3:0] rs = ins[19:16];
    wire s = ins[20];
    wire [6:0] ops = ins[27:21];
    wire [3:0] cond = ins[31:28];

    // expand imm12 to imm32
    reg exp_ops;
    reg [ARCH-1:0] imm32;
    reg exp_c;

    ToImm32 #(.N(ARCH)) ex_imm_c (
        .ops(exp_ops),
        .imm12(imm12),
        .cin(registers[16][2]),
        .imm32(imm32),
        .cout(exp_c)
    );

    // ALU stuff
    reg [ARCH-1:0] offset;
    reg [ARCH-1:0] alu_left;
    reg [ARCH-1:0] alu_right;
    reg cin;
    reg flag_n;
    reg flag_z;
    reg flag_c;
    reg flag_v;

    ALU alu (
        .ops(ops),
        .x(alu_left),
        .y(alu_right),
        .cin(cin),
        .result(offset),
        .n(flag_n),
        .z(flag_z),
        .c(flag_c),
        .v(flag_v)
    );

    reg [ARCH-1:0] offset_addr;

    always @(posedge clk) begin
        step <= step << 1;
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<32; i=i+1) registers[i] <= 0;
            trap <= 1'b0;
            step <= 1'b1;
        end

        ins <= r.mem[pc];

        case (ops)   
            7'b0000000: begin
            end
            7'b0000001: begin
            end
            7'b0000010: begin
            end
            7'b0000011: begin
            end
            7'b0000100: begin
            end
            7'b0000101: begin
            end
            7'b0000110: begin
            end
            7'b0000111: begin
            end
            7'b0001000: begin
            end
            7'b0001001: begin
            end
            7'b0001010: begin
            end
            7'b0001011: begin
            end
            7'b0001100: begin
            end
            7'b0001101: begin
            end
            7'b0001110: begin
            end
            7'b0001111: begin
            end
            7'b0010000: begin
            end
            7'b0010001: begin
            end
            7'b0010010: begin
                // SUB, SUBS (immediate)
                exp_ops <= 1'b0;
                // imm32 <= ~{ {20{1'b0}}, imm12 };
                cin <= 1'b1;
                if (rd == 15) begin
                    trap <= 1'b1;
                end else begin
                    registers[rd] <= offset;
                    registers[16][0] <= flag_n;
                    registers[16][1] <= flag_z;
                    registers[16][2] <= flag_c;
                    registers[16][3] <= flag_v;
                end
            end
            7'b0010011: begin
                // imm32 <= { {20{1'b0}}, imm12 };
            end
            7'b0010100: begin
                // ADD (immediate, to PC) & ADD, ADDS (immediate)
                // imm32 <= { {20{1'b0}}, imm12 };
                cin <= 1'b0;
                if (rd == 15) begin
                    trap <= 1'b1;
                end else begin
                    registers[rd] <= offset;
                    registers[16][0] <= flag_n;
                    registers[16][1] <= flag_z;
                    registers[16][2] <= flag_c;
                    registers[16][3] <= flag_v;
                end
            end
            7'b0010101: begin
            end
            7'b0010110: begin
            end
            7'b0010111: begin
            end
            7'b0011101: begin
                // MOV (immediate)
                if (s == 1'b1) begin
                    registers[rd] <= imm32;
                    registers[16][0] <= imm32[ARCH-1];
                    registers[16][1] <= imm32 == 0;
                    registers[16][2] <= flag_c;
                    registers[16][3] <= flag_v;
                end else begin
                    registers[rd] <= imm32;
                end
            end
            7'b0100000: begin
                // STR (immediate): P=0, U=0, W=0
                if (rd == 15) begin
                    r.mem[registers[rs]] <= registers[pc];
                end else begin
                    r.mem[registers[rs]] <= registers[rd];
                end
            end
            7'b0101000: begin
                // STR (immediate): P=1, U=0, W=0
                offset_addr <= rs - { {20{1'b0}}, imm12 };
                if (rd == 15) begin
                    r.mem[offset_addr] <= registers[pc];
                end else begin
                    r.mem[offset_addr] <= registers[rd];
                end
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=0, W=1
                offset_addr <= rs - { {20{1'b0}}, imm12 };
                if (rd == 15) begin
                    r.mem[offset_addr] <= registers[pc];
                end else begin
                    r.mem[offset_addr] <= registers[rd];
                end
                registers[rs] <= offset_addr;
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=1, W=0
                offset_addr <= rs + { {20{1'b0}}, imm12 };
                if (rd == 15) begin
                    r.mem[offset_addr] <= registers[pc];
                end else begin
                    r.mem[offset_addr] <= registers[rd];
                end
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=1, W=1
                offset_addr <= rs + { {20{1'b0}}, imm12 };
                if (rd == 15) begin
                    r.mem[offset_addr] <= registers[pc];
                end else begin
                    r.mem[offset_addr] <= registers[rd];
                end
                registers[rs] <= offset_addr;
            end
        endcase

        if (step[6] == 1'b1) begin
            pc <= pc + 1;
            step <= 1'b1;

            $display("\n");
            $display("ins: %h", ins, ", pc: %h", pc);
            $display("%b", cond, " %b", ops, " %b", s, " %b", rs, " %b", rd, " %b", imm12);

            $display("r00: %h", registers[0], ",  r01: %h", registers[1], ",  r02: %h", registers[2], ",  r03: %h", registers[3], ",  r04: %h", registers[4]);
            $display("r05: %h", registers[5], ",  r06: %h", registers[6], ",  r07: %h", registers[7], ",  r08: %h", registers[8], ",  r09: %h", registers[9]);
            $display("r10: %h", registers[10], ",   fp: %h", registers[11], ",   ip: %h", registers[12], ",   sp: %h", registers[13], ",   lr: %h", registers[14]);
            $display(" pc: %h", registers[15], ", cpsr: %h", registers[16]);

        end
    end
endmodule
