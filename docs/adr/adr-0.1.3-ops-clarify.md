# ADR 0.1.3: 運用の明確化（runner既定・例外運用・責任・必須チェック）

- **Status**: Accepted
- **Date**: 2025-10-28 (JST)
- **Relates**: ADR 0.1.0（参照入口/最低ガード）, ADR 0.1.1（CI基盤: Blacksmith）

## 1. 決定（サマリ）
1) **runner既定** を明文化: 既定は `blacksmith-2vcpu-ubuntu-2404`、重ビルドは `blacksmith-8vcpu-ubuntu-2404` + Sticky Disk。
2) **例外運用** を固定: ラベル `runner-exception`、TTL=30日、期限超過で自動失効・再申請必須。
3) **責任ロール** を明記: **CI/Ops Maintainer** が費用/SLOを月次レビュー。
4) **保護ブランチの必須チェック名** を列挙: `ci-guard`（名称を実装PRと合わせる）。
5) **tree.mdの役割整理**: ルール骨子はADRへ寄せ、tree.mdは構成のみ。
6) **entrypath表記の統一（append-only）**: 仕様上の標準を **`<layer>/<name>`** に統一（apps は **`apps/<name>`**）。過去ADRの記述は変更しない（参照互換）。

## 2. 詳細
### 2.1 runner既定
- 既定: 
  - `runs-on: blacksmith-2vcpu-ubuntu-2404`
- 重ビルド/キャッシュ重視ジョブ: 
  - `runs-on: blacksmith-8vcpu-ubuntu-2404` + Sticky Disk（費用は月次レビュー）

### 2.2 例外の扱い
- 例外ラベル: `runner-exception` をPRに付与。
- 必須記載項目（PR本文）: **ジョブ名 / 理由 / 代替runner / 期限**。
- 期限(TTL): **30日**。延長は再申請（再レビュー）必須。

### 2.3 責任ロール
- **CI/Ops Maintainer** が以下を月次レビュー: 
  - CI費用 / Sticky Disk利用状況 / 失敗率SLO / 実行時間SLO

### 2.4 必須チェック名（保護ブランチ）
- Required checks: **`ci-guard`**（最低ガード: flake lock/check, path:禁止, entrypath実在）。
- **一行併記（実装PR向け名称合わせ）**: `ci-guard = flake lock/check + entrypath検証 + path:禁止 + lock-only`。

### 2.5 entrypath表記の統一（append-only補足）
- 標準: **`<layer>/<name>`**（apps は **`apps/<name>`** に統一）。
- 互換: 過去ADRの `[<scope>/]` 表記はそのまま**履歴として維持**（修正しない）。
- 実装への影響: 新規PR/実装ドキュメントでは本表記を使用。旧記載は非推奨。

## 3. 影響
- 0.1.1の運用が具体化し、例外・責任・既定がブレなくなる。
- ディレクトリ構成/参照規約は**不変**。**命名表記のみ統一**（append-onlyで合意）。

## 4. 非スコープ
- ci-guardの詳細実装（正規表現/重複検出/タグGC/SLO閾値など）は 0.1.4 以降で扱う。
