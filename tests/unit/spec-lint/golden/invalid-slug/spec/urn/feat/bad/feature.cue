package feat
import "github.com/test/invalid-slug@v0/spec/schema"
feature: schema.#Feature & {
    slug: "Bad_Slug"  // Invalid: underscore not allowed
    id: "urn:feat:bad-slug"
}
