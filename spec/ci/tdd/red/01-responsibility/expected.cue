// DoD1: 責務配分 - RED期待出力
// Purpose: 禁止責務検出レポートの期待値を定義

package red_01_responsibility

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#ResponsibilityReport & {
	violations: [
		{
			category: "contract-override"
			field:    "contractOverride"
			message:  "Feat must not redefine contracts"
		},
		{
			category: "schema-override"
			field:    "schemaOverride"
			message:  "Feat must not inject custom schemas"
		},
		{
			category: "export-override"
			field:    "exportOverride"
			message:  "Feat must not override exports"
		},
	]
}
