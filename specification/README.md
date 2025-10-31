# specification ディレクトリの契約

このフォルダは “提供側（spec側）“ の公開物カタログ。
利用側プロジェクトはここを vendor して使う。

## 必須エクスポート (各 spec/<layer>/<spec>/flake.nix )
1. `packages.${system}.cueModule`
   - 純CUEツリーをNixでビルドした最終形。
   - これを import すれば使える状態になっていることが契約。

2. `apps.vendor`
   - `cue.mod/pkg/<module>` に symlink/copy する処理を提供。
   - `--mode=symlink` と `--mode=copy` の両方に対応する。
   - `--dry-run` / 上書き検知 など最低限のUXを持つ。

3. `devShells.${system}.default`
   - 固定バージョンの `cue` CLI を含む開発シェル。
   - CI でもこのシェルから `cue fmt -n` / `cue vet -c` / `cue eval -c` を実行する。

(任意) `meta.cueModulePath`
- 期待される import 文字列。
- `cue.mod/module.cue` の `module:` と一致しなければならない。

## checks/ フォルダ
各 spec は `checks/` を持てる。ここには *その spec 独自の* 健全性・スモークのみ置く。
- 例: vendor後に `cue eval` が落ちないか。
- 例: module名が想定どおり import できるか。
- これらは Nix derivation または `nix develop -c ...` から叩かれるだけ。
- bash等で終了コードのみ返す極小スクリプトでOK。

## 自動生成 index.json
`specification/index.json` は `nix run .#index` で自動生成される。手で編集しない。
- 各specの `{ name, modulePath, rev, narHash }` を列挙。
- 未コミット差分があれば CI でFailさせる。

## 互換性チェック (任意)
`PUBLIC.cue` を持つspecだけ `cue diff` で公開インターフェイスの互換性を監視する。
`PUBLIC.cue` がないspecはこのチェックをスキップしてよい (YAGNI)。