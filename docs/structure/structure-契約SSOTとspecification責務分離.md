# プロジェクト構造: 契約SSOTと specification 責務分離 (draft)

このファイルは、契約(contracts)の正をどこに置くか・`specification/` をどう扱うか・`docs/structure/index.md` をどう位置づけるかを明文化する。
本PRでは `docs/structure/index.md` 自体は変更しない。変更は adr/* 追加のみ。

---

## 状態
Draft / 2025-11-01 JST

## 1. ディレクトリ役割 (再定義)

- `contracts/ssot/`
  - API定義 / DBスキーマ / ドメインイベント / gRPC IDL などの契約を置く唯一の正(SSOT)。
  - 実行ロジックやアダプタ実装は禁止。ここは仕様レイヤとして扱う。
  - ここを変更する場合は必ず新しい ADR (`adr-<目的>.md`) を追加して、なぜ変えるかを説明する。

- `specification/`
  - capability単位での要求・期待を書く場所。SLO、ユースケースの目的、外部とどうつながるべきか等。
  - ただし契約本文(例: schema.sql / openapi.yaml / *.proto 等)は複製しない。
  - 契約本文は `contracts/ssot/` を参照するだけにする。
  - `specification/index.md` のような1枚巨大SSOTは作らない。理由: 常に衝突する単一ポイントになるのでスケールしない。

- `docs/structure/index.md`
  - リポジトリ全体の層構造・依存方向・infra分離・dist禁止/許可・R2前提などを示す唯一の正。
  - interfaces → apps → domains → contracts と apps → infra の依存方向ルールもここで宣言し、`policy/cue` がCIでこれを守る。
  - 既存方針どおり、このファイルは main 側の安定線として維持し、PRでは極力いじらない。

- `adr/`
  - 設計判断(ADR)を積む場所。1PRにつき1つ以上のADR追加を許可。古くなったADRは削除してよい。
  - 今回の2ファイル (`adr-契約SSOTとspecification責務分離.md`, `structure-契約SSOTとspecification責務分離.md`) は
    - 契約の正は `contracts/ssot/` に一本化する
    - `specification/` は契約本文を持たず、期待・SLO・ユースケース意図だけを持つ
    - `docs/structure/index.md` はリポ全体構造のSSOTとして維持する
    というルールを確定させる。

---

## 2. 依存とガード

- 依存方向はこれまでどおり:
  - `interfaces/` → `apps/` → `domains/` → `contracts/`
  - `apps/` → `infra/` (一方向)
  - 逆方向は禁止。
- `policy/cue/` はこの依存方向と命名・配置ルールをCIで検証する。
- 今後のTODO: `policy/cue/` で `contracts/ssot/` を「契約の正」として明文化し、
  実装側が勝手に別スキーマを名乗ったらCIでfailさせる。

---

## 3. 運用インパクト

1. 契約修正フローが一本化される。
   - まず `contracts/ssot/` を更新し、同じPRでADRを追加する。
   - 実装コード側(`apps/`, `domains/`, `interfaces/`, `infra/adapters/`)はその契約に従う。
2. `specification/` は引き続き残すが、そこは期待・SLO・結合方針を書く場。
   - 「このサービスはこう振る舞うべき」が書かれる。
   - ただし実際の入出力のフォーマット定義そのものは `contracts/ssot/` を参照する。
3. `docs/structure/index.md` は今後も main の安定線として生き続ける。
   - リポ全体の責務分割・依存制約・infra境界の説明はここが正。
   - 新しい構造案や変化は `adr/structure-*.md` 側に積み、必要に応じて main の `docs/structure/index.md` に反映する。

---

## 4. TODO (このPRの後にやるべきこと)

- CIで `contracts/ssot/` を唯一の契約ソースとして扱うルールを実装する。
  - 例: `openapi.yaml` / `*.proto` / `schema.sql` の差分を検証し、`apps/` や `domains/` に勝手な別定義がいないかをチェックする。
- `specification/` に契約本文を置いた場合はCIで即failさせる。
- `specification/` からも `contracts/ssot/` を参照するリンクテンプレを用意して、迷いなく誘導できるようにする。
- ADRの棚卸しルールを決める (古いものを消す or supersededマークを付ける)。

---

## 5. まとめ
- 契約(入出力・DBスキーマ・IDL)の正は `contracts/ssot/` に一本化する。
- `specification/` は期待・SLO・つなぎ方を記述するだけで、契約本文は持たない。
- `docs/structure/index.md` はリポ全体の層構造・依存・infra境界のSSOTとして引き続き維持する。
- 変更は必ずADRに残す。

Draft / 2025-11-01 JST
