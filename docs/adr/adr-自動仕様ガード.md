# ADR: 自動仕様ガード (spec-guard) 導入
Status: Accepted
Date: 2025-11-02
AffectsTree: true  # このADRの内容は docs/tree.md を更新すべきなので true
Labels: spec-drift / logic-conflict 監視

## 背景 / 課題
- 設計の意思決定は ADR (`docs/adr/*.md`) で積み上げる。
- リポ全体の「唯一の正（SSOT）」は `docs/tree.md` に宣言としてまとめる。
- 人間の更新漏れ・記憶違いで次が起きる:
  - drift: ADRのほうが新しいのに `docs/tree.md` が追いついていない
  - logic-conflict: `docs/adr/*.md` と `docs/tree.md` の主張が同時に成り立たない
- このズレと矛盾は必ず発生し、放置すると仕様が壊れる。

## 目的
1. drift と logic-conflict を自動で検知する
2. 検知内容を GitHub Issue で人間に通知する
3. 修正は人間がPRでやる（人間が最終責任を持つ）
4. Claude は診断と提案コメントだけ行う
5. bot が勝手にIssue乱発・PR作成しないよう権限を分離する

## 用語
- drift:
  - AffectsTree: true な ADR があるのに `docs/tree.md` がまだ反映されていない状態
- logic-conflict:
  - `docs/adr/*.md` と `docs/tree.md` の宣言が同時に成り立たない状態
  - または ADR 同士の宣言が同時には成り立たない状態

## 構成
- `docs/adr/`
  - すべてのADR
  - 各ADRは `AffectsTree: true|false` を持つ
    - true = このADRは `docs/tree.md` の更新を要求する
- `docs/tree.md`
  - このリポの最新レイアウトと責務の宣言ツリー
  - 「唯一の正（SSOT）」
- `scripts/validate_spec.js`
  - drift検知用のスクリプト
  - 仕組み:
    - `docs/adr/*.md` の中で AffectsTree: true の最新コミット時刻と
      `docs/tree.md` のコミット時刻を比べる
    - ADR側のほうが新しいのに tree.md がまだ変わってなければ drift=true
  - 出力: `drift-result.json` (drift=true/false, 差分対象ADR一覧など)
- Claude診断ステップ
  - `docs/adr/*.md` と `docs/tree.md` を読み
    論理的に同時成立しない宣言があるかだけをJSONで返す
  - 出力例:
    - `logic_conflict`: true/false
    - `logic_summary`: 人間向けサマリ
    - `affected_files`: 関係するADRやtree.md
  - ClaudeはここでIssueを作らない。JSONを出すだけ
- `scripts/create_or_update_issue.js`
  - `drift-result.json` と ClaudeのJSON(論理矛盾)を読み
  - 2種類のIssueだけを起票/更新する:
    - `spec-drift`
    - `logic-conflict`
  - すでに同ラベルでOpenなIssueがあれば新規起票せず更新だけ
  - 起票するIssue本文の末尾に `@claude` を入れて、
    Claudeに「修正方針と次の手順をコメントで提案して」と依頼する
  - Claude自身には `issues:write` を渡さない
    → 起票は常にこのスクリプト経由
- `.github/workflows/spec-guard.yml`
  - cron + docs/adr/** / docs/tree.md へのpushで動く
  - 手順:
    1. `scripts/validate_spec.js` で drift 判定
    2. Claude を1回だけ呼び、論理矛盾のJSONを受け取る
       (ClaudeにはIssue作成権限なし)
    3. `scripts/create_or_update_issue.js` を実行し、
       必要なら `spec-drift` / `logic-conflict`
       Issueを最大1本ずつだけ作成or更新する
  - `issues:write` 権限は `create_or_update_issue.js` 実行ステップだけに付与する
- `.github/workflows/claude-mention.yml`
  - IssueやPR本文/コメントに `@claude` が含まれた時だけClaudeを呼ぶ
  - Claudeは「提案コメントを書く」だけ
  - PRを勝手に作らない / マージしない
  - `if:` で bot自身のコメントでは再発火しないようにして無限ループを防ぐ

## 運用フロー
1. cron or push で spec-guard.yml が動く
2. drift / logic-conflict を検知
3. `spec-drift` / `logic-conflict` ラベルのIssueを最大1本ずつだけ自動で立てる or 更新する
4. Issue本文の末尾に `@claude` があるので、
   Claudeが修正方針と次の手順をコメントで提案する
5. 人間が docs/adr/*.md と `docs/tree.md` を更新するPRを作る
6. 直ったらIssueをClose
7. Close済みラベルのIssueは次回以降は新しく乱立しない

## 将来
- このspec-guardを Required check に昇格させ、
  drift や logic-conflict があると main にマージできないようにする拡張が可能
- ただし現時点ではまだ「検知→Issue通知」止まりにしておき、
  ワークフローを安定させる
