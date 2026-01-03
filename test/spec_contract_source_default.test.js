/**
 * TDD-red: spec_contract_source_resolves_default
 * Purpose: Verify contract.json can be generated from spec-repo outputs
 * Runner: spec-repo / bash + nix develop + cue export
 * Evidence: artifacts/resolution/default.log
 */

import test from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const REPO_ROOT = '/home/nixos/spec-repo';
const ARTIFACTS_DIR = `${REPO_ROOT}/artifacts/resolution`;
const LOG_FILE = `${ARTIFACTS_DIR}/default.log`;

// Ensure artifacts directory exists
if (!fs.existsSync(ARTIFACTS_DIR)) {
  fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
}

test('spec_contract_source_resolves_default - contract.json generates from spec-repo outputs', (t) => {
  const log = [];

  log.push(`[START] spec_contract_source_resolves_default`);
  log.push(`[REPO] spec-repo`);
  log.push(`[CMD] nix develop -c bash scripts/check.sh slow`);

  try {
    // Run spec-repo check.sh slow (which generates contract artifacts)
    const output = execSync(
      `cd ${REPO_ROOT} && nix develop -c bash scripts/check.sh slow 2>&1`,
      { encoding: 'utf-8', timeout: 300000 }
    );

    log.push(`[OUTPUT] ${output.substring(0, 500)}...`);
    log.push(`[RESULT] Generated successfully`);

    // Verify contract.json or equivalent was generated
    const contractFiles = [
      `${REPO_ROOT}/.gen/contract.json`,
      `${REPO_ROOT}/.gen/spec/contract.json`,
      `${REPO_ROOT}/spec/contract.json`,
    ];

    let foundContract = false;
    for (const file of contractFiles) {
      if (fs.existsSync(file)) {
        log.push(`[CONTRACT] Found: ${file}`);
        foundContract = true;
        break;
      }
    }

    // Critical assertion: contract.json MUST be generated
    assert.strictEqual(foundContract, true, 
      'contract.json must be generated in expected locations');

    log.push(`[PASS] spec_contract_source_resolves_default`);

  } catch (e) {
    log.push(`[FAIL] ${e.message}`);
    assert.fail(`spec_contract_source_resolves_default failed: ${e.message}`);
  } finally {
    // Save log
    fs.writeFileSync(LOG_FILE, log.join('\n'), 'utf-8');
    console.log(`[LOG] Saved to ${LOG_FILE}`);
  }
});
