# ADR 0.1.4: Nix × CUE 依存管理（vendor / registry / bridge）

- **Status**: Proposed
- **Date**: 2025-10-28 (JST)
- **Relates**: ADR 0.1.0（参照入口/最低ガード）, ADR 0.1.1（CI基盤）, ADR 0.1.2（Tree/Guard）, ADR 0.1.3（運用明確化）

## 1. コンテキスト
- `flake` の `inputs` は **取得と環境固定まで**。
- **CUE の import 解決は CUE の責務**（`cue.mod/pkg/<module>` への vendor か、OCI レジストリ経由）。
- 誤解を避け、両者の責務分離を**規約として明文化**する。

## 2. 決定（サマリ）
1) **依存側の選択肢を3通りに固定**:
   - **A: vendor-symlink（開発）** — devShell で symlink を自動作成。
   - **B: vendor-copy（CI/配布）** — `nix run .#vendor` でコピー固定。
   - **C: registry（再利用）** — GHCR 等の OCI レジストリで `cue mod publish/get/tidy`。
2) **提供側の出力規約**:
   - `packages.<sys>.cueModule` — CUE モジュールツリーを `$out` に展開。
   - `apps.vendor` — 依存側の `cue.mod/pkg/<module>` に symlink/copy を作る補助。
   - `templates.consumer` — 最小雛形（shellHook で symlink）。
   - `devShells.default` — `cue`（必要なら `go`）のバージョン pin。
3) **禁止/必須**:
   - **相対 import 禁止**（CUE）／**モジュールパス厳守**。
   - `inputs.path:` の使用禁止（再現性確保）。

## 3. 影響
- **再現性と導入容易性が向上**（Nixで取得を固定、CUEで依存を固定）。
- 依存側が常に**明示の vendor or registry** を踏むため、解決経路が透明。

## 4. 代替案と理由
- 依存側で `PYTHONPATH` 的な一時対処を行う案は**却下**（CUEでは無関係・再現性低下）。
- flake だけで自動 import させる案は**不可**（設計上の責務外）。

## 5. 参考: ツリー例
### 提供側（provider）
```text
provider/
├─ flake.nix              # packages.cueModule / apps.vendor / templates.consumer / devShells
└─ cue/                   # CUE module（例: example.com/libs/mathx）
```

### 依存側（consumer）
```text
consumer/
├─ flake.nix              # inputs.provider.url = "github:org/provider"（alias/pin 推奨）
├─ cue.mod/
│  ├─ module.cue          # 例: "example.com/app"
│  └─ pkg/
│     └─ example.com/libs/
│        └─ mathx -> /nix/store/...-cueModule   # symlink or copy
└─ main.cue               # import "example.com/libs/mathx"
```

## 6. マイグレーション
- 既存プロジェクトは、開発中は **A: symlink**、リリース/CI は **B: copy** へ誘導。
- 組織内共有が増えたら **C: registry**（GHCR 推奨）へ移行。

## 7. 追記（運用）
- CI の最低チェックは ADR 0.1.2/0.1.3 に委譲。
- 本ADRは**構成計画に影響しない**（tree.md は構成のみを保持）。
