# 1人と AI 体制で壊さず拡張し続けるための構造ルールと CI 境界

この文書は docs/structure/index.md の補足であり 1人と AI 体制でリポを壊さず拡張し続けるための具体ルールと CI 境界を定める
catalog adr skeleton src のディレクトリ責務と CI の照合ロジックをここに示す
この内容は CI の仕様書であり AI への制約宣言でもある

## 1. 三つの SSOT の物理配置

```text
catalog/                # カタログの SSOT 責務スロット全集合
  slot-catalog.cue      # 全スロット定義リスト
  schema/
    slot.cue            # 型 Slot  id responsibility owner dependsOn status など
    naming.cue          # id 形式ルール 例 area.path.with.more.dots
    validate.cue        # CI で使う検証ロジック
  slots/
    security/*.cue
    tenant/*.cue
    platform/*.cue
    frontend/*.cue
    ml/*.cue
    device/*.cue
    process/*.cue
    ops/*.cue
    risk/*.cue
    requirements/*.cue
    doc/*.cue
    cm/baseline.cue
    cm/change-request.cue
    external/*.cue      # 外部 SaaS や外部ベンダ責務も同じ一スロットとして管理
  model/
    sysml_allocation.cue
      # 要求 ID -> スロット ID -> 検証手段 という割当
      # 監査や規制で必要なトレーサビリティ線

adr/                    # 意思決定ログの SSOT
  adr-*.cue / adr-*.md  # どのスロットを採用 移譲 破棄するか その理由
                        # どの要求をどこに再割り当てしたか

skeleton/               # 構成スナップショットの SSOT
  tree.snapshot.json    # 実際に使うスロットだけ並べた現在構成
                        # この形以外の場所にコード置くな を示す
  spec/                 # スケルトンを I O API 契約まで具体化した spec
                        # spec がそろって初めて実装開始 OK
  generated/
    report.traceability.json
      # スロット ID -> 要求 ID -> 検証手段 -> ops 証跡
      # 監査と対外提出の証憑ビュー

src/                    # 実装本体
  ...                   # PR で skeleton が許していない場所を増やしたら CI でブロック
```

ポイント

- catalog は 使える引き出し の全集合
- adr は 今回どの引き出しをどう使うか その理由
- skeleton は その決定を踏まえた現行の形と spec
- src は skeleton の指示どおりにだけ触れる場所

## 2. CI が見るもの

### 2.1 catalog 検証

- 全スロットが schema/slot.cue の Slot 型を満たすこと
- id は area.path.with.more.dots 形式 先頭 area は固定列挙
- responsibility は一文だけ
- owner は一人だけ active スロットでは必須
- dependsOn は catalog 内の別スロット ID だけ参照可
  循環や自己参照は NG
- external 系も同じ制約で管理する

これで 勝手な新責務スロット を生やすことを不可能にする

### 2.2 adr と skeleton の照合

- skeleton/tree.snapshot.json に含まれるスロットは どれも直近の ADR で採用 移譲 維持 が正当化されていること
  いまこのスロットを使っていい理由 が明文化されていること
- ADR で宣言していないスロットを skeleton に勝手に入れたらブロック
  やりたいから入れた は許さない

### 2.3 skeleton と src の照合

- PR で新しいフォルダやサービスを増やしても skeleton が許していない場所なら CI で弾く
  スケルトンをすっ飛ばしてリポジトリを肥大させることを防ぐ

これで 責務のにじみ を物理的に止める

### 2.4 out of scope CI が見ないもの

- spec と src の乖離そのもの コードが仕様どおり動いているか は CI の別フェーズ または人間レビュー
- この分割は過剰では という美観や最小性は人間判断
- その機能がビジネス的に意味あるか は経営判断
- PoC 残骸の検知は別 repo で将来対応

要するに CI は 構造の正当性 だけを見る
感性や戦略や価値判断は見ない

## 3. この構造で何が保証されるか

### 3.1 catalog adr skeleton を順番に踏まないと実装に入れない

- catalog は スロット辞書 使える責務の定義
- adr は どれを採用し どこに置くかの意思決定ログ
- skeleton は それを具体的な形に落とした構成と spec
- src は skeleton に従うだけ

この順番を破って PR すると CI で止まる

### 3.2 ADR は 通行証 になる

ADR は やりたいことを正当化して skeleton に反映させるための通行証になる
理由のない変更は skeleton に入れられない

結果として 責務の拡散 勝手な肥大 闇フォルダ がそもそも成立しない

### 3.3 時系列 ADR は未来の判断のガイドになる

ADR には その時点のビジネス意図 リスク回避意図 安全や監査の都合が残る
後で構成を戻す 畳む 移す ときは そのログをもとに どこをいじるべきか いじると何を壊すか が読める

### 3.4 三つの正 は役割が被らない

- catalog 使ってもよい責務スロットの辞書の正
- adr どのスロットをいつどう採用 移譲 破棄すると決めたかの正
- skeleton この瞬間のシステム構成と契約の正

混ぜないので どれを見ればいいか毎回わかる

この文書のルールは CI が強制する前提である
catalog から adr を書かず skeleton を経ずに src を直接いじる差分は 受理しないし CI で拒否する
