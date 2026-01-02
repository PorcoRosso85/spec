# Phase 6 WORK_ORDER v1（等価リファクタ）

## 基準点
- **HEAD**: 353701d
- **flake check**: 29 checks, EXIT 0
- **tag**: phase5-freeze-2026-01-02 (維持)

## 進め方のルール
1. **1コミット = 1意図**（引数名だけ、コメントだけ、等）
2. 各コミットのDoD：
   - `nix flake check` → 29 checks, exit 0
   - `git diff` が意図した範囲のみ
3. **等価の定義**：出力（checks名集合・挙動・FAIL条件）を変えない

---

## T4: 引数形の統一

### 対象ファイル
- `nix/checks/repo-cue-validity.nix`

### 現在の問題
- 引数名が混在：`flakeChecksList` → `checksAttrNames` への移行途中
- 引数の並び順が不明確

### タスク一覧

| タスクID | 作業 | DoD（証拠） |
|----------|------|-------------|
| T4.1 | 引数名を `checksAttrNames` に統一 | `grep "checksAttrNames" nix/checks/repo-cue-validity.nix` |
| T4.2 | flake.nix の呼び出し側も統一 | `git diff` が引数名変更のみ |
| T4.3 | flake check で 29 PASS 確認 | ログ証拠 |

### 実行ログ
```bash
# T4.1: repo-cue-validity.nix の引数確認
cd /home/nixos/spec-repo
grep -n "checksAttrNames\|flakeChecksList" nix/checks/repo-cue-validity.nix
```

---

## T5: 命名/コメント整備

### 対象ファイル
- `nix/checks/repo-cue-validity.nix`
- `flake.nix`（該当セクション）

### 作業内容
- コメントのtypo修正
- 命名の一貫性確認
- ドキュメント化の追加

### タスク一覧

| タスクID | 作業 | DoD（証拠） |
|----------|------|-------------|
| T5.1 | コメントのtypo/整形 | `git diff` がコメント変更のみ |
| T5.2 | 命名の一貫性確認 | grepで命名が統一されていることを確認 |
| T5.3 | flake check で 29 PASS 確認 | ログ証拠 |

---

## REVIEW_CHECKLIST v1

各コミット前に確認：

- [ ] mock-spec という語が出ていないか
- [ ] 出力（checks名・FAIL条件）が変わっていないか
- [ ] `nix flake check` が 29 PASS するか
- [ ] `git diff` が意図した範囲か

---

## 実行記録

| 日時 | タスク | コミット | flake check | 備考 |
|------|--------|---------|-------------|------|
| 2026-01-02 | T4.1 | - | - | pending |
| 2026-01-02 | T4.2 | - | - | pending |
| 2026-01-02 | T4.3 | - | - | pending |
| 2026-01-02 | T5.1 | - | - | pending |
| 2026-01-02 | T5.2 | - | - | pending |
| 2026-01-02 | T5.3 | - | - | pending |

---

## TDD表（等価リファクタ用）

| テスト名 | 判定基準 | ステータス |
|----------|----------|------------|
| flake_check_29_pass | exit 0, 29 checks | ✅ |
| refactor_semantics_preserving | checks名・FAIL条件が不変 | pending |
| no_mock_spec_mentions | mock-spec語が混入しない | pending |
| diff_is_minimal | git diff が意図した範囲 | pending |
