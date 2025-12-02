package checks

// 1urn1feature1repo保証
// - adapter/git/repo で同じ internal URN が二重参照されていないこと
//
// 検証ロジック（CI実装側で実装する内容）:
// 1. adapter/git/repo/repo.cue の repos 配列を読み取る
// 2. internal フィールドの値を集約
// 3. 重複がある場合はエラー
//
// 現時点の CUE 制約では直接表現できないため、
// 別途 CI スクリプトでの実装を推奨。

// 将来の拡張候補:
// - CUE の list comprehension や uniqueness 制約を使った検証
