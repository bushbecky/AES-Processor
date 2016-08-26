//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESDefinitions::*;

typedef enum byte { DIRECTED, SEEDED } TEST_TYPE;

module Transactor;

parameter KEY_BYTES_128 = 128 / 8;
parameter KEY_BYTES_192 = 192 / 8;
parameter KEY_BYTES_256 = 256 / 8;
typedef byte_t [0:KEY_BYTES_128-1] key128_t;
typedef byte_t [0:KEY_BYTES_192-1] key192_t;
typedef byte_t [0:KEY_BYTES_256-1] key256_t;
parameter NUM_ROUNDS_128 = 10;
parameter NUM_ROUNDS_192 = 12;
parameter NUM_ROUNDS_256 = 14;

// Clock generation
parameter CLOCK_WIDTH = 20;
parameter CLOCK_CYCLE = CLOCK_WIDTH/2;
parameter END_DELAY = (NUM_ROUNDS_256+10)*CLOCK_WIDTH;

typedef struct packed {
  TEST_TYPE testType;
  state_t plain;
  key256_t key;
  state_t encrypt128;
  state_t encrypt192;
  state_t encrypt256;
} inputTest_t;

/** Clock Generation **/
logic clock = 0;

//tbx clkgen inactive_negedge
initial
begin
clock=0;
forever #CLOCK_CYCLE clock=~clock;
end

/** Reset Generation **/
logic reset;
logic globalReset = 1;
logic localReset = 0;
logic phaseReset = 0;
logic testPhase = 0;
//tbx clkgen
initial
begin
  globalReset = 1;
  #CLOCK_WIDTH globalReset = 0;
end

assign reset = globalReset | localReset;

// Reset Buffers
logic bufferedReset_128[NUM_ROUNDS_128+1];
logic bufferedReset_192[NUM_ROUNDS_192+1];
logic bufferedReset_256[NUM_ROUNDS_256+1];

// Reset Buffer Generation Assignment
genvar j;
generate
  for(j = 1; j <= NUM_ROUNDS_128; j++)
  begin
    Buffer #(logic) ResetBuffer_128(clock, 1'b0, bufferedReset_128[j-1], bufferedReset_128[j]);
  end
endgenerate

genvar k;
generate
  for(k = 1; k <= NUM_ROUNDS_192; k++)
  begin
    Buffer #(logic) ResetBuffer_192(clock, 1'b0, bufferedReset_192[k-1], bufferedReset_192[k]);
  end
endgenerate

genvar m;
generate
  for(m = 1; m <= NUM_ROUNDS_256; m++)
  begin
    Buffer #(logic) ResetBuffer_256(clock, 1'b0, bufferedReset_256[m-1], bufferedReset_256[m]);
  end
endgenerate

// Decode Reset Generation
assign bufferedReset_128[0] = reset;
assign bufferedReset_192[0] = reset;
assign bufferedReset_256[0] = reset;
assign decodeReset_128 = (testPhase == 0) ? reset :
                         (bufferedReset_128[NUM_ROUNDS_128] | phaseReset);
assign decodeReset_192 = (testPhase == 0) ? reset :
                         (bufferedReset_192[NUM_ROUNDS_192] | phaseReset);
assign decodeReset_256 = (testPhase == 0) ? reset :
                         (bufferedReset_256[NUM_ROUNDS_256] | phaseReset);

/** Key Buffering and Assignment  **/
key128_t inputKey_128, encryptKey_128, bufferEncryptKey_128;
key192_t inputKey_192, encryptKey_192, bufferEncryptKey_192;
key256_t inputKey_256, encryptKey_256, bufferEncryptKey_256;

key128_t bufferedEncryptKeys_128[NUM_ROUNDS_128+1];
key192_t bufferedEncryptKeys_192[NUM_ROUNDS_192+1];
key256_t bufferedEncryptKeys_256[NUM_ROUNDS_256+1];

assign bufferedEncryptKeys_128[0] = inputKey_128;
assign bufferedEncryptKeys_192[0] = inputKey_192;
assign bufferedEncryptKeys_256[0] = inputKey_256;

assign bufferEncryptKey_128 = bufferedEncryptKeys_128[NUM_ROUNDS_128];
assign bufferEncryptKey_192 = bufferedEncryptKeys_192[NUM_ROUNDS_192];
assign bufferEncryptKey_256 = bufferedEncryptKeys_256[NUM_ROUNDS_256];

assign encryptKey_128 = (testPhase == 0) ? inputKey_128 : bufferEncryptKey_128;
assign encryptKey_192 = (testPhase == 0) ? inputKey_192 : bufferEncryptKey_192;
assign encryptKey_256 = (testPhase == 0) ? inputKey_256 : bufferEncryptKey_256;

genvar n;
generate
  for(n = 1; n <= NUM_ROUNDS_128; n++)
  begin
    Buffer #(key128_t) KeyBuffer(clock, reset, bufferedEncryptKeys_128[n-1], bufferedEncryptKeys_128[n]);
  end
endgenerate

genvar p;
generate
  for(p = 1; p <= NUM_ROUNDS_192; p++)
  begin
    Buffer #(key192_t) KeyBuffer(clock, reset, bufferedEncryptKeys_192[p-1], bufferedEncryptKeys_192[p]);
  end
endgenerate

genvar q;
generate
  for(q = 1; q <= NUM_ROUNDS_256; q++)
  begin
    Buffer #(key256_t) KeyBuffer(clock, reset, bufferedEncryptKeys_256[q-1], bufferedEncryptKeys_256[q]);
  end
endgenerate

/** DUT Instantiation **/
state_t plainData, encryptData_128, inputEncryptData_128, outputEncrypt_128, outputPlain_128,
                   encryptData_192, inputEncryptData_192, outputEncrypt_192, outputPlain_192,
                   encryptData_256, inputEncryptData_256, outputEncrypt_256, outputPlain_256;

logic encodeValid_128, decodeValid_128,
      encodeValid_192, decodeValid_192,
      encodeValid_256, decodeValid_256;

assign inputEncryptData_128 = (testPhase == 0) ? encryptData_128 : outputEncrypt_128;
assign inputEncryptData_192 = (testPhase == 0) ? encryptData_192 : outputEncrypt_192;
assign inputEncryptData_256 = (testPhase == 0) ? encryptData_256 : outputEncrypt_256;

AESEncoder #(128) encoder_128(clock, reset, plainData, inputKey_128, outputEncrypt_128, 
                              encodeValid_128);
AESDecoder #(128) decoder_128(clock, decodeReset_128, inputEncryptData_128, encryptKey_128, 
                              outputPlain_128, decodeValid_128);
AESEncoder #(192) encoder_192(clock, reset, plainData, inputKey_192, outputEncrypt_192,
                              encodeValid_192);
AESDecoder #(192) decoder_192(clock, decodeReset_192, inputEncryptData_192, encryptKey_192,
                              outputPlain_192, decodeValid_192);
AESEncoder #(256) encoder_256(clock, reset, plainData, inputKey_256, outputEncrypt_256,
                              encodeValid_256);
AESDecoder #(256) decoder_256(clock, decodeReset_256, inputEncryptData_256, encryptKey_256,
                              outputPlain_256, decodeValid_256);

/** Assertions to Check Output **/
// KEY SIZE = 128
property encodeCheck_128;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (encodeValid_128 & (outputEncrypt_128 == $past(encryptData_128, NUM_ROUNDS_128))) | !encodeValid_128;
endproperty

encode_128: assert property(encodeCheck_128);

property decodeCheck_128;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (decodeValid_128 & (outputPlain_128 == $past(plainData, NUM_ROUNDS_128))) | !decodeValid_128;
endproperty

decode_128: assert property(decodeCheck_128);

property encodeDecodeCheck_128;
  @(posedge clock)
  disable iff(reset || testPhase != 1 || phaseReset)
  (decodeValid_128 & (outputPlain_128 == $past(plainData, 2*NUM_ROUNDS_128))) | !decodeValid_128;
endproperty

decodeEncode_128: assert property(encodeDecodeCheck_128);

// KEY SIZE = 192
property encodeCheck_192;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (encodeValid_192 & (outputEncrypt_192 == $past(encryptData_192, NUM_ROUNDS_192))) | !encodeValid_192;
endproperty

encode_192: assert property(encodeCheck_192);

property decodeCheck_192;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (decodeValid_192 & (outputPlain_192 == $past(plainData, NUM_ROUNDS_192))) | !decodeValid_192;
endproperty

decode_192: assert property(decodeCheck_192);

property encodeDecodeCheck_192;
  @(posedge clock)
  disable iff(reset || testPhase != 1 || phaseReset)
  (decodeValid_192 & (outputPlain_192 == $past(plainData, 2*NUM_ROUNDS_192))) | !decodeValid_192;
endproperty

decodeEncode_192: assert property(encodeDecodeCheck_192);

// KEY SIZE = 256
property encodeCheck_256;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (encodeValid_256 & (outputEncrypt_256 == $past(encryptData_256, NUM_ROUNDS_256))) | !encodeValid_256;
endproperty

encode_256: assert property(encodeCheck_256);

property decodeCheck_256;
  @(posedge clock)
  disable iff(reset || (testPhase != 0))
  (decodeValid_256 & (outputPlain_256 == $past(plainData, NUM_ROUNDS_256))) | !decodeValid_256;
endproperty

decode_256: assert property(decodeCheck_256);

property encodeDecodeCheck_256;
  @(posedge clock)
  disable iff(reset || testPhase != 1 || phaseReset)
  (decodeValid_256 & (outputPlain_256 == $past(plainData, 2*NUM_ROUNDS_256))) | !decodeValid_256;
endproperty

decodeEncode_256: assert property(encodeDecodeCheck_256);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(4*AES_STATE_SIZE+KEY_BYTES_256+1),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(50)
                  ) inputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
state_t tempData;
key256_t tempKey;
bit eom = 0;
int i = 0;
logic [7:0] ne_valid = 0;
logic switchedPhase = 0;

always @(posedge clock)
begin
  if(reset)
  begin
    plainData <= '0;
    encryptData_128 <= '0;
    encryptData_192 <= '0;
    encryptData_256 <= '0;
    inputKey_128 <= '0;
    inputKey_192 <= '0;
    inputKey_256 <= '0;
  end
  else
  begin
    if(!eom)
    begin
      inputpipe.receive(1,ne_valid,testIn,eom);
      //TODO: Invert data and keys to generate more test cases.
      if(!eom)
      begin
        testIn = {<<byte{testIn}};
        if((testIn.testType == SEEDED) && (switchedPhase == 0))
        begin
          testPhase = 1;
          switchedPhase = 1;
          phaseReset = 1;
          repeat(2) @(posedge clock);
          phaseReset = 0;
        end
        if(testIn.testType == DIRECTED)
        begin
          testPhase = 0;
          plainData <= testIn.plain;
          encryptData_128 <= testIn.encrypt128;
          encryptData_192 <= testIn.encrypt192;
          encryptData_256 <= testIn.encrypt256;
          inputKey_128 <= testIn.key[0:KEY_BYTES_128-1];
          inputKey_192 <= testIn.key[0:KEY_BYTES_192-1];
          inputKey_256 <= testIn.key;
        end
        else if(testIn.testType == SEEDED)
        begin
          tempData = testIn.plain;
          tempKey = testIn.key;
          for(i=0; i<128; i=i+1)
          begin
            plainData <= tempData ^ (1<<i);
            inputKey_128 <= tempKey[0:KEY_BYTES_128-1];
            inputKey_192 <= tempKey[0:KEY_BYTES_192-1];
            inputKey_256 <= tempKey;
            repeat(1) @(posedge clock);
          end
          for(i=0; i<128; i=i+1)
          begin
            plainData <= tempData ^ (1<<i);
            inputKey_128 <= ~tempKey[0:KEY_BYTES_128-1];
            inputKey_192 <= ~tempKey[0:KEY_BYTES_192-1];
            inputKey_256 <= ~tempKey;
            repeat(1) @(posedge clock);
          end
          plainData <= tempData;
          inputKey_128 <= tempKey[0:KEY_BYTES_128-1];
          inputKey_192 <= tempKey[0:KEY_BYTES_192-1];
          inputKey_256 <= tempKey;
        end
      end
    end
    else
    begin
      localReset = 1;
      #END_DELAY $finish();
    end
  end
end

endmodule : Transactor
