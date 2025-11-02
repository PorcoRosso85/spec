# docs/tree.md — リポ全体の宣言ツリー / 唯一の正(SSOT)

このファイルは「このリポの現時点の正式なディレクトリ構成と責務」を宣言する。
ここに書かれた内容が唯一の正(SSOT)。
実ディレクトリやCI/運用はこの宣言に従うべき。

このファイルは監視対象:
- AffectsTree: true な ADR が追加/更新されたら、必ずこのファイルも追記・更新されるべき
- もし追いついていなければそれは drift
- ADR とこのファイルの主張が同時に成り立たないなら logic-conflict

## トップレベル構成 (宣言)

```text
repo/
├─ docs/                       # 内部向けドキュメント・運用・背景メモの正
│  ├─ adr/                     # 設計判断ログ (1PR1ADR, append-only)
│  │   └─ adr-spec-guard.md    # ← このPRで追加。spec-guardの正式化
│  ├─ structure/
│  │   └─ index.md             # リポ全体の責務とツリーの説明（人向けの長文）
│  ├─ ops/                     # 運用手順や secrets など内部限定の運用知識
│  ├─ dist/                    # 外部公開してよい生成物だけ (pSEO等)
│  └─ tree.md                  # ← このファイル（SSOT宣言）
│
├─ specification/              # 実装仕様とふるまいの正
│  ├─ <module-name>/
│  │   ├─ flake.nix            # 外部に約束する出口 (packages.cueModule / apps.vendor / devShells.default)
│  │   ├─ cue/                 # CUEで宣言する制約・契約・構成
│  │   └─ checks/              # CI/guard用の検証
│  ├─ index.json               # specモジュールのカタログ (flakeから自動生成)
│  └─ dist/                    # 外部公開用に整えた仕様説明 (対外向け)
│
├─ interfaces/                 # DDDでいう I/O 境界 (API, CLI, エントリポイント)
│  ├─ cli/
│  │   ├─ flake.nix            # 生成環境をpin
│  │   └─ main.mjs             # CIやローカルから docs/dist と specification/dist を再生成するCLI
│  ├─ http-*/                  # HTTPエンドポイントなど
│  ├─ grpc-*/                  # gRPCサーバなど
│  └─ ...                      # 公開用の静的ページ本体は置かない
│
├─ apps/                       # ユースケース層 / オーケストレーション層
│                              # 複数ドメインやインフラを束ねて具体的な振る舞いを作る
│
├─ domains/                    # ドメインロジックの純粋な中心
│                              # 副作用なしのビジネスルール
│
├─ infra/                      # 実インフラと依存の束
│  ├─ content-build-tools/     # md→html, mermaid→svg 等の生成系ツール
│  └─ provisioning/            # IaCの正 (OpenTofu + CUE + pinned nix)
│
├─ policy/                     # 命名/依存/レイアウトなどのガードをCUEで定義
│
├─ ci/                         # CIワークフロー
│                              # flake経由で dist/ を再生成・配信するなど
│
├─ dist/                       # （将来）公開境界としてのビルド済み成果物をまとめる候補
│                              # 現状は docs/dist, specification/dist を優先し
│                              # トップレベルdist/はまだ固定しない/使わない場合もある
│
└─ README.md                   # リポの入口
```

## 不変ルール (Invariants)

1. この `docs/tree.md` が唯一の正 (SSOT)。  
   ここが最新に追いついていないなら、それは drift。

2. すべてのADRは `docs/adr/*.md` に追加される。  
   既存ADRは基本的に書き換えず、常に追記で進化させる（append-only）。

3. 各ADRは `AffectsTree: true | false` を必ず持つ。  
   - true なら、このADRはツリーや責務に影響する。  
   - true のADRがマージされたら、`docs/tree.md` も必ず更新されるべき。  
   - true なのに `docs/tree.md` が未更新なら drift とみなす。

4. 定期的/Push時に `.github/workflows/spec-guard.yml` が走り、  
   drift と logic-conflict を検知して、最大で2種類のIssueだけを自動で扱う。  
   - `spec-drift` ラベル  
   - `logic-conflict` ラベル  
   同じラベルのOpen Issueがあれば乱立させない。

5. Issue本文の末尾には `@claude` を入れる。  
   Claudeは「どう直すべきか」「どのファイルを更新すべきか」をコメントで提案するだけ。  
   Claude自身は `issues:write` を持たないので、自動でIssueを勝手に作ったりPRを勝手に出したりはしない。

6. mainにマージする修正PRは人間が最終責任で用意/承認する。  
   Claudeは提案・診断役に限定する。

---

これが破られていると検知された場合、`spec-drift` や `logic-conflict` Issueで必ず表に出る。  
この運用により、仕様のズレや矛盾は放置されず、docs/tree.md が常に最新の正として共有され続ける。
