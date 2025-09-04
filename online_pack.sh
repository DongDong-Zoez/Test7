#!/usr/bin/env bash
set -euo pipefail

# ===== 可調參數 =====
PKG="${PKG:-@qwen-code/qwen-code@latest}"  # 要打包的套件版本
CACHE_DIR="${CACHE_DIR:-$PWD/npm-cache}"    # npm 快取輸出位置
OUT_DIR="${OUT_DIR:-$PWD}"                  # 產物輸出資料夾
BUNDLE_NAME="${BUNDLE_NAME:-qwen-offline-bundle}"

# ===== 檢查環境 =====
command -v node >/dev/null 2>&1 || { echo "❌ node 未安裝"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "❌ npm 未安裝"; exit 1; }

NODE_VER="$(node -v)"
NPM_VER="$(npm -v)"
PREFIX="$(npm prefix -g)"
ROOT="$(npm root -g)"

echo "👉 Node: $NODE_VER"
echo "👉 npm : $NPM_VER"
echo "👉 prefix: $PREFIX"
echo "👉 root  : $ROOT"

# ===== 準備 npm 快取並全域安裝（填滿快取） =====
export NPM_CONFIG_CACHE="$CACHE_DIR"
mkdir -p "$CACHE_DIR"

echo "📦 安裝並快取 $PKG ..."
npm install -g "$PKG"

# 驗證 qwen 是否存在
if ! command -v qwen >/dev/null 2>&1; then
  echo "❌ 找不到 qwen 可執行檔（安裝可能失敗）"
  exit 1
fi

QWEN_PATH="$(command -v qwen)"
echo "✅ qwen 在：$QWEN_PATH"

# ===== 打包檔案 =====
STAMP="$(date +%Y%m%d-%H%M%S)"
BUNDLE_DIR="$OUT_DIR/${BUNDLE_NAME}_${NODE_VER#v}_$STAMP"
mkdir -p "$BUNDLE_DIR"

# 1) 打包 npm-cache
echo "🗜️ 打包 npm-cache 到 $BUNDLE_DIR/npm-cache.tgz"
tar -czf "$BUNDLE_DIR/npm-cache.tgz" -C "$(dirname "$CACHE_DIR")" "$(basename "$CACHE_DIR")"

# 2) 打包全域安裝位置（僅 qwen bin + lib/node_modules）
#    注意：為了穩妥，打包整個 lib/node_modules，確保依賴完整
echo "🗜️ 打包全域安裝到 $BUNDLE_DIR/qwen-global.tgz"
tar -czf "$BUNDLE_DIR/qwen-global.tgz" -C "$PREFIX" \
  lib/node_modules \
  bin/qwen

# 3) 寫入中繼資訊（供離線端校驗）
cat > "$BUNDLE_DIR/metadata.json" <<EOF
{
  "node_version": "$NODE_VER",
  "npm_version": "$NPM_VER",
  "prefix": "$PREFIX",
  "root": "$ROOT",
  "package": "$PKG",
  "created_at": "$STAMP"
}
EOF

echo
echo "🎁 產物已完成於：$BUNDLE_DIR"
echo "   - npm-cache.tgz"
echo "   - qwen-global.tgz"
echo "   - metadata.json"
echo
echo "➡️  請把整個資料夾帶到離線機器，然後執行 offline_install.sh"

