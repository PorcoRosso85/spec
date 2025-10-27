# ADR 0.1.2: Tree統合と最小ガード（partialブランチ + CI自動統合）

- **Status**: Accepted
- **Date**: 2025-10-27 (JST)
- **Relates**: ADR 0.1.0（参照入口/Flakes/日付タグ）, ADR 0.1.1（CI基盤: Blacksmith）

## 1. 決定
1) **Tree統合**：`specification/` を本体ツリーに常設し、Entrypoints の独立章を廃止。
2) **entrypath 規約（最小）**：`<layer>/[<scope>/]<name>` 直下に `flake.nix` を置く。
3) **partial ブランチ**：`partial/<entrypath('/'→'-')>` を標準。**同一 entrypath は並行1本**。
4) **CI最小ガード（ci-guard）**：
   - `nix flake lock --check` / `nix flake check`
   - `inputs.*.url` の `path:` 禁止
   - entrypath の存在確認（`specification/**` に `flake.nix` があること）
5) **自動統合**：`main` は branch protection。**required checks = ci-guard** を必須にし、緑なら自動マージ可。
6) **実行基盤**：CI runner は **Blacksmith** を標準（ADR 0.1.1）。

## 2. 理由
- Entrypoints を tree 本体へ統合すると、構造と規範の参照点が一つになり運用が簡潔。
- partial + 最小ガードで、**小さく安全に**進めつつ、`main` の安定と lead time を両立。

## 3. 影響
- `docs/tree.md` の Entrypoints 章を統合観点に更新。
- 追加でルールセット/CI雛形は 0.1.3 で詳細化予定。

## 4. 非スコープ（0.1.3で対応）
- SLO/コスト指標、entrypath 正規表現・重複検出、失敗メッセ定型、タグ掃除ルール、URL命名テンプレ。

## 5. 移行
- 直ちに `specification/` を作成/維持。古い Entrypoints 記述は削除。
- 既存 PR は `partial/<entrypath>` 命名へ揃え、ci-guard を通過。
- 例外 runner は期限付きで認める（次版で見直し）。

## 6. リスクと対応
- **命名ゆれ/並行衝突**：同一 entrypath は並行 1 本、PR テンプレで注意喚起。
- **ガード不足**：0.1.3 で正規表現/重複/タグGCを導入して強化。
