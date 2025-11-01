# structure: dist配置と公開境界ルール (2025-11-01)

この文書は docs/structure/index.md の補足であり、公開境界と dist ディレクトリ運用を明文化する。ADR: adr/adr-dist配置と公開境界.md も参照。

## 1. 基本ルール
- 公開してよい生成物は、元ディレクトリ直下の dist/ に置く
- docs/dist は docs 内から外に出していい内容だけ
- specification/dist は specification 内から外に出していい仕様だけ
- dist/ 配下は元ソースのパス構造をミラーする
- interfaces/ は I/O 境界と CLI 専用。公開ページ本体は置かない
- www や site などのトップディレクトリ名は作らない
- PDF 出力と architecture ディレクトリ正式化はまだ行わない

## 2. 現在のトップレベルツリー (宣言)
```text
repo/
├─ adr/                        # 設計判断ログ (1PR1ADR). 最新の決定を置く
│  └─ adr-dist配置と公開境界.md
│
├─ docs/                       # 内部ドキュメントの正
│  ├─ dist/                    # 外向けに公開して良い生成物 (pSEO 対象)
│  │   └─ ...                  # docs/ 以下のパス構造をミラー
│  ├─ structure/
│  │   ├─ index.md             # リポ全体の責務とツリーの SSOT
│  │   └─ structure-dist配置と公開境界.md  # 本ファイル
│  ├─ ops/                     # 運用手順や secrets 等 内部専用
│  ├─ adr/                     # 過去 ADR のログ (レガシー)
│  ├─ slides/                  # スライド原稿
│  └─ ...                      # 将来の architecture などはここで管理し dist/ に静的出力を吐く
│
├─ specification/              # 実装仕様とふるまいの正
│  ├─ dist/                    # 外部公開してよい仕様説明だけ
│  │   └─ ...                  # specification/ 以下のパス構造をミラー
│  ├─ index.json               # 各 spec モジュールのカタログ (flake で自動生成)
│  ├─ <module-name>/
│  │   ├─ flake.nix            # 外部に約束する出口 (packages.cueModule / apps.vendor / devShells.default)
│  │   ├─ cue/
│  │   └─ checks/
│  └─ ...
│
├─ interfaces/                 # DDD の I/O 境界 (API, CLI 入口)
│  ├─ cli/
│  │   ├─ flake.nix            # 生成環境を pin
│  │   └─ main.mjs             # CI や local から叩いて docs/dist と specification/dist を再生成する
│  ├─ http-*/                  # HTTP エンドポイントなど
│  ├─ grpc-*/                  # gRPC サーバなど
│  └─ ...                      # 公開ページ本体はここに置かない
│
├─ apps/                       # ユースケース / オーケストレーション層
├─ domains/                    # ドメインの純粋ロジック (副作用なし)
├─ infra/                      # 実インフラと依存の束
│  ├─ content-build-tools/     # md→html, mermaid→svg 等の生成エンジン
│  └─ provisioning/            # IaC の正 (OpenTofu + CUE + pinned nix)
│
├─ policy/                     # CUE でのガード (命名/依存/レイアウトなど)
├─ ci/                         # CI ワークフロー (flake 経由で dist を更新して配信する)
└─ README.md
```

## 3. まとめ
- 公開境界は dist/ で統一
- dist/ 以下は元ソースをミラー
- interfaces は I/O と CLI のみ。公開ページを置かない
- www, site など別トップは作らない
