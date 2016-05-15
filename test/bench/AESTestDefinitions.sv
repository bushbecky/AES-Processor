`ifndef AES_TEST_DEFINITIONS
  `define AES_TEST_DEFINITIONS

  package AESTestDefinitions;

  import AESDefinitions::*;

  // Test storage structure
  typedef struct {
    state_t plain;
    state_t encrypted;
  } test_t;  

  typedef struct {
    state_t plain;
    state_t encrypted;
    roundKey_t roundKey;
  } keyTest_t;

  //***************************************************************************************//
  class UnitTester;
    test_t qTests[$];

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted);
      test_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function test_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(bit [127:0] in, bit [127:0] out, test_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        $display("AES_SIM_ERROR");
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $finish();
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      bit [127:0] parse1, parse2;
      string parseString, tempString;
      int i, file;
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse2);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare(phaseString) == 0)
          AddTestCase(.plain(parse1), .encrypted(parse2));
        else
          parse1 = parse2;
      end 
    endfunction : ParseFileForTestCases

  endclass : UnitTester

  //***************************************************************************************//
  class UnitKeyTester;
    keyTest_t qTests[$];

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted, [127:0] roundKey);
      keyTest_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      $cast(newTest.roundKey, roundKey);
      qTests.push_back(newTest);
      `ifdef DEBUG_TEST
        $display("UnitKeyTester.AddTestCase");
        $display("Plain: %h", plain);
        $display("Encrypted: %h", encrypted);
        $display("Round Key: %h", roundKey);
      `endif
    endfunction : AddTestCase

    function keyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(bit [127:0] in, bit [127:0] out, keyTest_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        $display("AES_SIM_ERROR");
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Key:      %h", curTest.roundKey);
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $finish();
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      bit [127:0] parse1, parse2, parse3;
      string parseString, tempString;
      int i, file;
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse2);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare(phaseString) == 0)
        begin
          i = $fscanf(file, "%s %h\n", parseString, parse3);
          AddTestCase(.plain(parse1), .roundKey(parse2), .encrypted(parse3));
        end
        else
          parse1 = parse2;
      end 
    endfunction : ParseFileForTestCases

  endclass : UnitKeyTester

  //***************************************************************************************//
  class RoundTester;
    keyTest_t qTests[$];

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted, [127:0] roundKey);
      keyTest_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      $cast(newTest.roundKey, roundKey);
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function keyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(bit [127:0] in, bit [127:0] out, keyTest_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        PrintError((encryptedIn ? curTest.encrypted : curTest.plain), curTest.roundKey, out, (encryptedIn ? curTest.plain : curTest.encrypted), encryptedIn);
        $finish();
      end
    endfunction : Compare

    function void PrintError(bit [127:0] in, key, out, expected, bit inverse);
      $display("AES_SIM_ERROR");
      $display("*** Error: Current output doesn't match expected");
      if(inverse)
        $display("***        Inverse Phase");
      else
        $display("***        Normal Phase");

      $display("***        Input:    %h", in);
      $display("***        Key:      %h", key);
      $display("***        Output:   %h", out);
      $display("***        Expected: %h", expected);
    endfunction : PrintError

    function void ParseFileForTestCases(string testFile);
      bit [127:0] parse1, plain, encrypt, key;
      string parseString, tempString;
      int i, file;
      bit [127:0] inputs[$];
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse1);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare("start") == 0 || tempString.icompare("k_sch") == 0 || tempString.icompare("utput") == 0)
        begin
          inputs.push_back(parse1);
          if(tempString.icompare("utput") == 0)
          begin
            // Drop the last round
            void'(inputs.pop_back());
            void'(inputs.pop_back());
            while(inputs.size() > 2)
            begin
              encrypt = inputs.pop_back();
              key = inputs.pop_back();
              plain = inputs.pop_back();
              AddTestCase(.plain(plain), .roundKey(key), .encrypted(encrypt));
              inputs.push_back(plain);
            end
            inputs = {};
          end
        end
      end
    endfunction : ParseFileForTestCases

  endclass : RoundTester

  endpackage : AESTestDefinitions

`endif
