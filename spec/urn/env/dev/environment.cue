package env

import "spec/schema"

// dev: 開発環境
// - urn:env:dev
environment: schema.#Environment & {
	envId: "dev"
	// id: "urn:env:dev" は自動導出される
}
