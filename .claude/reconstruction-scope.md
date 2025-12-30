# 再構築フェーズの完璧 - 射程定義

## 目的

「削除の完璧」（MD禁止・GH非依存達成）から「**再構築の完璧（最小基盤）**」への接続。

## 完璧の射程（Scope）

### ✅ 含む（This Phase）

1. **Contract検証基盤**
   - `spec/ci/contract/*.cue` による構造制約
   - Naming（kebab-case, URN format）
   - Uniqueness（ID一意性）
   - Reference shape（URN形状検証のみ）

2. **Fixture検証システム**
   - PASS fixtures: 正しく通る証拠
   - FAIL fixtures: 制約違反を検出する証拠
   - Runner側でcontract注入（import policy）

3. **単一入口化**
   - `bash scripts/check.sh fast` 1コマンドで完結
   - Nix checks経由で再現性担保

4. **循環防止**
   - check.sh → nix checks → cue vet直接実行
   - ロジック禁止（KISS原則）

### ❌ 含まない（Next Phase）

1. **Checks実装**
   - `spec/ci/checks/*.cue` は現在**コメントのみ（未実装）**
   - DRY保証、1urn1repo保証、repo整合性等は**設計書として存在**
   - 実装は次フェーズ（P2）で対応

2. **参照整合性検証**
   - 参照先存在確認（broken-ref検出）
   - 循環依存検出
   - これらは構造参照化（P2）後に実現可能

## YAGNI vs 未実装の区別

### YAGNI（実装しない）
- GitHub Actions依存機能
- ブランチ保護設定
- MD契約

### 未実装（次フェーズで実装予定）
- spec/ci/checks/*.cue の制約実装
- 参照整合性validator
- 循環依存検出器

## 4原則の適用範囲

| 原則 | この射程での達成状況 |
|------|---------------------|
| **DRY** | ✅ Fixture検証ロジックはnix/checks.nixに集約 |
| **KISS** | ✅ check.shはnix呼び出しのみ（ロジックなし） |
| **YAGNI** | ✅ GH依存等の不要機能を削除済み |
| **SRP** | ✅ runner=検証実行、fixture=データ、contract=仕様 |

**注意**: checksが未実装でも4原則は満たす（YAGNIは「不要を作らない」であり「未実装を許容」ではない）

## 完璧宣言の正確な表現

**❌ 誤**: 「spec-repoの完璧達成」  
**✅ 正**: 「再構築の完璧（最小基盤）達成 - contract+fixtures+単一入口+Nix再現性」

## 次フェーズ（P2）への移行条件

1. spec/ci/checks/*.cue に実際の制約を1つ以上実装
2. その制約に対するFAIL fixtureを追加
3. 単一入口で制約違反を検出できることを証明

---

**作成日**: 2025-12-30  
**関連コミット**: ef3ad70 (refs.cue scope明確化)  
**ステータス**: 射程確定・完璧宣言可能
