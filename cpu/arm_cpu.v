// ARM32 CPU Implementation

module exp_to_32b_value
    #(parameter N = 32
    )(
    input              clk,
    input [N-1:0]      i_v_rm,
    input [11:0]       i_imm12,
    input              i_s_imm,
    input              i_s_mem,
    output reg [31:0]  o_res
);
    reg [N-1:0] imm32;
    reg [N-1:0] r_rotate_imm;

    wire [4:0] shift_imm  = i_imm12[11:7];
    wire [3:0] rotate_imm = i_imm12[11:8];
    wire [1:0] shift      = i_imm12[6:5];
    wire [7:0] imm8       = i_imm12[7:0];

    always @(posedge clk) begin
        imm32 <= {24'b0, imm8};

        for(integer k = 0; k < rotate_imm; k = k + 1) begin
            imm32 <= {imm32[1:0], imm32[31:2]};
        end 
        r_rotate_imm <= i_v_rm;

        for(integer k = 0; k <= i_imm12[11:7]; k = k + 1) begin
            r_rotate_imm <= {r_rotate_imm[0], r_rotate_imm[31:0]};
        end
    end

    assign o_res = i_s_mem == 1'b1  ? { {20{i_imm12[11]}}, i_imm12} : 
        i_s_imm == 1'b1     ? imm32 : 
        shift == 2'b00      ? i_v_rm <<  {1'b0, shift_imm} :
        shift == 2'b01      ? i_v_rm >>  {1'b0, shift_imm} :
        shift == 2'b10      ? i_v_rm >>> {1'b0, shift_imm} :
        r_rotate_imm; 
endmodule

module arm32_decoder
    #(parameter N = 32
    )(
    input              clk,
    input wire         i_reset_n,
    input wire [N-1:0] i_ins,
    input wire [3:0]   i_nzcv,
    output reg [11:0]  o_imm12,
    output reg [23:0]  o_imm24,
    output reg [3:0]   o_alu_c,
    output reg [N-1:0] o_vs1, 
    output reg [N-1:0] o_vs2, 
    output reg [3:0]   o_s1, 
    output reg [3:0]   o_s2, 
    output reg [3:0]   o_wb_addr,
    output reg         o_br,
    output reg         o_s_mem_r_en, 
    output reg         o_s_mem_w_en
);
    wire [3:0]  w_rn    = i_ins[19:16]; // 1st operand (reg address)
    // wire [3:0]  w_rs    = i_ins[];      // only used in mul and mla (reg address)
    wire [3:0]  w_rm    = i_ins[3:0];   // 2nd operand (reg address)
    wire [3:0]  w_rd    = i_ins[15:12]; // destination register
    wire [3:0]  w_op    = i_ins[24:21]; // opcode specifying the instruction
    wire [1:0]  w_ins_t = i_ins[27:26]; // instruction type
    wire [3:0]  w_cond  = i_ins[31:28]; // condition bits
    wire        w_ld_st = i_ins[25];    // load/store bit (1 = load)
    wire        w_s_bit;                // s bit
    wire        w_br;                   // branch bit (1 = branch)
    wire        w_cond_res;             // condition result
    wire        w_s_mux;                // mux select bit
    wire [9:0]  w_mux_in;           
    wire        w_wb_en;                // write back enable
    wire        w_mem_r_en;             // memory read enable 
    wire        w_mem_w_en;             // memory write enable
    wire [3:0]  w_alu_c;                // ALU control bits

    control_unit cu (
        .i_ops(w_op),
        .i_ins_t(w_ins_t),
        .i_ldr_str(w_ld_st),
        .o_s_c(w_alu_c),
        .o_s_wb_en(w_wb_en),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_s_br(w_br)
    );

    cond cc (
        .i_cond(w_cond),
        .i_nzcv(i_nzcv),
        .o_res(w_cond_res)
    );

    assign o_imm12      = i_ins[11:0];
    assign o_imm24      = i_ins[23:0];
    assign o_wb_addr    = w_rd;
    assign o_s1         = w_rn;
    assign o_s2         = w_rm;
    assign o_br         = w_br;
    // assign o_f_c        = i_nzcv[2];
    assign w_s_mux      = ~w_cond_res | 1'b0; 
    assign w_mux_in     = {w_mem_r_en, w_mem_w_en, w_wb_en, 1'b0, w_br, ldr_str, w_alu_c};
    assign {o_s_mem_r_en, o_s_mem_w_en, o_wb_en, o_s_w_en, o_br, o_imm, o_alu_c} = w_s_mux ? 10'b0: w_mux_in;
    assign w_r_s2 = w_mem_w_en ? w_rd : w_rm;

    register_bank rb (
        .clk(clk),
        .i_reset_n(i_reset_n),
        .i_r_s1(w_rn),
        .i_r_s2(w_rm),
        .i_wb_addr(w_rd),
        .i_wb_data(o_alu_res),
        .i_wb_en(w_wb_en),
        .o_vs1(o_vs1),
        .o_vs2(o_vs2)
    );

endmodule

module alu 
    #(parameter N = 32
    )(
    input wire [3:0]   i_ops,
    input wire [N-1:0] i_x,
    input wire [N-1:0] i_y,
    input wire         i_f_c,
    output reg [N-1:0] o_res,
    output reg [3:0]   o_nzcv
);
    reg c;
    reg v;
    wire z;
    wire n;

    always @* begin
        c <= 1'b0;
        v <= 1'b0;
        case (i_ops)
            4'b0001: o_res <= i_y;
            4'b1001: o_res <= ~i_y;
            4'b0010: {c, o_res} <= i_x + i_y;
            4'b0011: {c, o_res} <= i_x + i_y + i_f_c;
            4'b0100: {c, o_res} <= i_x - i_y;
            4'b0101: {c, o_res} <= i_x - i_y - i_f_c;
            4'b0110: o_res <= i_x & i_y;
            4'b0111: o_res <= i_x | i_y;
            4'b1000: o_res <= i_x ^ i_y;
            4'b0100: o_res <= i_x - i_y;
            4'b0110: o_res <= i_x & i_y;
            4'b0010: o_res <= i_x + i_y;
            4'b0010: o_res <= i_x + i_y;
        endcase

        if(i_ops == 4'b0010 || i_ops == 4'b0011)
            v <= (i_x[N-1] == i_y[N-1]) & (i_x[N-1] == ~o_res[N-1]);
        else if (i_ops == 4'b0100 || i_ops == 4'b0101)
            v <= (i_x[N-1] == ~i_y[N-1]) & (i_x[N-1] == ~o_res[N-1]);
    end

    assign n = o_res[N-1];
    assign z = o_res == 32'b0 ? 1'b1 : 1'b0;
    assign o_nzcv = {n, z, c, v};

endmodule


module cond (
    input wire [3:0] i_cond,
    input wire [3:0] i_nzcv,
    output reg       o_res
);
    wire n;
    wire z;
    wire c;
    wire v;
    assign {n, z, c, v} = i_nzcv;

    always@(i_cond, i_nzcv) begin
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
                o_res <= 1'b1;
            end
        endcase
    end
endmodule

module execution_unit
    #(parameter N = 32
    )(
    input               clk, 
    input wire [N-1:0]  i_pc,
    input wire          i_s_mem_r_en,
    input wire          i_s_mem_w_en,
    input wire          i_s_wb_en,
    input wire          i_s_imm,
    input wire          i_f_c,
    input wire [3:0]    i_ops,
    input wire [11:0]   i_imm12,
    input wire [23:0]   i_imm24,
    input wire [N-1:0]  i_v_rm,
    input wire [N-1:0]  i_v_rn,
    input wire [N-1:0]  i_v_mem_wb,
    input wire [N-1:0]  i_v_wb,
    output reg          o_s_mem_r_en,
    output reg          o_s_mem_w_en,
    output reg          o_s_wb_en,
    output reg [N-1:0]  o_alu_res,
    output reg [3:0]    o_alu_nzcv,
    output reg [N-1:0]  o_b_addr
);
    assign o_s_mem_r_en = i_s_mem_r_en;
    assign o_s_mem_w_en = i_s_mem_w_en;
    assign o_s_wb_en = i_s_wb_en;

    wire s_mem = i_s_mem_r_en | i_s_mem_w_en;
    wire [N-1:0] alu_left;
    wire [N-1:0] imm32;

    exp_to_32b_value e (
        .clk(clk),
        .i_v_rm(i_v_rm),
        .i_imm12(i_imm12),
        .i_s_imm(i_s_imm),
        .i_s_mem(s_mem),
        .o_res(imm32)
    );

    assign alu_left = i_v_rn;

    alu a (
        .i_ops(i_ops),
        .i_x(alu_left),
        .i_y(imm32),
        .i_f_c(i_f_c),
        .o_res(o_alu_res),
        .o_nzcv(o_alu_nzcv)
    );
    assign o_b_addr = i_pc + { {6{i_imm24[23]}}, i_imm24, 2'b0 };

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
        o_s_mem_w_en <= 1'b0;
        o_s_mem_r_en <= 1'b0;
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

module register_bank 
    #(parameter N = 32
    )(
    input wire         clk,
    input wire         i_reset_n,
    input wire [3:0]   i_r_s1,
    input wire [3:0]   i_r_s2,
    input wire [3:0]   i_wb_addr,
    input wire [N-1:0] i_wb_data,
    input wire         i_wb_en,
    output reg [N-1:0] o_vs1,
    output reg [N-1:0] o_vs2
);
    reg [N-1:0] regs [15:0];
    reg [N-1:0] cspr; 

    assign o_vs1 = regs[i_r_s1];
    assign o_vs2 = regs[i_r_s2];

    always @(negedge clk, posedge i_reset_n) begin
        if(!reset) begin
            for (integer i=0; i<N; i=i+1) regs[i] <= 32'b0;
        end

        else if(i_wb_en) begin
            regs[i_wb_addr] <= i_wb_data;
        end
         
        else begin
            for(i = 0; i < 15; i = i + 1) begin
                regs[i] <= regs[i];
            end
        end 
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

    // *** decode ***
    wire [3:0]      w_op;       // opcode specifying the instruction
    wire [3:0]      w_rn;       // 1st operand (reg address)
    wire [3:0]      w_rs;       // only used in mul and mla (reg address)
    wire [3:0]      w_rm;       // 2nd operand (reg address)
    wire [3:0]      w_rd;       // destination register
    wire            w_s_bit;    // s bit
    wire            w_s_br;     // branch bit (1 = branch)

    reg [3:0] nzcv = registers[16][3:0];
    wire [11:0] imm12;
    wire [23:0] imm24;
    reg [3:0] r_mem;
    reg s_imm;
    wire [3:0] alu_c;
    wire w_f_c;
    wire w_mem_r_en;
    wire w_mem_w_en;
    wire w_wb_en;
    wire s_w_en;

    input              clk,
    input wire         i_reset_n,
    input wire [N-1:0] i_ins,
    input wire [3:0]   i_nzcv,
    output reg [11:0]  o_imm12,
    output reg [23:0]  o_imm24,
    output reg [3:0]   o_alu_c,
    output reg [N-1:0] o_vs1, 
    output reg [N-1:0] o_vs2, 
    output reg [3:0]   o_s1, 
    output reg [3:0]   o_s2, 
    output reg [3:0]   o_wb_addr,
    output reg         o_br

    arm32_decoder dec (
        .clk(clk),
        .i_reset_n(reset_n),
        .i_ins(ins),
        .i_nzcv(nzcv),
        .o_imm12(imm12),
        .o_imm24(imm24),
        .o_rm(w_rm),
        .o_rn(w_rn),
        .o_rd(w_rd),
        .o_s_bit(w_s_bit),
        .o_br(w_s_br),
        .o_imm(s_imm),
        .o_f_c(w_f_c),
        .o_r_mem(r_mem),
        .o_alu_c(alu_c),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_wb_en(w_wb_en),
        .o_s_w_en(s_w_en)
    );

    reg s_mem_r_en;
    reg s_mem_w_en;
    reg s_wb_en;
    // reg [ARCH-1:0] v_rm;
    // reg [ARCH-1:0] v_rn;
    // reg [ARCH-1:0] alu_res;
    reg [ARCH-1:0] br_addr;
    reg [ARCH-1:0] v_mem_wb;
    reg [ARCH-1:0] v_wb;
    reg [3:0] alu_nzcv;

    execution_unit eu (
        .clk(clk), 
        .i_pc(pc),
        .i_s_mem_r_en(w_mem_r_en),
        .i_s_mem_w_en(w_mem_w_en),
        .i_s_wb_en(w_wb_en),
        .i_s_imm(s_imm),
        .i_f_c(w_f_c),
        .i_ops(alu_c),
        .i_imm12(imm12),
        .i_imm24(imm24),
        .i_v_rm(v_rm),
        .i_v_rn(v_rn),
        .i_v_mem_wb(v_mem_wb),
        .i_v_wb(v_wb),
        .o_s_mem_r_en(s_mem_r_en),
        .o_s_mem_w_en(s_mem_w_en),
        .o_s_wb_en(s_wb_en),
        .o_alu_res(alu_res),
        .o_alu_nzcv(alu_nzcv),
        .o_b_addr(br_addr)
    );

    wire [ARCH-1:0] w_addr_0 = { { alu_res[31:2], 2'b00 }}; 

    always @(posedge clk) begin
        step <= step << 1;
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<ARCH; i=i+1) registers[i] <= 32'b0;
            trap <= 1'b0;
            step <= 1'b1;
        end

        ins <= r.mem[pc];

        // *** memory access ***
        if (step[5] == 1'b1) begin
            if(s_mem_w_en == 1'b1) begin
                r.mem[w_addr_0] <= registers[r_mem];
            end
        end

        // *** write back ***
        if (step[6] == 1'b1) begin
            pc <= pc + 1;
            step <= 1'b1;
            // v_wb <= s_mem_r_en ? r_mem : alu_res;

            $display("ins: %h", ins, ", pc: %h", pc);
            $display("cond %b", ins[31:28], ", ops %b", ins[27:21], ", s %b", ins[20], ", rn %b", ins[19:16], ", rd %b", ins[15:12], ", imm12 %b", ins[11:0]);

            $display("r00: %h", registers[0], ",  r01: %h", registers[1], ",  r02: %h", registers[2], ",  r03: %h", registers[3], ",  r04: %h", registers[4]);
            $display("r05: %h", registers[5], ",  r06: %h", registers[6], ",  r07: %h", registers[7], ",  r08: %h", registers[8], ",  r09: %h", registers[9]);
            $display("r10: %h", registers[10], ",   fp: %h", registers[11], ",   ip: %h", registers[12], ",   sp: %h", registers[13], ",   lr: %h", registers[14]);
            $display(" pc: %h", registers[15], ", cpsr: %h", registers[16]);

            $display("\n");

            registers[16] <= {alu_nzcv, 28'b0};
            $display("alu_res: %b", alu_res); 
            registers[rd] <= s_wb_en ? v_wb : alu_res;

        end
    end
endmodule
