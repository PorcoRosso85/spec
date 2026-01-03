package spec_repo

// spec-repo CI要件SSOTの正本
// - ここにCI要件を書く（flake checksは具現）
// - ここにdeliverablesへの参照を書く（実装/素材は spec/* に集約）

// CI必須チェック一覧（ flake.checks と対照）
requiredChecks: [
  // Meta-DoD (LEVEL0)
  "dod0-factory-only",
  "dod0-flake-srp",
  "dod7-no-integration-duplication",
  "dod8-patterns-ssot",

  // spec-* (spec-repo固有)
  "spec-e2e",
  "spec-fast",
  "spec-slow",
  "spec-smoke",
  "spec-unit",

  // feat-* (URN別)
  "feat-decide-ci-score-matrix",
  "feat-spec",

  // unit-green-* (DoD1-4 GREEN)
  "unit-green-dod1",
  "unit-green-dod2",
  "unit-green-dod3",
  "unit-green-dod4",

  // integration-* (DoD1-4 実データ)
  "integration-negative-dod1",
  "integration-negative-dod2",
  "integration-negative-dod3",
  "integration-negative-dod4",
  "integration-verify-dod1",
  "integration-verify-dod2",
  "integration-verify-dod3",
  "integration-verify-dod4",

  // グローバル
  "global-uniq-fixtures",
  "policy-dev-scope",

  // DoD5/6 (feat-repo向け)
  "test-dod5-positive",
  "test-dod6-positive",

  // Repo DoD (LEVEL3 - CI要件SSOT成立条件)
  "repo-cue-validity",
]

// deliverablesへの参照（CUE側の素材/実装）
// 注: nix/* は具現側なので含めない（境界明確化）
deliverablesRefs: [
  "spec/ci/contract",    // 契約定義
  "spec/ci/detector",    // DoD検出ロジック
  "spec/ci/tdd",         // TDDテスト
  "spec/ci/fixtures",    // テスト用データ
  "spec/ci/checks",      // チェック素材
  "spec/urn",            // URN定義
  "spec/schema",         // 型定義
  "spec/adapter",        // アダプタ
  "spec/mapping",        // マッピング
  "spec/external",       // 外部標準
]
