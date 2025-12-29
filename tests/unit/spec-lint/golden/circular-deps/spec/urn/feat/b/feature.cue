package feat
import "github.com/test/circular-deps@v0/spec/schema"
feature: schema.#Feature & {
    slug: "feat-b"
    id: "urn:feat:b"
    deps: ["urn:feat:c"]
}
