# DoD6 Negative-Verify Test: Missing expected output should trigger throw
#
# Purpose:
#   Verify that mkCheck throws when expected outputs are missing
#
# Test case:
#   expected = ["default" "dev" "missing-output"]
#   actual = ["default" "dev"]
#
# Design (validator-compliant):
#   - Nix-side: builtins.tryEval (dod6.mkCheck testCase)
#   - Shell-side: Fixed output (no if/for/while)
#   - Result determination: Nix switches script string based on evalResult.success
#
# Expected (RED):
#   FAIL (stub mkCheck does not throw → evalResult.success = true → script exits 1)
#
# Expected (GREEN):
#   PASS (mkCheck throws → evalResult.success = false → script echoes success)

{ pkgs, self, builders, dod6ExpectedOutputs }:
let
  dod6 = dod6ExpectedOutputs;
  
  # Invalid case: missing expected output
  testCase = {
    expected = [ "default" "dev" "missing-output" ];
    actual = [ "default" "dev" ];
    system = "x86_64-linux";
  };
  
  # Nix-side evaluation (no shell execution)
  evalResult = builtins.tryEval (dod6.mkCheck testCase);
  
  # Switch script based on evaluation result
  # - evalResult.success = true  → mkCheck did NOT throw (RED or bug)
  # - evalResult.success = false → mkCheck threw correctly (GREEN)
  script = if evalResult.success
    then ''
      set -euo pipefail
      echo "ERROR: mkCheck did not throw on missing output"
      echo "  Expected: throw when outputs are missing"
      echo "  Actual: mkCheck succeeded (stub behavior)"
      exit 1
    ''
    else ''
      set -euo pipefail
      echo "DoD6 negative-verify: throw detected correctly"
      echo "  mkCheck threw on missing output 'missing-output'"
    '';
in
builders.mkTestCheck {
  name = "test-dod6-negative-verify";
  inherit script;
}
