package env

import "github.porcorosso85/spec-repo/spec/schema"

// prod: 本番環境
// - urn:env:prod
environment: schema.#Environment & {
	envId: "prod"
	// id: "urn:env:prod" は自動導出される
}
