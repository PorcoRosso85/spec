// DoD2: consumer API - GREEN入力（必須属性の欠落を含むfixture）
// Purpose: 必須属性が不足しているケース

package green_02_consumer_api

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

input: det.#ConsumerAPIInput & {
	required: [
		"spec.cuePath",
		"spec.schemaPath",
		"spec.urn.featPath",
		"spec.urn.envPath",
		"spec.outputsManifestPath",
		"spec.version",
	]
	
	actual: [
		"spec.cuePath",
		"spec.schemaPath",
		"spec.urn.featPath",
		// "spec.urn.envPath" は欠落（意図的）
		"spec.outputsManifestPath",
		"spec.version",
		"spec.extraAttribute", // 必須でない追加属性
	]
}
