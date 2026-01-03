# Phase 7 WORK_ORDER v1（CI要件配信）

## GOAL
spec-repo が「CI要件（requiredChecks）を配信物」として公開し、他repoが `repo.cue` を持たなくても CI 要件を参照できる状態にする。

## 基準点
- **HEAD**: 0550d1e
- **flake check**: 29 checks, exit 0
- **tags**: phase5-freeze-2026-01-02, phase6-dod-2026-01-02

---

## Decomposition

### Phase 7.1: 配信物生成（JSON + SHA256）

**目的**: requiredChecks を JSON 形式で配信可能なファイルにエクスポート

**対象ファイル**: `nix/lib/ci-requirements-export.nix`

**出力**: `packages.${system}.ci-requirements` = JSON + sha256

**実装方針**:
1. `repo.cue` から requiredChecks を抽出（Phase 6 で確立したフォーマット非依存方式）
2. JSON 形式で出力
3. SHA256 ハッシュを計算・併記

**DoD**:
- [ ] `nix build .#ci-requirements` で JSON + sha256 が生成される
- [ ] 生成物が `repo.cue` の requiredChecks と一致する

### Phase 7.2: 一致チェック（flake check 統合）

**目的**: 配信物が `repo.cue` と一致することを CI で保証

**対象ファイル**: `nix/checks/ci-requirements-consistency.nix`

**実装方針**:
1. 配信物（JSON）を読み込む
2. `repo.cue` から requiredChecks を抽出
3. 両者を比較・差分があれば FAIL

**DoD**:
- [ ] `nix flake check` が PASS（29+1 checks）
- [ ] 差分検知が正確に動作する

### Phase 7.3: 互換ルール定義

**目的**: 破壊変更条件を明示し、safe upgrade を保証

**対象ファイル**: `docs/phase7-compatibility.md`

**内容**:
- SemVer ルール（メジャーバージョン変更時のみ破壊）
- 配信物の更新条件
- 移行ガイド

**DoD**:
- [ ] 互換ルールが文書化されている

### Phase 7.4: 提出パック作成

**目的**: Phase 7 の完了を証跡として固定

**対象ファイル**: `phase7_submission_pack.md`

**内容**:
- 凍結点（tag/sha）
- 再現方法
- 配信物の検証方法

**DoD**:
- [ ] `phase7_submission_pack.md` が存在する

---

## 配信物のフォーマット

### ci-requirements.json

```json
{
  "version": "1.0.0",
  "requiredChecks": [
    "dod0-factory-only",
    "dod0-flake-srp",
    ...
  ],
  "deliverablesRefs": [
    "spec/ci/contract",
    ...
  ]
}
```

### ci-requirements.sha256

```
1e841880918c181f84034b1cfde17e44e575eea937ef899891312f6fac6b436d
```

---

## フォーマット非依存抽出（Phase 6 で確立）

```bash
# requiredChecks抽出（コメント除去＋要素抽出）
sed -n '/requiredChecks:/,/^[[:space:]]*\]/p' repo.cue \
  | sed 's,//.*$,,' \
  | grep -oE '"[^"]+"' \
  | tr -d '"' \
  | sort
```

---

## REVIEW_CHECKLIST v1（Phase 7用）

各タスク完了前に確認：

- [ ] mock-spec という語が出ていないか
- [ ] 配信物が `repo.cue` 由来のみ（外部参照を含まない）
- [ ] `nix flake check` が PASS するか
- [ ] 既存の phase5/phase6 tag を変更していないか

---

## 実行記録

| 日時 | タスク | コミット | flake check | 備考 |
|------|--------|---------|-------------|------|
| 2026-01-02 | T7.1: 配信物生成 | - | - | pending |
| 2026-01-02 | T7.2: 一致チェック | - | - | pending |
| 2026-01-02 | T7.3: 互換ルール | - | - | pending |
| 2026-01-02 | T7.4: 提出パック | - | - | pending |

---

## TDD表（Phase 7用）

| テスト名 | 判定基準 | ステータス |
|----------|----------|------------|
| ci_requirements_export_exists | nix build .#ci-requirements でJSON+sha256生成 | pending |
| ci_requirements_export_matches_repo_cue | 生成物が repo.cue の requiredChecks と一致 | pending |
| flake_check_30_pass | exit 0, 30 checks | pending |
| phase7_compatibility_defined | docs/phase7-compatibility.md が存在 | pending |
| phase7_submission_pack_exists | phase7_submission_pack.md が存在 | pending |
