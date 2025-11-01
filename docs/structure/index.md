# Repository Structure / 契約まとめ

このリポジトリは "spec (供給側)" を公開し、実装側がそれを vendor して使うことを前提にする。

## 1. ルート直下
- `docs/` : 仕様と運用のドキュメント。ADRもここ。
- `specification/` : 実際に配布するCUEモジュール郡（=プロダクトに取り込まれる素材）。

## 2. docs/ 下
- `docs/adr/` : 変更の意思決定ログ(ADR)。過去の判断も消さずに残す。
- `docs/structure/` : この構成・責務を説明するドキュメント（このファイル）。

特に `docs/adr/0.1.6-machine-hardening-nix-cue.md` は、
Nix×CUE で "人手の運用ルール" を禁止し、
CIで機械的に壊れにくさを保証する方針を定義している。

## 3. specification/ 下
`specification/` はすべての provider / spec を一覧化するカタログ。
実装側はここを vendor して使う。

- `specification/index.json` : 機械可読のカタログ。`nix run .#index` で自動生成される。
- `specification/README.md` : 契約の人間向けサマリ。
- `specification/<layer>/<spec>/` : 各プロバイダ (=1つの仕様単位)。例: `domain-layer/payment/` など。
    - `flake.nix` : このspecが外部に約束する3つだけをエクスポートする。
        - `packages.${system}.cueModule`
        - `apps.vendor`
        - `devShells.${system}.default`
    - `cue/` : ピュアCUEソース（相対import禁止がCIで担保される）。
    - `checks/` : このspec専用のスモーク/整合チェック（Nixから叩かれるだけ）。

## 4. CI の考え方
- すべて Nix 経由 (`nix flake check` / `nix develop -c ...`) で実行できること。
- 外部サービス依存や人間の手順は不可。
- Fail時には "次の1手" を表示する。

## 5. 方針キーワード
- YAGNI: いらないものは足さない。対象プラットフォームも2つだけ。
- KISS: ルールは単純に。読みやすく。
- DRY: index.json等は自動生成し、手書きの重複を残さない。
- SRP/SOLID: 各specは vendor 供給物としての単一責務に集中する。

# リポジトリ構成 / structure

## 1. このドキュメントの役割
- このファイル docs/structure/index.md がリポジトリ構成の単一の正 (SSOT)。
- ここに書かれていない置き場は基本的に作らない / 既存なら削除検討対象。
- ADR本文にフルのツリーは書かない。このファイルだけが最新ツリー。
- 更新日は手で書き換えること。

**Last Updated**: 2025-10-28 (JST)

## 2. 現在のツリー（宣言）
> 凡例: # = コメント（各行の責務説明）

```text
repo/
├─ flake.nix                                        # ルートflake：出力集約/forAllSystems
├─ flake.lock                                       # 単一lock（sub-flakeはfollows）
├─ README.md                                        # 規約/層責務/PRチェックリスト要約
├─ contracts/                                       # SSOT（実装禁止）
│  └─ ssot/
│     ├─ video/                                     # 例：video境界づけ文脈
│     │  ├─ schema.sql                              # DBスキーマ（唯一の正）
│     │  ├─ events.cue                              # ドメインイベント契約
│     │  └─ openapi.yaml                            # 外部API契約
│     └─ search/                                    # 例：search境界づけ文脈
│        ├─ schema.sql                              # DBスキーマ（唯一の正）
│        └─ search.proto                            # gRPC/IDL契約
├─ infra/                                           # 依存/SDK/ランタイム/アダプタ/プロビジョニングの唯一の置き場
│  ├─ flake.nix                                     # devShells/checks集約（ruff/pytest等）
│  ├─ runtimes/                                     # FW/ツール束（pin）
│  │  ├─ python-django/
│  │  │  ├─ flake.nix                               # ランタイム出力（packages.runtimes.python-django）
│  │  │  └─ constraints.txt                         # pip系制約（pin）
│  │  ├─ python-fastapi/
│  │  │  ├─ flake.nix                               # 出力・devShell
│  │  │  └─ constraints.txt                         # pin
│  │  ├─ python-ffmpeg/
│  │  │  ├─ flake.nix                               # 出力・devShell
│  │  │  └─ constraints.txt                         # pin
│  │  └─ python-ml/
│  │     ├─ flake.nix                               # 出力・devShell
│  │     └─ constraints.txt                         # pin
│  ├─ adapters/                                     # Port実装（外部I/O）群
│  │  ├─ storage/                                   # ストレージAdapter群（本番=R2 / CI=MinIO）
│  │  │  ├─ r2/                                     # R2実装（本番既定・唯一のクラウドストレージ）
│  │  │  │  ├─ flake.nix                            # packages.adapters.storage-r2
│  │  │  │  └─ requirements.in                      # 依存宣言（constraintsに取り込み）
│  │  │  ├─ drive/                                  # Drive実装（代替）
│  │  │  │  ├─ flake.nix                            # packages.adapters.storage-drive
│  │  │  │  └─ requirements.in                      # 依存宣言
│  │  │  └─ (s3/)                                   # ❌ S3廃止済み・復活禁止
│  │  ├─ db/                                        # DBアクセスAdapter群
│  │  │  ├─ libsql/
│  │  │  │  ├─ flake.nix                            # packages.adapters.db-libsql
│  │  │  │  └─ requirements.in                      # 依存宣言
│  │  │  └─ postgres/
│  │  │     ├─ flake.nix                            # packages.adapters.db-postgres
│  │  │     └─ requirements.in                      # 依存宣言
│  │  ├─ queue/                                     # キュー/ワークフローAdapter群
│  │  │  ├─ temporal/
│  │  │  │  ├─ flake.nix                            # packages.adapters.queue-temporal
│  │  │  │  └─ requirements.in                      # 依存宣言
│  │  │  └─ celery/
│  │  │     ├─ flake.nix                            # packages.adapters.queue-celery
│  │  │     └─ requirements.in                      # 依存宣言
│  │  ├─ tts/                                       # 音声合成Adapter群
│  │  │  ├─ azure/
│  │  │  │  ├─ flake.nix                            # packages.adapters.tts-azure
│  │  │  │  └─ requirements.in                      # 依存宣言
│  │  │  └─ polly/
│  │  │     ├─ flake.nix                            # packages.adapters.tts-polly
│  │  │     └─ requirements.in                      # 依存宣言
│  │  ├─ encoder/
│  │  │  └─ ffmpeg/
│  │  │     ├─ flake.nix                            # packages.adapters.encoder-ffmpeg
│  │  │     └─ requirements.in                      # 依存宣言
│  │  ├─ ml/                                        # ML推論Adapter群
│  │  │  ├─ openai/
│  │  │  │  ├─ flake.nix                            # packages.adapters.ml-openai
│  │  │  │  └─ requirements.in                      # 依存宣言
│  │  │  └─ azure-openai/
│  │  │     ├─ flake.nix                            # packages.adapters.ml-azure-openai
│  │  │     └─ requirements.in                      # 依存宣言
│  │  └─ opencode/
│  │     └─ autopilot/                              # orchestration系の受け皿
│  │        ├─ flake.nix                            # packages.adapters.opencode-autopilot
│  │        └─ requirements.in                      # 依存宣言
│  ├─ presentation-runtime/                         # プレゼン表示ランタイム（旧 infra/sdk/ui-wc）
│  │  └─ x-deck/
│  │     ├─ deck.ts                                 # ブラウザ表示/遷移制御
│  │     ├─ deck.css                                # スタイル
│  │     ├─ tsconfig.json                           # TypeScript設定
│  │     └─ flake.nix                               # packages.presentation-runtime.x-deck
│  ├─ content-build-tools/                          # コンテンツビルドツール群（旧 infra/sdk/md-tools）
│  │  ├─ shared/                                    # 共通ロジック（DRY）
│  │  │  ├─ out-path.mjs                            # 出力パス計算
│  │  │  ├─ frontmatter.mjs                         # frontmatter解析
│  │  │  └─ metadata.mjs                            # メタデータ抽出
│  │  ├─ md2html/                                   # MD→HTML/sections 変換
│  │  │  ├─ cli.mjs                                 # CLIエントリポイント
│  │  │  └─ pipeline/
│  │  │     ├─ remark-frag.mjs                      # フラグメント分割
│  │  │     ├─ remark-split.mjs                     # セクション分割
│  │  │     ├─ remark-wc-map.mjs                    # WCマッピング
│  │  │     └─ rehype-shiki.mjs                     # Shikiでコード埋め込み
│  │  ├─ mmd2svg/                                   # Mermaid→SVG
│  │  │  └─ cli.mjs                                 # CI側で生成
│  │  └─ pdf-export/                                # HTML→PDF
│  │     └─ cli.mjs                                 # Playwright使用
│  └─ provisioning/                                 # IaCの単一の正（OpenTofu運用域）
│     ├─ modules/                                   # クラウドリソース宣言(Tofu module)
│     │  ├─ storage_bucket/                         # R2バケット
│     │  ├─ cdn_distribution/                       # CDN
│     │  └─ compute_instance/                       # コンピュート
│     ├─ environments/                              # 環境別変数セット(dev/staging/prod)
│     ├─ state/                                     # 開発ローカルstate(.gitignore)
│     ├─ outputs/                                   # tofu output -json の生
│     ├─ cue/                                       # outputのCUEスキーマ/検証
│     ├─ scripts/                                   # plan.sh / verify.sh / export-env.sh
│     ├─ flake.nix                                  # tofu/cue/sops等のバージョン固定
│     └─ README.md                                  # 運用規約・R2 backendの方針
├─ domains/                                         # ドメイン純粋ロジック (外部I/Oなし)
│  ├─ video/
│  │  ├─ flake.nix                                  # nixpkgsのみfollows/devShell禁止
│  │  ├─ video/                                     # パッケージ直置き(src無し規約)
│  │  ├─ ports/                                     # 抽象Port定義 (storage/tts/encoder等)
│  │  └─ tests/                                     # ドメインの純ユニットテスト
│  └─ search/
│     ├─ flake.nix
│     ├─ search/
│     ├─ ports/
│     └─ tests/
├─ apps/                                            # ユースケース/編成 (DI対象)
│  ├─ video/
│  │  ├─ flake.nix                                  # apps.<sys>.video(type=app)を出力
│  │  ├─ usecases/                                  # Command/Query/Handler
│  │  ├─ workflows/                                 # 複数usecaseの編成(旧orchestration)
│  │  ├─ dto.py                                     # アプリ内DTO(Transport非依存)
│  │  ├─ manifest.cue                               # 入出力/依存宣言
│  │  └─ pipeline.cue                               # パイプライン定義
│  └─ search/
│     ├─ flake.nix
│     ├─ usecases/
│     ├─ dto.py
│     └─ manifest.cue
├─ interfaces/                                      # 入口(HTTP/gRPC/CLI/Web)。wireでDI
│  ├─ http-video-django/                            # Django/DRF HTTPエントリ
│  ├─ grpc-search/                                  # gRPCサーバ
│  ├─ cli-video/                                    # CLI
│  ├─ http-opencode-gateway/                        # orchestration HTTPゲートウェイ
│  ├─ web-search-next/                              # Next.js UI
│  ├─ docs-build-cli/                               # ドキュメント生成CLI
│  └─ docs-static-site/                             # 静的サイト配信 (dist/あり)
├─ policy/                                          # 構造ガード (CUE)
│  └─ cue/
│     ├─ schemas/                                   # deps.cue / naming.cue / layout.cue
│     └─ rules/                                     # strict.cue / forbidden-imports.cue 等
├─ ci/                                              # CI定義
│  └─ workflows/
│     ├─ apps-video.yml                             # apps/video のビルド/テスト
│     ├─ http-video.yml                             # http-video-django のCI
│     ├─ grpc-search.yml                            # grpc-search のCI
│     ├─ web-search.yml                             # web-search-next のCI
│     ├─ docs-build.yml                             # docs-build-cli でプリレンダ
│     ├─ slides-export.yml                          # pdf-export でPDF吐く
│     └─ infra-deploy.yml                           # infra/provisioning からTofuデプロイ
└─ docs/                                            # ドキュメント
   ├─ adr/                                          # ADR (設計の背景と履歴)
   ├─ ops/                                          # 運用Runbook(手順)
   ├─ structure/                                    # 今のこのファイル群(構成/責務の正)
   ├─ architecture/                                 # 図(context.mmd等)
   ├─ slides/                                       # スライド原稿(md→PDF)
   └─ dist/                                         # 生成物(.gitignore対象)
```

## 3. 層と依存方向
```text
interfaces → apps → domains → contracts
              ↓
           infra
```

- interfaces は入口(HTTP/gRPC/CLI/Web)だけを持つ。
- apps はユースケース調停とワークフロー。
- domains は純粋ロジック。外部SDKを直接importしてはいけない。
- infra は外部サービスやクラウドへの接続実装と実インフラ定義。
- contracts はスキーマ/IDLなど「契約」のみ。実装禁止。

依存の流れは一方向。逆向き依存は禁止。`policy/cue/rules/strict.cue` でCIチェックする。

## 4. infra/ の分割と境界
- `provisioning/` はクラウドリソースを「作る」宣言(OpenTofu)。
- `adapters/` は既に作られたリソースへ「つなぐ」コード(SDK)。
- 両者は別物。`provisioning → (tofu output / .env) → adapters` という片方向の流れだけ許す。
- `runtimes/` はランタイムやツールの固定セット(python-ffmpeg 等)。
- `presentation-runtime/` と `content-build-tools/` はUI表示系/ドキュメント生成系の共通ランタイム/ツール。

## 5. dist 配置ルール
- ✅ `interfaces/*/dist/` だけが dist を持ってよい (CDNや静的配信対象)。
- ❌ `infra/` 以下は dist を持たない。infraは配信元ではない。

## 6. CUE とガード
- `policy/cue/`:
  - リポ全体の構造・命名・依存方向を静的に検証するCUE。
  - ここはリポ構造を守る番人。
- `infra/provisioning/cue/`:
  - OpenTofuの `tofu output -json` の値を型チェック/整合性チェックするCUE。
  - 本番インフラの実データが契約どおりかを見る。
- 分離ルール:
  - `provisioning/cue` は `policy/cue` を import しない。
  - 片方がもう片方に依存すると、本番状態によってリポ構成ルールが壊れるから禁止。

## 7. ストレージ / state 方針
- 本番ストレージは R2。S3 は廃止済みで復活禁止。
- CI/開発では R2 互換の MinIO を使う。
- OpenTofu の remote state backend も R2 (CI / 本番)。
- ローカル開発時は `infra/provisioning/state/` (git ignore 済み) を使う。
- この前提に合わせて `infra/adapters/storage/` も R2 実装がデフォルト。
- 監視ログなど長期保管も R2。SaaSのログ倉庫は必須ではない。

## 8. 再配置マッピング (参照用)
この節は「昔どこにあったか」を示すだけ。新規開発では古いパスを使わない。

- `infra/sdk/ui-wc/x-deck/` → `infra/presentation-runtime/x-deck/`
- `infra/sdk/md-tools/md2html/` → `infra/content-build-tools/md2html/`
- `infra/sdk/md-tools/mmd2svg/` → `infra/content-build-tools/mmd2svg/`
- `infra/sdk/md-tools/pdf-export/` → `infra/content-build-tools/pdf-export/`
- `interfaces/cli-docs/` → `interfaces/docs-build-cli/`
- `interfaces/web-docs-vanilla/` → `interfaces/docs-static-site/`
- `infra/provisioning/` は 0.11.3 で新設 (OpenTofu / environments / scripts)。
- `ci/workflows/infra-deploy.yml` は 0.11.3 で追加。Tofuデプロイ専用。

## 9. 更新ルール
1. 新しいディレクトリや責務を増やしたら、このファイルを先に更新する。
2. ここで宣言されていない置き場にコードを置かない。
3. 運用手順や具体コマンドは docs/ops/ 側に置く。
4. 「なぜそうしたか」の背景は docs/adr/ 側に置く。

## 10. 関連
- 運用フロー・具体コマンド: `../ops/index.md`
- シークレットや .env の扱い: `../ops/secrets.md`
- manifestガード運用: `../ops/manifest-guard.md`
- 意思決定の履歴と理由: `../adr/`
