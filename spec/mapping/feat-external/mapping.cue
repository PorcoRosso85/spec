package mapping

import "github.com/porcorosso85/spec-repo/spec/schema"

// 内部機能URN ↔ 外部標準URN のマッピング
// - 内部URNと外部標準を完全分離し、ここだけで橋渡し
// - 現時点では空配列（将来の外部標準紐付け用）
mappings: [...schema.#FeatExternalMapping]
mappings: []

// 将来の拡張例:
// mappings: [
//     {
//         internal: "urn:feat:decide-ci-score-matrix"
//         external: "urn:ietf:rfc:xxxx"
//     },
// ]
