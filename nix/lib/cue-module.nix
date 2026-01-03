# CUE module utilities
# Purpose: Extract module name from cue.mod/module.cue for dynamic import path generation
# Design: Nix-only (no shell logic), reads module.cue and extracts module name

{ pkgs, self }:

let
  # Read cue.mod/module.cue
  moduleFile = builtins.readFile "${self}/cue.mod/module.cue";
  
  # Extract module name using builtins.match
  # Pattern: module: "..."
  moduleMatch = builtins.match ".*module:[[:space:]]*\"([^\"]+)\".*" moduleFile;
  
  # Get module name (first capture group)
  moduleName = 
    if moduleMatch != null && builtins.length moduleMatch > 0
    then builtins.head moduleMatch
    else throw "Failed to extract module name from cue.mod/module.cue";
  
  # Remove version suffix (@v0, @v1, etc.) for import prefix
  # Example: "github.com/user/repo@v0" -> "github.com/user/repo"
  importPrefix = builtins.head (builtins.split "@" moduleName);
  
in {
  inherit moduleName importPrefix;
  
  # Helper: Generate import statement for CUE
  mkImport = alias: pkgPath: ''import ${alias} "${importPrefix}/${pkgPath}"'';
}
