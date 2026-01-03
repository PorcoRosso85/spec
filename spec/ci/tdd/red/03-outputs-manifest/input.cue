// DoD3: outputs明確 - RED入力（不一致を含むfixture）
// Purpose: manifestに宣言されていないpathがactualに存在するケース

package red_03_outputs_manifest

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

input: det.#OutputsManifestInput & {
	expected: {
		paths: [
			"spec.cuePath",
			"spec.schemaPath",
			"spec.urn.featPath",
			"spec.urn.envPath",
		]
		version: "v0.1.0"
	}
	
	actual: {
		paths: [
			"spec.cuePath",
			"spec.schemaPath",
			"spec.urn.featPath",
			"spec.urn.envPath",
			"spec.undeclaredPath", // 未宣言のパス（不一致）
		]
		version: "v0.1.0"
	}
}
