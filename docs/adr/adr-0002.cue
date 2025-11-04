package adr

adr0002: {
  id:     "0002"
  title:  "ADRをCUEで管理する最小導入 (CI観測)"
  status: "proposed"
  date:   "2025-11-04"
  scope:  "repo-guardとADR同期の観測追加"
  background: """
  #33でCUE ADRが合意済み。#35で同期ツールが追加済み。
  本PRは削除を伴わず最小のADRを追加し、CIが動くかだけを見る。
  """
  decision: """
  CUE ADRを標準化フォーマットで継続。
  今回はactivationsを空にし、skeleton.jsonへの影響を避ける。
  """
  effects: [
    "CIの5ジョブ(repo-guard等)が起動することを確認",
    "既存ファイルを一切変更しない"
  ]
  activations: []
  references: [
    "docs/adr/adr-0001.cue"
  ]
}
