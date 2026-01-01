# DoD5: Validate feat-repo flake.lock inputs against allowlist
#
# Purpose:
#   Ensure feat-repo only depends on nixpkgs and spec-repo (no transitive deps)
#
# Args:
#   lockPath: Path to flake.lock file
#
# Exports:
#   allowedInputs: List of permitted input names
#   checkInputs: lockPath -> { isValid: bool, violations: [string] }
#   mkCheck: lockPath -> derivation (throws on violation)
#
# Example:
#   dod5.mkCheck ./flake.lock
#   # => Success if inputs ⊆ {nixpkgs, spec}
#   # => Throws "DoD5 violation: forbidden inputs [...]" otherwise

{ pkgs }:
let
  # SSOT: Allowed input names for feat-repo
  # NOTE: Assumes feat-repo uses `inputs.spec.url = "..."` (not `spec-repo`)
  allowedInputs = [ "nixpkgs" "spec" ];
  
  # Validate flake.lock inputs against allowlist
  #
  # Args:
  #   lockPath: string - Path to flake.lock file
  #
  # Returns:
  #   { isValid: bool, violations: [string] }
  #
  # Implementation (RED stub):
  #   Always returns isValid = true (does not detect violations)
  #   GREEN phase will implement actual validation
  checkInputs = lockPath:
    let
      # RED stub: Skip actual parsing (assume valid)
      # GREEN: lockData = builtins.fromJSON (builtins.readFile lockPath);
      # GREEN: actualInputs = builtins.attrNames (lockData.nodes.root.inputs or {});
      # GREEN: forbidden = builtins.filter (i: !(builtins.elem i allowedInputs)) actualInputs;
      
      # RED: Always pass
      forbidden = [];
    in {
      isValid = forbidden == [];
      violations = forbidden;
    };
  
  # Create check derivation
  #
  # Args:
  #   lockPath: string - Path to flake.lock file
  #
  # Returns:
  #   derivation that succeeds if valid, throws if violation detected
  #
  # Implementation (RED stub):
  #   Does not throw (allows negative-verify test to fail)
  #   GREEN phase will add throw logic
  mkCheck = lockPath:
    let
      result = checkInputs lockPath;
    in
      # RED stub: Always succeed (no throw)
      pkgs.runCommand "dod5-check" {} ''
        echo "DoD5 stub: inputs valid (stub always passes)" > $out
      '';
      
      # GREEN implementation:
      # if result.isValid
      # then pkgs.runCommand "dod5-check" {} ''
      #   echo "DoD5: inputs valid" > $out
      # ''
      # else throw ''
      #   DoD5 violation: forbidden inputs detected
      #     Allowed: ${toString allowedInputs}
      #     Forbidden: ${toString result.violations}
      #     
      #   Fix: Remove forbidden inputs from flake.lock
      # '';
in
{
  inherit allowedInputs checkInputs mkCheck;
}
