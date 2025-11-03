# ADR: 1人AI体制で壊さず拡張し続ける (v3)

**Status**: accepted

**Date**: 2025-11-03 (JST)

**Scope**: 3-SSOTのv3拡張（external/CM/OPS/DOC 棚、baseline/CR 必須、外部 owner 許容、DRY 強化）

---

## 背景
- 1人 + AI 体制でも、責務境界を壊さずに機能追加を継続したい。
- v2 では 3-SSOT（Catalog / ADR / Skeleton）で最小ガードを導入。
- 外部委託・運用変更・監査対応の増加に合わせ棚を拡張する。

## 決定（v3 追加）
1. **external** 棚を追加（IdP / HW / SaaS 等の社外責務）。
2. **CM** 棚を追加（baseline: BL-**** / change-request: CR-****）。
3. **OPS** 棚を追加（SLO / runtime evidence）。
4. **DOC** 棚を追加（certification / audit-report）。
5. **必須化**: baseline（現行BL）必須 / CR参照必須。
6. **外部 owner 許容**: `owner=="external.*"` を許す。
7. **DRY 強化**: 同一 `responsibility` の重複を警告（段階的に強制）。

## 具体（反映先とCI）
- `docs/catalog/slots/external/*`（例: `idp-auth.cue`, `hw-control-unit.cue`）
- `docs/catalog/slots/cm/{baseline.cue,change-request.cue}`（`BL-****`, `CR-****`）
- `docs/catalog/slots/ops/{slo.cue,runtime-evidence.cue}`
- `docs/catalog/slots/doc/{certification.cue,audit-report.cue}`
- （任意）`docs/catalog/schema/alias.cue` で近似IDの正規化
- `docs/catalog/schema/validate.cue` 強化: active→owner必須 / 未登録&循環NG / abstractのskeleton混入NG / 外部owner許容 / DRY警告 / baseline必須・CR参照必須
- skeleton: 必要なら `docs/structure/.gen/skeleton.json` に `external.*` の配置を追記
- traceability: `docs/structure/.gen/traceability.json` はCI再生成（人手編集禁止）
- CI: `.github/workflows/repo-guard.yml` の4ジョブにv3検証を追加。まず観察モードで、後に強制化。

## 移行
- v2記述との重複/矛盾を解消。`.md`直参照は `.gen` へ差替。
- 外部owner表記は `external.*` に統一。

## DoD
- CI 4ジョブがグリーン（観察 or 強制）。
- 新棚/スキーマ強化のlint通過。
- 本ADRと構造ドキュメント（v3）追加・リンク整合。
- `.gen` 手編集なし（検出ゼロ）。
