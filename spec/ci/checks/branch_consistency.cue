package checks

// branch整合性保証
// - adapter/git/branch の name の "+" 前半が対応する slug と一致すること
//
// 検証ロジック（CI実装側で実装する内容）:
// 1. adapter/git/branch/branch.cue の branches 配列を走査
// 2. 各 branch について:
//    a. internal URN から slug を抽出（"urn:feat:" を除いた部分）
//    b. name から "+" で分割し、前半を取得
//    c. slug と name の前半が一致するか検証
// 3. 不一致がある場合はエラー
//
// branch 名の文法:
// - slug（main相当）: "decide-ci-score-matrix"
// - slug + "+" + variant: "decide-ci-score-matrix+experimental"

// required:true なのに Git 上に無い branch の検出は、
// 別途 Git との連携スクリプトで実装（YAGNI: 将来拡張）
