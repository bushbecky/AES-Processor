//
// Testbench for SubBytes & Inverse SubBytes stage of AES round
//

`include "./AESTestDefinitions.svpkg"

module SubBytesTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv;

// Module declaration
SubBytes Dut(in, out);
SubBytesInverse Dut2(inInv, outInv);

// Test exectuion and verfication task
test_t curTest;
bit [127:0] curOut, curOutInv;

initial
begin
  UnitTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "s_box");

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    inInv = curTest.encrypted;
    #1 repeat(1);
    curOut = out;
    curOutInv = outInv;
    tester.Compare(in, curOut, curTest, 0);
    tester.Compare(inInv, curOutInv, curTest, 1);
  end

  $finish();
end

endmodule
