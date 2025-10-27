# Repository Tree (Latest Design Only)

> このリポジトリは仕様(ADR/ツリー)の単一の参照ソース。実装リポはここを読む。
> 実装手順やCIジョブ詳細は書かず、**構成だけ**を宣言する。

**Last Updated**: 2025-10-28 (JST)
**対応ADR**:
- docs/adr/adr-0.1.0-spec-impl-mirror-flake-tag.md
- docs/adr/adr-0.1.1-ci-runner-blacksmith.md
- docs/adr/adr-0.1.3-ops-clarify.md

---

## ツリー概観 (0.1.3時点)

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
│  │  ├─ adr-0.1.1-ci-runner-blacksmith.md
│  │  └─ adr-0.1.3-ops-clarify.md
│  └─ tree.md                     # このファイル (最新構成の単一真実)
└─ README.md                      # リポ説明
```

---

## 備考
- **運用詳細は ADR を参照**（0.1.0/0.1.1/0.1.3）。
- **Blacksmith導入でもディレクトリ構成は不変**。
