# Repository Tree (Latest Design Only)

> このリポジトリは仕様(ADR/ツリー)の単一の参照ソース。実装リポはここを読む。
> 実装手順やCIジョブ詳細は書かず、構成と責務だけを宣言する。

**Last Updated**: 2025-10-27 (JST)
**対応ADR**:
- docs/adr/adr-0.1.0-spec-impl-mirror-flake-tag.md
- docs/adr/adr-0.1.1-ci-runner-blacksmith.md

---

## ツリー概観 (0.1.1時点)

```text
repo/
├─ specification/                 # 仕様エントリのルート (唯一の参照入口)
│  ├─ apps/[<scope>/]<name>/      # 直下に flake.nix を持つ entrypath
│  ├─ contracts/<name>/           # 契約/プロトコル (実装禁止)
│  ├─ infra/<name>/               # 実行・配置・運用境界
│  ├─ interfaces/<name>/          # 外部公開IF
│  └─ domains/<name>/             # ドメインロジックの境界
├─ docs/
│  ├─ adr/                        # ADR群 (0.1.xシリーズなど)
│  │  ├─ adr-0.1.0-spec-impl-mirror-flake-tag.md
│  │  └─ adr-0.1.1-ci-runner-blacksmith.md
│  └─ tree.md                     # このファイル (最新構成の単一真実)
└─ README.md                      # リポ説明
```

---

## ルール骨子 (抜粋)
1. `specification/` が参照点。ここに無いものは未定義扱い。
2. entrypath は `<layer>/[<scope>/]<name>` で表し、直下に `flake.nix` を必ず置く。
3. 実装側は entrypath を Flakes で参照し、日付タグ (`spec-...-YYYYMMDD[-hhmm]`) でバージョン固定する。
4. CIは Blacksmith runner を標準とし、`flake check` 等の最低ガードを必須化する（ADR 0.1.1）。
5. Blacksmith 以外のrunnerを使う場合、PR本文に理由・期限・代替runnerを書く（例外扱い）。

---

## 更新履歴
- 2025-10-27: ADR 0.1.1 追加 (CI実行基盤をBlacksmith標準化し、最低ガードをBlacksmith上で必須化)
- 2025-10-27: ADR 0.1.0 追加 (spec/impl mirror, Flakes参照, 日付タグ導入)
