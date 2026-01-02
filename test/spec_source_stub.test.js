/**
 * TDD-red: spec_contract_source_resolves_stub_override
 * Purpose: Verify stub input can override default contract source
 * Runner: spec-repo / bash + nix develop + cue export --override-input
 * Evidence: artifacts/resolution/stub.log
 */

import test from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import fs from 'fs';

const REPO_ROOT = '/home/nixos/spec-repo';
const ARTIFACTS_DIR = `${REPO_ROOT}/artifacts/resolution`;
const LOG_FILE = `${ARTIFACTS_DIR}/stub.log`;
const STUB_FILE = `${REPO_ROOT}/.gen/stub_contract.json`;

if (!fs.existsSync(ARTIFACTS_DIR)) {
  fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
}

// Create .gen directory for stub file
const genDir = `${REPO_ROOT}/.gen`;
if (!fs.existsSync(genDir)) {
  fs.mkdirSync(genDir, { recursive: true });
}

// Create stub contract file for override test
const stubContent = JSON.stringify({
  requiredBindings: ['STUB_BINDING'],
  allowedTools: ['stub_tool'],
  allowedEndpoints: [{ method: 'GET', path: '/stub' }],
  errorShape: { code: 'STUB001', message: 'Stub error', requestId: 'stub-req' }
}, null, 2);
fs.writeFileSync(STUB_FILE, stubContent, 'utf-8');

test('spec_contract_source_resolves_stub_override - stub input overrides default source', (t) => {
  const log = [];

  log.push(`[START] spec_contract_source_resolves_stub_override`);
  log.push(`[REPO] spec-repo`);
  log.push(`[CMD] nix develop -c bash scripts/check.sh slow --override-input ${STUB_FILE}`);

  try {
    // Run with override-input
    const output = execSync(
      `cd ${REPO_ROOT} && nix develop -c bash scripts/check.sh slow --override-input ${STUB_FILE} 2>&1`,
      { encoding: 'utf-8', timeout: 300000 }
    );

    log.push(`[OUTPUT] ${output.substring(0, 500)}...`);
    log.push(`[RESULT] Override executed successfully`);

    // Verify stub was used (check for stub-related output)
    assert.strictEqual(output.includes('stub') || output.includes('override'), true,
      'Override should be reflected in output');

    log.push(`[PASS] spec_contract_source_resolves_stub_override`);

  } catch (e) {
    log.push(`[FAIL] ${e.message}`);
    assert.fail(`Stub override test failed: ${e.message}`);
  } finally {
    fs.writeFileSync(LOG_FILE, log.join('\n'), 'utf-8');
    console.log(`[LOG] Saved to ${LOG_FILE}`);
  }
});
