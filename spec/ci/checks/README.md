# ci/checks - CI検査ルールの SSOT

## 概要

このディレクトリは **CI が参照する検査ルール** を定義します。

- CUE の制約機能を使って不変条件を記述
- `cue vet` で検証可能
- 将来的には専用 CI スクリプトで拡張可能

## 検査ルール一覧

1. **dry.cue** - DRY保証
   - すべての `urn/feat/*/feature.cue` で `id == "urn:feat:" + slug`

2. **1urn1repo.cue** - 1urn1feature1repo保証
   - `adapter/git/repo` で同じ URN が二重参照されていない

3. **repo_consistency.cue** - repo整合性
   - `artifact.repoEnabled == true` な機能URNは必ず `adapter/git/repo` に存在

4. **branch_consistency.cue** - branch整合性
   - `adapter/git/branch` の name の "+" 前半が対応する slug と一致

## 実行方法

```bash
# 全体評価
cue eval ./spec/...

# 検証実行
cue vet ./spec/ci/checks/... ./spec/...
```

## 野良の扱い

- **SSOT に出てこない repo/branch/session** は検査対象外（見に行かない）
- この原則を明文化し、管理対象を明確にする
