//
// Testbench for ShiftRows & Inverse ShiftRows stage of AES round
//

include ../../src/AESDefinitions.svpkg;
include ./AESTestDefinitions.svpkg;

module ShiftRowsTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv;

// Module declaration
ShiftRows Dut(in, out);
ShiftRowsInverse Dut2(inInv, outInv);

UnitTester tester;
initial
begin
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt");

  // Test execution and verification task
  test_t curTest;
  bit [127:0] curOut, curOutInv;

  while(qTests.size() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    inInv = curTest.encrypted;
    #1 repeat(1);
    curOut = out;
    curOutInv = outInv;
    Compare(in, curOut, curTest, 0);
    Compare(inInv, curOutInv, curTest, 1);
  end
end

endmodule
