//
// Round module with buffering of the output
//

`include "AESDefinitions.svpkg"

module BufferedRound(input logic clock, reset,
                     input state_t in, roundKey_t key,
                     output state_t out);
parameter RoundNum = 1;
localparam finalRound = ((RoundNum == `NUM_ROUNDS) ? 1 : 0);

// State wire for intermediate value
state_t temp;

Round #(RoundNum) round(in, key, temp);
Buffer #(state_t) buffer(clock, reset, temp, out);

endmodule : BufferedRound
