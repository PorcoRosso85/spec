// DoD1: 責務配分 - RED入力（禁止責務を含むfixture）
// Purpose: 複数カテゴリの責務違反を検出するケース

package red_01_responsibility

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

input: det.#ResponsibilityInput & {
	feat: {
		id:   "urn:feat:test-violation"
		slug: "test-violation"
		
		repo: {
			enabled: true
			path:    "/repo/test"
		}
		
		// 禁止責務1: contract override
		contractOverride: {
			customRule: "this should not exist"
		}
		
		// 禁止責務2: schema override
		schemaOverride: {
			customType: "string"
		}
		
		// 禁止責務3: export override
		exportOverride: {
			customExport: "/path/to/custom"
		}
	}
}
