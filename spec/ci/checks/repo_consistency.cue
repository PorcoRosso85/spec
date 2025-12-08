package checks

// repo整合性保証
// - artifact.repoEnabled == true な機能URNは
//   必ず adapter/git/repo に存在すること
//
// 検証ロジック（CI実装側で実装する内容）:
// 1. urn/feat/*/feature.cue を走査し、artifact.repoEnabled == true な URN を収集
// 2. adapter/git/repo/repo.cue の repos 配列から internal URN を収集
// 3. 1 の URN がすべて 2 に含まれているか検証
// 4. 含まれていない URN がある場合はエラー
//
// この制約により、「SSOT定義された repo がほぼ確実にある」状態を保証。

// 将来の拡張候補:
// - 逆方向の検証: adapter/git/repo にある URN が urn/feat に存在するか
