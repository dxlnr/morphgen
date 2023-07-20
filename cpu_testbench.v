`define hdl_path_regf c.regs


module cpu_testbench #(parameter PERIOD = 10);
    parameter CLOCK_PERIOD_NS = 10;

	reg clk;
    reg reset_n;
    reg [7:0] pcount;
    reg [31:0] inst;

    wire [31:0] pc;
    wire [31:0] outM;
    wire [31:0] writeM;
    wire [31:0] addressM;

    processor p (
        .clk(clk),
        .reset_n(reset_n),
        .inst(inst),
        .pc(pc),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM)
    );

    initial begin 
        string firmware;
        clk = 0; 
        reset_n = 0;
        pcount = 0;
        if ($value$plusargs("firmware=%s", firmware)) begin
            $display($sformatf("Reading from %s", firmware));
        end else begin
            $display($sformatf("Expecting an argument %s", firmware), "ERROR");
            $finish;
        end
        $readmemh(firmware, p.r.mem);

        $display("ARM Processor Testbench.");

        for (int i = 0; i < $size(firmware) - 1; i = i + 1) begin
            $display("inst = %x", p.r.mem[i]);
        end
    end 

    always #CLOCK_PERIOD_NS clk = ~clk;

    always @(posedge clk) begin
        pcount <= pcount + 1;
    end

    initial begin
        #200
        $display("finished.");
        $finish;
    end
endmodule
