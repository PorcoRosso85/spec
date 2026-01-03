# Phase 9 feat-dxux テスト結果レポート（再実施版）

## テスト概要

| テスト | 内容 | 結果 |
|--------|------|------|
| PASS | 正常な contract.cue | ✅ PASS |
| FAIL-A | `requiredChecks` 欠如 | ✅ FAIL（期待通り） |
| FAIL-B | import/mock 追加 | ✅ FAIL（期待通り） |

## PASS パターン

**対象ファイル**: `spec/urn/feat/dx-ux-test/contract.cue`

```cue
package dx_ux_test

requiredChecks: [
  "test-dod5-positive",
]
```

**検証結果**: 39 checks all PASS ✅

## FAIL-A: requiredChecks 欠如（schema違反）

**操作**:
```cue
package dx_ux_test
```

**結果**: ✅ FAIL（期待通り）

**検出チェック**: `feat-contract-aggregate`

**エラーメッセージ**:
```
feat-contract-aggregate> Validating: /nix/store/.../spec/urn/feat/dx-ux-test/contract.cue
feat-contract-aggregate>   FAIL: requiredChecks missing or empty
feat-contract-aggregate> 
feat-contract-aggregate> FAIL:
feat-contract-aggregate> /nix/store/.../spec/urn/feat/dx-ux-test/contract.cue: requiredChecks missing
```

**復旧手順**:
```bash
# 1. contract.cue を元に戻す
cp /tmp/contract.bak spec/urn/feat/dx-ux-test/contract.cue

# 2. または手動で requiredChecks を追加
cat > spec/urn/feat/dx-ux-test/contract.cue << 'CUE'
package dx_ux_test

requiredChecks: [
  "test-dod5-positive",
]
CUE

# 3. 復旧確認
nix flake check -L
# Exit: 0 (39 checks all PASS)
```

**所感**:
- schema違反（必須フィールド欠如）は必ずFAIL
- 対象パスが明示表示され、修正箇所が明確
- 復旧は `requiredChecks` を追加するだけで简单

## FAIL-B: import/mock 追加

**操作**:
```cue
package dx_ux_test

import "github.com/example/mock"

requiredChecks: [
  "test-dod5-positive",
]
```

**結果**: ✅ FAIL（期待通り）

**検出チェック**: `contract-srp-policy`

**エラーメッセージ**:
```
contract-srp-policy> Checking: /nix/store/.../spec/urn/feat/dx-ux-test/contract.cue
contract-srp-policy>   FAIL: import detected
contract-srp-policy> 
contract-srp-policy> FAIL: SRP violations found:
contract-srp-policy> /nix/store/.../spec/urn/feat/dx-ux-test/contract.cue: import detected
```

**復旧手順**: FAIL-A と同じ

**所感**:
- 単一責務（SRP）ポリシーが正しく機能
- 外部依存を排除し、自己完結したcontractを強制
- 実装詳細はcontractではなくcodeで管理

## 例外リスト（dod0-factory-only.nix）の説明

Phase 9 で追加した6つのチェックは、`pkgs.runCommand` または `pkgs.stdenv.mkDerivation` を使用するため、Factory パターン原則の例外として登録。

| ファイル | 理由 |
|---------|------|
| `no-repo-cue-tracked.nix` | grep によるファイル存在確認（runCommand） |
| `no-repo-cue-any.nix` | grep によるファイル存在確認（runCommand） |
| `no-repo-cue-reference-in-code.nix` | grep によるコード内参照確認（runCommand） |
| `spec-repo-contract-validity.nix` | CUE vet 実行（runCommand） |
| `feat-sandboxes-contract-aggregate.nix` | CUE eval/export 実行（runCommand） |
| `feat-contract-aggregate.nix` | CUE eval/export 実行（runCommand） |
| `contract-srp-policy.nix` | grep によるimport検出（runCommand） |

**理由**:
- これらのチェックは CUE ファイルではなく Nix スクリプトとして実装が必要
- CUE vet/eval を実行し、返り値に基づいて成功/失敗を判定
- grep によるテキスト検索も Nix で実装が自然

**代替案検討**:
- CUE で同様のチェックを実装することは技術的に可能
- ただし、`nix flake check` との連携やエラー出力の制御が複雑化
- 現状の実装は「Nix が責務を持つ検証は Nix で実装」の原則に準拠

## 復旧確認

```bash
cd /home/nixos/spec-repo && nix flake check -L
# Exit: 0 (39 checks all PASS)
```

## UX 所感

### 試行回数
- FAIL-A: 2回目で成功（1回目は unknown field で不適切だったため再実施）
- FAIL-B: 1回目で成功
- 復旧: 1回目で成功

### DX（Developer Experience）
- ** good**: contract.cue のフォーマットがシンプル
- ** good**: エラー時に対象パスが表示される
- ** good**: 復旧が `requiredChecks` 追加のみで完了
- **改善点**: 例外リストの存在が初見では理解しにくいかも

### UX（User Experience）
- ** good**: FAIL 時のエラーメッセージが明確
- ** good**: 復旧手順が単純
- ** good**: 39 checks all PASS の達成感が明確

## 改善提案

1. **FAIL-A**: `requiredChecks` 欠如でFAILする設計を維持
2. **SRPポリシー**: `contract-srp-policy` がimportを検出
3. **ドキュメント**: contract.cue の責務を明文化
4. **例外リスト**: DoD に明記するか、コメントで説明追加

## 結論

| 観点 | 結果 |
|------|------|
| 正常系 | ✅ PASS |
| 異常系(requiredChecks欠如) | ✅ FAIL検出 |
| 異常系(import) | ✅ FAIL検出 |

**feat-repo定義のDX/UX**: 良好 ✅
- contract.cue は `requiredChecks` を定義するだけでOK
- 外部importは `contract-srp-policy` で検出
- 開発者体験：シンプルで明確
- 対象パス表示で修正箇所が明確

## ログファイル

| ファイル | 内容 |
|---------|------|
| `logs/pass-before.log` | 復旧後PASS状態（FAIL-A/B実施前） |
| `logs/fail-a.log` | FAIL-A: requiredChecks欠如 |
| `logs/fail-b.log` | FAIL-B: import追加 |
| `logs/pass-after.log` | 復旧後PASS状態（FAIL-A/B実施後） |
