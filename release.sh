#!/usr/bin/env bash
# release.sh — tri-license-aware release ceremony for Free Humanoid Platform
#              (OpenLoco Morphology #17)
#
# Packages a deterministic GNU tarball, emits tri-license-tagged Canonical
# Artifact records (CC0-1.0 for descriptor/datasets/prior-art/BOM, Apache-2.0
# for firmware/control/sim, CERN-OHL-S-2.0 for actuators/chassis/electronics),
# wraps the Unified Descriptor Document (UDD) in a conforming WAI1 binary
# container + WAI_RECEIPT.json, and generates commons_ingest_bundle.json.
#
# Usage:
#   ./release.sh <version-tag> [--dry-run]
#
# Examples:
#   ./release.sh 2026.Q3
#   ./release.sh 2026.11.24 --dry-run

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <version-tag> [--dry-run]"
  echo "example: $0 2026.11.24 --dry-run"
  exit 1
fi

VERSION="$1"
DRY_RUN=0
if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "[dry-run mode: will build deterministic artifacts and WAI1 envelope, skip TSA submissions and git tag]"
fi

if ! echo "$VERSION" | grep -Eq '^v?[0-9]{4}\.(Q[1-4]|[0-9]{2}\.[0-9]{2})$|^v[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "ERROR: version tag '$VERSION' should match YYYY.QN, YYYY.MM.DD, or vX.Y.Z"
  exit 1
fi

RELEASE_DIR="releases/${VERSION}"
TARBALL_NAME="platform-${VERSION}.tar.gz"
TARBALL_PATH="${RELEASE_DIR}/${TARBALL_NAME}"
WAI_NAME="free-humanoid-${VERSION}.wai"
WAI_PATH="${RELEASE_DIR}/${WAI_NAME}"

# ---------- preflight checks ----------

echo "=== Preflight checks ==="

need_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required tool '$1' not found in PATH"
    exit 1
  fi
}
need_tool python3
need_tool openssl
need_tool curl
need_tool sha256sum
need_tool git

if command -v gtar >/dev/null 2>&1; then
  TAR=gtar
elif tar --version 2>/dev/null | grep -q "GNU tar"; then
  TAR=tar
else
  echo "ERROR: GNU tar required (bsdtar lacks --sort)."
  echo "  install with: brew install gnu-tar"
  exit 1
fi
if [ "$DRY_RUN" -eq 0 ]; then
  need_tool ots || {
    echo "ERROR: 'ots' (OpenTimestamps client) required for non-dry-run."
    echo "  install with: pip install opentimestamps-client"
    exit 1
  }
fi

for req in descriptor/free-humanoid.udd.json LICENSE-DATA LICENSE-SOFTWARE LICENSE-HARDWARE ARCHITECTURE.md README.md; do
  if [ ! -f "$req" ]; then
    echo "ERROR: required platform file '$req' not found. Run from repo root."
    exit 1
  fi
done

if [ "$DRY_RUN" -eq 0 ]; then
  if ! git diff --quiet HEAD 2>/dev/null; then
    echo "ERROR: working tree has uncommitted changes. Commit or stash first."
    git status --short
    exit 1
  fi
  if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "ERROR: tag '$VERSION' already exists."
    exit 1
  fi
  if [ -d "$RELEASE_DIR" ]; then
    echo "ERROR: $RELEASE_DIR already exists."
    exit 1
  fi
fi

echo "  Preflight OK."

# ---------- step 1: validate UDD & tri-license subsystem layout ----------

echo ""
echo "=== Step 1: validate UDD descriptor & tri-license subsystems ==="
python3 tools/emit_wai_commons.py --validate-only --repo-root .
echo "  UDD & tri-license validation passed."

# ---------- step 2: build deterministic release tarball ----------

echo ""
echo "=== Step 2: build deterministic GNU tarball ==="
mkdir -p "$RELEASE_DIR"

case "$VERSION" in
  *.Q1) MTIME="${VERSION%.Q1}-01-01" ;;
  *.Q2) MTIME="${VERSION%.Q2}-04-01" ;;
  *.Q3) MTIME="${VERSION%.Q3}-07-01" ;;
  *.Q4) MTIME="${VERSION%.Q4}-10-01" ;;
  *.[0-9][0-9].[0-9][0-9]) MTIME=$(echo "${VERSION#v}" | tr '.' '-') ;;
  v*) MTIME="2026-01-01" ;;
  *) MTIME="2026-01-01" ;;
esac

$TAR --use-compress-program='gzip -n' -cf "$TARBALL_PATH" \
  --sort=name \
  --owner=0 --group=0 --numeric-owner \
  --mtime="${MTIME}T00:00:00Z" \
  --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
  README.md \
  ARCHITECTURE.md \
  CONTRIBUTING.md \
  LICENSE-DATA \
  LICENSE-DOCS \
  LICENSE-HARDWARE \
  LICENSE-SOFTWARE \
  descriptor/ \
  actuators/ \
  chassis/ \
  control/ \
  datasets/ \
  docs/ \
  electronics/ \
  firmware/ \
  prior-art/ \
  sim/

HASH=$(sha256sum "$TARBALL_PATH" | cut -d' ' -f1)
echo "${HASH}  ${TARBALL_NAME}" > "${RELEASE_DIR}/SHA256SUMS"
echo "  Tarball: ${TARBALL_PATH}"
echo "  SHA-256: ${HASH}"

# ---------- step 3: emit tri-license canonical artifacts, WAI1 UDD envelope & Commons bundle ----------

echo ""
echo "=== Step 3: emit tri-license canonical artifacts, WAI1 UDD envelope & Commons bundle ==="
EMIT_FLAGS=(
  --version "$VERSION"
  --release-dir "$RELEASE_DIR"
  --tarball "$TARBALL_PATH"
  --repo-root "."
  --timestamp "${MTIME}T00:00:00Z"
)
if [ "$DRY_RUN" -eq 1 ]; then
  EMIT_FLAGS+=(--dry-run)
fi
python3 tools/emit_wai_commons.py "${EMIT_FLAGS[@]}"

TARBALL_B3=$(grep "  ${TARBALL_NAME}\$" "${RELEASE_DIR}/BLAKE3SUMS" | cut -d' ' -f1)
WAI_SHA=$(grep "  ${WAI_NAME}\$" "${RELEASE_DIR}/SHA256SUMS" | cut -d' ' -f1)
WAI_B3=$(grep "  ${WAI_NAME}\$" "${RELEASE_DIR}/BLAKE3SUMS" | cut -d' ' -f1)
RECEIPT_SHA=$(grep "  WAI_RECEIPT.json\$" "${RELEASE_DIR}/SHA256SUMS" | cut -d' ' -f1)
RECEIPT_B3=$(grep "  WAI_RECEIPT.json\$" "${RELEASE_DIR}/BLAKE3SUMS" | cut -d' ' -f1)
CANON_SHA=$(grep "  artifacts.canonical.jsonl\$" "${RELEASE_DIR}/SHA256SUMS" | cut -d' ' -f1)
CANON_B3=$(grep "  artifacts.canonical.jsonl\$" "${RELEASE_DIR}/BLAKE3SUMS" | cut -d' ' -f1)
COMMONS_SHA=$(grep "  commons_ingest_bundle.json\$" "${RELEASE_DIR}/SHA256SUMS" | cut -d' ' -f1)
COMMONS_B3=$(grep "  commons_ingest_bundle.json\$" "${RELEASE_DIR}/BLAKE3SUMS" | cut -d' ' -f1)
RECORDS=$(wc -l < "${RELEASE_DIR}/artifacts.canonical.jsonl" | tr -d ' ')

write_manifest() {
  local manifest_date="$1"
  local commons_status="$2"
  cat > "${RELEASE_DIR}/MANIFEST.md" <<EOF
# Free Humanoid Platform Release ${VERSION} (OpenLoco Morphology #17)

| | |
|---|---|
| Date (UTC) | ${manifest_date} |
| Tarball | \`${TARBALL_NAME}\` |
| Tarball SHA-256 | \`${HASH}\` |
| Tarball BLAKE3 | \`${TARBALL_B3}\` |
| UDD WAI1 Envelope | \`${WAI_NAME}\` |
| WAI1 SHA-256 | \`${WAI_SHA}\` |
| WAI1 BLAKE3 | \`${WAI_B3}\` |
| Canonical Records | ${RECORDS} (tri-licensed: \`CC0-1.0\`, \`Apache-2.0\`, \`CERN-OHL-S-2.0\`) |
| Commons Sync | ${commons_status} |

## Tri-license posture

| Domain | Subsystems | SPDX License |
|---|---|---|
| Data, Descriptors & Prior-Art | \`descriptor/\`, \`datasets/\`, \`prior-art/\`, BOM CSVs | \`CC0-1.0\` (\`LICENSE-DATA\`) |
| Firmware, Control & Simulation | \`firmware/\`, \`control/\`, \`sim/\` | \`Apache-2.0\` (\`LICENSE-SOFTWARE\`) |
| Hardware, CAD & Electronics | \`actuators/\`, \`chassis/\`, \`electronics/\` | \`CERN-OHL-S-2.0\` (\`LICENSE-HARDWARE\`) |

## Release artifacts & digests

| Artifact | SHA-256 | BLAKE3 |
|---|---|---|
| \`${TARBALL_NAME}\` | \`${HASH}\` | \`${TARBALL_B3}\` |
| \`artifacts.canonical.jsonl\` | \`${CANON_SHA}\` | \`${CANON_B3}\` |
| \`${WAI_NAME}\` | \`${WAI_SHA}\` | \`${WAI_B3}\` |
| \`WAI_RECEIPT.json\` | \`${RECEIPT_SHA}\` | \`${RECEIPT_B3}\` |
| \`commons_ingest_bundle.json\` | \`${COMMONS_SHA}\` | \`${COMMONS_B3}\` |

## Verification

\`\`\`bash
sha256sum -c SHA256SUMS
python3 ../../tools/emit_wai_commons.py --verify .
\`\`\`
EOF
}

if [ "$DRY_RUN" -eq 1 ]; then
  write_manifest "${MTIME}T00:00:00Z" "dry-run (bundle emitted + non-blocking health ping)"
  echo ""
  echo "=== Dry-run complete ==="
  echo "Tarball built at:      ${TARBALL_PATH}"
  echo "WAI1 UDD envelope at:  ${WAI_PATH}"
  echo "Canonical OpenIE at:   ${RELEASE_DIR}/artifacts.canonical.jsonl"
  echo "Commons bundle at:     ${RELEASE_DIR}/commons_ingest_bundle.json"
  echo "Hashes recorded at:    ${RELEASE_DIR}/SHA256SUMS & ${RELEASE_DIR}/BLAKE3SUMS"
  echo "Manifest recorded at:  ${RELEASE_DIR}/MANIFEST.md"
  exit 0
fi

# ---------- step 4: RFC 3161 timestamping ----------

echo ""
echo "=== Step 4: RFC 3161 timestamping ==="
openssl ts -query -data "$TARBALL_PATH" -sha256 -cert -no_nonce \
  -out "${RELEASE_DIR}/request.tsq"
openssl ts -query -data "${RELEASE_DIR}/WAI_RECEIPT.json" -sha256 -cert -no_nonce \
  -out "${RELEASE_DIR}/wai_receipt.tsq"

if curl -sS --max-time 30 --fail \
    -H "Content-Type: application/timestamp-query" \
    --data-binary @"${RELEASE_DIR}/request.tsq" \
    https://freetsa.org/tsr \
    -o "${RELEASE_DIR}/freetsa.tsr"; then
  echo "    FreeTSA tarball OK"
else
  rm -f "${RELEASE_DIR}/freetsa.tsr"
fi

if curl -sS --max-time 30 --fail \
    -H "Content-Type: application/timestamp-query" \
    --data-binary @"${RELEASE_DIR}/wai_receipt.tsq" \
    https://freetsa.org/tsr \
    -o "${RELEASE_DIR}/wai_receipt.freetsa.tsr"; then
  echo "    FreeTSA WAI receipt OK"
else
  rm -f "${RELEASE_DIR}/wai_receipt.freetsa.tsr"
fi

if curl -sS --max-time 30 --fail \
    -H "Content-Type: application/timestamp-query" \
    --data-binary @"${RELEASE_DIR}/request.tsq" \
    http://timestamp.digicert.com \
    -o "${RELEASE_DIR}/digicert.tsr"; then
  echo "    DigiCert tarball OK"
else
  rm -f "${RELEASE_DIR}/digicert.tsr"
fi

if curl -sS --max-time 30 --fail \
    -H "Content-Type: application/timestamp-query" \
    --data-binary @"${RELEASE_DIR}/wai_receipt.tsq" \
    http://timestamp.digicert.com \
    -o "${RELEASE_DIR}/wai_receipt.digicert.tsr"; then
  echo "    DigiCert WAI receipt OK"
else
  rm -f "${RELEASE_DIR}/wai_receipt.digicert.tsr"
fi

if [ ! -f "${RELEASE_DIR}/freetsa.tsr" ] && [ ! -f "${RELEASE_DIR}/digicert.tsr" ]; then
  echo "ERROR: both RFC 3161 submissions failed. Aborting."
  exit 1
fi

# ---------- step 5: OpenTimestamps ----------

echo ""
echo "=== Step 5: OpenTimestamps anchoring ==="
ots stamp "$TARBALL_PATH"
if [ "${TARBALL_PATH}.ots" != "${RELEASE_DIR}/${TARBALL_NAME}.ots" ]; then
  mv "${TARBALL_PATH}.ots" "${RELEASE_DIR}/${TARBALL_NAME}.ots"
fi
ots stamp "${RELEASE_DIR}/WAI_RECEIPT.json"

# ---------- step 5b: Commons Scholar sync ----------

echo ""
echo "=== Step 5b: Commons Scholar sync ==="
python3 tools/emit_wai_commons.py \
  --push-commons-only \
  --version "$VERSION" \
  --release-dir "$RELEASE_DIR"

# ---------- step 6: write manifest & git tag ----------

write_manifest "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "synced / bundle emitted (\`commons_ingest_bundle.json\`)"
git add "$RELEASE_DIR"
git commit -m "release: ${VERSION}

OpenLoco Morphology #17 tri-license release.
SHA-256: ${HASH}"
git tag -a "$VERSION" -m "Free Humanoid Platform release ${VERSION}

SHA-256: ${HASH}"
echo "  Tagged ${VERSION}."
