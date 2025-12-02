package checks

// DRY保証: id == "urn:feat:" + slug
// - すべての urn/feat/*/feature.cue で id が slug から自動導出されること
// - schema/feature.cue の #Feature 型定義により構造的に保証される
//
// CUE の型システムにより、以下が強制される:
// - id: "urn:feat:\(slug)"
//
// この制約により、手動で id を書いても slug と不整合なら CUE エラーになる。

// 実装側への注意:
// - urn/feat/*/feature.cue は必ず schema.#Feature を継承すること
// - id フィールドを明示的に上書きしないこと（自動導出に任せる）
