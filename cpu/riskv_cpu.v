module alu (
  input clk,
  input [2:0] funct3,
  input [31:0] x,
  input [31:0] y,
  input alt,
  output reg [31:0] out
);
  always @(posedge clk) begin
    case (funct3) 
      3'b000: begin  // ADDI
        out <= alt ? (x - y) : (x + y);
      end
      3'b001: begin  // SLL
        out <= x << y[4:0];
      end
      3'b010: begin  // SLT
        out <= {31'b0, $signed(x) < $signed(y)};
      end
      3'b011: begin  // SLTU
        out <= {31'b0, x < y};
      end
      3'b100: begin  // XOR
        out <= x ^ y;
      end
      3'b101: begin  // SRL
        out <= alt ? (x >>> y[4:0]) : (x >> y[4:0]);
      end
      3'b110: begin  // OR
        out <= x | y;
      end
      3'b111: begin  // AND
        out <= x & y;
      end
    endcase
  end
endmodule

module cond (
  input clk, 
  input [2:0] funct3,
  input [31:0] x,
  input [31:0] y,
  output reg out
);
  always @(posedge clk) begin
    case (funct3) 
      3'b000: begin  // BEQ
        out <= x == y;
      end
      3'b001: begin  // BNE
        out <= x != y;
      end
      3'b100: begin  // BLT
        out <= $signed(x) < $signed(y);
      end
      3'b101: begin  // BGE
        out <= $signed(x) >= $signed(y);
      end
      3'b110: begin  // BLTU
        out <= x < y;
      end
      3'b111: begin  // BGEU
        out <= x >= y;
      end
    endcase
  end
endmodule

module ram 
  #(parameter DEPTH=4096,
    parameter ADDRW=32
  )(
  input                  clk,
  input [13:0]           i_addr,
  input [13:0]           d_addr,
  input [ADDRW-1:0]      dw_data,
  input [1:0]            dw_size,
  output reg [ADDRW-1:0] i_data,
  output reg [ADDRW-1:0] d_data
);

  reg [ADDRW-1:0] mem [0:DEPTH-1];
  wire [ADDRW-1:0] dt_data = mem[d_addr[13:2]];

  always @(posedge clk) begin
    // always aligned for instruction fetch
    i_data <= mem[i_addr[13:2]];
    // misaligned data, but it's filled with 0s
    // support some unaligned loads, but can't break word boundary
    d_data <=
      d_addr[1] ? (d_addr[0] ? (dt_data >> 24) : (dt_data >> 16))
                : (d_addr[0] ? (dt_data >> 8) : dt_data);
    // 2'b01 = 8-bit
    // 2'b10 = 16-bit
    // 2'b11 = 32-bit
    // again, can't break word boundary
    case (dw_size)
      2'b11: mem[d_addr[13:2]] <= dw_data;
      2'b10: mem[d_addr[13:2]] <= 
        d_addr[1] ? {dw_data[15:0], dt_data[15:0]} : 
                    {dt_data[31:16], dw_data[15:0]};
      2'b01: mem[d_addr[13:2]] <= 
        d_addr[1] ?
          (d_addr[0] ? {dw_data[7:0], dt_data[23:0]} : {dt_data[31:24], dw_data[7:0], dt_data[15:0]}) :
          (d_addr[0] ? {dt_data[31:16], dw_data[7:0], dt_data[7:0]} : {dt_data[31:8], dw_data[7:0]});
    endcase
  end
endmodule

module riscv
  #(parameter A=32
  )(
  input wire        clk, 
  input wire        resetn,
  output reg        trap,
  output reg [31:0] pc
);

  // *** Memory ***
  reg [13:0] i_addr;
  wire [31:0] i_data;
  reg [13:0] d_addr;
  wire [31:0] d_data;
  reg [31:0] dw_data;
  reg [1:0] dw_size;

  ram r (
    .clk (clk),
    .i_data (i_data),
    .i_addr (i_addr),
    .d_data (d_data),
    .d_addr (d_addr),
    .dw_data (dw_data),
    .dw_size (dw_size)
  );

  reg [31:0] regs [0:31];
  reg [4:0] rd;

  reg [31:0] vs1;
  reg [31:0] vs2;
  reg [31:0] vpc;

  // Instruction decode and register fetch
  wire [6:0] opcode = i_data[6:0];
  wire [2:0] funct3 = i_data[14:12];
  wire [6:0] funct7 = i_data[31:25];
  wire [4:0] rs1 = i_data[19:15];
  wire [4:0] rs2 = i_data[24:20];
  wire [31:0] imm_i = {{20{i_data[31]}}, i_data[31:20]};
  wire [31:0] imm_s = {{20{i_data[31]}}, i_data[31:25], i_data[11:7]};
  wire [31:0] imm_b = {{19{i_data[31]}}, i_data[31], i_data[7], i_data[30:25], i_data[11:8], 1'b0};
  wire [31:0] imm_u = {i_data[31:12], 12'b0};
  wire [31:0] imm_j = {{11{i_data[31]}}, i_data[31], i_data[19:12], i_data[20], i_data[30:21], 1'b0};

  reg [31:0] alu_left;
  reg [31:0] alu_imm;
  reg [2:0] alu_func;
  reg alu_alt;

  wire [31:0] pend;
  reg [2:0] funct3_saved;
  wire cond_out;
  reg [1:0] update_pc; 
  reg reg_writeback;

  wire pend_is_new_pc = update_pc[0] || (update_pc[1] && cond_out);
  reg do_load;
  reg do_store;

  reg [6:0] step;

  alu a (
    .clk (clk),
    .funct3 (alu_func),
    .x (alu_left),
    .y (alu_imm),
    .alt (alu_alt),
    .out (pend)
  );

  cond c (
    .clk (clk),
    .funct3 (funct3_saved),
    .x (vs1),
    .y (vs2),
    .out (cond_out)
  );

  always @(posedge clk) begin
    step <= step << 1;
    if (resetn) begin
      pc <= 32'h80000000;
      for (integer i=0; i<32; i=i+1) regs[i] <= 0;
      step <= 'b1;
      trap <= 1'b0;
    end

    // *** Instruction Fetch ***
    i_addr <= pc[13:0];

    // *** Instruction decode and register fetch ***
    vs1 <= regs[rs1];
    vs2 <= regs[rs2];
    vpc <= pc;
    rd <= i_data[11:7];
    funct3_saved <= funct3;

    alu_func <= 3'b000;
    alu_left <= vs1;
    alu_alt <= 1'b0;
    update_pc <= 2'b00;
    reg_writeback <= 1'b0;
    do_load <= 1'b0;
    do_store <= 1'b0;

    case (opcode)
      7'b0110111: begin // LUI
        alu_imm <= imm_u;
        alu_left <= 32'b0;
        reg_writeback <= 1'b1;
      end
      7'b0000011: begin // LOAD
        alu_imm <= imm_i;
        reg_writeback <= 1'b1;
        do_load <= 1'b1;
      end
      7'b0100011: begin // STORE
        alu_imm <= imm_s;
        do_store <= 1'b1;
      end
      7'b0010111: begin // AUIPC
        alu_imm <= imm_u;
        alu_left <= pc;
        reg_writeback <= 1'b1;
      end
      7'b1100011: begin // BRANCH
        alu_imm <= imm_b;
        alu_left <= pc;
        update_pc <= 2'b10;
      end
      7'b1101111: begin // JAL
        alu_imm <= imm_j;
        alu_left <= pc;
        update_pc <= 2'b01;
        reg_writeback <= 1'b1;
      end
      7'b1100111: begin // JALR
        alu_imm <= imm_i;
        update_pc <= 2'b01;
        reg_writeback <= 1'b1;
      end
      7'b0010011: begin // IMM
        alu_imm <= imm_i;
        alu_func <= funct3;
        alu_alt <= (funct7 == 7'b0100000 && funct3 == 3'b101);
        reg_writeback <= 1'b1;
      end
      7'b0110011: begin // OP
        alu_imm <= regs[rs2];
        alu_func <= funct3;
        alu_alt <= (funct7 == 7'b0100000);
        reg_writeback <= 1'b1;
      end
      7'b1110011: begin // SYSTEM
        trap <= regs[3] > 0;
      end
    endcase

    // *** Memory access ***
    if (step[5] == 1'b1) begin
      d_addr <= pend[13:0];
      if (do_store) begin
        dw_data <= vs2;
        dw_size <= (funct3_saved[1:0] + 1);
      end
    end
    
    // *** Register Writeback ***
    if (step[6] == 1'b1) begin
      pc <= pend_is_new_pc ? pend : (vpc + 4);
      if (reg_writeback && rd != 5'b00000) begin
        if (do_load) begin
          case (funct3_saved)
            3'b000: regs[rd] <= {{24{d_data[7]}}, d_data[7:0]};
            3'b001: regs[rd] <= {{16{d_data[15]}}, d_data[15:0]};
            3'b010: regs[rd] <= d_data;
            3'b100: regs[rd] <= {24'b0, d_data[7:0]};
            3'b101: regs[rd] <= {16'b0, d_data[15:0]};
          endcase
        end else begin
          regs[rd] <= (pend_is_new_pc ? (vpc + 4) : pend);
        end
      end
      step <= 'b1;
      dw_size <= 2'b00;
    end
  end

endmodule
