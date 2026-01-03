# DoD5 Positive Test: Allowlist-compliant flake.lock should pass
#
# Purpose:
#   Verify that mkCheck succeeds when flake.lock contains only allowed inputs
#
# Test case:
#   flake.lock with inputs: { nixpkgs, spec } (both in allowlist)
#
# Expected (RED):
#   PASS (stub mkCheck does not throw)
#
# Expected (GREEN):
#   PASS (mkCheck validates and succeeds)

{ pkgs, self, builders, dod5FeatInputs }:
let
  dod5 = dod5FeatInputs;
  
  # Valid flake.lock (allowlist-compliant)
  validLock = pkgs.writeText "flake.lock" (builtins.toJSON {
    nodes = {
      root = {
        inputs = {
          nixpkgs = "nixpkgs";
          spec = "spec";
        };
      };
      nixpkgs = {
        locked = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
        };
      };
      spec = {
        locked = {
          type = "github";
          owner = "example";
          repo = "spec-repo";
        };
      };
    };
  });
in
let
  # Pre-evaluate mkCheck to force dependency
  checkDrv = dod5.mkCheck validLock;
in
builders.mkTestCheck {
  name = "test-dod5-positive";
  script = ''
    set -euo pipefail
    
    # Force build dependency (derivation interpolation)
    # This ensures mkCheck is actually built and evaluated
    test -f ${checkDrv}
    
    echo "DoD5 positive: allowlist-compliant lock passed"
  '';
}
