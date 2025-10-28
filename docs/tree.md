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
├─ specification/                 # 仕様エントリのルート (唯一の参照入口)
│  ├─ apps/<name>/                # 直下に flake.nix を持つ entrypath（apps は <name> に統一）
│  ├─ contracts/<name>/           # 契約/プロトコル (実装禁止)
│  ├─ infra/<name>/               # 実行・配置・運用境界
│  ├─ interfaces/<name>/          # 外部公開IF
│  └─ domains/<name>/             # ドメインロジックの境界
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

---

## 備考
- **運用詳細は ADR を参照**（0.1.0/0.1.1/0.1.2/0.1.3/0.1.4）。
- **Blacksmith導入でもディレクトリ構成は不変**。

---

## 更新履歴
- 2025-10-28: ADR 0.1.4 追加 (Nix×CUE 依存管理を定義)。
- 2025-10-27: ADR 0.1.2 追加 (Tree統合、partialブランチ、最小ガード/自動統合の方針)。
- 2025-10-27: ADR 0.1.1 追加 (CI実行基盤をBlacksmith標準化し、最低ガードをBlacksmith上で必須化)。
- 2025-10-27: ADR 0.1.0 追加 (spec/impl mirror, Flakes参照, 日付タグ導入)。
