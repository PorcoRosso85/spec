# Repository Tree (Latest Structure Only)

**Last Updated**: 2025-10-28 (JST)

> 本ファイルは**構成計画のみ**を記述します。運用/規約/詳細は ADR を参照してください。

## ツリー概観

```text
repo/
├─ specification/                 # 仕様エントリのルート（唯一の参照入口）
│  ├─ apps/<name>/                # 各 entrypath は直下に flake.nix を置く
│  │  └─ flake.nix
│  ├─ contracts/<name>/
│  │  └─ flake.nix
│  ├─ infra/<name>/
│  │  └─ flake.nix
│  ├─ interfaces/<name>/
│  │  └─ flake.nix
│  └─ domains/<name>/             # ドメインロジックの境界
│     └─ flake.nix
├─ docs/
│  ├─ adr/                        # ADR群（詳細は各ADR本文へ）
│  │  └─ adr-*.md
│  └─ tree.md                     # ← 本ファイル（構成のみを記す）
└─ README.md
```

### Entrypath（最小）
- 形式: `<layer>/<name>`
- 各 entrypath の直下に `flake.nix` を配置する。
