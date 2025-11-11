# spec - 契約の番人 (Contract Guard)

`spec` は **adr リポジトリが公開する契約（tree-final-nar-*.json）を検証する**専用ツールです。

## 責務

- ✅ `tree-final-nar-*.json` の契約検証（互換性・必須項目・一意制約）
- ✅ `checks.spec-guard` で Green/Red を返す
- ❌ ADR の生成・編集・管理（adr リポジトリの責務）
- ❌ Catalog の管理（adr リポジトリの責務）
- ❌ Skeleton/Tree の生成（adr リポジトリの責務）

---

## アーキテクチャ（片方向・イベント駆動）

```
adr (upstream)
  ├── decisions.jsonl 管理
  ├── catalog URI 管理
  ├── tree-final-nar-<narHash>.json 生成（決定的JSON + narHash）
  └── repository_dispatch(adr-updated) 送信
      ↓ (片方向)
spec (guard)
  ├── tree-final-nar-<narHash>.json 取得
  ├── contracts/skeleton/*.cue で検証
  └── narHashをログ出力 + Green/Red判定

※ spec→adr のACKは将来対応（provisional）
```

---

## 入力フォーマット

### ファイル名規則
- `tree-final-nar-<narHash_8>.json`
- 例: `tree-final-nar-1a2b3c4d.json`
- narHash: `sha256-<base32>` の先頭8文字（内容アドレス化）

### JSON構造

```json
{
  "schema_version": "1",
  "narHash": "sha256-...",
  "generated_at": "2025-11-10T12:34:56Z",
  "generator": "adr-repository",
  "source_uri": "github:PorcoRosso85/adr",
  "slots": [
    {
      "slotId": "custom.repo-guard",
      "owner": "PorcoRosso85",
      "placement": ".github/workflows/repo-guard.yml",
      "status": "active",
      "rationale": "CI enforcement",
      "manifest": {
        "narHash": "sha256-...",
        "created_at": "2025-11-03T00:00:00Z",
        "adr_ref": "adr-0001"
      }
    }
  ]
}
```

### 必須フィールド
- `schema_version`: `"1"` (文字列として厳密)
- `narHash`: rootレベル（`sha256-<base32>`形式）
- `slots[].manifest.narHash`: per-node必須
- `slots[].status`: `"active"` のみ（`"provisional"` は許可しない）

---

## イベント駆動連携

### adr → spec (実装済み)

```yaml
# repository_dispatch(adr-updated)
event_type: adr-updated
client_payload:
  eventId: "01JCXXX..."              # ULID（Outbox再送用）
  treeFinalURL: "https://..."        # tree-final-nar-*.json URL
  narHash: "sha256-..."              # 内容ハッシュ
  timestamp: "2025-11-10T12:34:56Z"
  sender_repo: "PorcoRosso85/adr"    # 送信元検証用
```

### spec → adr (将来対応)
- `repository_dispatch(adr-ack)` は **provisional**（未実装）
- 当面は片方向のみ

---

## 契約検証

### 7つのガード

| # | ガード | 目的 |
|---|--------|------|
| 1 | Sender Allowlist | なりすまし防止（`PorcoRosso85/adr`のみ許可） |
| 2 | narHash Three-Way Match | 改ざん検出（payload/root/再計算の一致） |
| 3 | Concurrency Control | 重複起動抑止（同eventId=1実行のみ） |
| 4 | Size/Timeout Limits | DoS防止（10MB/30s制限） |
| 5 | schema_version | 未対応バージョン拒否（`"1"`のみ） |
| 6 | State Purity | provisional混入検知（`active`のみ許可） |
| 7 | CUE Contract | 型・制約・一意性検証 |

### 検証ルール (contracts/skeleton/*.cue)

- **slotId一意性**: 重複禁止
- **narHashフォーマット**: `sha256-<base32>` 検証
- **per-node manifest**: 各slotに必須
- **status厳密チェック**: `"active"` のみ（treeFinalでは）

---

## ローカル検証

### 依存インストール

```bash
# CUE インストール
curl -fsSL https://cuelang.org/install.sh | sh

# jq インストール（通常プリインストール済み）
sudo apt-get install -y jq
```

### CUE検証

```bash
# 正常系（Green）
cue vet contracts/skeleton/validate.cue contracts/skeleton/test_valid.json -d 'tree'

# 異常系（Red: slotId重複）
cue vet contracts/skeleton/validate.cue contracts/skeleton/test_invalid_duplicate.json -d 'tree'

# 異常系（Red: provisional混入）
cue vet contracts/skeleton/validate.cue contracts/skeleton/test_invalid_provisional.json -d 'tree'
```

### narHash確認

```bash
# rootレベルのnarHash
jq '.narHash' tree-final-nar-*.json

# per-node manifest
jq '.slots[].manifest.narHash' tree-final-nar-*.json
```

---

## CI検証（spec-guard.yml）

### トリガー

- `repository_dispatch(adr-updated)` - adr からの通知
- `push` - main ブランチへのプッシュ
- `pull_request` - PR作成時

### 実行フロー

1. 送信元検証（allowlist）
2. treeFinal.json ダウンロード（サイズ/タイムアウト制限）
3. schema_version 検証
4. provisional state チェック
5. narHash 三者一致
6. CUE契約検証
7. レポート出力（GitHub Step Summary）

### 出力例

```
🔒 Spec Guard Report (Production-Ready)

Event ID: 01JCXXX...
narHash: sha256-1a2b3c4d...
Status: ✅ GREEN

Guards Applied:
  1. Sender Allowlist: ✅ Verified
  2. narHash Three-Way Match: ✅ Payload == Root
  3. Concurrency Control: ✅ Enabled
  4. Size/Timeout Limits: ✅ 0.5MB / 30s
  5. schema_version: ✅ "1"
  6. State Purity: ✅ All active
  7. CUE Contract: ✅ GREEN

Verdict: Contract satisfied, tree is valid.
```

---

## provisional/final 区別

- **provisional**: Issue状態、可視化のみ（tree含む、通知・副作用なし）
- **final**: ADRマージ後、dispatch発火・副作用あり

spec は **treeFinal.json のみ**を検証対象とし、provisional は含まれない前提。

---

## Outbox 再送（Lazy Retry）

- adr側で eventId を Outbox に記録
- dispatch失敗時は同eventIdで再送可能
- spec側は eventId を受け取るが、ACK未実装のため応答なし

---

## ディレクトリ構造

```
/home/user/spec/
├── README.md                           (このファイル)
├── contracts/                          (契約定義)
│   └── skeleton/
│       ├── schema.cue                  (基本型定義)
│       ├── constraints.cue             (検証ルール)
│       ├── manifest.cue                (per-node manifest検証)
│       ├── validate.cue                (統合検証)
│       ├── test_valid.json             (Green用テスト)
│       ├── test_invalid_duplicate.json (Red用: slotId重複)
│       └── test_invalid_provisional.json (Red用: provisional混入)
├── .github/
│   └── workflows/
│       └── spec-guard.yml              (契約検証ワークフロー)
└── docs/                               (運用ドキュメント)
    └── ops/
        └── contract-guard.md           (運用手順)
```

### DEPRECATED ディレクトリ

以下は issue #42 により非推奨になりました（将来削除予定）:
- `docs/adr/` - ADR管理はadrリポジトリへ移行
- `docs/catalog/` - カタログ管理はadrリポジトリへ移行
- `docs/structure/` - skeleton生成はadrリポジトリへ移行
- `scripts/` - 生成スクリプトは廃止（adr側で実装）

---

## 受入条件（Exit Criteria）

以下をすべて満たす必要があります：

1. ✅ adr が `tree-final-nar-<hash>.json` を出力
2. ✅ spec が narHashをログ出力してGreen/Red判定
3. ✅ dispatch失敗時に Outbox から再送可能（adr側実装）
4. ✅ spec に ADR実装物が存在しない
5. ✅ README に I/F仕様が明記
6. ✅ eventId と narHash がログに出力
7. ✅ sender allowlist と concurrency が有効
8. ✅ treeFinal.json が schema_version=="1"、全件state==active
9. ✅ 受入テスト: 正常系Green、違反系（state混入・narHash不一致）でRed
10. ✅ E2E成功: adr final → dispatch → spec Green

---

## ライセンス

MIT

---

## 関連リポジトリ

- **adr**: https://github.com/PorcoRosso85/adr （upstream、ADR/catalog/tree生成）
- **spec**: https://github.com/PorcoRosso85/spec （このリポジトリ、契約検証のみ）
