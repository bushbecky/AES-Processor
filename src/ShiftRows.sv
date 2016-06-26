//
// ShiftRows Layer of the AES round
//

import AESDefinitions::*;

module ShiftRows(input state_t in, 
                 output state_t out);
/* ( 0  4  8 12)    ( 0  4  8 12)
 * ( 1  5  9 13) => ( 5  9 13  1)
 * ( 2  6 10 14)    (10 14  2  6)
 * ( 3  7 11 15)    (15  7 11 15) */
always_comb
  begin

    out = { in[0], in[5], in[10], in[15], in[4], in[9], in[14], in[3],
            in[8], in[13], in[2], in[7], in[12], in[1], in[6], in[11] };
    `ifdef DEBUG
      $display("%m");
      $display("In: %h", in);
      $display("Out: %h", out);
    `endif
  end
endmodule

module ShiftRowsInverse(input state_t in,
                        output state_t out);
/* ( 0  4  8 12)    ( 0  4  8 12)
 * ( 1  5  9 13) => (13  1  5  9)
 * ( 2  6 10 14)    (10 14  2  6)
 * ( 3  7 11 15)    ( 7 11 15  3) */
always_comb
  begin

    out = { in[0], in[13], in[10], in[7], in[4], in[1], in[14], in[11],
            in[8], in[5], in[2], in[15], in[12], in[9], in[6], in[3] };
    `ifdef DEBUG
      $display("%m");
      $display("In: %h", in);
      $display("Out: %h", out);
    `endif
  end
endmodule
