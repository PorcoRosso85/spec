# Structure: 実装ディレクトリ外部化の運用とスコープ定義

## スコープ定義（Boundary）
- **本repo（In scope）**  
  - `docs/catalog/**`, `docs/adr/**`, `docs/structure/.gen/{skeleton.json, traceability.json}`  
  - `specification/**/flake.nix`（契約属性のみ）
- **本repoのスコープ外（Out of scope）**  
  - 実装ディレクトリ：`apps/`, `infra/`, `domain/`  
  - 実装のビルド/テスト/配布  
  - これらは**外部repo**で管理する

> CIは「境界チェック」でスコープ外の変更を検知し、**別repoへ移動**を促す（禁止ではなく「スコープ外」の案内）。

## skeleton.json エントリ形式
```json
{
  "_meta": { "version": "0.2.0" },
  "custom.repo-structure-guard": ".github/workflows/repo-guard.yml",
  "app.video-encoder": {
    "kind": "external",
    "flake": "github:org/app-repo?dir=apps/video-encoder",
    "rev": "abcdef1234567890",
    "revPinned": true,
    "attrPath": "contracts.app-video-encoder"
  }
}
```

## specification/**/flake.nix（契約の最小形）

* 外部実装が満たすべき**契約属性**を公開（例 `contracts.<slotId>`）。
* 本repo CIは**存在のみ**確認（**非ビルド**）。

```nix
{
  description = "contract for app.video-encoder";
  outputs = { self, ... }:
  {
    contracts.app-video-encoder = {
      api = [ "encode" ];
      io = { in = "video"; out = "mp4"; };
    };
  };
}
```

## CI（境界チェック＋参照健全性）

* **境界チェック**（skeleton-guard）

  * 本repoの範囲外（`apps/`, `infra/`, `domain/`）への追加は**スコープ外の変更**として検知し、外部repo移動を提案。
* **external-refs-validate**

  1. 許可ドメイン（`github:`）
  2. `revPinned:true` かつ `rev` 必須
  3. `nix flake metadata '<ref>?rev=<rev>'` が成功
  4. `nix eval '<ref>?rev=<rev>#<attrPath>' --json` が成功

  * いずれも**非ビルド**で実施

## 運用ポリシー

* 本repoは**設計/契約/参照健全性のみ**に集中（実装は扱わない）。
* rev更新はPRでのみ実施（監査容易性を確保）。
* 強制化は段階移行（まず観察モード→安定後に必須化）。
