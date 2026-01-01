# DoD5/DoD6 HowTo - DX/UX簡易説明

## 🎯 目的
feat-repoが契約違反したら自動的にCI FAILさせる

---

## 📦 spec-repoの提供内容

### 1. ライブラリ (lib export)
```nix
inputs.spec.lib.dod5FeatInputs   # flake.lock inputs検証
inputs.spec.lib.dod6ExpectedOutputs  # outputs完全性検証
```

---

## 🚀 feat-repoでの使い方

### Step 1: spec-repoを inputs に追加

```nix
# feat-repo/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spec.url = "github:your-org/spec-repo";  # ← これだけ
  };
  
  outputs = { self, nixpkgs, spec }: { ... };
}
```

### Step 2: DoD5チェックを追加 (flake.lock検証)

```nix
# feat-repo/flake.nix
{
  outputs = { self, nixpkgs, spec }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dod5 = spec.lib.dod5FeatInputs;
      in {
        checks = {
          # DoD5: flake.lock が nixpkgs+spec のみを保証
          contract-inputs = dod5.mkCheck ./flake.lock;
        };
      }
    );
}
```

**何が起きる？**
- ✅ `flake.lock` に `nixpkgs` と `spec` だけ → CI PASS
- ❌ 禁止input (例: `flake-utils-plus`) があったら → CI FAIL + エラーメッセージ

**エラー例**:
```
DoD5 violation: forbidden inputs detected
  Allowed: nixpkgs spec
  Forbidden: flake-utils-plus

  Fix: Remove forbidden inputs from flake.lock
```

### Step 3: DoD6チェックを追加 (outputs検証)

```nix
# feat-repo/flake.nix
{
  outputs = { self, nixpkgs, spec }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dod6 = spec.lib.dod6ExpectedOutputs;
        
        # 期待するoutputsをリスト化
        expectedPackages = [ "default" ];
        expectedDevShells = [ "default" ];
        expectedChecks = [ "contract-inputs" "contract-outputs" ];
        
        # 実際のoutputsを事前抽出 (self.checksは避ける！)
        actualPackages = builtins.attrNames self.packages.${system};
        actualDevShells = builtins.attrNames self.devShells.${system};
        # ⚠️ self.checks は自己参照なので手動リスト化
        actualChecks = [ "contract-inputs" "contract-outputs" ];
      in {
        packages.default = ...;
        devShells.default = ...;
        
        checks = {
          contract-inputs = dod5.mkCheck ./flake.lock;
          
          # DoD6: 期待outputsが全て存在することを保証
          contract-outputs = dod6.mkCheck {
            expected = expectedPackages ++ expectedDevShells ++ expectedChecks;
            actual = actualPackages ++ actualDevShells ++ actualChecks;
            inherit system;
          };
        };
      }
    );
}
```

**何が起きる？**
- ✅ 期待する全outputsが存在 → CI PASS
- ❌ outputsが欠落 (例: `devShells.default`を削除) → CI FAIL

**エラー例**:
```
DoD6 violation: missing expected outputs
  Expected: default
  Actual: (empty)
  Missing: default
  System: x86_64-linux
  
  Fix: Add missing outputs to feat-repo flake.nix
```

---

## ⚠️ 重要な注意点

### DoD6での自己参照回避

❌ **ダメな例** (無限ループ):
```nix
actualChecks = builtins.attrNames self.checks.${system};
# ↑ contract-outputs が self.checks を参照 → 無限ループ
```

✅ **正しい例** (手動リスト化):
```nix
actualChecks = [ "contract-inputs" "contract-outputs" ];
# ↑ 手動で列挙することで自己参照を回避
```

**理由**:
- `contract-outputs` check 自体が `self.checks` の一部
- `self.checks` を参照すると循環依存
- packages/devShells は `self` 参照OK（checksに依存しないため）

---

## 🔄 開発フロー

### 1. 通常時 (CI)
```bash
nix flake check
# ✅ 全checks (contract-inputs, contract-outputs含む) 実行
```

### 2. 個別確認
```bash
# DoD5だけ確認
nix build .#checks.x86_64-linux.contract-inputs

# DoD6だけ確認
nix build .#checks.x86_64-linux.contract-outputs
```

### 3. エラー時
CI FAILしたら、エラーメッセージを読んで修正:
- DoD5違反 → `flake.lock` から禁止inputを削除
- DoD6違反 → 欠落outputsを追加実装

---

## 📊 メリット

| Before | After |
|--------|-------|
| 手動レビューで見落とし | 自動検出・CI FAIL |
| 契約違反に気づかず本番投入 | デプロイ前に必ず検出 |
| ドキュメントと実装が乖離 | 機械的に整合性保証 |

---

## 🎓 最小構成例

```nix
# feat-repo/flake.nix (最小)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spec.url = "github:your-org/spec-repo";
  };

  outputs = { self, nixpkgs, spec }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.hello;
      
      checks.${system} = {
        # DoD5: inputs検証
        contract-inputs = spec.lib.dod5FeatInputs.mkCheck ./flake.lock;
        
        # DoD6: outputs検証
        contract-outputs = spec.lib.dod6ExpectedOutputs.mkCheck {
          expected = [ "default" "contract-inputs" "contract-outputs" ];
          actual = [ "default" "contract-inputs" "contract-outputs" ];
          inherit system;
        };
      };
    };
}
```

これで `nix flake check` が契約を保証します 🎉

---

## 🔗 次のステップ

1. feat-repoに上記コードを追加
2. `nix flake check` 実行
3. CI (GitHub Actions等) に `nix flake check` 追加
4. 契約違反を自動検出！

詳細なドキュメントは `/docs/phase10/` を参照
