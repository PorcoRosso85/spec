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
  # Implementation (GREEN):
  #   Compares actual outputs against expected set
  #
  # Note: `actual` is a pre-extracted list provided by caller.
  #   Self-reference safety is caller's responsibility
  #   (e.g., avoid extracting from self.checks when validating checks)
  checkOutputs =
    {
      expected,
      actual,
      system,
    }:
    let
      actualSet = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = true;
        }) actual
      );
      missing = builtins.filter (name: !(builtins.hasAttr name actualSet)) expected;
    in
    {
      allValid = missing == [ ];
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
  # Implementation (GREEN):
  #   Validates outputs and throws on missing items
  mkCheck =
    {
      expected,
      actual,
      system,
    }:
    let
      result = checkOutputs { inherit expected actual system; };
    in
    if result.allValid then
      pkgs.runCommand "dod6-check" { } ''
        echo "DoD6: outputs complete" > $out
      ''
    else
      throw ''
        DoD6 violation: missing expected outputs
          Expected: ${builtins.concatStringsSep " " expected}
          Actual: ${builtins.concatStringsSep " " actual}
          Missing: ${builtins.concatStringsSep " " result.violations}
          System: ${system}
          
          Fix: Add missing outputs to feat-repo flake.nix
      '';
in
{
  inherit checkOutputs mkCheck;
}
