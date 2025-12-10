package skeleton

// 統合検証: すべての制約を適用
#ValidTreeFinal: #TreeFinal & #UniqueSlotIds & #StrictVersion & #RequireNarHash & #ActiveOnly & #ValidManifests

// 外部JSONの検証エントリーポイント
// 使用例: cue vet validate.cue input.json
tree: #ValidTreeFinal
