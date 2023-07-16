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

    arm_cpu cpu (
        .clk(clk),
        .reset_n(reset_n),
        .inst(inst),
        .pc(pc),
        .outM(outM),
        .writeM(writeM),
        .addressM(addressM)
    );

    initial 
    begin 
        $display("Testing ARM CPU");
        clk = 0; 
        reset_n = 0;
        $display($sformatf("Using %s as firmware", firmware));
        // $readmemh(firmware, mem);
        // $display("mem[0] = %b", mem[0]);
    end 

    // always #CLOCK_PERIOD_NS clk = ~clk;
endmodule
