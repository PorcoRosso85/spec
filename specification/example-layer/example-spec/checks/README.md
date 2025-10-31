# checks/ の役割

この spec 専用のスモーク / 整合性テストを置く場所。

最低ライン:
- vendor 後の `cue eval` が成功すること
- `meta.cueModulePath` と `cue.mod/module.cue` の `module:` が一致して import できること
- 対応プラットフォーム (x86_64-linux / aarch64-darwin) で壊れていないこと

これらは Nix derivation か `nix develop -c ./checks/...` 経由で実行されることだけを前提にする。
外部サービスや人手作業には依存しない。