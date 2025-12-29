package spec

import "test.example/circular-deps/spec/schema"

features: "feat-a": schema.#Feature & {
    id: "feat-a"
    slug: "feat-a"
    title: "Feature A"
    depends_on: ["urn:spec:feat:feat-b"]
}
