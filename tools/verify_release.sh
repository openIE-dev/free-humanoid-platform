#!/usr/bin/env bash
# verify_release.sh — verify a Free Humanoid Platform release independently
#
# Usage:
#   ./tools/verify_release.sh <version-tag>

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <version-tag>"
  exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RELEASE_DIR="${REPO_ROOT}/releases/${VERSION}"
TARBALL_NAME="platform-${VERSION}.tar.gz"
WAI_NAME="free-humanoid-${VERSION}.wai"

if [ ! -d "$RELEASE_DIR" ]; then
  echo "ERROR: $RELEASE_DIR not found."
  exit 1
fi

cd "$RELEASE_DIR"

echo "=== Verifying Free Humanoid Platform release ${VERSION} ==="
echo ""

echo "1. SHA-256 verification"
if sha256sum -c SHA256SUMS; then
  echo "   PASS: artifact SHA-256 hashes match SHA256SUMS"
else
  echo "   FAIL: SHA-256 verification failed"
  exit 1
fi
echo ""

echo "1b. WAI1 UDD container, tri-license canonical records, BLAKE3 & Ed25519 signatures (offline)"
if [ -f "$WAI_NAME" ] || [ -f "WAI_RECEIPT.json" ]; then
  if python3 "${REPO_ROOT}/tools/emit_wai_commons.py" --verify .; then
    echo "   PASS: WAI1 UDD envelope, tri-license invariants, BLAKE3SUMS, and Ed25519 receipts verified offline"
  else
    echo "   FAIL: WAI1 / BLAKE3 / Ed25519 verification failed"
    exit 1
  fi
else
  echo "   FAIL: WAI1 envelope not present"
  exit 1
fi
echo ""

echo "=== Verification complete ==="
