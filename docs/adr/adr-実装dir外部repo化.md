# ADR: 実装ディレクトリの外部リポジトリ化と境界の明示

- Status: Proposed
- Deciders: Owner
- Date: 2025-11-03
- Related: repo-guard, catalog/ADR/skeleton, structure-実装dir外部repo化

## Context
- 本repoは「**設計と契約**」のSSOTであり、実装はここに含めない。
- `specification/**/flake.nix` は契約（期待する属性）を定義。実体は外部repoが担う。
- 直近のPRで 3-SSOT（catalog/ADR/skeleton）と境界チェックCIを導入済み。

## Decision
- **責務分担（境界の明示）**
  - **本repo（In scope）**  
    - catalog（責務スロットの全集合）  
    - ADR（意思決定の記録）  
    - skeleton（現在の配置＝参照の一覧）  
    - specification/**/flake.nix（契約属性の提示）  
    - 外部参照の**健全性検証**（解決可能性 / rev固定 / 許可ドメイン / 契約属性の存在）
  - **外部repo（Out of scope）**  
    - 実装コード（`apps/`, `infra/`, `domain/` 相当）  
    - ビルド / ユニット / 統合テスト / 成果物配布

- **用語**  
  - 「NG」ではなく「**スコープ外**」と表記。  
  - CIは「**境界チェック**」として、スコープ外の変更を検知し、**別repoへ移動を提案**する。

- **データモデル**  
  - `docs/structure/.gen/skeleton.json` を拡張：  
    - `kind: "external" | "local"`  
    - `flake: string`（例: `github:org/repo?dir=path`）  
    - `rev: string`（固定Git SHA）  
    - `revPinned: bool`（true必須）  
    - `attrPath: string`（例: `contracts.app-video-encoder`）

- **CI**  
  - `external-refs-validate` を追加。Nixで**非ビルド**検証を実施：  
    1) 許可ドメイン（例: `github:`）  
    2) rev固定（`revPinned:true` かつ `rev` あり）  
    3) `nix flake metadata <ref>?rev=<rev>` が成功  
    4) `nix eval '<ref>?rev=<rev>#<attrPath>' --json` が成功  

## Consequences
- 設計と実装の分離がCIで固定化され、**境界逸脱を早期検知**。  
- rev固定により**供給網の再現性**と**影響範囲の局所化**を確保。  
- 本repoはビルドをしないため、**軽量かつ継続的に安全**。

## Alternatives
- 本repoでビルド/テストも行う：境界が曖昧になり、重く脆くなるため不採用。

## Migration Plan
1. `skeleton.json` に対象スロットを `kind:"external"` で登録（`revPinned:true` & `rev` 付与）。  
2. `specification/**/flake.nix` に `contracts.<slotId>` を公開。  
3. 外部repoに実装とCIを配置（ビルド/テストは外部側）。  
4. `external-refs-validate` を**観察→強制**へ段階移行（ブランチ保護で必須化）。

## Decision Record
- slots: 例 `app.video-encoder`, `infra.kv`, …  
- CI: repo-guard（境界チェック） + external-refs-validate（参照健全性）
