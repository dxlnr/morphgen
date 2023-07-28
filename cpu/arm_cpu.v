// ARM32 CPU Implementation

module exp_to_32b_value
    #(parameter N = 32
    )(
    input clk,
    input wire [N-1:0] v_rm,
    input wire [11:0]  imm12,
    input wire         i,
    input wire         s_mem,
    output reg [31:0]  res
);
    reg [N-1:0] imm32;
    reg [N-1:0] r_rotate_imm;

    wire [4:0] shift_imm = imm12[11:7];
    wire [3:0] rotate_imm = imm12[11:8];
    wire [1:0] shift = imm12[6:5];
    wire [7:0] imm8 = imm12[7:0];

    assign res = s_mem == 1'b1  ? { {20{imm12[11]}}, imm12} : 
        i == 1'b1           ? imm32 : 
        shift == 2'b00      ? v_rm <<  {1'b0, shift_imm} :
        shift == 2'b01      ? v_rm >>  {1'b0, shift_imm} :
        shift == 2'b10      ? v_rm >>> {1'b0, shift_imm} :
        r_rotate_imm; 

    always @(posedge clk) begin
        imm32 <= {24'b0, imm8};

        for(integer k = 0; k < rotate_imm; k = k + 1) begin
            imm32 <= {imm32[1:0], imm32[31:2]};
        end 

        r_rotate_imm <= v_rm;

        for(integer k = 0; k <= imm12[11:7]; k = k + 1) begin
            r_rotate_imm <= {r_rotate_imm[0], r_rotate_imm[31:0]};
        end
    end
endmodule

module arm32_decoder
    #(parameter N = 32
    )(
    input wire [N-1:0] i_ins,
    input wire [3:0]   i_flags,
    output reg [11:0]  o_imm12,
    output reg [23:0]  o_imm24,
    output reg [3:0]   o_rm,
    output reg [3:0]   o_rn,
    output reg [3:0]   o_rd,
    output reg         o_s_bit,
    output reg         o_br,
    output reg         o_imm,
    output reg         o_f_c,
    output reg [3:0]   o_flags,
    output reg [3:0]   o_r_mem,
    output reg [3:0]   o_s_alu,
    output reg         o_s_mem_r_en, 
    output reg         o_s_mem_w_en,
    output reg         o_wb_en
);
    wire cc_res;
    wire s_mux;
    wire[9:0] mux_in;

    wire [3:0] w_alu_c;
    wire w_wb_en;
    wire w_br;
    wire w_mem_r_en; 
    wire w_mem_w_en;
    wire w_s_w_en;

    wire [3:0] opc = ins[24:21];
    wire [1:0] ins_t = ins[27:26];
    wire [3:0] rd = ins[15:12];
    wire [3:0] ldr_str = ins[25];
    wire [3:0] cond = ins[31:28];

    control_unit cu (
        .i_ops(opc),
        .i_ins_t(ins_t),
        .i_ldr_str(ldr_str),
        .o_s_c(w_alu_c),
        .o_s_wb_en(w_s_wb_en),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_s_br(w_br)
    );

    cond cc (
        .i_cond(cond),
        .i_flags(i_flags),
        .o_res(cc_res)
    );

    assign o_imm12 = ins[11:0];
    assign o_imm24 = ins[23:0];
    assign o_rm = ins[3:0];
    assign o_rn = ins[19:16];
    assign o_rd = ins[15:12];
    assign o_s_bit = ins[20];
    assign o_f_c = flags[2];
    assign o_s_alu = w_alu_c;
    assign o_s_mux = ~cc_res | 1'b0; 
    assign mux_in = {w_mem_r_en, w_mem_w_en, w_wb_en, 1'b0, w_br, ldr_str, w_flags};
    assign {o_s_mem_r_en, o_s_mem_w_en, o_wb_en, _, o_br, o_imm, o_flags} = s_mux ? 10'b0: mux_in;
    assign o_r_mem = s_mem_w_en ? rd : rm;

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
    input wire [3:0] i_cond,
    input wire [3:0] i_flags,
    output reg       o_res
);
    wire z;
    wire c;
    wire n;
    wire v;

    assign {z, c, n, v} = i_flags;

    always@(i_cond, i_flags) begin
        o_res <= 1'b0;

        case(i_cond)
            4'b0000: begin
                if(z == 1'b1)
                    o_res <= 1'b1;
            end
            4'b0001: begin
                if(z == 1'b0)
                    o_res <= 1'b1;
            end
            4'b0010: begin
                if(c == 1'b1)
                    o_res <= 1'b1;
            end
            4'b0011: begin
                if(c == 1'b0)
                    o_res = 1'b1;
            end
            4'b0100: begin
                if(n == 1'b1)
                    o_res <= 1'b1;
            end
            4'b0101: begin
                if(n == 1'b0)
                    o_res <= 1'b1;
            end
            4'b0110: begin
                if(v == 1'b1)
                    o_res <= 1'b1;
            end
            4'b0111: begin
                if(v == 1'b0)
                    o_res <= 1'b1;
            end
            4'b1000: begin
                if(c == 1'b1 & z == 1'b0)
                    o_res <= 1'b1;
            end
            4'b1001: begin
                if(c == 1'b0 & z == 1'b1)
                    o_res <= 1'b1;
            end
            4'b1010: begin
                if(n == v)
                    o_res <= 1'b1;
            end
            4'b1011: begin
                if(n != v)
                    o_res <= 1'b1;
            end
            4'b1100: begin
                if(z == 1'b0 & n == v)
                    o_res <= 1'b1;
            end
            4'b1101: begin
                if(z == 1'b1& n != v)
                    o_res = 1'b1;
            end
            4'b1111: begin
                res <= 1'b1;
            end
        endcase
    end
endmodule

module execution_unit
    #(parameter N = 32
    )(
    input clk, 
    input wire i_s_mem_r_en,
    input wire i_s_mem_w_en,
    input wire i_s_wb_en,
    input wire i_imm,
    input wire i_cin,
    input wire [3:0] i_ops,
    input wire [3:0] i_s_c,
    input wire [11:0] i_imm12,
    input wire [23:0] i_imm24,
    input wire [N-1:0] i_v_rm,
    input wire [N-1:0] i_v_rn,
    input wire [N-1:0] i_v_mem_wb,
    input wire [N-1:0] i_v_wb,
    output reg o_s_mem_r_en,
    output reg o_s_mem_w_en,
    output reg o_s_wb_en,
    output reg [N-1:0] o_alu_res,
    output reg [3:0] o_alu_flags,
    output reg [N-1:0] o_v_rm,
    output reg [N-1:0] o_b_addr,
);
    assign o_s_mem_r_en = i_s_mem_r_en;
    assign o_s_mem_w_en = i_s_mem_w_en;
    assign o_s_wb_en = i_s_wb_en;

    wire s_mem = s_mem_r_en | s_mem_w_en;
    wire [N-1:0] alu_left;
    wire [N-1:0] imm32;

    assign o_v_rm = i_v_rm;
    exp_to_32b_value e (
        .v_rm(o_v_rm),
        .imm12(i_imm12),
        .i(i_imm),
        .s_mem(i_s_mem),
        .res(imm32)
    );

    assign alu_left = i_v_rn;
    alu a (
        .ops(),
        .x(alu_left),
        .y(imm32),
        .cin(i_cin),
        .res(o_alu_res),
        .flags(o_alu_flags)
    );
    assign o_b_addr = i_pc + { {6{imm24[23]}}, imm24, 2'b0 };

    // alu Alu(
    //     .i_A(w_Value_1), 
    //     .i_B(w_Value_2),
    //     .i_Sigs_Control(i_Sigs_Control),
    //     .i_Sig_Carry_In(i_Carry_In),
    //     .o_ALU_Result(o_ALU_Result),
    //     .o_Status(o_ALU_Status)
    // );
endmodule

module control_unit
    #(parameter N = 32
    )(
    input wire [3:0] i_ops,
    input wire [1:0] i_ins_t,
    input wire       i_ldr_str,
    output reg[3:0]  o_s_c,
    output reg       o_s_wb_en,
    output reg       o_s_mem_r_en,
    output reg       o_s_mem_w_en,
    output reg       o_s_br
);
    always @(i_ops, i_ins_t, i_ldr_str) begin
        o_s_mem_r_en = 1'b0;
        o_s_mem_w_en = 1'b0;
        o_s_wb_en = 1'b0;
        o_s_br <= 1'b0;
        o_s_c <= 4'b0000;
        
        case (i_ins_t)
            2'b00: begin // Arithmetic Instruction
                case (i_ops)
                    4'b1101: begin // MOV
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b0001;
                    end 
                    4'b1101: begin // MVN
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b1001;
                    end
                    4'b0100: begin // ADD
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b0010;
                    end
                    4'b0010: begin // SUB
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b0100;
                    end
                    4'b0000: begin // AND
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b0110;
                    end
                    4'b1100: begin // ORR
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b0111;
                    end
                    4'b0001: begin // EOR
                        o_s_wb_en <= 1'b1;
                        o_s_c <= 4'b1000;
                    end
                    4'b1010: begin // CMP
                        o_s_c <= 4'b0100;
                    end
                    4'b1000: begin // TST
                        o_s_c <= 4'b0110;
                    end 
                endcase
            end
            2'b01: begin // Memory (Load/Store) Instruction
                case (i_ldr_str)
                    1'b1: begin // LDR
                        o_s_mem_r_en <= 1'b1;
                        o_s_c <= 4'b0010;
                        o_s_wb_en <= 1'b1;
                    end
                    1'b0: begin // STR
                        o_s_mem_w_en <= 1'b1;
                        o_s_c <= 4'b0010;
                    end
                endcase
            end
            2'b10: begin // Branch Instruction
                o_s_br <= 1'b1;
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
    reg [23:0] imm24;
    reg [3:0] rm;
    reg [3:0] rn;
    reg [3:0] rd;
    reg [3:0] s_alu;
    reg [3:0] r_mem;
    reg s_bit;
    reg s_imm;
    wire w_f_c;
    wire w_mem_r_en;
    wire w_mem_w_en;
    wire w_wb_en;

    arm32_decoder dec (
        .i_ins(ins),
        .i_flags(flags),
        .o_imm12(imm12),
        .o_imm24(imm24),
        .o_rm(rm),
        .o_rn(rn),
        .o_rd(rd),
        .o_s_bit(s_bit),
        .o_br(),
        .o_imm(s_imm),
        .f_c(w_f_c),
        .o_flags(),
        .o_r_mem(r_mem),
        .o_s_alu(s_alu),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_wb_en(w_wb_en)
    );

    reg s_mem_r_en;
    reg s_mem_w_en;

    execution_unit eu (
        .clk(clk), 
        .i_s_mem_r_en(w_mem_r_en),
        .i_s_mem_w_en(w_mem_w_en),
        .i_s_wb_en(w_wb_en),
        .i_imm(s_imm),
        .i_cin(w_f_c),
        .i_ops(),
        .i_s_c(),
        .i_imm12(),
        .i_imm24(),
        .i_v_rm(),
        .i_v_rn(),
        .o_s_mem_r_en(s_mem_r_en),
        .o_s_mem_w_en(s_mem_w_en),
        .o_s_wb_en(),
        .o_alu_res(),
        .o_alu_flags(),
        .o_v_rm()
    );
 
    // *** expand imm12 to imm32 ***
    reg [ARCH-1:0] v_rm;
    reg [ARCH-1:0] imm32;

    exp_to_32b_value e (
        .v_rm(v_rm),
        .imm12(imm12),
        .i(imm),
        .s(s),
        .res(imm32)
    );

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
    wire [ARCH-1:0] w_addr_1 = { w_addr_0[ARCH-1:1], 1'b1 };
    wire [ARCH-1:0] w_addr_2 = { w_addr_0[ARCH-1:2], 2'b10 };
    wire [ARCH-1:0] w_addr_3 = { w_addr_0[ARCH-1:2], 2'b11 };

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

        $display("imm32 = %b", imm32);

        // *** memory access ***
        if (step[5] == 1'b1) begin
            if(s_mem_w_en == 1'b1) begin
                r.mem[w_addr_3] <= registers[r_mem][7:0];
                r.mem[w_addr_2] <= registers[r_mem][15:8];
                r.mem[w_addr_1] <= registers[r_mem][23:16];
                r.mem[w_addr_0] <= registers[r_mem][ARCH-1:24];
            end
        end

        if (step[2] == 1'b1) begin
            v_rm <= registers[rm];
            $display("v_rm = %b", v_rm);
        end

        // *** write back ***
        if (step[6] == 1'b1) begin
            pc <= pc + 1;
            step <= 1'b1;
            v_wb <= s_mem_r_en ? r_mem : alu_res;

            $display("\n");
            $display("ins: %h", ins, ", pc: %h", pc);
            $display("cond %b", ins[31:28], ", ops %b", ins[27:21], ", s %b", ins[20], ", rn %b", ins[19:16], ", rd %b", ins[15:12], ", imm12 %b", ins[11:0]);

            $display("r00: %h", registers[0], ",  r01: %h", registers[1], ",  r02: %h", registers[2], ",  r03: %h", registers[3], ",  r04: %h", registers[4]);
            $display("r05: %h", registers[5], ",  r06: %h", registers[6], ",  r07: %h", registers[7], ",  r08: %h", registers[8], ",  r09: %h", registers[9]);
            $display("r10: %h", registers[10], ",   fp: %h", registers[11], ",   ip: %h", registers[12], ",   sp: %h", registers[13], ",   lr: %h", registers[14]);
            $display(" pc: %h", registers[15], ", cpsr: %h", registers[16]);

        end
        $display("%b", step);
    end
endmodule
