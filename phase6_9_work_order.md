# Phase 6.9 WORK_ORDER v1（運用DoD・完了パック）

## 目的
Phase 6 の完了を「運用上の完了」に昇格させ、将来の破壊を防ぐ。

## 基準点
- **HEAD**: b7ab953
- **flake check**: 29 checks, exit 0
- **phase5-freeze tag**: 499381b（維持）
- **phase6-dod tag**: なし ← 今回作成

---

## T6.9.1: Phase 6 完了タグの作成

### 目的
Phase 6 の完了点 (b7ab953) を再現可能な形で固定する。

### 実行
```bash
cd /home/nixos/spec-repo
git tag -a phase6-dod-2026-01-02 -m "Phase 6 complete: repo-cue-format-independence regression + comment improvement

- Commit: b7ab953
- flake check: 29 checks, exit 0
- Changes:
  * Add repo-cue-format-independence.nix (format independence test)
  * Add phase6_work_order.md (documentation)
  * Improve Japanese comments in flake.nix

Reproduce: nix flake check && echo $?
"

git show --stat phase6-dod-2026-01-02 | head -10
```

### DoD
- [ ] tag `phase6-dod-2026-01-02` が存在する
- [ ] `git show phase6-dod-2026-01-02` でコミット b7ab953 を指す

---

## T6.9.2: requiredChecks 差分検知の追加

### 目的
将来、checks を増減したときや repo.cue を変更したときに「requiredChecks の意図せぬ変更」を検知する。

### 対象ファイル
- `nix/checks/repo-cue-validity.nix` に検知ロジックを追加

### 実行
```bash
# 現在の requiredChecks をハッシュ化
cd /home/nixos/spec-repo
SHA256=$(grep -A100 'requiredChecks:' repo.cue | grep -B100 '^  \]' | grep '"' | sort | tr '\n' ' ' | sha256sum | cut -d' ' -f1)
echo "Current requiredChecks SHA256: $SHA256"
```

### 実装方針
1. 現在の requiredChecks を SHA256 で固定
2. 変更時に差分をログ出力
3. FAIL にはしない（検知のみ）

### DoD
- [ ] requiredChecks のハッシュを計算・記録する処理が追加されている
- [ ] flake check が 29 PASS を維持

---

## T6.9.3: 提出パック（証跡）の作成

### 目的
第三者向けに「このタグで、これを打てば同じ結果になる」を1ファイルにまとめる。

### 対象ファイル
- `phase6_submission_pack.md`

### 内容
```
## Phase 6 完了パック

### 凍結点
- Tag: phase6-dod-2026-01-02
- Commit: b7ab953

### 再現方法
```bash
cd /home/nixos/spec-repo
git checkout phase6-dod-2026-01-02
nix flake check && echo "EXIT_CODE: $?"
```

### 証拠ログの場所
- flake check 結果: なし（実行時に生成）
- git log: `git log --oneline phase6-dod-2026-01-02..HEAD`

### 変更履歴
- 0db7ee9: Add format-independence regression test
- 794751b: Add exception for format-independence test
- 353701d: Fix test (remove passAsFile)
- a492d7c: Improve Japanese comments
- b7ab953: Update WORK_ORDER (completion)
```

### DoD
- [ ] `phase6_submission_pack.md` が作成されている
- [ ] 内容が正確（タグ、コミット、再現コマンド）

---

## REVIEW_CHECKLIST v1（Phase 6.9用）

各タスク完了前に確認：

- [ ] mock-spec という語が出ていないか
- [ ] 出力（checks名・FAIL条件）が変わっていないか
- [ ] `nix flake check` が 29 PASS するか
- [ ] 既存の phase5-freeze tag を変更していないか

---

## 実行記録

| 日時 | タスク | コミット | flake check | 備考 |
|------|--------|---------|-------------|------|
| 2026-01-02 | T6.9.1: Phase6完了タグ | - | - | pending |
| 2026-01-02 | T6.9.2: requiredChecks差分検知 | - | - | pending |
| 2026-01-02 | T6.9.3: 提出パック作成 | - | - | pending |

---

## TDD表（Phase 6.9用）

| テスト名 | 判定基準 | ステータス |
|----------|----------|------------|
| release_tag_created | phase6-dod-2026-01-02 が存在する | pending |
| tag_points_to_correct_commit | tag → b7ab953 | pending |
| requiredChecks_hash_stable | requiredChecks ハッシュが計算可能 | pending |
| submission_pack_exists | phase6_submission_pack.md が存在 | pending |
| flake_check_29_pass | exit 0, 29 checks | pending |
