// ARM32 CPU Implementation

module memory
    #(parameter DEPTH=4096,
      parameter N=32
    )(
    input wire         clk,
    input wire         i_mem_r_en,
    input wire         i_mem_w_en,
    input wire [N-1:0] i_mem_addr,
    input wire [N-1:0] i_mem_w_data,
    output reg [N-1:0] o_mem_r_data
);
    reg [N-1:0] mem [0:DEPTH-1];
    
    always @(posedge clk) begin
        if(i_mem_r_en == 1'b1)
            o_mem_r_data <= mem[i_mem_addr];
        else if(i_mem_w_en == 1'b1)
            mem[i_mem_addr] <= i_mem_w_data;
    end
endmodule

module control_unit
    #(parameter N = 32
    )(
    input wire       clk,
    input wire [3:0] i_ops,
    input wire [1:0] i_ins_t,
    input wire       i_ld_st,
    output reg[3:0]  o_s_c,
    output reg       o_s_wb_en,
    output reg       o_s_mem_r_en,
    output reg       o_s_mem_w_en,
    output reg       o_s_br
);
    always @(posedge clk, i_ops, i_ins_t, i_ld_st) begin
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
                case (i_ld_st)
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
            2'b11: begin
            end
        endcase
    end
endmodule

module cond (
    input wire       clk,
    input wire [3:0] i_cond,
    input wire [3:0] i_nzcv,
    output reg       o_res
);
    wire n;
    wire z;
    wire c;
    wire v;
    assign {n, z, c, v} = i_nzcv;

    always@(posedge clk, i_cond, i_nzcv) begin
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
                if(z == 1'b1 & n != v)
                    o_res = 1'b1;
            end
            4'b1111: begin
                o_res <= 1'b1;
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

    assign o_vs1 = regs[i_r_s1];
    assign o_vs2 = regs[i_r_s2];

    always @(negedge clk, posedge i_reset_n) begin
        if(!i_reset_n) begin
            for (integer i=0; i<N; i=i+1) regs[i] <= 32'b0;
        end

        else if(i_wb_en) begin
            regs[i_wb_addr] <= i_wb_data;
        end
         
        else begin
            for(integer i = 0; i < 15; i = i + 1) begin
                regs[i] <= regs[i];
            end
        end 
    end
endmodule

module arm32_decoder
    #(parameter N = 32
    )(
    input              clk,
    input wire         i_reset_n,
    input wire [N-1:0] i_ins,
    input wire [3:0]   i_nzcv,          // Condition flags (NZCV)
    output reg [11:0]  o_imm12,         // 12-bit immediate
    output reg [23:0]  o_imm24,         // 24-bit immediate
    output reg [3:0]   o_alu_c,         // ALU control                         (3)
    output reg [N-1:0] o_vs1,           // 1st operand (value)                 (3)  
    output reg [N-1:0] o_vs2,           // 2nd operand (value)                 (3)
    output reg [3:0]   o_s1,            // 1st operand (reg address) : Rn
    output reg [3:0]   o_s2,            // 2nd operand (reg address) : Rm
    output reg [3:0]   o_wb_addr,       // destination (wb) register : Rd      (5)
    output reg         o_ld_st,         // load/store bit
    output reg         o_br,            // branch taken 
    output reg         o_f_c,           // carry flag
    output reg         o_imm,           // immediate bit
    output reg         o_s_mem_r_en,    // memory read enable used mem access  (4)
    output reg         o_s_mem_w_en,    // memory write enable used mem access (4)
    output reg         o_s_wb_en        // write back enable used write back   (5) 
);
    wire [3:0]  w_rn    = i_ins[19:16]; // 1st operand (reg address)
    // wire [3:0]  w_rs    = i_ins[];      // only used in mul and mla (reg address)
    wire [3:0]  w_rm    = i_ins[3:0];   // 2nd operand (reg address)
    wire [3:0]  w_rd    = i_ins[15:12]; // destination register
    wire [3:0]  w_op    = i_ins[24:21]; // opcode specifying the instruction
    wire [1:0]  w_ins_t = i_ins[27:26]; // instruction type
    wire [3:0]  w_cond  = i_ins[31:28]; // condition bits
    wire        w_imm   = i_ins[25];    // immediate bit (1 = immediate) for expanding to imm32.
    wire        w_ld_st = i_ins[20];    // load/store bit (1 = load)
    wire        w_br;                   // branch bit (1 = branch)
    wire        w_cond_res;             // condition result
    wire        w_s_mux;                // mux select bit
    wire [9:0]  w_mux_in;           
    wire        w_wb_en;                // write back enable
    wire        w_mem_r_en;             // memory read enable 
    wire        w_mem_w_en;             // memory write enable
    wire [3:0]  w_alu_c;                // ALU control bits
    wire        w_r_s2;

    control_unit cu (
        .clk(clk),
        .i_ops(w_op),
        .i_ins_t(w_ins_t),
        .i_ld_st(w_ld_st),
        .o_s_c(w_alu_c),
        .o_s_wb_en(w_wb_en),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_s_br(w_br)
    );

    cond cc (
        .clk(clk),
        .i_cond(w_cond),
        .i_nzcv(i_nzcv),
        .o_res(w_cond_res)
    );

    assign o_imm12      = i_ins[11:0];
    assign o_imm24      = i_ins[23:0];
    assign o_wb_addr    = w_rd;
    assign o_s1         = w_rn;
    assign o_s2         = w_rm;
    assign o_f_c        = i_nzcv[2];
    assign w_s_mux      = w_cond_res; 
    // assign w_s_mux      = ~w_cond_res | 1'b0; 
    assign o_s_mem_r_en = w_s_mux ? 1'b0 : w_mem_r_en;
    assign o_s_mem_w_en = w_s_mux ? 1'b0 : w_mem_w_en;
    assign o_s_wb_en    = w_s_mux ? 1'b0 : w_wb_en;
    assign o_br         = w_s_mux ? 1'b0 : w_br;
    assign o_ld_st      = w_s_mux ? 1'b0 : w_ld_st;
    assign o_imm        = w_s_mux ? 1'b0 : w_imm;
    assign o_alu_c      = w_s_mux ? 4'b0 : w_alu_c;
    assign w_r_s2 = w_mem_w_en ? w_rd : w_rm;

    register_bank rb (
        .clk(clk),
        .i_reset_n(i_reset_n),
        .i_r_s1(w_rn),
        .i_r_s2(w_rm),
        .i_wb_addr(w_rd),
        .i_wb_data(32'b0),
        .i_wb_en(w_wb_en),
        .o_vs1(o_vs1),
        .o_vs2(o_vs2)
    );

endmodule

module decoder_stage
    #(parameter N = 32
    )(
    input              clk,
    input wire         i_reset_n,
    input wire         i_flush,         // flush the pipe (branch predict gone wrong)
    input wire         i_freeze,        // freeze pipeline (potential inefficiency)
    input wire         i_s_mem_r_en,
    input wire         i_s_mem_w_en,
    input wire         i_s_wb_en,
    input wire         i_imm,
    input wire         i_br,
    input wire [3:0]   i_alu_c,
    input wire [N-1:0] i_vs1,
    input wire [N-1:0] i_vs2,
    input wire [11:0]  i_imm12,
    input wire [23:0]  i_imm24,
    input wire [3:0]   i_wb_addr,
    input wire         i_ld_st,
    input wire         i_f_c,
    input wire [3:0]   i_s1,
    input wire [3:0]   i_s2,

    output reg [11:0]  o_imm12,
    output reg [23:0]  o_imm24,
    output reg [3:0]   o_alu_c,
    output reg [N-1:0] o_vs1, 
    output reg [N-1:0] o_vs2,
    output reg [3:0]   o_s1, 
    output reg [3:0]   o_s2,
    output reg [3:0]   o_wb_addr,
    output reg         o_ld_st,
    output reg         o_br,
    output reg         o_f_c,
    output reg         o_imm,
    output reg         o_s_mem_r_en,
    output reg         o_s_mem_w_en,
    output reg         o_s_wb_en
);
    always @(posedge clk, posedge i_reset_n) begin
        if (!i_reset_n || i_flush) begin
            o_imm12      <= 12'b0;
            o_imm24      <= 24'b0;
            o_alu_c      <= 4'b0;
            o_vs1        <= 32'b0;
            o_vs2        <= 32'b0;
            o_s1         <= 4'b0;
            o_s1         <= 4'b0;
            o_wb_addr    <= 4'b0; 
            o_ld_st      <= 1'b0;
            o_br         <= 1'b0;
            o_f_c        <= 1'b0;
            o_imm        <= 1'b0;
            o_s_mem_r_en <= 1'b0;
            o_s_mem_w_en <= 1'b0;
            o_s_wb_en    <= 1'b0;
        end else begin
            o_imm12      <= i_imm12;
            o_imm24      <= i_imm24;
            o_alu_c      <= i_alu_c;
            o_vs1        <= i_vs1;
            o_vs2        <= i_vs2;
            o_s1         <= i_s1;
            o_s1         <= i_s2;
            o_wb_addr    <= i_wb_addr; 
            o_ld_st      <= i_ld_st;
            o_br         <= i_br;
            o_f_c        <= i_f_c;
            o_imm        <= i_imm;
            o_s_mem_r_en <= i_s_mem_r_en;
            o_s_mem_w_en <= i_s_mem_w_en;
            o_s_wb_en    <= i_s_wb_en;
        end
    end
endmodule

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
    reg [N-1:0] r_imm32;
    reg [N-1:0] r_rotate_imm;

    wire [4:0] w_shift_imm  = i_imm12[11:7];
    wire [3:0] w_rotate_imm = i_imm12[11:8];
    wire [1:0] w_shift      = i_imm12[6:5];
    wire [7:0] w_imm8       = i_imm12[7:0];

    always @(posedge clk) begin
        r_imm32 <= {24'b0, w_imm8};

        for(integer k = 0; k < w_rotate_imm; k = k + 1) begin
            r_imm32 <= {r_imm32[1:0], r_imm32[31:2]};
        end 
        r_rotate_imm <= i_v_rm;

        for(integer k = 0; k <= w_shift_imm; k = k + 1) begin
            r_rotate_imm <= {r_rotate_imm[0], r_rotate_imm[31:0]};
        end
    end

    assign o_res = i_s_mem == 1'b1  ? { {20{i_imm12[11]}}, i_imm12} : 
        i_s_imm == 1'b1             ? r_imm32 : 
        w_shift == 2'b00            ? i_v_rm <<  {1'b0, w_shift_imm} :
        w_shift == 2'b01            ? i_v_rm >>  {1'b0, w_shift_imm} :
        w_shift == 2'b10            ? i_v_rm >>> {1'b0, w_shift_imm} :
        r_rotate_imm; 
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
    input wire [N-1:0]  i_v_rn,
    input wire [N-1:0]  i_v_rm,
    input wire [3:0]    i_wb_addr,
    output reg          o_s_mem_r_en,   // memory read enable used mem access  (4)
    output reg          o_s_mem_w_en,   // memory write enable used mem access (4)
    output reg          o_s_wb_en,      // write back enable used write back   (5) 
    output reg [N-1:0]  o_alu_res,      // alu result                          (4)
    output reg [N-1:0]  o_vs2,          // 
    output reg [3:0]    o_wb_addr,      // write back address                  (5)
    output reg [3:0]    o_alu_nzcv,     // conditio flags (NZCV)
    output reg [N-1:0]  o_b_addr        // branch address (pc)                 (5) 
);
    assign o_s_mem_r_en  = i_s_mem_r_en;
    assign o_s_mem_w_en  = i_s_mem_w_en;
    assign o_s_wb_en     = i_s_wb_en;

    wire         w_s_mem = i_s_mem_r_en | i_s_mem_w_en;
    wire [N-1:0] w_alu_left;
    wire [N-1:0] w_imm32;

    exp_to_32b_value e (
        .clk(clk),
        .i_v_rm(i_v_rm),
        .i_imm12(i_imm12),
        .i_s_imm(i_s_imm),
        .i_s_mem(w_s_mem),
        .o_res(w_imm32)
    );

    assign w_alu_left = i_v_rn;

    alu a (
        .i_ops(i_ops),
        .i_x(w_alu_left),
        .i_y(w_imm32),
        .i_f_c(i_f_c),
        .o_res(o_alu_res),
        .o_nzcv(o_alu_nzcv)
    );
    assign o_b_addr = i_pc + { {6{i_imm24[23]}}, i_imm24, 2'b0 };

endmodule

module memory_stage
    #(parameter N = 32
    )(
    input wire         clk, 
    input wire         i_reset_n,
    input wire         i_s_mem_r_en,
    input wire         i_s_mem_w_en,
    input wire         i_s_wb_en,
    input wire [N-1:0] i_alu_res,
    input wire [N-1:0] i_vs2,
    input wire [N-1:0] i_wb_addr,
    output reg         o_s_wb_en,
    output reg         o_s_mem_r_en,
    output reg         o_s_mem_w_en,
    output reg [N-1:0] o_alu_res,       // alu result
    output reg [N-1:0] o_wb_addr,       // write back address
    output reg [N-1:0] o_wb_data        // write back data from memory
    );

    assign o_s_wb_en    = i_s_wb_en;
    assign o_s_mem_r_en = i_s_mem_r_en;
    assign o_s_mem_w_en = i_s_mem_w_en;
    assign o_alu_res    = i_alu_res;
    assign o_wb_addr    = i_wb_addr;

    memory m  (
        .clk(clk),
        .i_mem_r_en(i_s_mem_r_en),
        .i_mem_w_en(i_s_mem_w_en),
        .i_mem_addr(i_alu_res),
        .i_mem_w_data(i_vs2),
        .o_mem_r_data(o_wb_data)
    );
endmodule

module forwarding_unit
    #(parameter N = 32
    )(
    input wire         clk,
    input wire         i_forw_en,
    input wire [3:0]   i_wb_addr,
    input wire [3:0]   i_mem_addr,
    input wire         i_s_wb_en,
    input wire         i_s_mem_en,
    input wire [3:0]   i_s1,
    input wire [3:0]   i_s2,
    output reg [1:0]   o_s1,
    output reg [1:0]   o_s2
);
    always @(posedge clk) begin
        o_s1 <= 2'b00;
        o_s2 <= 2'b00;

        if(i_forw_en == 1'b1) begin
            if(i_s_mem_en == 1'b1) begin
                if(i_mem_addr == i_s1) begin
                    o_s1 = 2'b10;
                end
                if(i_mem_addr == i_s2) begin
                    o_s2 = 2'b10; 
                end
            end

            if(i_s_wb_en == 1'b1) begin
                if(i_wb_addr == i_s1) begin
                    o_s1 = 2'b01;
                end
                if(i_wb_addr == i_s2) begin
                    o_s2 = 2'b01;
                end 
            end
        end
    end
endmodule

module processor
    #(parameter ARCH = 32,
      parameter RAM_SIZE = 1024 
    )(
    input wire clk, 
    input wire reset_n,
    output reg trap
);
    reg [ARCH-1:0] registers [0:16];
    reg [ARCH-1:0] ins;
    reg [ARCH-1:0] pc;
    reg [6:0] step;

    ram #(.DEPTH(RAM_SIZE)) r (
        .clk(clk)
    );

    wire [3:0] w_de_nzcv = 4'b0000; // todo

    // *** decode ***
    wire            w_de_reset_n;
    wire [3:0]      w_rn;           // 1st operand (reg address)
    wire [3:0]      w_rm;           // 2nd operand (reg address)
    wire [3:0]      w_rd;           // Destination register
    wire            w_br;           // Branch bit (1 = branch)
    wire            w_f_c;          // Carry flag
    wire            w_ld_st;        // Load/Store bit (1 = load)
    wire            w_imm;          // Immediate bit (1 = immediate) for expanding 12-bit immediate to 32-bit
    wire [11:0]     w_imm12;        // 12-bit immediate
    wire [23:0]     w_imm24;        // 24-bit immediate (for branch)
    wire [3:0]      w_alu_c;        // ALU control
    wire            w_mem_r_en;     // Memory read enable
    wire            w_mem_w_en;     // Memory write enable
    wire            w_wb_en;        // Write back enable
    wire [ARCH-1:0] w_v_rn;         // 1st operand (value)
    wire [ARCH-1:0] w_v_s2;         // 2st operand (value)
    wire [ARCH-1:0] w_v_rd;         // 2st operand (value)

    arm32_decoder dec (
        .clk(clk),
        .i_reset_n(w_de_reset_n),
        .i_ins(ins),
        .i_nzcv(w_de_nzcv),
        .o_imm12(w_imm12),
        .o_imm24(w_imm24),
        .o_alu_c(w_alu_c),
        .o_vs1(w_v_rn),
        .o_vs2(w_v_s2),
        .o_s1(w_rn),
        .o_s2(w_rm),
        .o_wb_addr(w_rd),
        .o_ld_st(w_ld_st),
        .o_br(w_br),
        .o_f_c(w_f_c),
        .o_imm(w_imm),
        .o_s_mem_r_en(w_mem_r_en),
        .o_s_mem_w_en(w_mem_w_en),
        .o_s_wb_en(w_wb_en)
    );

    // *** execute ***
    wire [3:0]      w_nzcv;
    wire [ARCH-1:0] w_v_rm;
    wire [ARCH-1:0] w_alu_res;      // ALU result (value)
    wire [ARCH-1:0] w_eu_vs2;       // 2nd operand (value) : Rm
    wire [ARCH-1:0] w_br_addr; 
    wire [3:0]      w_eu_wb_addr;   // Write back address (Destination)
    wire            w_eu_mem_r_en;  // Memory read enable
    wire            w_eu_mem_w_en;  // Memory write enable
    wire            w_eu_wb_en;     // Write back enable

    execution_unit eu (
        .clk(clk), 
        .i_pc(pc),
        .i_s_mem_r_en(w_mem_r_en),
        .i_s_mem_w_en(w_mem_w_en),
        .i_s_wb_en(w_wb_en),
        .i_s_imm(w_imm),
        .i_f_c(w_f_c),
        .i_ops(w_alu_c),
        .i_imm12(w_imm12),
        .i_imm24(w_imm24),
        .i_v_rn(w_v_rn),
        .i_v_rm(w_v_rm),
        .i_wb_addr(w_rd),
        .o_s_mem_r_en(w_eu_mem_r_en),
        .o_s_mem_w_en(w_eu_mem_w_en),
        .o_s_wb_en(w_eu_wb_en),
        .o_alu_res(w_alu_res),
        .o_vs2(w_eu_vs2),
        .o_wb_addr(w_eu_wb_addr),
        .o_alu_nzcv(w_nzcv),
        .o_b_addr(w_br_addr)
    );

    // *** memory access ***
    wire [ARCH-1:0] w_m_mem_res;    // ALU result  (value) : memory write 
    wire            w_m_mem_r_en;
    wire            w_m_mem_w_en;
    wire            w_m_wb_en;
    wire [ARCH-1:0] w_m_wb_addr;    // write back address
    wire [3:0]      w_m_wb_data;    // write back data (value) read from memory

    memory_stage m (
        .clk(clk), 
        .i_reset_n(w_de_reset_n),
        .i_s_mem_r_en(w_eu_mem_r_en),
        .i_s_mem_w_en(w_eu_mem_w_en),
        .i_s_wb_en(w_eu_wb_en),
        .i_alu_res(w_alu_res),
        .i_vs2(w_eu_vs2),
        .i_wb_addr(w_eu_wb_addr),
        .o_s_wb_en(w_m_wb_en),
        .o_s_mem_r_en(w_m_mem_r_en),
        .o_s_mem_w_en(w_m_mem_w_en),
        .o_alu_res(w_m_mem_res),
        .o_wb_addr(w_m_wb_addr),       
        .o_wb_data(w_m_wb_data)
    );

    always @(posedge clk) begin
        step <= step << 1;
        if (!reset_n) begin 
            pc <= 0;
            for (integer i=0; i<ARCH; i=i+1) registers[i] <= 32'b0;
            trap <= 1'b0;
            step <= 1'b1;
        end

        ins <= r.mem[pc];

        // // *** memory access ***
        // if (step[5] == 1'b1) begin
        //     if(s_mem_w_en == 1'b1) begin
        //         r.mem[w_addr_0] <= registers[r_mem];
        //     end
        // end

        // *** write back ***
        if (step[6] == 1'b1) begin
            pc <= pc + 1;
            step <= 1'b1;

            if (w_eu_wb_en == 1'b1) begin
                registers[w_rd] <= w_alu_res;
            end

            $display("wb_en: %b", w_m_wb_en, ", w_mem_r_en: %b", w_m_mem_r_en, ", w_mem_w_en: %b", w_m_mem_w_en);
            $display("alu control: %b", w_alu_c);
            $display("alu result: %b", w_alu_res);
            $display("w_rd: %b %d", w_rd, w_rd);

            $display("ins: %h", ins, ", pc: %h", pc);
            $display("cond %b", ins[31:28], ", ops %b", ins[27:21], ", s %b", ins[20], ", rn %b", ins[19:16], ", rd %b", ins[15:12], ", imm12 %b", ins[11:0]);

            $display("r00: %h", registers[0], ",  r01: %h", registers[1], ",  r02: %h", registers[2], ",  r03: %h", registers[3], ",  r04: %h", registers[4]);
            $display("r05: %h", registers[5], ",  r06: %h", registers[6], ",  r07: %h", registers[7], ",  r08: %h", registers[8], ",  r09: %h", registers[9]);
            $display("r10: %h", registers[10], ",   fp: %h", registers[11], ",   ip: %h", registers[12], ",   sp: %h", registers[13], ",   lr: %h", registers[14]);
            $display(" pc: %h", registers[15], ", cpsr: %h", registers[16]);

            $display("\n");
        end
    end
endmodule
