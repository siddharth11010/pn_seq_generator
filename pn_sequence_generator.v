//======================================================================
// Title:      Parameterized PN Sequence Generator (LFSR)
//
// Description:
// This module implements a configurable Pseudo-Noise (PN) sequence
// generator using a Linear Feedback Shift Register (LFSR). The number
// of stages (flip-flops) is determined by the 'N' parameter.
//
// The LFSR is seeded with a non-zero value
// on reset to avoid the lock-up state (all zeros).
//
// Configurable Taps:
// N=3: Taps at [3,1],
// N=4: Taps at [4,1], 
// N=5: Taps at [5,2],
// N=7: Taps at [7,0]

//======================================================================

module pn_generator #(
    parameter N = 3  // Number of stages in the LFSR
) (
    input wire clk,      // Clock signal
    input wire rst,      // Active-high reset
    output wire pn_out   // PN sequence output
);

    // Register to hold the state of the shift register.
    // Initialized to a non-zero seed value on reset.
    reg [N-1:0] lfsr_reg;

    wire feedback;

    // The output is taken from the last flip-flop.
    assign pn_out = lfsr_reg[N-1];

    // Combinational logic to determine the feedback based on the number of stages.
    assign feedback = 
        (N == 3) ? (lfsr_reg[2] ^ lfsr_reg[0]):
        (N == 4) ? (lfsr_reg[3] ^ lfsr_reg[0]):
        (N == 5) ? (lfsr_reg[4] ^ lfsr_reg[1]):
        (N == 7) ? (lfsr_reg[6] ^ lfsr_reg[0]):
                    (lfsr_reg[N-1] ^ lfsr_reg[0]); // Default taps

    // Sequential logic for the shift register.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, load the LFSR with a non-zero seed value.
//            if (N == 5) begin
//                lfsr_reg <= 5'b11111;
//            end 
             begin
            lfsr_reg <= {{(N-1){1'b0}}, 1'b1};
            end
        end else begin
            // On each clock edge, shift the register to the right
            // and load the feedback value into the first bit.
            lfsr_reg <= {lfsr_reg[N-2:0], feedback};
        end
    end

endmodule

