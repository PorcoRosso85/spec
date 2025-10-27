# ADR 0.1.0: spec/impl mirror構成・Flakes参照・日付タグ運用

- **Status**: Accepted
- **Date**: 2025-10-27 (JST)

## 1. 目的
- `specification/` ディレクトリを単一の参照入口 (Source of Truth) として定義する。
- 実装側は `specification/` 内の各エントリパス (entrypath) を Flakes 参照で取り込む。
- 参照時は日付タグでスナップショット化し、再現可能性を担保する。

## 2. entrypath ルール
- entrypath とは `specification/**` 直下に `flake.nix` を持つディレクトリ。
- 形式: `<layer>/[<scope>/]<name>`  (例: `apps/video`, `apps/core/video`, `contracts/http`, `infra/runtime`)
- 参照テンプレート例:

```nix
# 実装 → 仕様参照 (read-only)
inputs.spec.url = "git+https://github.com/<you>/<repo>?ref=<tag>&dir=<entrypath>";
```

## 3. 日付タグ運用
- 形式: 

```text
spec-<entrypath ('/'→'-')>-YYYYMMDD[-hhmm]
```

- 例: 
  - `spec-apps-video-20251026`
  - `spec-contracts-http-20251026-0930`

目的: どの仕様スナップショットを参照しているかを明示し、依存側の再現性を保証する。

## 4. mirror 方針
- `specification/` は設計・契約（公開IF、infra境界など）の唯一の参照元。
- 実装はこの参照を読むだけでよい。仕様のコピーや手書き同期は禁止。
- 新しい capability / entrypoint を増やすときは、まず `specification/` 側に entrypath を追加し、その直下に `flake.nix` を置く。

## 5. CI 最低ガード (概要)
- `nix flake lock --check` / `nix flake check` が通ること。
- `inputs.*.url` に `path:` を使わないこと。
- entrypath が `specification/**` に存在すること (＝未定義参照を禁止)。

## 6. 今後
- CI実行環境・runner標準化は **0.1.1** で扱う予定。
- partialブランチと自動統合ルールは **0.1.2** 以降で扱う予定。
