# 運用ハンドブック / ops

## 1. 目的
- docs/ops/ は「実際にどう回すか」をまとめた現場向け手順書。
- 設計の背景や歴史は docs/adr/ に書く。ここでは手だけ動かせばいいようにする。
- .env や本番インフラを壊さないための最低限の守るべきことを1か所に置く。

## 2. このディレクトリにあるもの
- secrets.md  
  - シークレット/APIキーの追加・ローテーション手順
  - .envの扱いと禁止事項
- manifest-guard.md  
  - 壊すと高額請求/ダウンにつながる設定(manifest)を安全に変える手順
  - PRの作り方
- (この index.md)
  - IaC(OpenTofu)の標準フロー
  - R2/MinIOなど運用ポリシーの要点

## 3. IaC / デプロイ標準フロー
インフラ変更は `infra/provisioning/` からのみ行う。手順は次の通り。

```bash
# 1. Nix環境に入る
cd infra/provisioning/
nix develop

# 2. Plan実行
#    - 開発: ローカルstate (./state/)
#    - CI/本番: R2 backend (ロック有り)
./scripts/plan.sh <環境名>   # dev / staging / prod など

# 3. Apply実行
./scripts/apply.sh <環境名>

# 4. 出力の検証と.env生成
./scripts/verify.sh <環境名>       # CUEで output値 を検証
./scripts/export-env.sh <環境名>   # 検証済みの値だけを .env に書く
```

重要:
- `tofu output` の生値を直で .env にコピペしない。
- 必ず `verify.sh` → `export-env.sh` の順で経由する。
- これが .env の唯一の正しい入り口。手書きで追加しない。

## 4. ストレージ / state のポリシー (要約)
- 本番ストレージ: R2 が唯一のクラウドストレージ。S3 は禁止 (再導入もしない)。
- CI/開発: MinIO (R2互換) を使う想定。
- OpenTofu の remote state backend も R2 (CI / 本番)。
- ローカル開発時の state は `infra/provisioning/state/` (git ignore 済み)。
- 監視ログなどの長期保管も R2 側に積む想定。SaaSのログ倉庫は必須ではない。

この前提に合わせて:
- `infra/adapters/storage/` のデフォルト実装は R2。
- `infra/adapters/storage/s3/` は削除済み。復活禁止。
  - 誤って復活させたPRはCIで落とす予定。

## 5. よくあるタスク
1. シークレットを更新したい  
   → `secrets.md` の「ローテーション手順」をそのまま実行。
2. 新しい環境変数を追加したい  
   → `secrets.md` の「追加手順」。  
   → `.env.example` のダミー値も忘れずに更新する。
3. 危険なmanifestを変えたい  
   → `manifest-guard.md` の「変更前チェックリスト」を読んでからPRを切る。
4. デプロイしたい / IaCを反映したい  
   → 上の「IaC / デプロイ標準フロー」を実行。

## 6. セキュリティで絶対NGなこと
- 検証前の値を直接 .env に書く。
- シークレットを平文で git にコミットする。
- main に直接 push して本番を変える。
- 影響範囲が分からないまま課金系や公開範囲系のフラグを true/公開に変える。

これを破った変更は即revert対象。

## 7. メンテナンス指針
- コマンド例は「実際に動く形」だけを書く。ダミーの嘘コマンドは置かない。
- 手順が変わったら、まず docs/ops/ を直す。過去手順は消す。
- 個人メモや試行錯誤メモはPRマージ前に本文へ整理してから入れる。

## 8. 関連リンク
- シークレットの管理: `./secrets.md`
- manifest保護とPRの書き方: `./manifest-guard.md`
- リポジトリの構成と依存ルール: `../structure/index.md`
- なぜそういうルールにしたか: `../adr/`
