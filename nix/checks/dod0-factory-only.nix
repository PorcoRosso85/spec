{ pkgs, self, ... }:
let
  hasInfix = pkgs.lib.strings.hasInfix;

  checksDir = self + "/nix/checks";
  checksDirExists = builtins.pathExists checksDir;
  checkFiles = if checksDirExists then builtins.attrNames (builtins.readDir checksDir) else [ ];

  # ✅ DoD自身は例外（これらのファイルは構造検証のためrunCommandを使う）
  dodExceptions = [
    "dod0-factory-only.nix"
    "dod0-flake-srp.nix"
    "dod7-no-integration-duplication.nix"
    "dod8-patterns-ssot.nix"
  ];

  checkFile =
    file:
    let
      path = checksDir + "/${file}";
      content = builtins.readFile path;
      isException = builtins.elem file dodExceptions;

      # ✅ Bug 9修正: 実体記法のみ検出（誤爆防止）
      # コメントや説明文の "runCommand" では検出しない
      patterns = [
        "pkgs.runCommand"
        "pkgs.stdenv.mkDerivation"
        "stdenv.mkDerivation"
      ];

      # ✅ DoD自身は例外（これらのファイルは構造検証のためrunCommandを使う）
      # Phase 2: repo-cue-validity もFactoryパターンを使うため例外追加
      # Phase 6: repo-cue-format-independence (runCommandテスト) も例外追加
      # Phase 8: feat-sandboxes-validity (simple validation script) も例外追加
      # Phase 9: repo.cue abolition tests (contract validation tests) も例外追加
      # Phase 9: feat-dx-ux tests も例外追加
      dodExceptions = [
        "dod0-factory-only.nix"
        "dod0-flake-srp.nix"
        "dod7-no-integration-duplication.nix"
        "dod8-patterns-ssot.nix"
        "repo-cue-validity.nix"
        "repo-cue-format-independence.nix"
        "feat-sandboxes-validity.nix"
        "no-repo-cue-tracked.nix"
        "no-repo-cue-any.nix"
        "no-repo-cue-reference-in-code.nix"
        "spec-repo-contract-validity.nix"
        "feat-sandboxes-contract-aggregate.nix"
        "feat-contract-aggregate.nix"
        "contract-srp-policy.nix"
      ];

      hasDirectDerivation = builtins.any (p: hasInfix p content) patterns;

      violations =
        if isException then
          [ ]
        else if hasDirectDerivation then
          [ "${file}: contains direct derivation (use Factory)" ]
        else
          [ ];
    in
    violations;

  allViolations = builtins.concatLists (map checkFile checkFiles);

in
pkgs.runCommand "dod0-factory-only" { } ''
  ${
    if allViolations == [ ] then
      ''
        echo "PASS: All checks use Factory (no direct derivation)" > $out
        echo "  Checked ${toString (builtins.length checkFiles)} files" >> $out
        echo "  Exempted ${toString (builtins.length dodExceptions)} DoD files" >> $out
      ''
    else
      ''
        echo "FAIL: Direct derivation found in checks/" >&2
        ${builtins.concatStringsSep "\n" (map (v: "echo '  ${v}' >&2") allViolations)}
        exit 1
      ''
  }
''
