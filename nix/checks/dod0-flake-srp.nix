{ pkgs, self, ... }:
let
  hasInfix = pkgs.lib.strings.hasInfix;
  
  flakeContent = builtins.readFile (self + "/flake.nix");
  
  # packages セクション内での直接derivation定義を検出
  # 例外:
  # - let内のツールビルド（cue-v15等）
  # - packages.verify-red-* (TDD-RED検証用)
  # - packages.validate (スクリプト)
  
  # packagesセクションを抽出（簡易版: "packages." で始まる行）
  lines = pkgs.lib.splitString "\n" flakeContent;
  
  # packages.integration-* 以外で pkgs.stdenv.mkDerivation を使っているか
  checkPackagesSection = line:
    let
      isPackageLine = hasInfix "packages." line;
      isIntegrationRef = hasInfix "self.checks" line;  # integration-*はchecks参照のみ
      hasMkDerivation = hasInfix "pkgs.stdenv.mkDerivation" line;
      hasRunCommand = hasInfix "pkgs.runCommand" line;
      
      # verify-red系とvalidateは例外（TDD-RED用）
      isAllowedException = hasInfix "verify-red-" line || hasInfix "packages.validate" line || hasInfix "packages.cue" line;
      
      isViolation = isPackageLine && (hasMkDerivation || hasRunCommand) && !isIntegrationRef && !isAllowedException;
    in
      if isViolation then [line] else [];
  
  violations = builtins.concatLists (map checkPackagesSection lines);

in pkgs.runCommand "dod0-flake-srp" {} ''
  ${if violations == [] then ''
    echo "PASS: flake.nix packages section maintains SRP" > $out
    echo "  Integration tests: Reference checks only (no duplication)" >> $out
    echo "  Allowed exceptions: verify-red-*, validate, cue" >> $out
  '' else ''
    echo "FAIL: flake.nix packages contains direct derivations" >&2
    echo "  Found ${toString (builtins.length violations)} violation(s)" >&2
    echo "  Solution: Move derivations to nix/checks/ or use self.checks reference" >&2
    exit 1
  ''}
''
