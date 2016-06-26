//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out,
                 output encodeValid);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeys;

// counter for valid signal
Counter validCounter(clock, reset, encodeValid);

// Key expansion block - outside the rounds
ExpandKey keyExpBlock(clock, reset, key, roundKeys);

// First round - add key only
AddRoundKey firstRound(in, roundKeys[0], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRound #(i) Round(clock, reset, roundOutput[i-1], roundKeys[i], roundOutput[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];

endmodule : AESEncoder


module AESDecoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out,
                 output decodeValid);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeys;

// counter for valid signal
Counter validCounter(clock, reset, decodeValid);

// Key expansion block - outside the rounds
ExpandKey keyExpBlock(clock, reset, key, roundKeys);

// First round - add key only
AddRoundKey firstRound(in, roundKeys[0], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRoundInverse #(i) Round(clock, reset, roundOutput[i-1], roundKeys[`NUM_ROUNDS-i], roundOutput[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];

endmodule : AESDecoder
