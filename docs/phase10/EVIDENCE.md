# Phase 10 監査可能な証拠

## 最終更新
コミット: e9b40067dc679c3f35f45bcead8b04a675353a4e

---

## U1: 重複検出の定義

### ファイル
`spec/ci/detector/uniq.cue`

### 重複の定義
- 一意性保証対象: `feat.id`（URN） と `feat.slug`（kebab-case識別子）
- 検出ロジック: O(n^2) pairwise比較

### 該当箇所（lines 31-54）
```nix
_duplicateIDsRaw: [
    for i, f1 in input.feats
    for j, f2 in input.feats
    if i < j && f1.id == f2.id { f1.id }
]

_duplicateSlugsRaw: [
    for i, f1 in input.feats
    for j, f2 in input.feats
    if i < j && f1.slug == f2.slug { f1.slug }
]
```

### 検証
```bash
nix build .#checks.x86_64-linux.integration-verify-dod4 --no-link
```

---

## U2: DoD5/DoD6 FAILログ

### DoD5: 禁止input検出
```bash
nix eval --impure --expr '
let pkgs = import <nixpkgs> {};
    dod5 = import ./nix/lib/dod5-feat-inputs.nix { inherit pkgs; };
    testLock = pkgs.writeText "invalid.lock" (builtins.toJSON {
      nodes.root.inputs = { nixpkgs = "nixpkgs"; spec = "spec"; forbidden-input = "forbidden"; };
    });
in dod5.mkCheck testLock
' 2>&1 | grep -A5 "DoD5 violation"
```

出力:
```
error: DoD5 violation: forbidden inputs detected
  Allowed: nixpkgs spec
  Forbidden: forbidden-input
  Fix: Remove forbidden inputs from flake.lock
```

### DoD6: 欠落output検出
```bash
nix eval --impure --expr '
let pkgs = import <nixpkgs> {};
    dod6 = import ./nix/lib/dod6-expected-outputs.nix { inherit pkgs; };
in dod6.mkCheck {
  expected = [ "default" "dev" "missing-output" ];
  actual = [ "default" "dev" ];
  system = "x86_64-linux";
}
' 2>&1 | grep -A6 "DoD6 violation"
```

出力:
```
error: DoD6 violation: missing expected outputs
  Expected: default dev missing-output
  Actual: default dev
  Missing: missing-output
  System: x86_64-linux
  Fix: Add missing outputs to feat-repo flake.nix
```

---

## U3: CUE型定義と契約導線

### schema.#Feature の必須フィールド
1. `slug: string` - kebab-case識別子
2. `id: "urn:feat:\(slug)"` - 自動導出
3. `artifact.repoEnabled: bool` - repo所持フラグ

### URN→契約→CI check 導線
```
spec/urn/feat/{slug}/feature.cue
    ↓ CUE型定義
spec/schema/feature.cue (#Feature)
    ↓ 検証ロジック
spec/ci/detector/uniq.cue
    ↓ Nix実装
nix/lib/dod5-feat-inputs.nix
nix/lib/dod6-expected-outputs.nix
    ↓ CI実行
nix flake check
```

---

## U4: 最小feat例

### 追加手順
```bash
mkdir -p spec/urn/feat/minimal-example

cat > spec/urn/feat/minimal-example/feature.cue << 'CUE'
package feat
import "github.com/porcorosso85/spec-repo/spec/schema"

feature: schema.#Feature & {
    slug: "minimal-example"
    artifact: repoEnabled: false
}
CUE

# 検証
nix build .#checks.x86_64-linux.integration-verify-dod4 --no-link
cue eval ./spec/urn/feat/minimal-example/...
cue vet ./spec/urn/feat/minimal-example/...
```

---

## 検証コマンド一覧

```bash
# 全テスト実行
nix build .#checks.x86_64-linux.{test-dod5-positive,test-dod6-positive,integration-verify-dod4}

# DoD5 FAIL確認
nix eval --impure --expr '...' 2>&1 | grep "DoD5 violation"

# DoD6 FAIL確認
nix eval --impure --expr '...' 2>&1 | grep "DoD6 violation"

# CUE検証
cue vet ./spec/urn/feat/...
cue vet ./spec/ci/checks/...
```
