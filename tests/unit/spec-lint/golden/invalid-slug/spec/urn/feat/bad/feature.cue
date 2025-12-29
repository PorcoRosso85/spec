package feat
import "test.example/invalid-slug/spec/schema"
feature: schema.#Feature & {
    slug: "Bad_Slug"  // Invalid: underscore not allowed
    id: "urn:feat:bad-slug"
    title: "Bad Slug Example"
}
