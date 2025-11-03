# structure-1人AI体制で壊さず拡張し続ける.md

## 1. リポジトリ構成（最終）

```text
repo/
  docs/
    catalog/                             # カタログSSOT（使える引き出し全集合）
      slot-catalog.cue                   # 全スロット (id -> #Slot) これが唯一の正
      schema/
        slot.cue                         # #Slot型
        naming.cue                       # id命名規則: <source>.<duty[.sub...]>
        validate.cue                     # CIルール
      slots/
        nist80053.cue                    # nist80053.* （アクセス制御 など）
        nist80061.cue                    # nist80061.* （インシデント検知・封じ込め など）
        saaslens.cue                     # saaslens.* （テナント隔離・課金メータリング など）
        sre.cue                          # sre.* （SLO/エラーバジェット責務 など）
        sysml81346.cue                   # sysml81346.* （デバイス/ファーム責務）
        itilCSDM.cue                     # itilCSDM.* （ベースライン/変更要求/外部委託）
        audit.cue                        # audit.* （提出済み証憑管理）
        requirements.cue                 # requirements.* （機能/NFR/規制要求）
        risk.cue                         # risk.* （安全/プライバシ/コンプライアンス要求）
        process.cue                      # process.* （開発・変更・業務プロセス）
      model/
        sysml_allocation.cue             # requirement_id -> slot.id -> verify手段
                                         # 要求→責務→検証

    adr/
      adr-0001.cue                       # 機械可読: どのslot.idをactive化/移譲/廃止
      adr-0001.md                        # なぜそう決めたのか（理由・背景）
      ...                                # ADRは時系列で積む

    structure/
      .gen/
        skeleton.json                    # 現行構成スナップショット
                                         #   "slot.id": "配置パス/"
                                         #   ※apps/ domain/ infra/ interfaces/ features/ など自由
                                         #   ※この許可パス以外に新しい場所を増やしたらCIで拒否
        traceability.json                # CI自動生成・人間編集禁止
                                         #   要求/リスク -> slot.id
                                         #   slot.id -> 検証手段
                                         #   slot.id -> 配置パス(skeleton.json)
                                         #   slot.id -> 本番SLO・監査証憑

  specification/
    apps/
      flake.nix                          # apps系エンドポイント/契約
    domain/
      flake.nix                          # ドメインロジック契約
    infra/
      flake.nix                          # 基盤・観測・鍵管理などの契約
    interfaces/
      flake.nix                          # UI・外部IF契約
    # 将来: features/flake.nix 等もOK
    # skeleton.json の配置パスに合わせてここを増やしていく

  apps/                                  # 実コード(アプリケーションサービス等)
    ...
  domain/                                # 実コード(ドメインロジック/ユースケース)
    ...
  infra/                                 # 実コード(観測・鍵・外部統合など)
    ...
  interfaces/                            # 実コード(API, UI, 公開IF)
    ...
  # 将来: features/ なども追加可 (skeleton.jsonで宣言した上で)
```

要点:

* `docs/catalog/**` = 「引き出しカタログ」
* `docs/adr/**` = 「どの引き出しを今回なぜ採用/移動/廃止したか」
* `docs/structure/.gen/skeleton.json` = 「今の正式な配置」
* `docs/structure/.gen/traceability.json` = 「要求→責務→配置→検証→運用証跡→監査提出」
* `specification/**` = 「その配置の契約・I/O・API定義。実装の前提条件」
* `apps/ domain/ infra/ interfaces/ (features/)` = 「実装本体」
* この順番（catalog→ADR→skeleton→specification→実コード）を踏まない変更はCIが止める

## 2. スロットのライフサイクル

### 2.1 "abstract"

* カタログに存在するが、まだ本番では使っていない責務
* ownerは空でもよい
* skeleton.json に出してはならない
* = YAGNI対応。何でも先にタンスに入れておけるが、勝手に使い始めることはできない

### 2.2 "active"

* ADRで「使う」と宣言済みの責務
* owner必須
* skeleton.json に `slot.id -> 配置パス` として載る
* CIはこのパス外での勝手なディレクトリ増設を弾く
* この状態から specification/** と実装に入れる

### 2.3 "deprecated"

* 過去はactiveだったが、もう使いたくない責務
* 歴史と監査説明のため残す
* skeleton.json からは外す
* ここに落とすには再度ADRを書く（なぜやめるのかを正当化する）

## 3. skeleton.json の意味

* skeleton.json は「この瞬間の正式なフォルダ構成と責務の割当」。
* これをいじれば、apps/domain/infra/interfaces/features といった実装側の物理レイアウトを合法的に変えられる。
* 逆に skeleton.json を通さないレイアウト変更はCIで即ブロックされる。
* つまり skeleton.json は「AIや自分が勝手な場所に勝手な責務を生やすこと」を物理で止めるゲート。

## 4. traceability.json の意味

* traceability.json はCIで自動再生成され、人間編集は禁止。
* これは要求IDや規制要求（`requirements.*`, `risk.*`）が、
  どの slot.id に割り当てられ、
  その slot.id がどこに置かれ、
  どう検証されていて、
  どの実運用SLOや監査証憑でその有効性を示しているか、
  を一本の鎖で示す。
* これは監査・顧客説明・規制対応・ISO/IEC/IEEE 29148のトレーサビリティ要求にそのまま使える。
* 「説明責任を後から作文する」のではなく、「常に最新の証拠を吐く」ための自動エビデンス。

## 5. CIの見るものと見ないもの

### 5.1 CIが見る

* カタログ（docs/catalog/**）
  * #Slotに合っているか
  * `status=="active"` なら `owner` が入っているか
  * `dependsOn` が未登録参照や明らかな循環になっていないか
  * 重複責務（同じresponsibility文の別ID）を警告
  * `"abstract"` なslotが skeleton.json に紛れ込んでないか

* ADR（docs/adr/**）
  * skeleton.jsonにあるslot.idが、ちゃんとADRで正当化されているか

* skeleton.json（docs/structure/.gen/）
  * PRが skeleton.json にないパスで新モジュールを増やしていないか
  * skeleton.json 自体に無断で新slot.idを追加していないか（ADRなしはNG）

* traceability.json
  * CIが再生成した内容と一致するか（人間編集していないか）

### 5.2 CIが見ない

* specification/** の契約を本当にコードが守っているか
* 実装がビジネス的に正しいか
* 「もっと小さくまとめられるのでは？」という美観や抽象度
* PoCの産廃除去
  → そこは人間/経営判断の領域として明確に切り離す

## 6. この構造で守れること

### 6.1 勝手な責務の増殖を止める

* 新機能を積みたいなら、まずカタログにスロット（タンスの引き出し）を追加する
* そのスロットをADRで `"abstract"→"active"` に昇格させ、配置を決める
* skeleton.json にその配置を書き、そこにだけコードを置く
* CIはこの順路を破るPRを全部止める
  → つまり、無許可の新境界や横ズレは物理的に発生しない

### 6.2 将来の自分とAIが安全に触れる

* 「この責務はどのディレクトリが正？」→ skeleton.json を見れば即答
* 「なぜここなの？」→ ADRを読めば意図まで即答
* 「この要求は本番でちゃんと守られてる？」→ traceability.json が即答
  → 半年後・1年後の自分が復帰しても、壊さず触れる

### 6.3 監査・規制への回答をテンプレにできる

* 各スロットはソース標準prefixつきID（例: `nist80053.AC-access-control`）で管理している
* だから「NIST 800-53のACはどこで満たしてますか？」と聞かれたら、そのslot.idと配置パスとtraceability.jsonをそのまま出せばいい
* 後追いで資料を再構成しなくていい

---
