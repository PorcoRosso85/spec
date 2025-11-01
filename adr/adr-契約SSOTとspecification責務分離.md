# ADR: 契約SSOTとspecification責務分離

## 状態
Accepted / 2025-11-01 JST

## 背景
- このリポジトリでは、ドメイン/API/DBスキーマなどの「契約」が複数の場所に散りやすい。
- 過去 (0.1.x 系議論) では「spec が正 / impl はミラー」という運用を想定していたが、実装側に同じ定義を複製すると 2 系統がズレるリスクがあった。
- 最新方針では、契約を 1 か所にまとめ、それを apps / domains / interfaces / infra が読む。これを固定する。

## 決定
1. 契約 (API 定義 / DB スキーマ / ドメインイベント / gRPC IDL など) の唯一の正 (SSOT) は `contracts/ssot/` 以下とする。
   - ここには実行ロジックやアダプタ実装は置かない。契約そのものだけを置く。
   - `contracts/ssot/` は「仕様側の領域」と扱う。アプリケーション実装ではここを勝手に編集しない。
2. `specification/` ディレクトリは capability ごとの要求・期待 (SLO / ユースケース定義 / 公開インターフェースの期待など) を記述する場所として残すが、契約そのもの (スキーマ / IDL 本文) は複製しない。
   - 代わりに `contracts/ssot/...` への参照リンクを貼るだけにする。
   - `specification/index.md` のような巨大な 1 ファイルの SSOT は作らない。
3. 実装層 (`domains/`, `apps/`, `interfaces/`, `infra/adapters/`) は `contracts/ssot/` を読むことで入出力境界を合わせる。
   - 実装都合でローカルコピーを別に置くのは原則禁止。
4. 契約を変更したい場合は、まず `contracts/ssot/` を更新し、その理由と影響を新しい ADR (`adr-<目的>.md`) として追加する。
5. `docs/structure/index.md` は引き続き「リポ全体の構成・依存方向・境界ルール」の SSOT とし、そこから `contracts/ssot/` を「契約の正」として参照する。

## なぜこの決定か
- SSOT が 2 か所にある状態をやめたい。
- 「spec 側が正で impl はミラー」という運用だと、どちらが最終決定権を持つのか毎回判断コストが発生する。
- 開発者が読む場所を 1 か所 (`contracts/ssot/`) に決めれば、IDE・テスト・CI からも直接参照できてブレにくい。
- `specification/` は「この capability は何をしたいのか」「どんな SLO を守るべきか」を書く場として使い続ける。ただし契約本文は置かないことで、ドキュメントの分裂を防ぐ。
- `specification/index.md` を 1 枚の巨大SSOTにしない方針をはっきりさせ、コンフリクト源を減らす。

## 影響
- `contracts/ssot/` は「仕様ディレクトリ」とみなす。ここにアプリ固有のロジックを置くのは禁止。
- CI (`policy/cue` 等) は `contracts/ssot/` の外からこの契約を壊す依存方向を禁止していく。
- 以後の PR は、契約変更時に必ず新しい ADR を追加し、変更理由を残す。
- `specification/` に契約本文 (openapi.yaml / *.proto / schema.sql 等) をコピペした PR は基本 NG。

## TODO
- CI で `contracts/ssot/` と実装コードのズレ検出を自動化する (CUE 等でスキーマ整合性をチェックする)。
- `policy/cue` に「契約の正は `contracts/ssot/` 」というルールを明文化し、破ったら fail させる。
- `specification/` に契約本文を置こうとした場合は CI で弾く。
- 古い ADR を定期的に消す／新しい ADR で置き換える運用を正式化する。

## ステータス
Accepted / 2025-11-01 JST
