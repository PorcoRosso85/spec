package spec

import "test.example/circular-deps/spec/schema"

features: "feat-b": schema.#Feature & {
    id: "feat-b"
    slug: "feat-b"
    title: "Feature B"
    depends_on: ["urn:spec:feat:feat-a"]
}
