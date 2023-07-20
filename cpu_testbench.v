`define hdl_path_regf c.regs


module cpu_testbench #(parameter PERIOD = 10);
    parameter CLOCK_PERIOD_NS = 10;

	reg clk;
    reg reset_n;

    processor p (
        .clk(clk),
        .reset_n(reset_n)
    );

    initial begin 
        string firmware;
        clk = 0; 
        reset_n = 0;
        $display("Running ARM Processor Testbench.");
        if ($value$plusargs("firmware=%s", firmware)) begin
            $display($sformatf("  Reading from %s", firmware));
        end else begin
            $display($sformatf("  Expecting an argument %s", firmware), "ERROR");
            $finish;
        end
        $readmemh(firmware, p.r.mem);
    end 

    always #CLOCK_PERIOD_NS clk = ~clk;

    always @(posedge clk) begin
        reset_n <= 1;
    end

    initial begin
        #200
        $display("\nfinished.");
        $finish;
    end
endmodule
