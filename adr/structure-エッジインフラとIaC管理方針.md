# プロジェクト構造: エッジインフラと IaC 管理 (draft)

このファイルは「このリポジトリはいまこう分けて運用する」という宣言的な最新の形。 変更が入るPRでは必ずここも更新する。

---

## ルート直下 (現時点での公式ディレクトリ)

- `adr/`
- `docs/`
- `infra/`
- `services/`
- `tools/` (将来用)

### adr/
設計判断(ADR)を置く。
- 命名は `adr-<目的>.md`（番号なし、日本語OK）
- 1つのPRにつき1つのADR
- 古くなったADRは消してよい（消すときもPRでログが残る）
- 今回の `adr-エッジインフラとIaC管理方針.md` が現時点のベースライン

### docs/
ドキュメント・リファレンス。
- `docs/structure/index.md` は “今このリポジトリはこういう責務分けです” を常に最新化する特別ファイル
- 手順書やSLOメモなど増やしてOK

---

## infra/
インフラ(IaCと初期ブート)を管理する領域。
`infra/` は3レイヤに分かれる想定:

1. `infra/cue/`
   - CUEスキーマと値のソースオブトゥルース
   - サービスのポート・ENV・依存リソース(Postgres, R2, KV等)を型付きで定義する
   - ここから NixOS flake / OpenTofu / Cloudflare Worker の設定に値を流す
   - OpenTofu実行後に払い出される ID (Floating IP / Tunnel ID など) は逆にここへ取り込み、手書きメモを禁止する

2. `infra/tofu/`
   - OpenTofu (Terraform互換) による IaC 本体
   - VPSインスタンス、Firewall、Floating IP、Volume、Snapshot、(必要なら)LB、Cloudflare Tunnel / Route などを宣言する
   - Postgresなど状態系の配置もここで定義
   - stackごとに「どのVPSにどのサービス(glued flake)を載せるか」を変数で割り当てる

3. `infra/bootstrap/` (将来)
   - 初回だけ人間が叩くレスキュー/ブート用スクリプトやメモ置き場
   - 例: Cloudflare Tunnelの初回作成、Linode側への最初のSSHキー登録など
   - 恒常運用の正はあくまで `infra/tofu/`

---

## services/
実際のアプリケーションと実行単位をまとめる場所。 NixOS上の glued flake サービスと、Cloudflare Worker がここに並ぶ。

想定ディレクトリ例:

```text
services/
  <service-a>/
    flake.nix               # glued flake本体 (= デプロイ単位)
    module.nix / default.nix
    observability/          # OTEL exporter, Vector設定など(ログ/メトリクス送信)
    cue/                    # service固有のCUE断片 (portやENVスキーマ)

  <service-b>/
    ...

  edge-worker/
    worker/                 # Cloudflare Worker (Durable Object / R2 binding 等)
    wrangler.toml           # ただし値そのものは CUE から注入される前提
    cue/                    # Worker用のbinding/ENVスキーマ
```

ポイント:
- 「サービス境界 = glued flake もしくは Worker」＝“これ単体でデプロイ・再起動・監視できる”単位。
- 同一VPSに複数サービスを同居させてよい。将来的に役割ごとにVPSを分けるのもアリ。
- 観測(OTEL/Vector→R2)は各サービス側で必須。後付けじゃなく最初から前提。

---

## tools/ (将来)
- ローカルでの解析や検証用の補助スクリプトを置く
  - 例: R2からログを取ってDuckDBで集計するバッチ
  - eBPF/課金計測PoCなど
- 本番パスには載らないので、infraやservicesとは分離しておく

---

## ランタイムの標準フロー（概念）

```text
[ユーザ]
   ↓ HTTPS
[Cloudflare Worker]  -- WAF/TLS/DDoS/RateLimit/キャッシュ
   ↓ (Cloudflare Tunnel)
[VPS群 / glued flake services (NixOS)]
   ↘ (ライト系)        [Postgres 正系(低RTTリージョン)]
   ↘ (ログ/メトリクス) [R2] → [DuckDBでオフライン分析]
```

- 公開面・証明書・DDoS防御はCloudflareに押しつける
- VPSは基本的に“内向き実行ノード”として扱う（外に丸裸で出さない）
- Postgresの書き込みは1拠点に集約し、一貫性とRTTを優先
- ログ/トレース/メトリクスはVector→R2→あとでDuckDB。SaaS監視常設は初期スコープ外

---

## この構造で満たしたいこと
1. ローカルNixOSで動いているものをほぼそのまま公開できる
2. 公開・TLS・WAFなど“インターネット正面のつらい部分”をCloudflareに任せられる
3. IaC(OpenTofu)とCUEが唯一の真実になり、手作業メモを残さない
4. 観測とログ転送(課金計測の布石)をはじめからビルトインにする

---

## 直近TODOメモ（このPR後にやること）
- `infra/tofu/linode/` (など) を追加して、東京リージョンのVPS 1台をコード化
- `services/edge-worker/` のたたき台を作る (wrangler.toml と CUE スキーマの骨だけでもOK)
- `services/<service-a>/flake.nix` 最小雛形 (systemd unit + Vector/OTEL exporter同梱) を置く
- CUE → (tofu vars / flake / worker) への値注入パスを用意する
