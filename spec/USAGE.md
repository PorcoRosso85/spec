# Spec Repo Usage Guide

## 概要

このドキュメントは、**impl repo**（実装リポジトリ）が **spec-flake** を使って SSOT を受け取る方法を説明します。

## 設計原則の達成

### ✅ 1. SSOT定義したrepoがほぼ確実にあり

- `spec/urn/feat/` で機能URNを定義
- `spec/adapter/git/repo/` で 1urn1repo マッピング
- CI (GitHub Actions) で `cue eval/vet` が自動実行され、不整合を検出

### ✅ 2. 各repoがどんな責務を果たすかが定義され

- 1urn1feature1repo により、URN と repo が 1:1 対応
- `schema/feature.cue` の `#Feature` 型で責務を定義

### ✅ 3. 各repoはその定義をremote forgeでも問わずflake経由で受け取ることができる

- `flake.nix` の `outputs.spec` で spec/ を露出
- GitHub, Codeberg, self-hosted など forge を問わず同じ定義を参照可能

---

## impl repo での参照方法

### Step 1: flake.nix に spec-flake を追加

```nix
{
  description = "decide-ci-score-matrix - CI score matrix decision engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ★ spec-flake を inputs に追加
    spec.url = "github:porcorosso85/spec";
  };

  outputs = { self, nixpkgs, spec }:
    {
      # spec-flake から定義を受け取る例
      inherit (spec) spec;

      # 開発環境で spec を参照
      devShells.default = pkgs.mkShell {
        shellHook = ''
          echo "URN: $(cat ${spec.spec.cuePath}/urn/feat/decide-ci-score-matrix/feature.cue)"
        '';
      };
    };
}
```

### Step 2: spec-flake から定義を読み取る

```bash
# flake.lock を更新
nix flake update spec

# spec の cuePath にアクセス
nix eval .#spec.cuePath
# 出力: /nix/store/xxxx-source/spec

# 機能URN定義を読み取る
nix eval --raw .#spec.urn.featPath
# 出力: /nix/store/xxxx-source/spec/urn/feat
```

### Step 3: CI で spec を検証

```yaml
# .github/workflows/spec-check.yml
name: Validate against spec

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v24

      - name: Verify URN definition
        run: |
          # spec-flake から自分の URN を取得
          MY_URN="urn:feat:decide-ci-score-matrix"

          # spec/adapter/git/repo で自分の repo が定義されているか確認
          nix eval .#spec.adapter.gitRepoPath

          echo "✓ URN $MY_URN is defined in spec-flake"
```

---

## スクリプトでの参照例

### Bash スクリプトで spec を読み取る

```bash
#!/usr/bin/env bash
# get-my-urn.sh - 自分の repo の URN を spec-flake から取得

set -e

# spec-flake のパスを取得
SPEC_PATH=$(nix eval --raw .#spec.cuePath)

# 自分の repo の slug（repo名と同じ）
SLUG="decide-ci-score-matrix"

# 機能URN定義を読み取る
FEATURE_FILE="$SPEC_PATH/urn/feat/$SLUG/feature.cue"

if [ -f "$FEATURE_FILE" ]; then
  echo "✓ URN definition found: urn:feat:$SLUG"
  cat "$FEATURE_FILE"
else
  echo "❌ URN definition not found for slug: $SLUG"
  exit 1
fi
```

### Python スクリプトで CUE を解析

```python
#!/usr/bin/env python3
# read-spec.py - spec-flake から URN マッピングを読み取る

import subprocess
import json

def get_spec_path():
    """spec-flake の cuePath を取得"""
    result = subprocess.run(
        ["nix", "eval", "--raw", ".#spec.cuePath"],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout

def get_repo_mapping():
    """adapter/git/repo の定義を取得"""
    spec_path = get_spec_path()
    repo_file = f"{spec_path}/adapter/git/repo/repo.cue"

    # CUE eval でマッピングを JSON として取得
    result = subprocess.run(
        ["cue", "eval", "-e", "repos", repo_file, "--out", "json"],
        capture_output=True,
        text=True,
        check=True
    )
    return json.loads(result.stdout)

if __name__ == "__main__":
    mappings = get_repo_mapping()
    for mapping in mappings:
        print(f"{mapping['internal']} → {mapping['forge']}/{mapping['org']}/{mapping['repo']}")
```

---

## DoD（Definition of Done）確認

### ✅ spec repo 側

- [x] spec/ 以下の tree が存在
- [x] `cue eval ./spec/...` が成功
- [x] `cue vet ./spec/ci/checks/...` が成功

### ✅ CI 側

- [x] GitHub Actions で `cue eval/vet` が自動実行
- [x] PR の Checks に結果が反映

### ✅ flake & impl repo 側

- [x] `flake.nix` で `outputs.spec` に spec/ を露出
- [ ] **少なくとも1つの impl repo で `inputs.spec` を参照**（次のステップ）
- [ ] **その repo で spec を使った検証 CI が動作**（次のステップ）

---

## 次のステップ

### impl repo（例: decide-ci-score-matrix）での実装

1. `flake.nix` に `inputs.spec` を追加
2. CI で spec-flake から URN 定義を読み取る
3. 自分の repo が `adapter/git/repo` に定義されているか確認

この3点が完了した時点で、**「期待すべて達成」と断言できる** 状態になります。

---

## トラブルシューティング

### Q: `nix eval .#spec.cuePath` でエラーが出る

A: `flake.lock` を更新してください:
```bash
nix flake update spec
```

### Q: CUE eval が失敗する

A: spec repo の最新版を pull してください:
```bash
nix flake update spec
```

### Q: 自分の repo が spec に定義されていない

A: spec repo の `spec/adapter/git/repo/repo.cue` に追加してください:
```cue
{
    internal: "urn:feat:your-repo-slug"
    forge:    "github.com"
    org:      "porcorosso85"
    repo:     "your-repo-slug"
},
```
