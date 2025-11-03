# リポジトリ構造と現在の正 (SSOT の入口)

このファイルはリポ全体の現在の構成ビューと、正(SSOT)をどこで管理するかの入口。

このリポでは正を分割して管理する:
- docs/catalog/**        … 責務スロットの全集合 (タンス)。ここにない責務スロットは存在しない扱い。
- docs/adr/**            … どのスロットを使う / どこに置く / やめる、となぜそう決めたか。意思決定ログ。
- docs/structure/.gen/   … skeleton.json / traceability.json
    - skeleton.json      … slot.id -> 配置パス の唯一の正。ここにない場所にコードを置くのは禁止。
    - traceability.json  … 要求→責務→配置→検証→証跡 の鎖。CIが自動生成し、人間編集禁止。

実装コード (`apps/`, `domain/`, `infra/`, `interfaces/`, `features/` 等) は skeleton.json の指示どおりにだけ増やしてよい。

より詳しい運用ルール・CIがブロックする/しない境界は
`structure-1人AI体制で壊さず拡張し続ける.md`
を参照。

この index.md 自体が古いままになることは drift とみなす。
drift を検知したら修正PRで必ずここを更新する。
