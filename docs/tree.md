# Repository Tree (Latest Structure Only)

**Last Updated**: 2025-10-28 (JST)

> 本ファイルは**構成計画のみ**を記述します。運用/規約/詳細は ADR を参照してください。

## ツリー概観

```text
repo/
├─ specification/                 # 仕様エントリのルート（唯一の参照入口）
│  ├─ apps/<name>/                # アプリ実装の入口（直下に flake.nix）
│  │  └─ flake.nix
│  ├─ contracts/<name>/           # 契約/プロトコル定義（実装コード不可）
│  │  └─ flake.nix
│  ├─ infra/<name>/               # 実行・配置・運用境界（IaC 等）
│  │  └─ flake.nix
│  ├─ interfaces/<name>/          # 外部公開IF（API/イベント/CLI 等）
│  │  └─ flake.nix
│  └─ domains/<name>/             # ドメインロジックの境界（仕様モジュール）
│     └─ flake.nix
├─ docs/
│  ├─ adr/                        # ADR群（詳細は各ADR本文へ）
│  │  └─ adr-*.md
│  └─ tree.md                     # ← 本ファイル（構成のみ）
└─ README.md
```

### Entrypath（最小）
- 形式: `<layer>/<name>`
- 各 entrypath の直下に `flake.nix` を配置する。
