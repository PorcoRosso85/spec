# ADR 0.1.1: CI実行基盤の標準化（Blacksmith）

- **Status**: Accepted
- **Date**: 2025-10-27 (JST)
- **Relates**: ADR 0.1.0（CIガード/参照規約）

## 1. 目的
- CIは Blacksmith のマネージド self-hosted runner を **標準** とする。
- 自前常駐 runner や GitHubホスト runner は原則不採用（必要な場合は例外として明記）。

## 2. 採用理由（要約）
- **性能**: ベアメタル級CPU、近接キャッシュ、Sticky Disk等で高速。
- **コスト**: 実行時間短縮＋分単価抑制で総コスト削減。
- **運用**: ランナーライフサイクル管理が不要で、ジョブ単位隔離・可観測性あり。

## 3. 運用ルール
- `runs-on: blacksmith-<plan>` を標準にする。例: 

```yaml
runs-on: blacksmith-2vcpu-ubuntu-2404
```

- キャッシュ方針:
  - 依存キャッシュ (`actions/cache`) は通常利用可。
  - Dockerビルド向けSticky Diskはビルド系ジョブに限定し、費用監視する。
- 例外使用時:
  - Blacksmith以外のrunnerを使う場合はPR本文に以下を必須で書く:
    - 対象ジョブ名
    - なぜBlacksmithで不可なのか（ネットワーク/特権など）
    - 代替runner名
    - 期限

## 4. CIゲート（ADR 0.1.0との接続）
ADR 0.1.0で定義した最低ガードをBlacksmith上で必須化する。
- `nix flake lock --check` / `nix flake check` が通ること
- entrypath検証（`specification/**` 直下に `flake.nix` があること）
- `inputs.*.url` に `path:` を使わないこと
- 未定義entrypath参照は禁止

→ `main` へのマージは「Blacksmith CIが緑であること」を必須条件にする。

## 5. 維持
- SLO / 費用 / キャッシュ方針はこのADR(0.1.1)を更新して通知する。0.1.0自体はなるべく不改変。
- Sticky Disk等のオプションは月次で費用レビューし、対象ジョブを見直す。

## 6. 非スコープ
- Actions YAML の実際の `runs-on` 置き換えや、GitHubリポの保護ブランチ設定などはこのADRでは変更しない（別PRで行う）。
