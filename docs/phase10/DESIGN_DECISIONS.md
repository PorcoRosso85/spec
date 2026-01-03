# Phase 10 設計決定記録

## 概要
このドキュメントはPhase 10（DoD5/DoD6実装）における重要な設計判断を記録します。

---

## 決定1: DoD6インターフェース - リスト型採用

### 決定内容
DoD6の`actual`引数はリスト型（`[String]`）を要求する

```nix
mkCheck :: {
  expected :: [String],
  actual :: [String],  # ← リスト型を要求
  system :: String
} -> Derivation
```

### 理由
1. **インターフェース制約**: attrset型を受け取らないため、自己参照が構造的に困難
2. **責務分離**: 出力抽出は呼び出し側の責任として明確化
3. **シンプルさ**: リスト比較のみで実装が単純
4. **評価時エラー**: attrset渡しは評価時に即座にエラー（Nixの動的評価）

### 代替案と却下理由
**代替案A**: attrset型を受け取る設計
```nix
mkCheck :: {
  outputs :: Attrset,  # flake outputsをそのまま渡す
  expected :: { packages :: [String], checks :: [String], ... },
  system :: String
} -> Derivation
```

**却下理由**:
- `outputs.checks`の抽出時に自己参照リスク
- 条件分岐（`if expected.checks != [] then ...`）が複雑
- 回帰テストが必要になる

### 影響
- ✅ 自己参照は設計レベルで困難化（現時点）
- 🟨 回帰テスト無し（将来の保証は弱い）
- ⚠️ 呼び出し側で手動リスト化が必要
- ⚠️ 評価時エラー（静的チェックではない）

---

## 決定2: 回帰テスト不要（YAGNI）

### 決定内容
DoD6の自己参照安全性を検証する回帰テストを作成しない

### 理由（現時点）
1. **インターフェース制約**: リスト型要求により、attrset型の誤用は評価エラー
2. **早期失敗**: 誤用は評価時に即座に無限ループ（開発者が気づく）
3. **設計配慮**: 現在の実装では自己参照パスが存在しない

### 制限事項
- ⚠️ **"将来も保証"ではない**: 小変更で自己参照パスが混入する可能性
- ⚠️ **評価時エラー**: 静的型チェックではなく実行時検出
- ⚠️ **文書化頼り**: コード変更時に設計意図が失われるリスク

### 代替案（回帰テスト追加）
"将来も保証"を主張する場合は、以下の回帰テストを推奨:
```nix
# test-dod6-skip-checks-safe.nix
# actualに self.checks を含めても、expected.checks=[] なら安全
```
コスト: ~50行、メリット: 将来の事故防止

### 回帰テストが必要な条件
以下のいずれかに該当する場合は回帰テスト追加を検討:
- インターフェースをattrset型受け取りに変更
- 内部で`builtins.attrNames`等の動的抽出を実装
- 条件分岐による評価スキップロジック追加

### 証跡
現在の実装では、誤用例は型エラーまたは無限ループで即座に検出:

```nix
# ❌ 型エラー例
actual = self.checks.${system};  # attrset型 → list型不一致

# ❌ 無限ループ例（評価時エラー）
actual = builtins.attrNames self.checks.${system};  # 循環参照
```

---

## 決定3: checksRed分離維持

### 決定内容
negative-verify testsを`checksRed.${system}`に配置し、`checks.${system}`に統合しない

### 理由
1. **TDDサイクル可視化**: RED/GREEN状態を明示的に分離
2. **CI安定性**: 開発中のRED testsがCI breakしない
3. **将来拡張性**: 新DoD追加時のRED tests分離が容易

### 運用方針
- **RED phase**: negative-verify testsは`checksRed`で失敗
- **GREEN phase**: negative-verify testsは`checksRed`で成功
- **本番運用**: `checks`のみをCI実行（`checksRed`は任意）

---

## 決定4: 安全な文字列処理

### 決定内容
すべてのリスト→文字列変換で`builtins.concatStringsSep`を使用

### 理由
1. **予測可能性**: `toString`のリスト挙動は不安定
2. **明示性**: 区切り文字を明示的に指定
3. **可読性**: エラーメッセージが読みやすい

### 実装例
```nix
# ❌ 避けるパターン
throw "Missing: ${toString violations}";

# ✅ 推奨パターン
throw "Missing: ${builtins.concatStringsSep " " violations}";
```

---

## 決定5: flake.lock allowlist

### 決定内容
DoD5のallowlistは`["nixpkgs", "spec"]`のみ

### 意図
feat-repoの依存を最小限に制限（spec-repoが提供する機能のみ使用）

### 注意点
一般的なfeat-repoが`flake-utils`等を使う場合は違反となる
→ これは**意図した厳格さ**（追加依存の禁止）

### 緩和方法（必要に応じて）
allowlistを拡張可能にする場合:
```nix
# feat-repo側で上書き可能にする
dod5.mkCheckWithAllowlist {
  lockPath = ./flake.lock;
  allowedInputs = [ "nixpkgs" "spec" "flake-utils" ];
}
```

現時点では実装しない（YAGNI）

---

## 証跡: エラーメッセージ実証

### DoD5: 禁止input検出
```
error: DoD5 violation: forbidden inputs detected
  Allowed: nixpkgs spec
  Forbidden: forbidden-input

  Fix: Remove forbidden inputs from flake.lock
```

### DoD6: 欠落output検出
```
error: DoD6 violation: missing expected outputs
  Expected: default dev missing-output
  Actual: default dev
  Missing: missing-output
  System: x86_64-linux
  
  Fix: Add missing outputs to feat-repo flake.nix
```

---

## まとめ

### 採用した設計原則
1. **型安全性**: 型レベルでバグを防止
2. **責務分離**: 明確なインターフェース境界
3. **YAGNI**: 必要最小限の実装
4. **Fail Fast**: エラーは早期に顕在化

### トレードオフ
- ❌ 呼び出し側での手動リスト化が必要
- ✅ シンプルで理解しやすい実装
- ✅ 型エラーによる早期検出
- ✅ メンテナンスコスト削減

### 将来の拡張ポイント
1. allowlistのカスタマイズ機能
2. attrset型受け取り（回帰テスト必須）
3. outputsカテゴリ別検証（packages/devShells/checks）

現時点では YAGNI により保留
