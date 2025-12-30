# スケール設計レビュー - 競合リスク評価

**レビュー日**: 2025-12-30  
**対象ブランチ**: dev  
**レビュー対象**: nix/checks.nix, flake.nix  
**現状feat数**: 2件 (spec, decide-ci-score-matrix)

---

## エグゼクティブサマリー

### 判定結果: ❌ **競合しやすい設計（現状）**

| 評価項目 | 判定 | 理由 |
|---------|------|------|
| **Git衝突回避** | ❌ NG | feat追加時に中央ファイル（nix/checks.nix）を編集不要だが、全量vet方式のため実質的な衝突リスクあり |
| **スケール性** | ❌ NG | featごとのderivation分割なし、全量一括vetで線形に重くなる |
| **自動列挙** | ❌ NG | readDir等の自動検出なし、`./spec/urn/...` glob依存 |

### 総合評価
**現状**: feat追加は`spec/urn/feat/<slug>/`配下の追加のみで済むが、**Nix checks側の最適化なし**  
**リスク**: feat数増加時に全量vetの実行時間が線形増加、並列化・キャッシュ効率が悪い

---

## 3.1 変更ファイル境界（競合リスクの一次判定）

### 現状の設計
```bash
# feat追加時の変更範囲（理想）
spec/urn/feat/<slug>/feature.cue  # 追加のみ

# 実際に必要な変更
なし（glob ./spec/urn/... で自動認識）
```

### ✅ 形式的な競合回避
- feat追加は `spec/urn/feat/<slug>/` 配下のみ
- nix/checks.nix の編集不要（glob使用）

### ⚠️ 実質的な競合リスク
- 全量vet方式のため、feat A追加のPRとfeat B追加のPRが同時進行すると：
  - 両方が`spec/urn/...`全体を検証対象とする
  - マージ後に互いの追加featを検証し直す（キャッシュ無効化）

---

## 3.2 Nixが自動列挙しているか（設計の核心）

### 証拠: nix/checks.nix の検証コマンド

```bash
# spec-fast の検証コマンド（L79-84）
${pkgs.cue}/bin/cue vet \
  ./spec/urn/... \           # ← glob依存（自動列挙ではない）
  ./spec/schema/... \
  ./spec/adapter/... \
  ./spec/mapping/... \
  ./spec/external/... \
  ./spec/ci/contract/...
```

### 判定: ❌ NG（自動列挙なし）

**現状**:
- `./spec/urn/...` globでCUEが自動認識
- Nix側で`readDir`等の明示的な列挙なし

**問題点**:
- glob展開は実行時にCUEが行う
- Nix derivationからは「spec/urn/全体」が入力として扱われる
- featごとの独立したderivationに分割されていない

### 証拠: flake.nix の featPath定義

```nix
# flake.nix:89
featPath = ./spec/urn/feat;
```

**用途**: 他repoからの参照用（現状、Nix checks内では未使用）

---

## 3.3 局所derivation分割の有無（スケール確認）

### 証拠: checks.nix の構造

```bash
$ rg -n "map|forEach|mkDerivation|builtins\." nix/checks.nix
（該当なし）
```

### 判定: ❌ NG（局所分割なし）

**現状の構造**:
```nix
{
  spec-fast = pkgs.runCommand "spec-fast" { ... } ''
    cue vet ./spec/urn/... ./spec/ci/contract/...
  '';
}
```

**問題点**:
1. **単一derivation**: spec-fast が全量検証を1つのderivationで実行
2. **キャッシュ粒度**: feat1件追加で全体が再検証される
3. **並列化不可**: featごとの並列実行ができない

### 理想的な設計（参考）
```nix
let
  # spec/urn/feat/を列挙
  featDirs = builtins.attrNames (builtins.readDir ./spec/urn/feat);
  
  # featごとのcheck derivation
  featChecks = builtins.map (slug:
    pkgs.runCommand "check-feat-${slug}" { ... } ''
      cue vet ./spec/urn/feat/${slug}/... ./spec/ci/contract/...
    ''
  ) featDirs;
in {
  # 全featのチェックを集約
  spec-fast = pkgs.runCommand "spec-fast" {
    buildInputs = featChecks;
  } ''
    echo "All feats validated"
  '';
}
```

---

## 競合シナリオ分析

### シナリオ1: 同時feat追加（2PR）

**前提**:
- PR A: `spec/urn/feat/feature-a/feature.cue` 追加
- PR B: `spec/urn/feat/feature-b/feature.cue` 追加

**現状の挙動**:
```
1. PR A マージ: spec-fast が feature-a を含む全量検証
2. PR B マージ: spec-fast が feature-a + feature-b を含む全量検証
   → PR Aのキャッシュが無効化（全量再vet）
```

**リスク**: ✅ Git衝突なし、⚠️ CI実行時間増加

### シナリオ2: feat100件追加後の1件追加

**前提**:
- 既存feat: 100件
- 追加: `spec/urn/feat/feature-101/feature.cue`

**現状の挙動**:
```
cue vet ./spec/urn/...  # 101件全量検証（線形増加）
```

**実行時間予測**:
- feat 2件: 0.5秒
- feat 100件: 25秒（線形）
- feat 1000件: 250秒（4分超）

**リスク**: ❌ スケール不可

---

## 改善提案（優先順位付き）

### 🔴 P0: 局所derivation分割（必須）

**目的**: featごとの並列検証・キャッシュ効率化

**実装例**:
```nix
# nix/checks.nix
let
  featDirs = builtins.attrNames (builtins.readDir (self + "/spec/urn/feat"));
  
  mkFeatCheck = slug: pkgs.runCommand "check-feat-${slug}" {
    buildInputs = with pkgs; [ cue ];
  } ''
    cd ${self}
    cue vet ./spec/urn/feat/${slug}/... ./spec/ci/contract/...
    echo "ok" > $out
  '';
  
  featChecks = builtins.listToAttrs (
    map (slug: { name = "feat-${slug}"; value = mkFeatCheck slug; }) featDirs
  );
in
featChecks // {
  spec-fast = pkgs.runCommand "spec-fast" {
    buildInputs = builtins.attrValues featChecks;
  } ''
    echo "All feats validated"
    mkdir -p $out && echo "ok" > $out/result
  '';
}
```

**効果**:
- ✅ featごとに独立したderivation
- ✅ feat追加時は新規featのみビルド（既存はキャッシュ）
- ✅ 並列実行可能

**DoD**:
```bash
nix build .#checks.x86_64-linux.feat-feature-a  # 個別check可能
nix build .#checks.x86_64-linux.spec-fast       # 全体check（依存）
```

### 🟡 P1: fixture検証の分離（推奨）

**目的**: fixture追加時にfeat検証を再実行しない

**実装**:
```nix
spec-fast-fixtures = pkgs.runCommand "spec-fast-fixtures" { ... } ''
  # PASS/FAILのみ検証
'';

spec-fast = pkgs.runCommand "spec-fast" {
  buildInputs = [ spec-fast-fixtures ] ++ (builtins.attrValues featChecks);
} ''
  echo "All validated"
'';
```

### 🟢 P2: schema/contract/adapter検証の分離（任意）

**目的**: 基盤変更とfeat追加の影響範囲を分離

**実装**: schema/contract/adapterをそれぞれ独立derivationに

---

## 実装計画（段階的移行）

### Phase 1: 証明（PoC）
**目的**: 局所derivation分割が機能することを証明

**タスク**:
1. `nix/checks-split.nix` 作成（新規ファイル、既存維持）
2. feat 2件で動作確認
3. キャッシュ効率を測定

**DoD**: feat 1件追加時、既存featのビルドがスキップされる

### Phase 2: 統合
**目的**: checks.nixを置き換え

**タスク**:
1. checks-split.nixをchecks.nixにリネーム
2. 全checksが通ることを確認
3. ドキュメント更新

**DoD**: `nix flake check` が全てPASS

### Phase 3: 運用検証
**目的**: 実際のfeat追加フローで効果確認

**タスク**:
1. feat 3件追加（並行PR）
2. CI実行時間・キャッシュ効率を計測
3. 改善効果を定量評価

---

## 次のアクション（推奨順）

### 1. P0実装の優先判断
**質問**: 現時点でfeat数が2件、今後何件まで増やす予定か？
- feat < 10件: 現状維持も可（実害少ない）
- feat 10-50件: P0実装推奨（体感速度低下）
- feat > 50件: P0実装必須（実用不可）

### 2. PoC実施（推奨）
```bash
# 新規ブランチ作成
git checkout -b scale/ci-split

# checks-split.nix 作成
# feat-<slug> derivation群を実装

# 検証
nix build .#checks.x86_64-linux.feat-spec
nix build .#checks.x86_64-linux.spec-fast
```

### 3. 効果測定
```bash
# Before: 全量vet
time nix build .#checks.x86_64-linux.spec-fast --rebuild

# After: 局所derivation
time nix build .#checks.x86_64-linux.feat-new --rebuild
# → 既存featはキャッシュから取得（高速）
```

---

## 結論

### 現状評価: ❌ **競合しやすい設計**

| 項目 | 現状 | 理想 |
|------|------|------|
| Git衝突 | 形式的に回避 | ✅ |
| スケール性 | 線形増加 | ❌ |
| 自動列挙 | glob依存 | ❌ |
| キャッシュ | 全量無効化 | ❌ |
| 並列実行 | 不可 | ❌ |

### 推奨アクション

1. **即座に実施**: `.claude/scale-design-review.md`（本文書）をレビュー
2. **feat数 < 10件**: 現状維持も可、将来の改善を計画
3. **feat数 > 10件**: P0（局所derivation分割）を最優先実装

### 実装優先度
```
P0（必須）: 局所derivation分割
P1（推奨）: fixture検証分離
P2（任意）: 基盤検証分離
```

---

**関連文書**:
- `.claude/reconstruction-scope.md` - 現在の射程定義
- `nix/checks.nix` - 現行実装（全量vet方式）
- `flake.nix` - featPath定義
