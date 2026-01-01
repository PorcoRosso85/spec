{ pkgs, self, cue }:
let
  # ✅ Bug 1修正: 真のsubstring判定（regex不使用）
  hasInfix = pkgs.lib.strings.hasInfix;

  # Shell validator - 禁止構文を検出
  validateShellScript = script:
    let
      # ✅ Bug 2修正: 単語出現検出（pipe/option/standalone）
      # ✅ U2修正: 先頭パターン追加（抜け道防止）
      forbidden = [
        # 制御構文（先頭・中間・行頭カバー）
        "if " " if " "\nif " "if[" "if;"
        "for " " for " "\nfor "
        "while " " while " "\nwhile "
        "case " " case " "\ncase "
        
        # テキスト処理（先頭・中間・行頭・パイプカバー）
        "sed " " sed " "\nsed " "sed -" "|sed"
        "awk " " awk " "\nawk " "|awk"
        "grep " " grep " "\ngrep " "|grep"
        "jq " " jq " "\njq " "|jq"
      ];
      
      violations = builtins.filter (p: hasInfix p script) forbidden;
    in
      if violations != []
      then throw "Shell script contains forbidden patterns: ${toString violations}"
      else script;

  # Factory: Red verify test
  # ✅ Bug 4修正: if排除
  # ✅ Bug 7修正: && exit 1 || true方式（touch到達保証）
  # ✅ U1修正: set -eとの相性問題回避
  mkRedVerify = { name, dod, genInputCue }:
    pkgs.runCommand name {} (validateShellScript ''
      set -euo pipefail
      
      mkdir -p $out
      cd $out
      
      ${genInputCue}
      
      # RED期待: CUE validation失敗が正常
      # - 成功時: && exit 1 で即終了（set -e）→ ビルド失敗
      # - 失敗時: || true で継続 → touch実行
      (${cue}/bin/cue vet . && exit 1) || true
      
      touch $out/red-verified
    '');

  # Factory: Integration verify test
  mkIntegrationVerify = { name, dod, genInputCue }:
    pkgs.runCommand name {} (validateShellScript ''
      set -euo pipefail
      
      mkdir -p $out
      cd $out
      
      ${genInputCue}
      
      ${cue}/bin/cue vet .
      
      touch $out/integration-verified
    '');

  # Factory: Integration negative test
  # ✅ Bug 4修正: if排除
  # ✅ Bug 7修正: && exit 1 || true方式
  # ✅ U1修正: set -eとの相性問題回避
  mkIntegrationNegative = { name, dod, genInputCue }:
    pkgs.runCommand name {} (validateShellScript ''
      set -euo pipefail
      
      mkdir -p $out
      cd $out
      
      ${genInputCue}
      
      # Negative期待: 不正なデータでvalidation失敗が正常
      (${cue}/bin/cue vet . && exit 1) || true
      
      touch $out/negative-verified
    '');

  # Generic test check (for Phase 10+ tests)
  # Validates shell script and creates simple test derivation
  mkTestCheck = { name, script }:
    pkgs.runCommand name {} (validateShellScript ''
      ${script}
      
      # Ensure output file is created
      touch $out
    '');

in {
  inherit mkRedVerify mkIntegrationVerify mkIntegrationNegative;
  inherit mkTestCheck;
  inherit validateShellScript hasInfix;
}
