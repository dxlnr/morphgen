// ARM32 CPU Implementation

module exp_to_32b_value
    #(parameter N = 32
    )(
    input wire [N-1:0]  rm,
    input wire [11:0]  imm12,
    input wire i,
    input wire s,
    output reg [31:0] res
);

    reg [31:0] imm32;
    reg [31:0] r_rotate_imm;

    wire [4:0] shift_imm = imm12[11:7];
    wire [3:0] rotate_imm = imm12[11:8];
    wire [1:0] shift = imm12[6:5];
    wire [7:0] imm8 = imm12[7:0];
 
    assign res = s == 1'b1  ? { {20{imm12[11]}}, imm12} : 
        i == 1'b1           ? imm32 : 
        shift == 2'b00      ? rm <<  {1'b0, shift_imm} :
        shift == 2'b01      ? rm >>  {1'b0, shift_imm} :
        shift == 2'b10      ? rm >>> {1'b0, shift_imm} :
        r_rotate_imm; 

    integer k = 0;
    always @* begin
        imm32 <= {24'b0, imm8};

        for(integer k = 0; k < rotate_imm; k = k + 1) begin
            imm32 <= {imm32[1:0], imm32[31:2]};
        end 

        r_rotate_imm <= rm;

        for(integer k = 0; k <= imm12[11:7]; k = k + 1) begin
            r_rotate_imm <= {r_rotate_imm[0], r_rotate_imm[31:0]};
        end
    end
endmodule

module arm32_decoder
    #(parameter N = 32
    )(
    input wire [N-1:0] registers [0:16],
    input wire [N-1:0] ins,
    input wire [3:0]   flags,
    output reg [11:0]  imm12,
    output reg         s,
    output reg         i,
    output reg         f_c,
    output reg [3:0]   rm,
    output reg [3:0]   rn,
    output reg [3:0]   r_mem,
    output reg [3:0]   s_alu,
    output reg         s_mem_r_en, 
    output reg         s_mem_w_en
);

    wire cc_res;
    wire s_mux;
    wire[9:0] mux_in;

    wire [3:0] s_c;
    wire s_wb_en;
    wire s_br;
    wire s_s;
    wire s_imm;
    wire w_mem_r_en; 
    wire w_mem_w_en;

    wire [3:0] cond = ins[31:28];
    wire [1:0] ins_t = ins[27:26];
    wire [3:0] opc = ins[24:21];
    wire [3:0] rd = ins[15:12];
    //wire [23:0] imm24 = ins[23:0];

    control_unit cu (
        .ops(opc),
        .ins_t(ins_t),
        .ldr_str(s),
        .s_c(s_c),
        .s_wb_en(s_wb_en),
        .s_mem_r_en(w_mem_r_en),
        .s_mem_w_en(w_mem_w_en),
        .s_br(s_br)
    );

    cond cc (
        .cond(cond),
        .flags(flags),
        .res(cc_res)
    );

    assign imm12 = ins[11:0];
    assign rm = ins[3:0];
    assign rn = ins[19:16];
    assign s = ins[20];
    assign i = ins[25];
    assign f_c = flags[2];
    assign s_alu = s_c;
    assign s_mux = ~cc_res | 1'b0; 
    assign mux_in = {w_mem_r_en, w_mem_w_en, s_wb_en, s_s, s_br, s_imm, s_c};
    assign {s_mem_r_en, s_mem_w_en, s_wb_en, s_s, s_br, s_imm, s_c} = s_mux ? 10'b0: mux_in;
    assign r_mem = s_mem_w_en ? rd : rm;

endmodule

module alu 
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

module cond (
    input wire [3:0] cond,
    input wire [3:0] flags,
    output reg       res
    );

    wire z;
    wire c;
    wire n;
    wire v;

    assign {z, c, n, v} = flags;

    always@(cond, flags) begin
        res <= 1'b0;

        case(cond)
            4'b0000: begin
                if(z == 1'b1)
                    res <= 1'b1;
            end
            4'b0001: begin
                if(z == 1'b0)
                    res <= 1'b1;
            end
            4'b0010: begin
                if(c == 1'b1)
                    res <= 1'b1;
            end
            4'b0011:begin
                if(c == 1'b0)
                    res = 1'b1;
            end
            4'b0100: begin
                if(n == 1'b1)
                    res <= 1'b1;
            end
            4'b0101: begin
                if(n == 1'b0)
                    res <= 1'b1;
            end
            4'b0110: begin
                if(v == 1'b1)
                    res <= 1'b1;
            end
            4'b0111: begin
                if(v == 1'b0)
                    res <= 1'b1;
            end
            4'b1000: begin
                if(c == 1'b1 & z == 1'b0)
                    res <= 1'b1;
            end
            4'b1001: begin
                if(c == 1'b0 & z == 1'b1)
                    res <= 1'b1;
            end
            4'b1010: begin
                if(n == v)
                    res <= 1'b1;
            end
            4'b1011: begin
                if(n != v)
                    res <= 1'b1;
            end
            4'b1100: begin
                if(z == 1'b0 & n == v)
                    res <= 1'b1;
            end
            4'b1101: begin
                if(z == 1'b1& n != v)
                    res = 1'b1;
            end
            4'b1111: begin
                res <= 1'b1;
            end
        endcase
    end
endmodule

module control_unit
    #(parameter N = 32
    )(
    input wire [3:0] ops,
    input wire [1:0] ins_t,
    input wire       ldr_str,
    output reg[3:0]  s_c,
    output reg       s_wb_en,
    output reg       s_mem_r_en,
    output reg       s_mem_w_en,
    output reg       s_br
);

    always @(ops, ins_t, ldr_str) begin
        s_mem_r_en = 1'b0;
        s_mem_w_en = 1'b0;
        s_wb_en = 1'b0;
        s_br <= 1'b0;
        s_c <= 4'b0000;
        
        case (ins_t)
            2'b00: begin // Arithmetic Instruction
                case (ops)
                    4'b1101: begin // MOV
                        s_wb_en <= 1'b1;
                        s_c <= 4'b0001;
                    end 
                    4'b1101: begin // MVN
                        s_wb_en <= 1'b1;
                        s_c <= 4'b1001;
                    end
                    4'b0100: begin // ADD
                        s_wb_en <= 1'b1;
                        s_c <= 4'b0010;
                    end
                    4'b0010: begin // SUB
                        s_wb_en <= 1'b1;
                        s_c <= 4'b0100;
                    end
                    4'b0000: begin // AND
                        s_wb_en <= 1'b1;
                        s_c <= 4'b0110;
                    end
                    4'b1100: begin // ORR
                        s_wb_en <= 1'b1;
                        s_c <= 4'b0111;
                    end
                    4'b0001: begin // EOR
                        s_wb_en <= 1'b1;
                        s_c <= 4'b1000;
                    end
                    4'b1010: begin // CMP
                        s_c <= 4'b0100;
                    end
                    4'b1000: begin // TST
                        s_c <= 4'b0110;
                    end 
                endcase
            end
            2'b01: begin // Memory (Load/Store) Instruction
                case (ldr_str)
                    1'b1: begin // LDR
                        s_mem_r_en <= 1'b1;
                        s_c <= 4'b0010;
                        s_wb_en <= 1'b1;
                    end
                    1'b0: begin // STR
                        s_mem_w_en <= 1'b1;
                        s_c <= 4'b0010;
                    end
                endcase
            end
            2'b10: begin // Branch Instruction
                s_br <= 1'b1;
            end
            2'b11: begin // Co Processor Instruction
            end
        endcase
    end
endmodule

module processor
    #(parameter ARCH = 32,
      parameter RAM_SIZE = 1024 
    )(
    input clk, 
    input reset_n,
    output reg trap
);

    reg [ARCH-1:0] registers [0:16];
    reg [ARCH-1:0] ins;
    reg [ARCH-1:0] pc;
    reg [6:0] step;

    ram #(.DEPTH(RAM_SIZE)) r (
        .clk(clk)
    );

    reg [ARCH-1:0] v_wb;

    // *** decode ***
    reg [3:0] flags;
    reg [11:0] imm12;
    reg [3:0] rm;
    reg [3:0] rn;
    reg [3:0] s_alu;
    reg [3:0] r_mem;
    reg s;
    reg imm;
    reg f_c;
    reg s_mem_r_en;
    reg s_mem_w_en;

    reg [ARCH-1:0] v_rm;

    arm32_decoder dec (
        .ins(ins),
        .flags(flags),
        .imm12(imm12),
        .s(s),
        .i(imm),
        .rm(rm),
        .rn(rn),
        .f_c(f_c),
        .r_mem(r_mem),
        .s_alu(s_alu),
        .s_mem_r_en(s_mem_r_en),
        .s_mem_w_en(s_mem_w_en)
    );

    // *** expand imm12 to imm32 ***
    wire [ARCH-1:0] imm32 = 32'b0;

    //exp_to_32b_value e (
    //    .rm(v_rm),
    //    .imm12(imm12),
    //    .i(imm),
    //    .s(s),
    //    .res(imm32)
    //);

    // *** ALU ***
    reg [ARCH-1:0] alu_res;
    reg [3:0] alu_flags;

    alu a (
        .ops(s_alu),
        .x(registers[rn]),
        .y(imm32),
        .cin(f_c),
        .res(alu_res),
        .flags(alu_flags)
    );

    wire [ARCH-1:0] w_addr_0 = { alu_res[31:2], 2'b00 } - 32'd1024;
    wire [ARCH-1:0] w_addr_1 = {w_addr_0[ARCH-1:1], 1'b1};
    wire [ARCH-1:0] w_addr_2 = {w_addr_0[ARCH-1:2], 2'b10};
    wire [ARCH-1:0] w_addr_3 = {w_addr_0[ARCH-1:2], 2'b11};

    always @(posedge clk) begin
        step <= step << 1;
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<ARCH; i=i+1) registers[i] <= 32'b0;
            flags <= 4'b0;
            trap <= 1'b0;
            step <= 1'b1;
        end

        ins <= r.mem[pc];

        // *** memory access ***
        if (step[5] == 1'b1) begin
            if(s_mem_w_en == 1'b1) begin
                r.mem[w_addr_3] <= registers[r_mem][7:0];
                r.mem[w_addr_2] <= registers[r_mem][15:8];
                r.mem[w_addr_1] <= registers[r_mem][23:16];
                r.mem[w_addr_0] <= registers[r_mem][ARCH-1:24];
            end
        end

        // *** write back ***
        if (step[6] == 1'b1) begin
            pc <= pc + 1;
            step <= 1'b1;
            v_wb <= s_mem_r_en ? r_mem : alu_res;

            $display("\n");
            $display("ins: %h", ins, ", pc: %h", pc);

            $display("r00: %h", registers[0], ",  r01: %h", registers[1], ",  r02: %h", registers[2], ",  r03: %h", registers[3], ",  r04: %h", registers[4]);
            $display("r05: %h", registers[5], ",  r06: %h", registers[6], ",  r07: %h", registers[7], ",  r08: %h", registers[8], ",  r09: %h", registers[9]);
            $display("r10: %h", registers[10], ",   fp: %h", registers[11], ",   ip: %h", registers[12], ",   sp: %h", registers[13], ",   lr: %h", registers[14]);
            $display(" pc: %h", registers[15], ", cpsr: %h", registers[16]);

        end
        $display("%b", step);
    end
endmodule
