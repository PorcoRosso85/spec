package feat
import "test.example/duplicate-feat-id/spec/schema"
feature: schema.#Feature & {
    slug: "test-two"
    id: "urn:feat:test"  // Same ID as one
    title: "Test Two"
}
