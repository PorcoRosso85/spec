{ pkgs, self, ... }:
let
  hasInfix = pkgs.lib.strings.hasInfix;
  
  # ✅ Bug 6修正: Nixエスケープ整合（CUEファイル上の文字列と完全一致）
  forbiddenLiterals = [
    "^[a-z0-9]+(-[a-z0-9]+)*$"        # kebab-case pattern
    "^urn:feat:"                       # URN prefix (partial match)
    "^urn:feat:[a-z0-9-]+$"           # URN pattern (git_adapter/mapping variant)
    "^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"  # URN pattern (full)
    "^[a-z0-9-]+(\\\\+[a-z0-9-]+)?$"  # branch name with overlay
  ];
  
  # spec/配下の.cueファイルを再帰的に取得
  findCueFiles = dir:
    let
      entries = builtins.readDir dir;
      processEntry = name: type:
        let path = dir + "/${name}"; in
        if type == "directory" then findCueFiles path
        else if type == "regular" && pkgs.lib.hasSuffix ".cue" name then [path]
        else [];
    in builtins.concatLists (builtins.attrValues (builtins.mapAttrs processEntry entries));
  
  cueFiles = findCueFiles (self + "/spec");
  
  # ✅ Bug 8修正: 完全一致パスで免除（SSOT境界明確化）
  patternsPath = self + "/spec/schema/patterns.cue";
  
  checkFile = file:
    let
      content = builtins.readFile file;
      
      # 完全一致のみ免除（substring判定は使わない）
      isPatternsCue = file == patternsPath;
      
      # ✅ Bug 3修正: hasInfixで純粋なリテラル一致（regex解釈なし）
      violations = if isPatternsCue then []
                   else builtins.filter (lit: hasInfix lit content) forbiddenLiterals;
      
      formatViolation = lit: "${builtins.baseNameOf (toString file)}: '${lit}'";
    in map formatViolation violations;
  
  allViolations = builtins.concatLists (map checkFile cueFiles);
  violationCount = builtins.length allViolations;

in pkgs.runCommand "dod8-patterns-ssot" {
  inherit violationCount;
} ''
  ${if allViolations == [] then ''
    echo "PASS: All patterns reference SSOT (spec/schema/patterns.cue)" > $out
    echo "  Checked ${toString (builtins.length cueFiles)} CUE files" >> $out
    echo "  Exempted: patterns.cue" >> $out
    echo "  Forbidden literals: ${toString (builtins.length forbiddenLiterals)}" >> $out
  '' else ''
    echo "FAIL: Found $violationCount hardcoded pattern(s) outside SSOT" >&2
    echo "  Patterns must be defined in spec/schema/patterns.cue" >&2
    echo "  Violations:" >&2
    ${builtins.concatStringsSep "\n" (map (v: "echo '  - ${v}' >&2") allViolations)}
    exit 1
  ''}
''
