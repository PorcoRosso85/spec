# Structure: 1人AI体制で壊さず拡張し続ける (v3)

**目的**: external/CM/OPS/DOC 追加、baseline/CR必須、外部owner許容、DRY強化を3-SSOT運用に組み込む。

---

## ルール
1. 3-SSOT厳守（Catalog/ADR/Skeleton）。
2. 1スロット=1責務=1 owner。
3. baseline必須 / CR参照必須。
4. 外部ownerは `external.*`。
5. DRY警告（重複responsibility）。
6. abstractはskeleton禁止。

## 棚の追加
- external/*（IdP, HW, SaaS 等）
- cm/baseline.cue（`BL-2025Q4` 等）
- cm/change-request.cue（`CR-0012` 等）
- ops/slo.cue / ops/runtime-evidence.cue
- doc/certification.cue / doc/audit-report.cue

## 命名・属性
- ID: `<source>.<duty[.sub]>`。CMは `BL-****`, `CR-****`。
- owner: 内部=自由、外部=`external.*`。
- tier: `business|app|infra`。

## 最短フロー
1. Catalogにスロット定義（CUE）。
2. ADRで採用/配置/ownerを宣言（CUE→`.gen/*.md`生成）。
3. Skeletonに `slot.id→path` を追記。
4. CI 4ジョブを通す（観察→強制）。

## CIジョブ（観察モード）
- catalog-validate（CUE/依存/DRY）
- adr-validate（ADR↔skeleton）
- skeleton-guard（未許可パス検知）
- traceability-gen（再生成・人手編集禁止検知）

## 注意
- `.md`直参照は `.gen` へ。
- `.gen/traceability.json` はCIのみ更新。
- v2と矛盾しない差分最小化。

## 参照
- `docs/adr/adr-1人AI体制で壊さず拡張し続ける3.md`（本ADR）
- 既存v2ドキュメント

