//======================================================================
// Title:      Testbench for Parameterized PN Sequence Generator
//
// Description:
// This testbench instantiates and verifies the 'pn_generator' module
// for 3, 4, and 5 stages to confirm its functionality. It generates
// clock and reset signals and monitors the output of each instance.
//======================================================================

`timescale 1ns / 1ps

module pn_generator_tb;

    //------------- Signal Declarations -------------
    reg clk;
    reg rst;

    wire pn_out_3_stage;
    wire pn_out_4_stage;
    wire pn_out_5_stage;
    wire pn_out_7_stage;

    //------------- Clock Generation -------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock (10ns period)
    end

    //------------- Instantiate DUTs -------------

    // Instance for N=3. Sequence length should be 2^3 - 1 = 7
    pn_generator #(.N(3)) dut_3_stage (
        .clk(clk),
        .rst(rst),
        .pn_out(pn_out_3_stage)
    );

    // Instance for N=4. Sequence length should be 2^4 - 1 = 15
    pn_generator #(.N(4)) dut_4_stage (
        .clk(clk),
        .rst(rst),
        .pn_out(pn_out_4_stage)
    );

    // Instance for N=5. Sequence length should be 2^5 - 1 = 31
    pn_generator #(.N(5)) dut_5_stage (
        .clk(clk),
        .rst(rst),
        .pn_out(pn_out_5_stage)
    );

    // Instance for N=7. Sequence length should be 2^7 - 1 = 127
    pn_generator #(.N(7)) dut_7_stage (
        .clk(clk),
        .rst(rst),
        .pn_out(pn_out_7_stage)
    );

    //------------- Test Procedure -------------
    initial begin
        $display("Starting Testbench for PN Sequence Generator");
        $display("Time\t | N=3 Out | N=4 Out | N=5 Out | N=7 Out");
        $display("---------------------------------------");

        // Use $monitor to automatically print values when they change
        $monitor("%4t ns\t |    %b    |    %b    |    %b    |    %b    ", $time, pn_out_3_stage, pn_out_4_stage, pn_out_5_stage, pn_out_7_stage);

        // 1. Assert reset
        rst = 1;
        #20;

        // 2. De-assert reset and let the simulation run
        rst = 0;
        #700; // Run for enough cycles to see all sequences repeat

        // 3. End simulation
        $display("Simulation finished.");
        $finish;
    end

endmodule

