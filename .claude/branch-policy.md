# ブランチ変更範囲ポリシー - Git競合回避のSSOT

**作成日**: 2025-12-30  
**目的**: dev（スケール作業）とfeat追加（並列）のGit競合を原理的に回避  
**適用範囲**: spec-repo全ブランチ

---

## エグゼクティブサマリー

### 並列開発を可能にする原則

**原則**: ブランチ種別ごとに変更範囲を**非交差**に固定する

| ブランチ種別 | 触っていい範囲（許可） | 触ってはいけない範囲（禁止） |
|-------------|---------------------|------------------------|
| **dev（スケール作業）** | `nix/**`, `flake.nix`, `scripts/**`, `spec/ci/**`, `.claude/**` | `spec/urn/feat/**` |
| **feat追加ブランチ** | `spec/urn/feat/<slug>/**` のみ（新規追加） | `nix/**`, `flake.nix`, `scripts/**`, `spec/ci/**`, `spec/schema/**`, その他全て |

### 断言可能な保証

✅ **上記範囲を守る限り、Git競合（テキスト衝突）は原理的に発生しない**

---

## 競合の定義（2種類を区別）

| 競合の種類 | 定義 | 検出方法 | 対処 |
|-----------|------|---------|------|
| **Git競合（テキスト衝突）** | 同じファイルを複数ブランチが編集 | `git merge`時のコンフリクト | 変更範囲を非交差に |
| **意味的競合（テスト失敗）** | 異なるファイル変更の組み合わせで動作不良 | `nix flake check` | マージゲートで検出 |

**ポリシーの責務**: Git競合の回避（意味的競合はflake checkで検出）

---

## ブランチ種別と変更範囲（詳細）

### 1. dev（スケール作業）ブランチ

**用途**: Nix checks最適化、CI基盤改善、contract拡張等

**許可範囲**:
```
nix/**                    # Nix checks実装
flake.nix                 # flake設定
scripts/**                # 検証スクリプト
spec/ci/contract/**       # Contract定義
spec/ci/checks/**         # Checks定義
spec/ci/fixtures/**       # Fixture追加
.claude/**                # ドキュメント
docs/**                   # ドキュメント
```

**禁止範囲**:
```
spec/urn/feat/**          # feat追加専用領域
```

**チェックスクリプト**:
```bash
bash scripts/policy/check-dev-scope.sh main
# → spec/urn/feat を触っていないことを検証
```

### 2. feat追加ブランチ

**命名規則**: `feat/add-<slug>`  
**用途**: 新機能URN定義の追加

**許可範囲**:
```
spec/urn/feat/<slug>/**   # 新規feat追加（このslug専用）
```

**禁止範囲**:
```
nix/**                    # Nix基盤（dev専用）
flake.nix                 # flake設定（dev専用）
scripts/**                # スクリプト（dev専用）
spec/ci/**                # CI設定（dev専用）
spec/schema/**            # 型定義（schema-change専用）
spec/adapter/**           # adapter定義
spec/mapping/**           # mapping定義
spec/external/**          # 外部カタログ
```

**チェックスクリプト**:
```bash
bash scripts/policy/check-feat-scope.sh dev
# → spec/urn/feat/<slug>/ のみ変更していることを検証
```

### 3. schema-change ブランチ（例外）

**用途**: 型定義の変更（既存featに影響）

**許可範囲**:
```
spec/schema/**            # 型定義変更
```

**注意**: 全featに影響するため、並列保証の対象外（単独実施）

---

## 運用ルール

### ブランチ作成時

#### dev（スケール作業）
```bash
git checkout -b dev
# spec/urn/feat を触らないことを意識
```

#### feat追加
```bash
git checkout -b feat/add-my-feature dev
# spec/urn/feat/my-feature/ のみ追加
```

### 作業中の検証

#### dev
```bash
# 定期的にチェック
bash scripts/policy/check-dev-scope.sh main
```

#### feat追加
```bash
# 作業開始時・コミット前にチェック
bash scripts/policy/check-feat-scope.sh dev
```

### マージ前の必須ゲート

#### 全ブランチ共通
```bash
# 1. 変更範囲チェック（ブランチ種別に応じて）
bash scripts/policy/check-XXX-scope.sh <base>

# 2. 意味的整合性チェック
nix flake check

# 両方がPASSしたらマージ可
```

---

## Git競合回避の証明

### 定理
```
ブランチAの変更範囲 ∩ ブランチB の変更範囲 = ∅
⇒ Git競合は発生しない
```

### 証明（dev vs feat）
```
dev許可範囲:
  {nix/**, flake.nix, scripts/**, spec/ci/**, .claude/**}

feat許可範囲:
  {spec/urn/feat/<slug>/**}

交差:
  {nix/**, ...} ∩ {spec/urn/feat/<slug>/**} = ∅

∴ Git競合は発生しない（QED）
```

---

## 例外ケース（並列保証外）

### ケース1: schema変更が必要なfeat追加

**問題**: `spec/schema/**` 変更が必要  
**対処**: 
1. schema-changeブランチで型定義変更（単独）
2. マージ後、featブランチを作成

### ケース2: 複数featブランチが同じslug

**問題**: `spec/urn/feat/same-slug/` を複数ブランチが作成  
**対処**:
1. slug予約システム（中央ファイル不要、GitHubラベル等で管理）
2. 先着順マージ、後続はリネーム

### ケース3: contractルール追加でfeatが落ちる

**問題**: dev側のcontract変更で既存featが`nix flake check`失敗  
**対処**:
1. これは意味的競合（ポリシー対象外）
2. マージゲートで検出、featブランチ側で修正

---

## スクリプト詳細

### check-dev-scope.sh

**目的**: dev（スケール作業）が`spec/urn/feat`を触っていないことを検証

**使い方**:
```bash
bash scripts/policy/check-dev-scope.sh main
```

**判定ロジック**:
```bash
# spec/urn/feat/ への変更を検出したらNG
git diff --name-only main...HEAD | grep '^spec/urn/feat/'
```

### check-feat-scope.sh

**目的**: featブランチが`spec/urn/feat/<slug>/`のみ変更していることを検証

**使い方**:
```bash
bash scripts/policy/check-feat-scope.sh dev
```

**判定ロジック**:
```bash
# spec/urn/feat/<slug>/ 以外の変更を検出したらNG
git diff --name-only dev...HEAD | grep -v '^spec/urn/feat/[^/]+/'
```

---

## マージフロー（推奨）

### パターン1: dev → main（スケール作業）

```bash
# 1. devブランチで作業
git checkout dev
# nix/**, flake.nix等を変更

# 2. 変更範囲チェック
bash scripts/policy/check-dev-scope.sh main
# ✅ OK: spec/urn/feat を触っていない

# 3. 意味的整合性チェック
nix flake check
# ✅ PASS

# 4. マージ
git checkout main
git merge dev --no-ff
```

### パターン2: feat/add-xxx → dev（feat追加）

```bash
# 1. featブランチで作業
git checkout -b feat/add-my-feature dev
# spec/urn/feat/my-feature/ を追加

# 2. 変更範囲チェック
bash scripts/policy/check-feat-scope.sh dev
# ✅ OK: spec/urn/feat/my-feature/ のみ変更

# 3. 意味的整合性チェック
nix flake check
# ✅ PASS

# 4. マージ
git checkout dev
git merge feat/add-my-feature --no-ff
```

### パターン3: 並列feat追加（devが共通基盤）

```bash
# 前提: dev にスケール基盤が完成

# ブランチA
git checkout -b feat/add-feature-a dev
# spec/urn/feat/feature-a/ 追加

# ブランチB（並列）
git checkout -b feat/add-feature-b dev
# spec/urn/feat/feature-b/ 追加

# 両方がdevにマージ可能（Git競合なし）
# マージ順は任意
```

---

## 監査証跡

### devブランチの検証
```bash
$ git checkout dev
$ bash scripts/policy/check-dev-scope.sh main
✅ OK: dev（スケール作業）は spec/urn/feat 領域を触っていない
```

### featブランチの検証
```bash
$ git checkout feat/add-my-feature
$ bash scripts/policy/check-feat-scope.sh dev
✅ OK: featブランチは spec/urn/feat/my-feature/ のみ変更
```

---

## よくある質問

### Q1: devとfeatブランチは同時進行可能？
**A**: 可能。変更範囲が非交差のため、Git競合は発生しない。

### Q2: 複数featブランチを並列で作業可能？
**A**: 可能。各featブランチが異なるslugを使う限り、Git競合は発生しない。

### Q3: マージ順は？
**A**: 任意。Git競合がないため、どの順序でマージしても問題なし。

### Q4: 意味的競合（flake check失敗）はどう扱う？
**A**: マージゲートで検出。失敗したブランチ側で修正してから再マージ。

---

## 次のアクション

### 即座実施
1. devブランチで`check-dev-scope.sh main`を実行
2. 結果を確認（spec/urn/featを触っていないことを証明）

### feat追加時
1. `git checkout -b feat/add-<slug> dev`
2. `spec/urn/feat/<slug>/`のみ変更
3. `check-feat-scope.sh dev`でチェック
4. `nix flake check`を通す
5. マージ

---

**関連文書**:
- `scripts/policy/check-dev-scope.sh` - dev変更範囲チェック
- `scripts/policy/check-feat-scope.sh` - feat変更範囲チェック
- `.claude/scale-design-review.md` - スケール設計レビュー
