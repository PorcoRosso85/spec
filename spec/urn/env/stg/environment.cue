package env

import "spec/schema"

// stg: ステージング環境
// - urn:env:stg
environment: schema.#Environment & {
	envId: "stg"
	// id: "urn:env:stg" は自動導出される
}
