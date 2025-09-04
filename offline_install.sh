#!/usr/bin/env bash
set -euo pipefail

# 使用方式：
#   ./offline_install.sh /path/to/qwen-offline-bundle_x.y.z_DATE
#
# 參數：
BUNDLE_DIR="${1:-}"
if [[ -z "$BUNDLE_DIR" ]]; then
  echo "用法：$0 /path/to/qwen-offline-bundle_<node>_<stamp>"
  exit 1
fi

[[ -d "$BUNDLE_DIR" ]] || { echo "❌ 找不到目錄：$BUNDLE_DIR"; exit 1; }
[[ -f "$BUNDLE_DIR/qwen-global.tgz" ]] || { echo "❌ 缺少 $BUNDLE_DIR/qwen-global.tgz"; exit 1; }
[[ -f "$BUNDLE_DIR/npm-cache.tgz"    ]] || { echo "❌ 缺少 $BUNDLE_DIR/npm-cache.tgz"; exit 1; }

# ===== 檢查 node/npm 與 prefix/root =====
command -v node >/dev/null 2>&1 || { echo "❌ 離線機器未安裝 node"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "❌ 離線機器未安裝 npm"; exit 1; }

NODE_VER="$(node -v)"
NPM_VER="$(npm -v)"
PREFIX="$(npm prefix -g)"
ROOT="$(npm root -g)"

echo "👉 離線機器 Node: $NODE_VER"
echo "👉 離線機器 npm : $NPM_VER"
echo "👉 prefix: $PREFIX"
echo "👉 root  : $ROOT"

# （選擇性）讀 metadata.json 提示版本比對
if [[ -f "$BUNDLE_DIR/metadata.json" ]]; then
  echo "ℹ️  線上端 metadata："
  cat "$BUNDLE_DIR/metadata.json"
  echo
fi

# ===== 解壓 npm-cache =====
echo "📂 解壓 npm-cache 到 \$HOME/npm-cache"
mkdir -p "$HOME"
tar -xzf "$BUNDLE_DIR/npm-cache.tgz" -C "$HOME"
export NPM_CONFIG_CACHE="$HOME/npm-cache"

# ===== 解壓全域安裝內容到本機 prefix =====
# 這會把 lib/node_modules 與 bin/qwen 放到你的全域目錄
echo "📂 解壓 qwen-global.tgz 到 $PREFIX"
tar -xzf "$BUNDLE_DIR/qwen-global.tgz" -C "$PREFIX"

# ===== 確保 PATH 含全域 bin =====
case ":$PATH:" in
  *":$PREFIX/bin:"*) : ;;  # 已在 PATH 中
  *) export PATH="$PREFIX/bin:$PATH";;
esac

# ===== 驗證 =====
echo "🔎 驗證 qwen 版本與可執行性..."
if ! command -v qwen >/dev/null 2>&1; then
  echo "❌ 找不到 qwen，可執行檔不在 PATH？目前 PATH=$PATH"
  exit 1
fi

qwen --version || {
  echo "⚠️ qwen 可執行但執行失敗，可能是 Node 版本或依賴差異。"
  echo "   你可以嘗試：npm install -g --offline @qwen-code/qwen-code"
  echo "   （使用剛才展開的 npm-cache）"
  exit 1
}

echo "✅ 安裝完成，可以使用 qwen 了！例如："
echo "   qwen --help"

