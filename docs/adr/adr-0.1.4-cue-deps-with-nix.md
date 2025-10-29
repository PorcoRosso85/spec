# ADR 0.1.4: Nix × CUE 依存管理（vendor 一本化）

- **Status**: Proposed
- **Date**: 2025-10-28 (JST)
- **Relates**: ADR 0.1.0 / 0.1.1 / 0.1.2 / 0.1.3

## 1. コンテキスト
- `flake` の `inputs` は **取得と環境固定**まで。
- CUE の import 解決は **CUE の責務**。
- 以前は *vendor* と *registry* の両案を併記していた。

## 2. 決定（一本化方針）
- **採用**: **Vendor ブリッジ**
  - 開発: **symlink** で `cue.mod/pkg/<module>` に自動リンク（`nix develop` の `shellHook` で実行）。
  - 配布/CI: **copy 固定**（`nix run .#vendor` を実行し、`cue.mod/pkg` に実ファイルを配置）。
- **非採用**: **Registry 方式**（将来の再検討は可）。
  - 理由: 「**flake input + import だけ**」の体験に最も近いのは **vendor 自動化**であり、評価系（CUE）と取得系（Nix）の橋渡しが単純になるため。

## 3. 影響
- 開発者は **`flake.nix` に provider を追加**して **CUE で import を書く**だけ。
- 再現性: flake.lock で provider のリビジョンを固定。CI は copy で安定。

## 4. 実装ガイド（要点のみ）
- **Provider（配布側）**
  - `packages.<sys>.cueModule`（CUEモジュール純ツリー）、`apps.vendor`（vendor コマンド）、`devShells.default`（cue を pin）。
- **Consumer（依存側）**
  - `shellHook` で `cue.mod/pkg/<module>` に symlink を作成。
  - CI は `nix run .#vendor && cue fmt -n && cue vet -c && cue eval -c`。

## 5. 代替案（却下）
- **Registry（OCI/GHCR）**: 共有性は高いが、**flake input との自然連携が薄く**、CUE 側の操作（`cue mod tidy/get`）が必須になるため本方針では不採用。

## 6. ノート
- 相対 import は不可。**モジュールパス厳守**。
- `inputs.path:` は使用禁止（再現性確保）。

## 7. 表記指針（役割の扱い）
- **Provider/Consumer は文脈依存の相対概念**であり、
  **`docs/tree.md` には役割ラベルを記載しない**。
- 役割の説明・適用例は **本ADR** に集約し、tree は **構成のみ**を扱う。
