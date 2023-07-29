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
    parameter ADDRW=32,
  )(
  input                  clk,
  input [13:0]           i_addr,
  input [13:0]           d_addr,
  input [ADDRW-1:0]      dw_data,
  input [1:0]            dw_size,
  output reg [ADDRW-1:0] i_data,
  output reg [ADDRW-1:0] d_data
);

  reg [31:0] mem [0:4095];

  always @(posedge clk) begin
    i_data <= mem[i_addr[13:2]];
  end
endmodule
