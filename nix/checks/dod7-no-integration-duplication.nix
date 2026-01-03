{ pkgs, self, ... }:
let
  system = "x86_64-linux";
  checks = self.checks.${system} or {};
  packages = self.packages.${system} or {};
  
  # Integration testの一覧（既存のものを列挙）
  integrationTests = [
    "integration-verify-dod1"
    "integration-verify-dod2"
    "integration-verify-dod3"
    "integration-verify-dod4"
    "integration-negative-dod1"
    "integration-negative-dod2"
    "integration-negative-dod3"
    "integration-negative-dod4"
  ];
  
  # drvPath比較による重複検出
  checkDuplication = name:
    let
      checkDrv = checks.${name}.drvPath or null;
      pkgDrv = packages.${name}.drvPath or null;
    in
      if pkgDrv == null then 
        "OK: ${name} not in packages (no duplication)"
      else if checkDrv == null then
        throw "${name} missing in checks"
      else if checkDrv != pkgDrv then
        # ✅ 重複検出: 異なるdrvPath = 独立した定義が2箇所ある
        throw "${name} has different drvPath (DUPLICATION DETECTED)\n  checks: ${checkDrv}\n  packages: ${pkgDrv}"
      else
        "OK: ${name} references same derivation";
  
  results = map checkDuplication integrationTests;

in pkgs.runCommand "dod7-no-integration-duplication" {} ''
  echo "DoD7: Integration test duplication check" > $out
  echo "" >> $out
  ${builtins.concatStringsSep "\n" (map (r: "echo '  ${r}' >> $out") results)}
  echo "" >> $out
  echo "PASS: All integration tests use single definition" >> $out
''
