# DoD4: 重複なし - RED check
# Purpose: CUE vet でdetector仕様（report=expected）を検証
# Design: ビルダは cue vet 実行 + touch $out のみ（判断ロジックなし）

{ pkgs, self, cue }:

pkgs.runCommand "tdd-red-04-uniq" {
  buildInputs = [ cue ];
} ''
  cd ${self}
  ${cue}/bin/cue vet ./spec/ci/tdd/red/04-uniq/test.cue
  touch $out
''
