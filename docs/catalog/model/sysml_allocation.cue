// docs/catalog/model/sysml_allocation.cue
// requirement_id -> slot.id -> verify手段
// 要求→責務→検証 の割り当て表。
// ISO/IEC/IEEE 29148 のトレーサビリティ線 (要求→割当→検証) の元データになる。
//
// 例:
// "REQ-login-mfa": {
//   slot:   "nist80053.AC-access-control"
//   verify: ["automated-test:test/authz.test.mjs", "audit-log:authz-deny-events"]
// }

package catalog
