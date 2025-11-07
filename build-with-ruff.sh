#!/bin/bash

# Build script with Ruff support for Linux and macOS
# Windows build included but without Ruff (Pyright only)
# Note: Ruff is only bundled for Unix-based systems (Linux/macOS)

set -e

NODE_VERSION="v20.11.0"
RUFF_VERSION="0.14.3"

# Function to get ruff download info for a platform
# Returns empty string for Windows (no Ruff bundling)
get_ruff_info() {
    local os=$1
    local arch=$2
    
    case "${os}-${arch}" in
        "linux-x64")
            echo "ruff-x86_64-unknown-linux-gnu.tar.gz|ruff"
            ;;
        "linux-arm64")
            echo "ruff-aarch64-unknown-linux-gnu.tar.gz|ruff"
            ;;
        "darwin-x64")
            echo "ruff-x86_64-apple-darwin.tar.gz|ruff"
            ;;
        "darwin-arm64")
            echo "ruff-aarch64-apple-darwin.tar.gz|ruff"
            ;;
        *)
            # Windows and other platforms: no Ruff bundling
            echo ""
            ;;
    esac
}

# Function to build for a specific platform
build_platform() {
    local os=$1
    local arch=$2
    local platform="${os}-${arch}"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  Building for ${platform}                              "
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Get Node.js architecture name
    local node_arch="${os}-${arch}"
    if [ "${os}" = "win32" ]; then
        node_arch="win-${arch}"  # Node.js uses "win-x64" for Windows
    fi
    
    # Step 1: Bundle TypeScript
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Bundling TypeScript with esbuild..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    mkdir -p "output/${platform}"
    
    npx esbuild index.ts \
      --bundle \
      --platform=node \
      --target=node18 \
      --format=esm \
      --outfile=output/${platform}/bundle.js \
      --external:ws \
      --external:vscode-ws-jsonrpc \
      --external:vscode-jsonrpc \
      --external:dotenv
    
    echo "✓ Bundled: output/${platform}/bundle.js"
    echo ""
    
    # Step 2: Download Node.js
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 Downloading Node.js ${NODE_VERSION} for ${node_arch}..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    NODE_PKG="node-${NODE_VERSION}-${node_arch}"
    
    if [ "${os}" = "win32" ]; then
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PKG}.zip"
        NODE_FILE="/tmp/${NODE_PKG}.zip"
    else
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PKG}.tar.gz"
        NODE_FILE="/tmp/${NODE_PKG}.tar.gz"
    fi
    
    if [ ! -f "${NODE_FILE}" ]; then
        curl -L "${NODE_URL}" -o "${NODE_FILE}" || {
            echo "❌ Failed to download Node.js"
            return 1
        }
    else
        echo "✓ Using cached Node.js"
    fi
    
    echo "📂 Extracting Node.js..."
    if [ "${os}" = "win32" ]; then
        unzip -q "${NODE_FILE}" -d /tmp/
    else
        tar -xzf "${NODE_FILE}" -C /tmp/
    fi
    mv "/tmp/${NODE_PKG}" "output/${platform}/node"
    
    # Strip unnecessary files from Node.js
    echo "🧹 Stripping unnecessary files from Node.js..."
    cd "output/${platform}/node"
    
    if [ "${os}" = "win32" ]; then
        # Windows cleanup
        rm -rf node_modules/npm 2>/dev/null || true
        rm -rf node_modules/corepack 2>/dev/null || true
        rm -f npm npm.cmd npx npx.cmd corepack corepack.cmd 2>/dev/null || true
        rm -f *.md LICENSE 2>/dev/null || true
    else
        # Unix cleanup
        rm -rf lib/node_modules/npm 2>/dev/null || true
        rm -rf lib/node_modules/corepack 2>/dev/null || true
        rm -f bin/npm bin/npx bin/corepack 2>/dev/null || true
        rm -rf share/doc share/man share/systemtap include 2>/dev/null || true
        rm -f README.md CHANGELOG.md LICENSE *.md 2>/dev/null || true
        
        if command -v strip &> /dev/null && [ "${os}" != "darwin" ]; then
            strip bin/node 2>/dev/null || true
        fi
    fi
    
    cd ../../..
    echo "✓ Node.js ready"
    echo ""
    
    # Step 3: Download Ruff
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 Downloading Ruff ${RUFF_VERSION} for ${platform}..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    ruff_info=$(get_ruff_info "$os" "$arch")
    if [ -z "$ruff_info" ]; then
        echo "⚠️  Ruff not available for ${platform}, skipping..."
    else
        IFS='|' read -r ruff_file ruff_binary <<< "$ruff_info"
        RUFF_URL="https://github.com/astral-sh/ruff/releases/download/${RUFF_VERSION}/${ruff_file}"
        RUFF_FILE="/tmp/ruff-${platform}.tar.gz"
        
        curl -L -A "Mozilla/5.0" "${RUFF_URL}" -o "${RUFF_FILE}" || {
            echo "❌ Failed to download Ruff"
            return 1
        }
        
        echo "📂 Extracting Ruff..."
        mkdir -p "output/${platform}/bin"
        
        # Extract to temp and find the ruff binary
        RUFF_EXTRACT_DIR="/tmp/ruff-extract-${platform}"
        rm -rf "${RUFF_EXTRACT_DIR}"
        mkdir -p "${RUFF_EXTRACT_DIR}"
        tar -xzf "${RUFF_FILE}" -C "${RUFF_EXTRACT_DIR}"
        
        # Find and copy the ruff binary (it might be in a subdirectory)
        find "${RUFF_EXTRACT_DIR}" -name "ruff" -type f -exec cp {} "output/${platform}/bin/ruff" \;
        chmod +x "output/${platform}/bin/ruff"
        
        rm -rf "${RUFF_EXTRACT_DIR}"
        echo "✓ Ruff extracted to output/${platform}/bin/ruff"
    fi
    echo ""
    
    # Step 4: Install dependencies
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 Installing production node_modules..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cp package.json output/${platform}/
    cd output/${platform}
    npm install --production --no-optional --silent
    rm package-lock.json
    echo '{"type":"module"}' > package.json
    
    # Prune unnecessary files
    find node_modules -type d -name "test" -exec rm -rf {} + 2>/dev/null || true
    find node_modules -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
    find node_modules -type d -name "docs" -exec rm -rf {} + 2>/dev/null || true
    find node_modules -type f -name "*.md" -delete 2>/dev/null || true
    find node_modules -type f -name "*.ts" ! -name "*.d.ts" -delete 2>/dev/null || true
    find node_modules -type f -name "*.map" -delete 2>/dev/null || true
    
    cd ../..
    echo "✓ Dependencies installed"
    echo ""
    
    # Step 5: Copy config
    echo "📋 Copying pyrightconfig.json..."
    cp pyrightconfig.json output/${platform}/
    echo "✓ Config copied"
    echo ""
    
    # Step 6: Create start script
    echo "📝 Creating start script..."
    if [ "${os}" = "win32" ]; then
        cat > "output/${platform}/start.bat" << 'EOF'
@echo off
REM Pyright LSP WebSocket Bridge (Pyright only - no Ruff bundled)
REM Usage: start.bat --port <PORT> --bot-root <BOT_ROOT> --jesse-root <JESSE_ROOT>

set DIR=%~dp0
"%DIR%node\node.exe" "%DIR%bundle.js" %*
EOF
        echo "✓ Created start.bat"
    else
        cat > "output/${platform}/start.sh" << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export RUFF_PATH="${DIR}/bin/ruff"
"${DIR}/node/bin/node" "${DIR}/bundle.js" "$@"
EOF
        chmod +x "output/${platform}/start.sh"
        echo "✓ Created start.sh"
    fi
    echo ""
    
    # Step 7: Create archive
    echo "📦 Creating compressed archive..."
    cd output
    if [ "${os}" = "win32" ]; then
        zip -r -q "${platform}.zip" "${platform}/"
        ARCHIVE_FILE="${platform}.zip"
    else
        tar -czf "${platform}.tar.gz" "${platform}/"
        ARCHIVE_FILE="${platform}.tar.gz"
    fi
    
    DIR_SIZE=$(du -sh "${platform}" | cut -f1)
    ARCHIVE_SIZE=$(du -sh "${ARCHIVE_FILE}" | cut -f1)
    
    rm -rf "${platform}"
    cd ..
    
    echo "✓ Created ${ARCHIVE_FILE}"
    echo "   Directory size: ${DIR_SIZE}"
    echo "   Archive size: ${ARCHIVE_SIZE}"
    echo ""
    echo "✅ Build complete for ${platform}!"
}

# Main script
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Building Pyright LSP with Ruff Support               ║"
echo "║  (Ruff bundled for Linux/macOS only)                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf output
mkdir -p output
echo ""

# Build for specified platforms or all
if [ $# -eq 0 ]; then
    # Build for Linux, macOS, and Windows by default
    # Note: Ruff is only bundled for Linux and macOS
    PLATFORMS=("linux:x64" "darwin:x64" "darwin:arm64" "win32:x64")
else
    PLATFORMS=("$@")
fi

echo "Building for platforms: ${PLATFORMS[@]}"
echo ""

for platform_spec in "${PLATFORMS[@]}"; do
    IFS=':' read -r os arch <<< "$platform_spec"
    build_platform "$os" "$arch" || echo "⚠️  Build failed for ${os}-${arch}"
done

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ ALL BUILDS COMPLETE                                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Output files in ./output/"
ls -lh output/*.tar.gz output/*.zip 2>/dev/null || true
echo ""

