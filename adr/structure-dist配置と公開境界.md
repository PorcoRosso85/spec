# 構造メモ: dist配置と公開境界 (draft)

このメモは 現状のリポ構造と dist/ 運用ルールを日本語で宣言しておくもの。docs/structure/index.md 本体は触らず このメモとADRで合意を残す。

---

## ディレクトリの役割

### docs/
- 内部向けドキュメントと運用知識の正。
- 手順書 や secrets系 や SLOメモ などもここに置く。
- 公開前提ではない。
- docs/dist/ だけが "外に出してよい形に整えたもの" になる。

### specification/
- 実装仕様・挙動・制約などの生の説明。開発者/実装者のための資料。
- ここも基本は内部向けの正。
- specification/dist/ は 外部の利用者やパートナーに読ませてもいい形に整えた仕様説明だけを置く。

### interfaces/
- DDDでいうインターフェース層 (I/O境界)。
- CLIエントリやAPIエンドポイントなど 外部との境界(入出力)がここに来る。
- CIから dist/ を生成する専用CLIもここ (interfaces/cli/) に置く想定。
- ただし ここには公開サイト本体(完成HTMLなど)は置かない。
  - 公開静的ページはあくまで docs/dist/ や specification/dist/ が持つ。

### adr/
- 設計判断ログ。1PRにつき1本。日本語でOK。古くなったら消しても良い。
- dist運用やinfra方針など 変更のたびにここへ新しいADRを積み増す。

---

## dist/ の扱い

- dist/ は "この下は基本的に公開OK" のサイン。
- dist/ は各ソースディレクトリ直下に置く。例:
  - docs/dist/
  - specification/dist/

- dist/ 配下は 元ソース側のパスをミラーする。
  - 例: docs/public/structure.md → docs/dist/public/structure.html
  - 例: specification/api/video.md → specification/dist/api/video.html

- これにより 生成物から元ソースを一意に逆引きできる。
- ミラーにならない単発ファイルを dist/ 直下に手書きで置くのは禁止。

---

## 意図していないディレクトリを増やさない

- www/ や site/ のような曖昧なトップレベルを作らない。
- 公開境界は */dist/ で明示する。
- architecture/ (図の出力用トップ) はまだ公式ディレクトリとしては作らない。必要になったら後続PR。
- PDF出力もまだやらない。まずはHTML/Markdownの静的生成に集中する。

---

## この構成で解決すること
1. 内部向けの生情報(docs/, specification/)と 外向けに出す最終物(dist/)が物理的に分離される。
2. DDD上の interfaces/ は I/O境界とCLIに専念できる。公開サイトを無理にinterfaces/配下に置かないで済む。
3. pSEO向けにクローラへ出したいHTMLは docs/dist/ と specification/dist/ だけ見ればよい と宣言できる。
4. dist/ の中身はソースパスをミラーしているので どこから生成されたのかが即座に説明できる。

---

## TODO / 未決
- CI (flake) のどのターゲットで dist/ を更新するか。
- dist 生成のとき secretsや内部運用手順が混入しないフィルタをどこで掛けるか。
- pSEO用のメタ(title / description / schema.org等)を dist側のどの層で付与するか。
- Mermaid→SVG (アーキ図) をどこに置くかは将来決める。今は固定しない。

---

このメモ自体は docs/structure/index.md を直接書き換えずに 変更点だけを差分で説明するための補助。
今後 dist/ 運用や公開境界に変更が入るPRでは このメモと対応するADRを追加していく。
