# feat追加ワークフロー - 並列開発手順書

**対象**: feat追加作業者  
**前提**: devブランチにスケール基盤が完成済み  
**保証**: Git競合を回避した並列開発

---

## クイックスタート（3ステップ）

```bash
# 1. featブランチ作成
git checkout -b feat/add-my-feature dev

# 2. feat追加（spec/urn/feat/my-feature/ のみ）
mkdir -p spec/urn/feat/my-feature
# feature.cue を作成

# 3. 検証
bash scripts/policy/check-feat-scope.sh dev  # ✅ 変更範囲OK
nix flake check                              # ✅ 意味的整合性OK
```

---

## 詳細手順

### Step 1: ブランチ作成

```bash
# devブランチから分岐
git checkout dev
git pull origin dev  # 最新取得

# featブランチ作成
git checkout -b feat/add-<slug> dev
```

**命名規則**:
- `feat/add-<slug>` (例: `feat/add-user-auth`)
- slug: kebab-case、既存と重複しないこと

### Step 2: feat定義作成

#### ディレクトリ作成
```bash
mkdir -p spec/urn/feat/<slug>
```

#### feature.cue作成
```bash
cat > spec/urn/feat/<slug>/feature.cue <<'EOF'
package feat_<slug_underscore>

import "github.com/porcorosso85/spec-repo/spec/schema"

feature: schema.#Feature & {
	slug: "<slug>"
	id:   "urn:feat:<slug>"
	artifact: {
		repoEnabled: false  // または true
	}
	// deps: ["urn:feat:other-feature"]  // 依存がある場合
}
EOF
```

**重要**:
- slugは kebab-case
- package名は feat_<slug_underscore> (ハイフン→アンダースコア)
- schemaをimport（型制約）
- contract/checksはimportしない（runner側が注入）

### Step 3: 変更範囲チェック

```bash
bash scripts/policy/check-feat-scope.sh dev
```

**期待結果**:
```
✅ OK: featブランチは spec/urn/feat/<slug>/ のみ変更
```

**NG例**:
```
❌ NG: featブランチが許可範囲外を変更しています

【禁止されている変更】:
nix/checks.nix
flake.nix
```

**対処**:
- 禁止範囲のファイルを元に戻す
- または、別ブランチ種別として扱う

### Step 4: 意味的整合性チェック

```bash
nix flake check
```

**期待結果**:
```
running 5 flake checks...
✅ spec-smoke
✅ spec-fast  # 新規featを含めて検証
✅ spec-slow
✅ spec-unit
✅ spec-e2e
```

**NG例**:
```
error: cue vet failed
feat_my_feature.slug: invalid value "My_Feature" (out of bound =~"^[a-z0-9]+(-[a-z0-9]+)*$")
```

**対処**:
- feature.cue を修正（contract制約に準拠）
- 再度 `nix flake check`

### Step 5: コミット

```bash
git add spec/urn/feat/<slug>/
git commit -m "feat: add <slug> feature

- Add spec/urn/feat/<slug>/feature.cue
- slug: <slug>
- id: urn:feat:<slug>
"
```

### Step 6: マージ準備

```bash
# 最新devを取り込み
git checkout dev
git pull origin dev
git checkout feat/add-<slug>
git rebase dev

# 再検証
bash scripts/policy/check-feat-scope.sh dev
nix flake check
```

### Step 7: マージ

```bash
git checkout dev
git merge feat/add-<slug> --no-ff -m "Merge feat/add-<slug>"
```

---

## 並列開発のシナリオ

### シナリオ1: 2つのfeatを同時開発

**ブランチA**:
```bash
git checkout -b feat/add-feature-a dev
mkdir -p spec/urn/feat/feature-a
# feature.cueを作成
```

**ブランチB**（並列）:
```bash
git checkout -b feat/add-feature-b dev
mkdir -p spec/urn/feat/feature-b
# feature.cueを作成
```

**マージ**:
```bash
# どちらを先にマージしても問題なし
git checkout dev
git merge feat/add-feature-a --no-ff
git merge feat/add-feature-b --no-ff  # Git競合なし
```

### シナリオ2: devスケール作業とfeat追加の並行

**dev（スケール作業）**:
```bash
git checkout dev
# nix/checks.nix を修正（featごとのderivation分割）
git commit -m "feat(nix): add per-feat checks"
```

**feat（並行）**:
```bash
git checkout -b feat/add-feature-c dev
# spec/urn/feat/feature-c/ 追加
```

**マージ**:
```bash
# devの変更をマージ
git checkout main
git merge dev --no-ff

# featの変更をマージ（Git競合なし）
git checkout dev
git pull origin dev  # devの最新を取得
git merge feat/add-feature-c --no-ff
```

---

## トラブルシューティング

### Q1: check-feat-scope.shがNG判定

**原因**: 許可範囲外のファイルを変更している

**対処**:
```bash
# 禁止ファイルの変更を確認
git diff dev...HEAD --name-only

# 不要な変更を戻す
git checkout dev -- nix/checks.nix flake.nix
```

### Q2: nix flake checkが失敗

**原因1**: contract制約違反（slug, id等）

**対処**:
```bash
# エラーメッセージを確認
nix flake check 2>&1 | grep -A 5 "error"

# feature.cueを修正
# 例: slug が kebab-caseでない → 修正
```

**原因2**: 依存featが存在しない

**対処**:
```bash
# deps配列を確認
# 存在しないURNを参照していないか
```

### Q3: マージ後に他のfeatが落ちる

**原因**: 意味的競合（contract変更等）

**対処**:
```bash
# これはポリシー対象外（設計上の問題）
# contract変更は慎重に行う
# 影響範囲を事前テスト
```

---

## チェックリスト

### ブランチ作成時
- [ ] `git checkout -b feat/add-<slug> dev` で作成
- [ ] slug が kebab-caseで既存と重複しない

### 作業中
- [ ] `spec/urn/feat/<slug>/` のみ変更
- [ ] `bash scripts/policy/check-feat-scope.sh dev` が PASS
- [ ] `nix flake check` が PASS

### マージ前
- [ ] 最新devをrebase
- [ ] check-feat-scope.sh 再チェック
- [ ] nix flake check 再チェック
- [ ] コミットメッセージが明確

---

## 参考: feature.cue テンプレート

### 最小構成
```cue
package feat_my_feature

import "github.com/porcorosso85/spec-repo/spec/schema"

feature: schema.#Feature & {
	slug: "my-feature"
	id:   "urn:feat:my-feature"
	artifact: {
		repoEnabled: false
	}
}
```

### 依存あり
```cue
package feat_my_feature

import "github.com/porcorosso85/spec-repo/spec/schema"

feature: schema.#Feature & {
	slug: "my-feature"
	id:   "urn:feat:my-feature"
	artifact: {
		repoEnabled: true
	}
	deps: [
		"urn:feat:base-feature",
		"urn:feat:util-feature",
	]
}
```

---

## 関連文書

- `.claude/branch-policy.md` - ブランチ変更範囲ポリシー（SSOT）
- `scripts/policy/check-feat-scope.sh` - 変更範囲チェックスクリプト
- `spec/schema/feature.cue` - Feature型定義
- `spec/ci/contract/*.cue` - Contract制約

---

## サポート

問題が発生した場合:
1. `bash scripts/policy/check-feat-scope.sh dev` の出力を確認
2. `nix flake check` のエラーメッセージを確認
3. `.claude/branch-policy.md` でルールを再確認
