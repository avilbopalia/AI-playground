#!/usr/bin/env bash
# Offline setup for pii.engineer on a machine where HuggingFace is blocked
# but GitHub is reachable. Downloads pre-packaged model bundles from the
# GitHub release 'models-v1' of this repo, then (optionally) builds pii.engineer.
set -euo pipefail

REPO="avilbopalia/AI-playground"
RELEASE_TAG="models-v1"
BASE="https://github.com/${REPO}/releases/download/${RELEASE_TAG}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="${ROOT}/models"

echo "== PII Engineer offline setup =="
echo "Workspace: ${ROOT}"

# 1. Models
mkdir -p "${MODELS_DIR}"
cd "${MODELS_DIR}"

download_and_extract() {
  local name="$1"
  local tarball="${name}.tar.gz"
  local url="${BASE}/${tarball}"
  if [ -d "${name}" ] && [ -f "${name}/.ready" ]; then
    echo "[models] ${name} already present, skipping"
    return
  fi
  echo "[models] downloading ${tarball} ..."
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail -o "/tmp/${tarball}" "${url}"
  else
    wget -O "/tmp/${tarball}" "${url}"
  fi
  echo "[models] extracting ${tarball} ..."
  tar -xzf "/tmp/${tarball}" -C "${MODELS_DIR}"
  # normalize: ensure gliner_config.json exists (renamed from config.json)
  if [ -f "${MODELS_DIR}/PII-Engineer-Multi-NER-v2.1/config.json" ] && [ ! -f "${MODELS_DIR}/PII-Engineer-Multi-NER-v2.1/gliner_config.json" ]; then
    cp "${MODELS_DIR}/PII-Engineer-Multi-NER-v2.1/config.json" \
       "${MODELS_DIR}/PII-Engineer-Multi-NER-v2.1/gliner_config.json"
  fi
  touch "${MODELS_DIR}/${name}/.ready"
  rm -f "/tmp/${tarball}"
}

download_and_extract "PII-Engineer-Multi-NER-v2.1"
download_and_extract "PII-Engineer-Chinese-NER-v1.0"

echo "[models] done. Sizes:"
du -sh "${MODELS_DIR}"/* 2>/dev/null || true

# 2. pii.engineer source (GitHub accessible in office)
SRC_DIR="${ROOT}/pii.engineer"
if [ ! -d "${SRC_DIR}/.git" ]; then
  echo "[src] cloning pii.engineer from GitHub ..."
  git clone https://github.com/gantz-ai/pii.engineer "${SRC_DIR}"
else
  echo "[src] pii.engineer already cloned"
fi

# 3. Build (optional)
if command -v cargo >/dev/null 2>&1; then
  echo "[build] cargo found, building release binary ..."
  cd "${SRC_DIR}"
  cargo build --release --package pii-engineer-server
  echo "[build] binary at ${SRC_DIR}/target/release/pii-engineer-server"
else
  echo "[build] cargo not found. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  echo "        Then re-run this script or build manually."
fi

echo ""
echo "== Next steps =="
echo "  cd ${SRC_DIR}"
echo "  GLINER_MODELS=${MODELS_DIR}/PII-Engineer-Multi-NER-v2.1 \\"
echo "  CHINESE_NER_MODEL=${MODELS_DIR}/PII-Engineer-Chinese-NER-v1.0 \\"
echo "  ./target/release/pii-engineer-server"
echo "  # API: http://localhost:8000  (POST /api/detect)"
