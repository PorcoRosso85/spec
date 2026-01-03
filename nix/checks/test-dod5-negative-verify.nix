# DoD5 Negative-Verify Test: Forbidden input should trigger throw
#
# Purpose:
#   Verify that mkCheck throws when flake.lock contains forbidden inputs
#
# Test case:
#   flake.lock with inputs: { nixpkgs, spec, forbidden-input }
#
# Design (validator-compliant):
#   - Nix-side: builtins.tryEval (dod5.mkCheck lockPath)
#   - Shell-side: Fixed output (no if/for/while)
#   - Result determination: Nix switches script string based on evalResult.success
#
# Expected (RED):
#   FAIL (stub mkCheck does not throw → evalResult.success = true → script exits 1)
#
# Expected (GREEN):
#   PASS (mkCheck throws → evalResult.success = false → script echoes success)

{ pkgs, self, builders, dod5FeatInputs }:
let
  dod5 = dod5FeatInputs;
  
  # Invalid flake.lock (contains forbidden input)
  invalidLock = pkgs.writeText "flake.lock" (builtins.toJSON {
    nodes = {
      root = {
        inputs = {
          nixpkgs = "nixpkgs";
          spec = "spec";
          forbidden-input = "forbidden";  # ❌ Not in allowlist
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
      forbidden = {
        locked = {
          type = "github";
          owner = "example";
          repo = "forbidden-repo";
        };
      };
    };
  });
  
  # Nix-side evaluation (no shell execution)
  evalResult = builtins.tryEval (dod5.mkCheck invalidLock);
  
  # Switch script based on evaluation result
  # - evalResult.success = true  → mkCheck did NOT throw (RED or bug)
  # - evalResult.success = false → mkCheck threw correctly (GREEN)
  script = if evalResult.success
    then ''
      set -euo pipefail
      echo "ERROR: mkCheck did not throw on forbidden input"
      echo "  Expected: throw on inputs outside allowlist"
      echo "  Actual: mkCheck succeeded (stub behavior)"
      exit 1
    ''
    else ''
      set -euo pipefail
      echo "DoD5 negative-verify: throw detected correctly"
      echo "  mkCheck threw on forbidden input 'forbidden-input'"
    '';
in
builders.mkTestCheck {
  name = "test-dod5-negative-verify";
  inherit script;
}
