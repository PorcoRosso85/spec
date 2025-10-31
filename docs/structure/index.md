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