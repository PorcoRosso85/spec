#!/usr/bin/env bash
set -euo pipefail

# feat追加ブランチの変更範囲チェック
# 目的: spec/urn/feat/<slug>/ 以外の変更を禁止（Git競合回避）
#
# Usage:
#   bash scripts/policy/check-feat-scope.sh [BASE_BRANCH]
#
# Example:
#   bash scripts/policy/check-feat-scope.sh dev
#   bash scripts/policy/check-feat-scope.sh origin/dev

BASE="${1:-dev}"

echo "🔍 feat追加ブランチの変更範囲チェック"
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

# 許可範囲: spec/urn/feat/<slug>/ 以下のみ
# 禁止: それ以外の全ファイル
DENY="$(echo "$CHANGED" | grep -Ev '^spec/urn/feat/[^/]+/' || true)"

if [[ -n "$DENY" ]]; then
  echo "❌ NG: featブランチが許可範囲外を変更しています"
  echo ""
  echo "【禁止されている変更】:"
  echo "$DENY"
  echo ""
  echo "【許可範囲】:"
  echo "  spec/urn/feat/<slug>/**  （新規feat追加のみ）"
  echo ""
  echo "【禁止範囲】:"
  echo "  nix/**, flake.nix, scripts/**, spec/ci/**, spec/schema/**, その他全て"
  echo ""
  echo "💡 修正方法:"
  echo "  1. 禁止範囲のファイルを元に戻す"
  echo "  2. または、別のブランチ種別（dev/schema-change）として扱う"
  exit 1
fi

echo "✅ OK: featブランチは spec/urn/feat/<slug>/ のみ変更"
echo ""
echo "変更範囲（許可）:"
echo "$CHANGED"
