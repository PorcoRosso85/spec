// docs/phase7/submission_pack.cue
// Phase 7 提出パック（証跡の最小集合）

package phase7

submissionPack: {
	summary: "Phase7 提出パック（証跡の最小集合）"

	// 参照点
	reference: {
		commitSha: string
		tag:       string
	}

	// 生成物
	artifacts: {
		exportedJsonPath: string
		sha256:           string
	}

	// 検証結果
	verification: {
		flakeCheck: {
			command:  "nix flake check"
			exitCode: 0
		}
	}

	// 再現手順
	reproduction: {
		steps: [
			"git checkout <tag>",
			"nix flake check",
			"nix build .#packages.x86_64-linux.ci-requirements",
		]
	}
}
