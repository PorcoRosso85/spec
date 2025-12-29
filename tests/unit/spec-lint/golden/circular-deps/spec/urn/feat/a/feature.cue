package feat
import "github.com/test/circular-deps@v0/spec/schema"
feature: schema.#Feature & {
    slug: "feat-a"
    id: "urn:feat:a"
    deps: ["urn:feat:b"]
}
