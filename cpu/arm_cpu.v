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

module arm32_alu
    #(parameter N = 32
    )(
    input wire [3:0]   ops,
    input wire [N-1:0] x,
    input wire [N-1:0] y,
    input wire         cin,
    output reg [N-1:0] res,
    output reg [3:0]   flags
);
    reg c;
    reg v;
    wire z;
    wire n;

    always @* begin
        c <= 1'b0;
        v <= 1'b0;
        case (ops)
            4'b0001: res <= y;
            4'b1001: res <= ~y;
            4'b0010: {c, res} <= x + y;
            4'b0011: {c, res} <= x + y + cin;
            4'b0100: {c, res} <= x - y;
            4'b0101: {c, res} <= x - y - cin;
            4'b0110: res <= x & y;
            4'b0111: res <= x | y;
            4'b1000: res <= x ^ y;
            4'b0100: res <= x - y;
            4'b0110: res <= x & y;
            4'b0010: res <= x + y;
            4'b0010: res <= x + y;
        endcase

        if(ops == 4'b0010 || ops == 4'b0011)
            v <= (x[N-1] == y[N-1]) & (x[N-1] == ~res[N-1]);
        else if (ops == 4'b0100 || ops == 4'b0101)
            v <= (x[N-1] == ~y[N-1]) & (x[N-1] == ~res[N-1]);
    end

    assign n = res[N-1];
    assign z = res == 32'b0 ? 1'b1 : 1'b0;

    assign flags = {c, v, z, n};
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

    ram #(.DEPTH(1024)) r (
        .clk(clk)
    );

    // *** decode ***
    wire [11:0] imm12 = ins[11:0];
    wire [3:0] rn = ins[3:0];
    wire op1 = ins[4];
    wire [3:0] rm = ins[11:8];
    wire [3:0] rd = ins[15:12];
    wire [3:0] rt = ins[15:12];
    wire [3:0] rs = ins[19:16];
    wire s = ins[20];
    wire p = ins[24];
    wire u = ins[23];
    wire w = ins[21];
    wire [6:0] ops = ins[27:21];
    wire [3:0] cond = ins[31:28];

    // *** expand imm12 to imm32 ***
    reg exp_cin;
    reg [ARCH-1:0] exp_imm;
    reg exp_cout;

    A32ExpandImm_C #(.N(ARCH)) a32_expand_imm_c (
        .imm12(imm12),
        .cin(exp_cin),
        .imm32(exp_imm),
        .cout(exp_cout)
    );

    reg [ARCH-1:0] imm32;

    // *** ALU ***
    reg [ARCH-1:0] alu_result;
    reg [ARCH-1:0] alu_left;
    reg [ARCH-1:0] alu_right;
    reg alu_neg;

    // arm32_alu alu (
    //     .ops(ops),
    //     .x(alu_left),
    //     .y(alu_right),
    //     .n(alu_neg),
    //     .result(alu_result),
    // );

    // reg [ARCH-1:0] offset_addr;

    always @(posedge clk) begin
        step <= step << 1;
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<ARCH; i=i+1) registers[i] <= 0;
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
            end
            7'b0010011: begin
            end
            7'b0010100: begin
                // ADD (immediate, to PC) & ADD, ADDS (immediate)
                imm32 <= exp_imm;
                $display("ADD rd:%d, imm32:%d", rd, imm32, " - ", "%b", cond, " %b", ops, " %b", s, " %b", rs, " %b", rd, " %b", imm12);
            end
            7'b0010101: begin
            end
            7'b0010110: begin
            end
            7'b0010111: begin
            end
            7'b0011101: begin
                // MOV (immediate)
            end
            7'b0100000: begin
                // STR (immediate): P=0, U=0, W=0
            end
            7'b0101000: begin
                // STR (immediate): P=1, U=0, W=0
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=0, W=1
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=1, W=0
            end
            7'b0101001: begin
                // STR (immediate): P=1, U=1, W=1
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
