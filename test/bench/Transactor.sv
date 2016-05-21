//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESTestDefinitions::*;

module Transactor();

// Clock generation
logic clock;
//tbx clkgen
initial
begin
clock=0;
forever #10 clock=~clock;
end

// Reset generation
logic reset;
initial
begin
  reset = 1;
  #20 reset = 0;
end

// DUT Instantiation
key_t inputKey;
state_t plainData, encryptData, outputEncrypt, outputPlain;

AESEncoder encoder(clock, reset, plainData, inputKey, outputEncrypt);
AESDecoder decoder(clock, reset, encryptData, inputKey, outputPlain);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+KEY_BYTES),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(100)
                  ) inputpipe(clock);

// Output Pipe Instantiation
scemi_output_pipe #(.BYTES_PER_ELEMENT(AES_STATE_SIZE),
                    .PAYLOAD_MAX_ELEMENTS(2),
                    .BUFFER_MAX_ELEMENTS(100)
                  ) outputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
state_t [1:0] testOut;
bit eom = 0;
logic [7:0] ne_valid = 0;

always @(posedge clock)
begin
  if(reset)
  begin
    plainData <= '0;
    encryptData <= '0;
    inputKey <= '0;
  end
  else
  begin
    testOut = {outputEncrypt, outputPlain};
    outputpipe.send(2,testOut,eom);

    if(!eom)
    begin
      inputpipe.receive(1,ne_valid,testIn,eom);
      plainData <= testIn.plain;
      encryptData <= testIn.encrypt;
      inputKey <= testIn.key;
    end
  end
end

endmodule : Transactor
