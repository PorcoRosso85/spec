# Phase 1: 参照整合（Reference Integrity）

## Phase 0 → Phase 1 への遷移

Phase 0 で確立した基礎（FQDN+@v0 module、統一 import、smoke test Green）の上に、
参照整合を機械化することで「人間の暗黙運用」を排除し、CI で自動検知します。

---

## Phase 1 Goal

**すべての feat/env/adapter/mapping/rules の相互参照が、CI で自動的に検証される状態**

- 参照切れを検知（URN 不在、ファイル不在）
- 循環依存を検知（feat → deps → ... → feat）
- 重複を検知（feat-id 重複、env-id 重複）
- 命名規約を強制（kebab-case）

---

## Phase 1 Minimum Scope

### 1. `spec:lint` コマンド実装

**責務**: spec/ 全体を走査し、以下を検知

```bash
cue eval ./spec/... | validate_lint_rules
```

または

```bash
spec:lint [--check] [--fix]
```

**検査項目**:

| 検査 | 対象 | 落ちる条件 | 出力例 |
|-----|------|---------|--------|
| feat-id 重複 | `spec/urn/feat/*/` | 同じ `id` が 2 回以上 | `ERROR: feat 'urn:feat:foo' defined in 2 files` |
| env-id 重複 | `spec/urn/env/*/` | 同じ `id` が 2 回以上 | `ERROR: env 'urn:env:dev' defined in 2 files` |
| deps 循環 | `spec/urn/feat/*/feature.cue` の `deps:` | A→B→C→A | `ERROR: circular deps feat:A → feat:C` |
| 参照切れ | adapter/mapping/rules 内の URN 参照 | 存在しない feat/env | `ERROR: unknown feat 'urn:feat:unknown'` |
| 命名規約 | slug/feat-id/env-id | kebab-case 違反 | `ERROR: slug 'My-Feat' must be kebab-case` |

---

### 2. Registry 統合ビュー（`spec/registry.cue`）

**責務**: spec 全体への唯一の入口

```cue
package registry

import "github.com/porcorosso85/spec-repo/spec/urn/feat"
import "github.com/porcorosso85/spec-repo/spec/urn/env"
import "github.com/porcorosso85/spec-repo/spec/adapter/git/repo"
import "github.com/porcorosso85/spec-repo/spec/adapter/git/branch"
import "github.com/porcorosso85/spec-repo/spec/adapter/session/rules"
import "github.com/porcorosso85/spec-repo/spec/mapping/feat-external"
import "github.com/porcorosso85/spec-repo/spec/external/std"

// 全feat・env・adapter・mapping・rules を集約
feats: feat.feature
envs: env.environment
repos: repo.repos
branches: branch.branches
sessions: rules.sessions
mappings: mapping.mappings
externals: std.standards
```

**利点**:
- 生成ツールが `spec/registry.cue` だけを eval すれば全構造が見える
- 新しい feat/env/adapter を追加した時、registry に自動反映（module import system）

---

### 3. 命名規約エンフォース（kebab-case）

CUE の正規表現で全 slug/id をチェック:

```cue
// spec/schema/feature.cue に追加
#Feature: {
    slug: string & =~"^[a-z0-9]+(-[a-z0-9]+)*$"  // 既に存在
    deps: [...string] & [for d in deps if d =~ "^urn:feat:[a-z0-9-]+$"]  // 新規
}
```

---

## Phase 1 DoD（Definition of Done）

| チェック | 実装 | 検証方法 |
|--------|------|--------|
| `spec:lint` 存在 | bash/Go/Bun で実装 | `spec:lint --check` exit 0 |
| feat-id 重複検知 | lint ロジック | 2 つの同じ id で lint fail |
| deps 循環検知 | グラフ走査 | 循環構造で lint fail |
| 参照切れ検知 | URN 照合 | 存在しない URN で lint fail |
| 命名規約強制 | CUE regexp | kebab-case 違反で lint fail |
| `spec/registry.cue` | 作成 | `cue eval spec/registry.cue` exit 0 |
| CUE vet 常時 Green | 型追加 | `cue vet ./spec/...` exit 0 |
| CI 統合 | GitHub Actions | PR で `spec:lint` 自動実行 |

---

## Implementation Order (Baby Steps)

1. **Step 1**: `spec/registry.cue` 作成（最小版）
2. **Step 2**: CUE schema に `deps` フィールド追加 + vet 確認
3. **Step 3**: `spec:lint` 最小版実装（feat-id 重複検知のみ）
4. **Step 4**: lint を CI に統合（`.github/workflows/spec-lint.yml`）
5. **Step 5**: 循環検知・参照切れ検知を lint に追加
6. **Step 6**: 命名規約を lint に追加

---

## 疑問点/決めるべき点

1. **lint の実装言語** - bash, Go, CUE, Bun?
   - **推奨**: bash（軽量、ツール依存最小） or Go（速度・保守性）
2. **CI 失敗の扱い** - `continue-on-error` か strict か?
   - **推奨**: strict（Phase 1 では observation mode ではなく enforcement）
3. **deps フィールド** - 全 feat に必須か、任意か?
   - **推奨**: 任意（deps がない feat も許可）

---

## まとめ

Phase 1 の目標は **「CI で参照整合を自動検知し、人間レビューを減らす」** ことです。
上の 6 ステップを順に実装すれば、フェーズ 1 の DoD が達成できます。
