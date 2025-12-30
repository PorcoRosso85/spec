#!/usr/bin/env bash
set -euo pipefail

# dev（スケール作業）ブランチの変更範囲チェック
# 目的: spec/urn/feat/ への変更を禁止（Git競合回避）
#
# Usage:
#   bash scripts/policy/check-dev-scope.sh [BASE_BRANCH]
#
# Example:
#   bash scripts/policy/check-dev-scope.sh main
#   bash scripts/policy/check-dev-scope.sh origin/main

BASE="${1:-main}"

echo "🔍 dev（スケール作業）ブランチの変更範囲チェック"
echo "Base: $BASE"
echo ""

# 変更ファイル一覧取得
CHANGED="$(git diff --name-only "$BASE"...HEAD)"

if [[ -z "$CHANGED" ]]; then
  echo "ℹ️  変更なし（baseと同一）"
  exit 0
fi

echo "変更ファイル一覧:"
echo "$CHANGED"
echo ""

# 禁止範囲: spec/urn/feat/ を触ったらNG
DENY="$(echo "$CHANGED" | grep -E '^spec/urn/feat/' || true)"

if [[ -n "$DENY" ]]; then
  echo "❌ NG: dev（スケール作業）が spec/urn/feat を変更しています"
  echo ""
  echo "【禁止されている変更】:"
  echo "$DENY"
  echo ""
  echo "【許可範囲】:"
  echo "  nix/**, flake.nix, scripts/**, spec/ci/**, .claude/**, その他"
  echo ""
  echo "【禁止範囲】:"
  echo "  spec/urn/feat/**  （feat追加ブランチ専用）"
  echo ""
  echo "💡 修正方法:"
  echo "  1. spec/urn/feat の変更を別ブランチ（feat/add-xxx）に分離"
  echo "  2. devブランチからfeat変更をrevert"
  exit 1
fi

echo "✅ OK: dev（スケール作業）は spec/urn/feat 領域を触っていない"
echo ""
echo "変更範囲（許可）:"
echo "$CHANGED"
