# ADR 0.1.0: spec/impl mirror + Flakes参照 + 日付タグ

- **Status**: Accepted
- **Date**: 2025-10-27 (JST)

## 1. 目的
- 仕様リポ（本リポ）を**単一の参照源（SSOT）**とし、実装リポは Flakes で参照する。

## 2. エントリ規約（最小）
- entrypath 形式: **`<layer>/<name>`**（appsは `apps/<name>` に統一）
- 各 entrypath 直下に `flake.nix` を置くこと。

## 3. Flakes 参照とタグ運用
- 実装側は entrypath を Flakes で参照し、**日付タグ**でバージョン固定する。
- タグ形式: 
  - `spec-<entrypath('/'→'-')>-YYYYMMDD[-hhmm]`

## 4. 最低ガード（骨子）
- `nix flake lock --check` / `nix flake check`
- `inputs.*.url` に `path:` を使わない
- entrypath 実在（`specification/**` 配下に `flake.nix` がある）

## 5. ミラー方針
- 仕様 = 本リポ。実装は参照のみ。ズレた場合は本リポを正とする。
