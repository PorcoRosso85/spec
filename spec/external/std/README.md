# external/std - 外部標準URNカタログ

## 概要

このディレクトリは **外部標準URN箪笥** として機能します。

- **内部URN** (`urn/`) と **外部標準** を完全に分離
- IETF RFC、ISO規格、Cloudflareアカウント等の外部URNをカタログ化
- `mapping/feat-external/` で内部URNと橋渡し

## 現状

現時点では `std.cue` に空配列として定義されています。

## 将来の拡張例

```cue
standards: [
    {
        name: "RFC 9110"
        urn:  "urn:ietf:rfc:9110"
    },
    {
        name: "Cloudflare Account"
        urn:  "urn:cloudflare:account:xxxx"
    },
]
```

## 設計原則

- 外部標準は **事実の記録** として独立管理
- 内部URNに外部情報を埋め込まない（DRY違反を防ぐ）
- マッピングは `mapping/feat-external/` で一元管理
