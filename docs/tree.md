# Repository Tree (Latest Design Only)

> このリポジトリは仕様(ADR/ツリー)の単一の参照ソース。実装リポはここを読む。
> 実装手順やCIジョブ詳細は書かず、**構成だけ**を宣言する。

**Last Updated**: 2025-10-28 (JST)
**対応ADR**:
- docs/adr/adr-0.1.0-spec-impl-mirror-flake-tag.md
- docs/adr/adr-0.1.1-ci-runner-blacksmith.md
- docs/adr/adr-0.1.2-tree-unify-and-guards.md
- docs/adr/adr-0.1.3-ops-clarify.md
- docs/adr/adr-0.1.4-cue-deps-with-nix.md

---

## ツリー概観 (0.1.4時点)

```text
repo/
├─ specification/                 # **Provider**: 提供側（配布用flake/契約の単一入口）
│  ├─ apps/<name>/                # **Consumer**: アプリ実装（直下に flake.nix）
│  ├─ contracts/<name>/           # **Provider**: 契約/プロトコル（実装コード不可）
│  ├─ infra/<name>/               # **Consumer**: 実行・配置・運用境界
│  ├─ interfaces/<name>/          # **Consumer**: 外部公開IF
│  └─ domains/<name>/             # **Consumer**: ドメインロジック境界
├─ docs/
│  ├─ adr/                        # ADR群 (0.1.xシリーズなど)
│  │  ├─ adr-0.1.0-spec-impl-mirror-flake-tag.md
│  │  ├─ adr-0.1.1-ci-runner-blacksmith.md
│  │  ├─ adr-0.1.2-tree-unify-and-guards.md
│  │  ├─ adr-0.1.3-ops-clarify.md
│  │  └─ adr-0.1.4-cue-deps-with-nix.md
│  └─ tree.md                     # このファイル (最新構成の単一真実)
└─ README.md                      # リポ説明
```

> **本リポの基本方針（ADR 0.1.4）**: Consumer は Provider の CUE を **vendor（`cue.mod/pkg/<module>`）**で取り込む。**registry は採用しない**。

---

## 備考
- **運用詳細は ADR を参照**（0.1.0/0.1.1/0.1.2/0.1.3/0.1.4）。
- **Blacksmith導入でもディレクトリ構成は不変**。

---

## 更新履歴
- 2025-10-28: ADR 0.1.4 更新（vendor 一本化）。
- 2025-10-27: ADR 0.1.2 追加 (Tree統合、partialブランチ、最小ガード/自動統合の方針)。
- 2025-10-27: ADR 0.1.1 追加 (CI実行基盤をBlacksmith標準化し、最低ガードをBlacksmith上で必須化)。
- 2025-10-27: ADR 0.1.0 追加 (spec/impl mirror, Flakes参照, 日付タグ導入)。
