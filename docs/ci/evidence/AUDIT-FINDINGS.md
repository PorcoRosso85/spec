# Phase 1.5 監査証跡実装 - 現地調査結果

**調査日時**: 2025-12-30  
**調査対象**: Branch protection設定準備状況  
**調査者**: Claude (OpenCode)

---

## 調査目的

> 監査証跡を残すという方針について、実装はどこまで実現されている？現地調査頼む

---

## 発見事項（Critical Issues）

### 1. ❌ Context名の不整合（ドキュメント vs 実装）

**発見箇所**:
- `docs/ci/ENFORCEMENT.md`: `fast`, `smoke`のみ記載
- `docs/ci/evidence/phase15-branch-protection-config.json`: 5つ記載

**リスク**:
- ドキュメントが実装を反映していない
- 監査時に矛盾として指摘される

**修正方針**:
- ENFORCEMENT.mdを全context含むように更新
- Phase 2.0追加分（unit/unit-strict）を明記

---

### 2. ❌ 他workflowのcheck漏れ（重大）

**発見**:
```bash
$ grep -E "^  [a-z-]+:" .github/workflows/repo-guard.yml
  catalog-validate:
  adr-validate:
  skeleton-guard:
  skeleton-gen:
  traceability-gen:
  guard-summary:
```

**問題**:
- `repo-guard.yml`がPRでトリガーされる
- これらのcheckが必須check listに**含まれていない**
- → repo-guardの検証をバイパス可能！

**影響度**: **HIGH**（破れないゲートの穴）

**修正**: Required contextsに追加
```json
"contexts": [
  "fast", "slow", "smoke", "unit-strict",
  "catalog-validate",
  "adr-validate", 
  "skeleton-guard",
  "guard-summary"
]
```

**Note**: `skeleton-gen`, `traceability-gen`は生成系なので必須から除外（guard-summaryで十分）

---

### 3. ❌ Admin bypass矛盾（"破れないゲート"主張と不一致）

**現状**:
```json
"enforce_admins": false
```

**問題**:
- CERT/ENFORCEMENTで"破れないゲート"を主張
- でもadmin は bypass可能 = **矛盾**

**修正選択肢**:

**A. 完全な破れないゲート（推奨）**:
```json
"enforce_admins": true
```
- 管理者も含めてbypass不可
- 緊急時は一時的にprotection無効化が必要（手順要文書化）

**B. 文言を正確に**:
- `enforce_admins: false`のまま
- "破れないゲート（管理者例外あり）"と明記
- 監査強度は下がる

**推奨**: **A** （真の破れないゲート）

---

### 4. ❌ unit/unit-strict 重複（設計不整合）

**現状**: mainで`unit`と`unit-strict`両方を必須化

**問題**:
- `unit`: PR用（XFAIL警告のみ、exit 0）
- `unit-strict`: main用（XFAIL>MAX → exit 1）
- 両方必須 = 二重実行、運用混乱

**正しい設計**:
| Branch | Required Check | Mode |
|--------|---------------|------|
| PR     | `unit`        | XFAIL_STRICT=false |
| main   | `unit-strict` | XFAIL_STRICT=true  |

**修正**: `contexts`から`unit`を削除（mainでは不要）

---

## 修正版 Config

**Before**: `docs/ci/evidence/phase15-branch-protection-config.json`
**After**: `docs/ci/evidence/phase15-branch-protection-config-corrected.json`

### 主な変更

1. ✅ Context追加: `catalog-validate`, `adr-validate`, `skeleton-guard`, `guard-summary`
2. ✅ Admin bypass無効化: `enforce_admins: true`
3. ✅ unit削除: mainでは`unit-strict`のみ

### 修正後のcontexts一覧

```json
"contexts": [
  "fast",           // Phase 1 PR gate
  "slow",           // Phase 1 main gate
  "smoke",          // Phase 0 baseline
  "unit-strict",    // Phase 2 main gate (XFAIL enforced)
  "catalog-validate",  // repo-guard
  "adr-validate",      // repo-guard
  "skeleton-guard",    // repo-guard
  "guard-summary"      // repo-guard summary
]
```

**Total**: 8 required checks

---

## 監査証跡実装状況

### ✅ 実現されているもの

1. **Config JSONの準備**
   - `phase15-branch-protection-config.json`作成済み
   - Git commit済み（証跡固定）

2. **適用/検証手順の文書化**
   - `docs/ci/evidence/README.md`に記載
   - gh CLI コマンド明記
   - UI代替手段も記載

3. **証拠取得方法の定義**
   - Applied settings → JSON保存
   - Git commitで時点固定

### ⚠️  未実現/不完全なもの

1. **Context名の実在確認**
   - 推測で設定（実PRでの検証なし）
   - → 適用後に404エラーのリスク

2. **Admin bypass方針の不明確さ**
   - `enforce_admins: false`の理由未記載
   - "破れないゲート"との矛盾

3. **他workflowの網羅性不足**
   - `repo-guard.yml`のcheckを見落とし
   - 全workflow の棚卸し未実施

4. **実適用の未完了**
   - GitHub API への PUT未実施
   - Applied settings JSON 未取得

---

## 次のアクション（優先順位順）

### 1. Config修正（HIGH）
```bash
cd /home/nixos/spec-repo
# Use corrected version
mv docs/ci/evidence/phase15-branch-protection-config-corrected.json \
   docs/ci/evidence/phase15-branch-protection-config.json
   
git add docs/ci/evidence/
git commit -m "fix(ci): Phase 1.5 config修正 - context追加+admin enforce+重複削除"
```

### 2. 実適用 + 証拠取得（HIGH）
```bash
# Apply
gh api repos/PorcoRosso85/spec/branches/main/protection \
  --method PUT \
  --input docs/ci/evidence/phase15-branch-protection-config.json

# Capture evidence
gh api repos/PorcoRosso85/spec/branches/main/protection \
  > docs/ci/evidence/phase15-branch-protection-applied.json

git add docs/ci/evidence/phase15-branch-protection-applied.json
git commit -m "docs(ci): Phase 1.5 完了 - branch protection適用証拠"
```

### 3. ENFORCEMENT.md更新（MEDIUM）
- Context一覧を最新化
- Admin bypass方針明記
- repo-guard checks説明追加

### 4. Phase 1.5 CERTIFICATION作成（MEDIUM）
- 適用証拠含む
- 全context説明
- 監査可能性の証明

---

## 結論

### 現状評価

| 観点 | 状態 | スコア |
|------|------|--------|
| Config準備 | ⚠️  不完全（4問題あり） | 70% |
| 証跡取得方法 | ✅ 文書化済み | 100% |
| 実適用 | ❌ 未実施 | 0% |
| ドキュメント整合 | ❌ 不一致あり | 60% |
| **総合** | **未完了** | **58%** |

### 完璧か？

**NO** - 4つの致命的問題があり、未適用。

### 修正後の見込み

修正版configで適用 → **95%**（残りはテストPRでの検証）

---

## 監査証跡方針（明文化）

**要件（手段非依存）**:
> Branch protectionが実際に適用された事実を、第三者が後日検証できる証拠として、リポジトリ内に固定保存する

**推奨実装**:
- ✅ GitHub API JSONをgit commit（gh CLI使用）
- ✅ スクリーンショット不要
- ✅ 適用前後のdiff可能
- ✅ 再適用可能（災害復旧）

**代替手段**:
- UI + 手順書 + スクショ（監査強度低）

**証拠セット**:
1. Config JSON（宣言）
2. Applied JSON（実体）
3. Git commit（時点固定）
4. (Optional) Required contexts抽出テキスト

---

**調査完了。修正版configをcommitし、適用待ち。**
