`define hdl_path_regf c.regs


module cpu_testbench #(parameter PERIOD = 10);
    parameter CLOCK_PERIOD_NS = 10;

    reg [31:0] mem [0:1024];

	reg clk;
    reg reset_n;
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
        if ($value$plusargs("firmware=%s", firmware)) begin
            $display($sformatf("Using %s as firmware", firmware));
        end else begin
            $display($sformatf("Expecting a command line argument %s", firmware), "ERROR");
            $finish;
        end
        $readmemh(firmware, p.r.mem);

        $display("ARM Processor Testbench.");
    end 

    // always #CLOCK_PERIOD_NS clk = ~clk;
endmodule
