# DoD6 Positive Test: All expected outputs present should pass
#
# Purpose:
#   Verify that mkCheck succeeds when all expected outputs are provided
#
# Test case:
#   expected = ["default" "dev"]
#   actual = ["default" "dev"]
#
# Expected (RED):
#   PASS (stub mkCheck does not throw)
#
# Expected (GREEN):
#   PASS (mkCheck validates and succeeds)

{ pkgs, self, builders, dod6ExpectedOutputs }:
let
  dod6 = dod6ExpectedOutputs;
  
  # Valid case: all expected outputs are present
  testCase = {
    expected = [ "default" "dev" ];
    actual = [ "default" "dev" ];
    system = "x86_64-linux";
  };
in
let
  # Pre-evaluate mkCheck to force dependency
  checkDrv = dod6.mkCheck testCase;
in
builders.mkTestCheck {
  name = "test-dod6-positive";
  script = ''
    set -euo pipefail
    
    # Force build dependency (derivation interpolation)
    test -f ${checkDrv}
    
    echo "DoD6 positive: all expected outputs present"
  '';
}
