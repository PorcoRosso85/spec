# adr-1人AI体制で壊さず拡張し続ける.md

## 1. 背景

* 開発は「自分＋AI」で回す。
* 思いついた機能や改善をその場でコードに直接足すと、責務があいまいなまま肥大していく。
* いったん責務境界がにじむと後から戻すのはほぼ不可能になる。なぜなら「どこまでが誰の役割だったか」の線が消え、将来の自分が再分離できなくなるから。
* それは最終的に「本番を壊せるのは自分だけなのに、自分ですらどこ触ると壊れるか分からない」という最悪状態に行く。これは売上まで止めるリスク。
* このADRは、その崩壊を構造で物理的に防ぎ、かつ将来の自分とAIが安全に拡張し続けられるようにする。

## 2. 目的

2.1 好きなときに機能を足し続けたい。ただし勝手な肥大・責務のにじみは物理的に禁止したい。  
2.2 「今この瞬間の正しい構成」と「なぜそう決めたか」を、常に1発で説明できるようにしたい。  
2.3 将来の自分や将来の参加者が、最小の資料だけで「どこを触ると壊れるか」「どこは安全か」を判断できるようにしたい。  
2.4 AIに作業を任せても、AIが勝手に新しい責務や新しいディレクトリを増やせないようにしたい。  
2.5 規制・監査・要求トレーサビリティ（ISO/IEC/IEEE 29148ライン）を後付けではなく、日常の更新ログそのものから即出したい。

## 3. 決定

このリポジトリでは、「正」を3種類に分離して持つ。混ぜない。

### 3.1 カタログ（catalog = タンスそのもの）

* 物理パス: `docs/catalog/**`

* 中身:
  * `slot-catalog.cue`
    * 全スロットの集約 (id -> #Slot)。これが唯一の正。
  * `schema/slot.cue`
    * スロットの型。
    * `id`（例: `nist80053.AC-access-control`）
    * `responsibility`（そのスロットの義務。必ず1文 = SRP）
    * `owner`（単独責任者）
    * `dependsOn`（他スロットID）
    * `status` = `"abstract" | "active" | "deprecated"`
    * `tier` = `"business" | "app" | "infra"`
    * `standardRef`（元になった標準のIDリスト）
    * `notes`
  * `schema/naming.cue`
    * `id`は `<source>.<duty[.sub...]>` という安定ID
    * `<source>` は標準ソース（例: `nist80053`, `saaslens`, `sre`, `sysml81346`, `itilCSDM`, `audit`, `requirements`, `risk`, `process`）
    * これで長期参照・監査説明が安定する
  * `schema/validate.cue`
    * CIで使う検証ロジック
    * `responsibility` は1文
    * `status=="active"` なのに `owner` が空はNG
    * `dependsOn` は未登録ID禁止・明らかな循環禁止
    * 同じような `responsibility` を別IDで重複させない（DRY）。厳しさは今後強化する
    * `"abstract"` なスロットが後述の skeleton に現れていないこともチェックする
  * `slots/*.cue`
    * 具体的なスロット定義の束
    * 例:
      * `nist80053.cue`
        * `nist80053.AC-access-control`
        * `nist80053.AU-audit-accountability`
        * …
        * これらはNIST SP 800-53の各統制ファミリー由来
        * 初期状態は `status: "abstract"` にして入れる
      * `saaslens.cue`
        * `saaslens.tenant-isolation`
        * `saaslens.billing-metering`
        * SaaS Lensの責務
        * 同じく初期は `"abstract"`
      * `sre.cue`（SLO/エラーバジェットなど）
      * `nist80061.cue`（インシデント検知・封じ込めなど）
      * `sysml81346.cue`（デバイス/ファーム責務）
      * `itilCSDM.cue`（ベースライン、変更要求、外部委託責務など）
      * `audit.cue`（提出済み証憑管理責務）
      * `requirements.cue`（機能要求/NFR/規制要求。要求そのものは世界中で"requirement"と呼ばれるのでこのprefixが安定用語になる）
      * `risk.cue`（安全・プライバシ・コンプライアンスの拘束要求）
      * `process.cue`（変更管理、リリースゲート、運用プロセス。ISO/IEC 12207やAPQCなどの業務/工程プロセス分類を反映）
  * `model/sysml_allocation.cue`
    * `requirement_id -> slot.id -> verify手段`
    * 「どの要求が、どのスロットに割り当てられ、どう検証されるか」を明文化した表
    * これは29148で求められるトレーサビリティ線（要求→割当→検証）に対応する

* 運用ルール（この決定が肝）:
  * カタログにないスロットは存在しないものとして扱う。
  * 新しい責務スロットを勝手に発明してコードに入れることはCIが禁止する。
  * スロットは最初 `"abstract"` で入るだけ。
  * 本番・実装に使っていいのは `"active"` のスロットだけ。
  * `"deprecated"` は歴史のために残すが、新しい実装には使えない。

→ これは「どんな引き出しがあるか」「何をその引き出しに任せるのか」を固定したタンス（唯一の正）  
→ 5原則（特にSRPとDRY）に沿って1責務=1スロットを強制する

### 3.2 ADR（意思決定ログ）

* 物理パス: `docs/adr/adr-*.cue`, `docs/adr/adr-*.md`
* 役割: 「どのスロットを今回使う／移す／やめるか」「なぜそう決めたか」を時系列で残す
* 具体的には、ADRはこういうことを書く:
  * どの `slot.id` を `"abstract" → "active"` に昇格させるか
  * どの `slot.id` を `"active" → "deprecated"` に落とすか
  * どの `slot.id` をどの配置パスに置くか（後述の skeleton に反映させるための宣言）
  * なぜその変更が正当なのか（ビジネス上/安全上/監査上の理由）

* このログがないスロット変更は無効扱い
* つまりADRは「今回この責務を公式に採用していい」という通行証になる

* 運用イメージ:
  * スロットを本番で使いたいなら、まずADRを書く
  * ADRがマージされたら、そのスロットの `status` は `"active"` に変わる
  * それが次にskeleton.jsonへ反映されて、実装許可が出る

* このADR自体も監査証跡になる
  * なぜこの責務を外部SaaS側に逃がしたのか
  * なぜテナント隔離を別ブロックに分離したのか
  * そういった判断理由が記録に残る
  * 将来「戻したい／畳みたい」と思ったときの根拠になる

→ ADRは“なぜそうしたのか”の唯一の正  
→ カタログが「箱の定義」、ADRが「その箱を採用・配置すると宣言した瞬間の記録」

### 3.3 構成スナップショット（structure）

* 物理パス: `docs/structure/.gen/`
  * `skeleton.json`
    * 今の正式な構成スナップショット
    * 形式イメージ:
      """json
      {
        "nist80053.AC-access-control": "apps/authz/",
        "saaslens.billing-metering":   "features/billing/",
        "sre.slo-definition":          "infra/observability/"
      }
      """
    * 意味:
      * どの slot.id が、どの実ディレクトリ/モジュール配下に存在してよいか
      * `apps/`・`domain/`・`infra/`・`interfaces/`・`features/` 等どこに置くかはここが唯一の真実
      * ここにないパスで新フォルダや新モジュールを生やそうとするPRはCIで拒否
      * つまり「勝手に責務ブロックを増やす」「勝手に境界線をにじませる」を物理的に止める
    * 注意:
      * `tier`（`"business" | "app" | "infra"`）はスロット自体が持つメタ
      * だが「apps/ に置くか features/ に置くか」はここで自由に決めてよい
      * 事前ルール（tier→appsなどの固定マッピング）は設けない
      * 自分の設計判断でslotをどこに落とすかを毎回宣言する
      * これにより柔軟なDDD構成（`apps/` / `domain/` / `infra/` / `interfaces/` だけでなく `features/` など）も許容できる

  * `traceability.json`
    * CIが自動生成。人間編集禁止
    * 含むもの:
      * 各要求ID・リスクID から どの `slot.id` に割り当てたか（= `docs/catalog/model/sysml_allocation.cue` 由来）
      * その `slot.id` が `skeleton.json` でどこに配置されているか
      * その `slot.id` の検証手段（テスト・観測・証跡）
      * 運用SLO・監査提出済み証憑（例: `audit.certification` など）
    * これが「要求→責務→配置→検証→本番証跡→監査提出物」までの鎖になる
    * この鎖はISO/IEC/IEEE 29148が要求するトレーサビリティ（要求から検証証跡まで）にそのまま使える

→ structure配下は「今のシステムはこうなっていて、こう証明できます」のSSOT  
→ `skeleton.json` は人間が作るが `traceability.json` はCIが再生成してロックする  
→ どちらも `docs/structure/.gen/` にあり、`.gen` は生成物扱いだが `skeleton.json` は“この瞬間の正”なのでレビュー対象になる

## 4. CIの責務

CIは「3つの正」（catalog / adr / structure）だけを照合し、矛盾を止める。

* catalog検証
  * `docs/catalog/schema/validate.cue` に従って `#Slot` を全チェック
  * `status=="active"` なら `owner` 必須
  * `"abstract"` なものが `skeleton.json` に現れたらブロック
  * `dependsOn` 未登録や循環を最低限禁止
  * `responsibility` の重複を検知し、明らかに同じ義務を複数IDにしない（DRY）

* adr ↔ skeleton.json
  * `skeleton.json` に出てくる全ての `slot.id` は、どこかのADRで「active化」「配置」「移譲」など正当化されている必要がある
  * ADRなしで勝手に新しい `slot.id` を `skeleton.json` に入れたらアウト

* skeleton.json ↔ 実コード配置
  * PRで新しいディレクトリやモジュールを追加したとき、そのパスが `skeleton.json` にないならアウト
  * 逆に `skeleton.json` に許可されたパス内の変更は通る
  * つまり勝手な境界拡大は物理的に封じられる

* traceability.json
  * CIが自動生成する
  * 人間が編集していたらアウト
  * これによって「要求→責務→配置→検証→本番証跡→監査提出」の鎖が常に最新状態で揃う

CIがあえて見ないもの:
* その仕様(`specification/**`)とコードの完全一致までは見ない（そこは別フェーズのレビュー）
* ビジネス上の優先順位・売上インパクトは見ない
* 美しさ（もっと統合できたのでは？）は見ない
* PoCの汚い残骸をどうするかは別で扱う

→ CIは「構造と正当性（正しい箱・正しい場所・正当な理由でそこにあるか）」だけに集中する

## 5. 効果

5.1 自由に足せるが、勝手ににじませることはできない
* 何か新しいことをしたければ、まずカタログにスロット（タンスの引き出し）を追加する
  * なければ新スロットを追加するが、その時点では `"abstract"`
* ADRを書いて「このスロットを使う/移す/やめる」理由を残す
* `skeleton.json` にその `slot.id` をどこに置くかを書く
* そこまでやって初めて、その場所に実装が許される
* このルート以外でコードを増やそうとするとCIが止める

5.2 将来の自分が守られる
* 「なぜこれがここにあるの？」→ ADRが答え
* 「どこを直せば壊れる？」→ `skeleton.json` が答え
* 「この要求ちゃんと満たしてるの？」→ `traceability.json` が答え
* 自分＋AIで進めても、半年後の自分が読み返して安全にいじれる

5.3 監査・29148要求の説明も即出しできる
* 要求ID→どの `slot.id`→どの配置パス→どの検証手段→どの本番証跡→どの監査提出物、までの線が `traceability.json` に常にそろっている
* これは要求トレーサビリティ（ISO/IEC/IEEE 29148）や外部審査でほぼそのまま使える

---
