# DoD6: Validate feat-repo outputs against expected set
#
# Purpose:
#   Ensure feat-repo provides all expected outputs (packages, devShells, checks)
#
# Args:
#   { expected, actual, system }
#     expected: [string] - List of required output names
#     actual: [string] - List of provided output names
#     system: string - Target system (e.g., "x86_64-linux")
#
# Exports:
#   checkOutputs: { expected, actual, system } -> { allValid: bool, violations: [string] }
#   mkCheck: { expected, actual, system } -> derivation (throws on violation)
#
# Example:
#   dod6.mkCheck { expected = ["default" "dev"]; actual = ["default"]; system = "x86_64-linux"; }
#   # => Throws "DoD6 violation: missing outputs [dev]"

{ pkgs }:
let
  # Validate outputs against expected set
  #
  # Args:
  #   { expected, actual, system }
  #
  # Returns:
  #   { allValid: bool, violations: [string] }
  #
  # Implementation (RED stub):
  #   Always returns allValid = true (does not detect violations)
  #   GREEN phase will implement actual validation
  checkOutputs = { expected, actual, system }:
    let
      # RED stub: Skip actual comparison (assume valid)
      # GREEN: actualSet = builtins.listToAttrs (map (name: { inherit name; value = true; }) actual);
      # GREEN: missing = builtins.filter (name: !(builtins.hasAttr name actualSet)) expected;
      
      # RED: Always pass
      missing = [];
    in {
      allValid = missing == [];
      violations = missing;
    };
  
  # Create check derivation
  #
  # Args:
  #   { expected, actual, system }
  #
  # Returns:
  #   derivation that succeeds if valid, throws if violation detected
  #
  # Implementation (RED stub):
  #   Does not throw (allows negative-verify test to fail)
  #   GREEN phase will add throw logic
  mkCheck = { expected, actual, system }:
    let
      result = checkOutputs { inherit expected actual system; };
    in
      # RED stub: Always succeed (no throw)
      pkgs.runCommand "dod6-check" {} ''
        echo "DoD6 stub: outputs valid (stub always passes)" > $out
      '';
      
      # GREEN implementation:
      # if result.allValid
      # then pkgs.runCommand "dod6-check" {} ''
      #   echo "DoD6: outputs complete" > $out
      # ''
      # else throw ''
      #   DoD6 violation: missing expected outputs
      #     Expected: ${toString expected}
      #     Actual: ${toString actual}
      #     Missing: ${toString result.violations}
      #     System: ${system}
      #     
      #   Fix: Add missing outputs to feat-repo flake.nix
      # '';
in
{
  inherit checkOutputs mkCheck;
}
