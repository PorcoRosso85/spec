package spec

import "test.example/broken-ref/spec/schema"

features: "feature-with-broken-ref": schema.#Feature & {
    id: "feature-with-broken-ref"
    slug: "feature-with-broken-ref"
    title: "Feature with Broken Reference"
    depends_on: ["urn:spec:feat:nonexistent-feature"]
}
