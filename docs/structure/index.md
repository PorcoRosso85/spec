# Repository Structure / 契約まとめ

このリポジトリは "spec (供給側)" を公開し、実装側がそれを vendor して使うことを前提にする。

## 1. ルート直下
- `docs/` : 仕様と運用のドキュメント。ADRもここ。
- `specification/` : 実際に配布するCUEモジュール郡（=プロダクトに取り込まれる素材）。

## 2. docs/ 下
- `docs/adr/` : 変更の意思決定ログ(ADR)。過去の判断も消さずに残す。
- `docs/structure/` : この構成・責務を説明するドキュメント（このファイル）。

特に `docs/adr/0.1.6-machine-hardening-nix-cue.md` は、
Nix×CUE で "人手の運用ルール" を禁止し、
CIで機械的に壊れにくさを保証する方針を定義している。

## 3. specification/ 下
`specification/` はすべての provider / spec を一覧化するカタログ。
実装側はここを vendor して使う。

- `specification/index.json` : 機械可読のカタログ。`nix run .#index` で自動生成される。
- `specification/README.md` : 契約の人間向けサマリ。
- `specification/<layer>/<spec>/` : 各プロバイダ (=1つの仕様単位)。例: `domain-layer/payment/` など。
    - `flake.nix` : このspecが外部に約束する3つだけをエクスポートする。
        - `packages.${system}.cueModule`
        - `apps.vendor`
        - `devShells.${system}.default`
    - `cue/` : ピュアCUEソース（相対import禁止がCIで担保される）。
    - `checks/` : このspec専用のスモーク/整合チェック（Nixから叩かれるだけ）。

## 4. CI の考え方
- すべて Nix 経由 (`nix flake check` / `nix develop -c ...`) で実行できること。
- 外部サービス依存や人間の手順は不可。
- Fail時には "次の1手" を表示する。

## 5. 方針キーワード
- YAGNI: いらないものは足さない。対象プラットフォームも2つだけ。
- KISS: ルールは単純に。読みやすく。
- DRY: index.json等は自動生成し、手書きの重複を残さない。
- SRP/SOLID: 各specは vendor 供給物としての単一責務に集中する。

# リポジトリ構成 / structure

## 1. このドキュメントの役割
- このファイル docs/structure/index.md がリポジトリ構成の単一の正 (SSOT)。
- ここに書かれていない置き場は基本的に作らない / 既存なら削除検討対象。
- ADR本文にフルのツリーは書かない。このファイルだけが最新ツリー。
- 更新日は手で書き換えること。

**Last Updated**: 2025-10-28 (JST)

## 2. 現在のツリー（宣言）
> 凡例: # = コメント（各行の責務説明）


```text
catalog/   事業カタログ 責務スロット全集合
adr/       意思決定ログ なぜそう置くか
skeleton/  今回の形と spec
src/       実装本体 skeleton で許された場所だけ
```

index.md 自体は 常に最新の正 を示す義務を持つ
このファイルが古い状態は drift であり CI で検知対象になる予定
