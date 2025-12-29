package feat
import "test.example/duplicate-feat-id/spec/schema"
feature: schema.#Feature & {
    slug: "test-one"
    id: "urn:feat:test"  // Duplicate ID
    title: "Test One"
}
