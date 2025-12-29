package feat
import "github.com/test/duplicate-feat-id@v0/spec/schema"
feature: schema.#Feature & {
    slug: "test-two"
    id: "urn:feat:test"  // Duplicate ID
}
