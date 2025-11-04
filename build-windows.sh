#!/bin/bash

# Build script for Windows platform using Unix shell (WSL/Git Bash)
# Creates win32-x64.zip with bundled Node.js runtime

set -e

PLATFORM="win32-x64"
NODE_VERSION="v20.11.0"
NODE_ARCH="win-x64"  # Node.js uses "win-x64" in download URLs

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Building Pyright LSP Bridge for Windows              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf output
mkdir -p output/${PLATFORM}

# Step 1: Bundle TypeScript into one JavaScript file with esbuild
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Bundling TypeScript with esbuild..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

npx esbuild index.ts \
  --bundle \
  --platform=node \
  --target=node18 \
  --format=esm \
  --outfile=output/${PLATFORM}/bundle.js \
  --external:ws \
  --external:vscode-ws-jsonrpc \
  --external:vscode-jsonrpc \
  --external:dotenv

if [ ! -f "output/${PLATFORM}/bundle.js" ]; then
    echo "❌ esbuild bundling failed!"
    exit 1
fi
echo "✓ Bundled: output/${PLATFORM}/bundle.js"
echo ""

# Step 2: Download and extract Node.js runtime for Windows
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Downloading Node.js ${NODE_VERSION} for ${NODE_ARCH}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NODE_PKG="node-${NODE_VERSION}-${NODE_ARCH}"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_PKG}.zip"
NODE_FILE="/tmp/${NODE_PKG}.zip"

# Check if cached file exists and is valid
if [ -f "${NODE_FILE}" ]; then
    echo "Found cached Node.js, verifying..."
    if unzip -t "${NODE_FILE}" >/dev/null 2>&1; then
        echo "✓ Using cached Node.js"
    else
        echo "⚠️  Cached file is corrupted, re-downloading..."
        rm -f "${NODE_FILE}"
    fi
fi

# Download if not exists or was corrupted
if [ ! -f "${NODE_FILE}" ]; then
    echo "Downloading from ${NODE_URL}..."
    
    # Try curl first
    if command -v curl &> /dev/null; then
        curl -f -L --progress-bar "${NODE_URL}" -o "${NODE_FILE}" || {
            echo "❌ curl download failed"
            rm -f "${NODE_FILE}"
            
            # Try wget as fallback
            if command -v wget &> /dev/null; then
                echo "Trying wget..."
                wget -q --show-progress "${NODE_URL}" -O "${NODE_FILE}" || {
                    echo "❌ wget download also failed"
                    rm -f "${NODE_FILE}"
                    echo "Please download manually from: ${NODE_URL}"
                    exit 1
                }
            else
                echo "Please download manually from: ${NODE_URL}"
                echo "Save it to: ${NODE_FILE}"
                exit 1
            fi
        }
    elif command -v wget &> /dev/null; then
        wget -q --show-progress "${NODE_URL}" -O "${NODE_FILE}" || {
            echo "❌ Failed to download Node.js"
            rm -f "${NODE_FILE}"
            echo "Please download manually from: ${NODE_URL}"
            exit 1
        }
    else
        echo "❌ Neither curl nor wget found"
        echo "Please install curl or wget, or download manually from: ${NODE_URL}"
        exit 1
    fi
    
    # Check file size (should be around 28-30 MB)
    FILE_SIZE=$(stat -f%z "${NODE_FILE}" 2>/dev/null || stat -c%s "${NODE_FILE}" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -lt 1000000 ]; then
        echo "❌ Downloaded file is too small (${FILE_SIZE} bytes)"
        echo "Expected around 28-30 MB"
        echo "The download might have failed or returned an error page"
        echo ""
        echo "Please try:"
        echo "1. Check your internet connection"
        echo "2. Download manually: ${NODE_URL}"
        echo "3. Save to: ${NODE_FILE}"
        rm -f "${NODE_FILE}"
        exit 1
    fi
    
    # Verify the downloaded file
    echo "Verifying download..."
    if ! unzip -t "${NODE_FILE}" >/dev/null 2>&1; then
        echo "❌ Downloaded file is corrupted or not a valid zip"
        rm -f "${NODE_FILE}"
        exit 1
    fi
    echo "✓ Download verified"
fi

echo "📂 Extracting Node.js..."
unzip -q "${NODE_FILE}" -d /tmp/ || {
    echo "❌ Failed to extract Node.js"
    echo "Removing corrupted file, please run again"
    rm -f "${NODE_FILE}"
    exit 1
}

mv "/tmp/${NODE_PKG}" "output/${PLATFORM}/node"
echo "✓ Node.js extracted to output/${PLATFORM}/node"

# Step 3: Strip unnecessary files from Node.js to reduce size
echo "🧹 Stripping unnecessary files from Node.js..."
cd "output/${PLATFORM}/node"

# Remove npm, npx, corepack (we don't need package managers at runtime)
rm -rf node_modules/npm 2>/dev/null || true
rm -rf node_modules/corepack 2>/dev/null || true
rm -f npm npm.cmd npx npx.cmd corepack corepack.cmd 2>/dev/null || true

# Remove docs and other non-essential files
rm -f *.md LICENSE 2>/dev/null || true

cd ../../..
echo "✓ Stripped unnecessary files from Node.js"
echo ""

# Step 4: Install production dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Installing production node_modules..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cp package.json output/${PLATFORM}/
cd output/${PLATFORM}
npm install --production --no-optional
rm package-lock.json
echo '{"type":"module"}' > package.json
echo "✓ Installed production dependencies"
echo ""

# Step 5: Prune unnecessary files from node_modules
echo "🧹 Pruning unnecessary files from node_modules..."
find node_modules -type d -name "test" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "docs" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "example" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name ".github" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "coverage" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type d -name "benchmark" -exec rm -rf {} + 2>/dev/null || true
find node_modules -type f -name "*.md" -delete 2>/dev/null || true
find node_modules -type f -name "*.ts" ! -name "*.d.ts" -delete 2>/dev/null || true
find node_modules -type f -name "*.map" -delete 2>/dev/null || true
find node_modules -type f -name "LICENSE*" -delete 2>/dev/null || true
find node_modules -type f -name "CHANGELOG*" -delete 2>/dev/null || true
find node_modules -type f -name ".npmignore" -delete 2>/dev/null || true
find node_modules -type f -name ".eslintrc*" -delete 2>/dev/null || true
find node_modules -type f -name ".prettierrc*" -delete 2>/dev/null || true
find node_modules -type f -name "tsconfig.json" -delete 2>/dev/null || true
echo "✓ Pruned unnecessary files"

cd ../..
echo ""

# Step 6: Copy config template
echo "📋 Copying pyrightconfig.json..."
cp pyrightconfig.json output/${PLATFORM}/
echo "✓ Copied config template"
echo ""

# Step 7: Create Windows start script (.bat)
echo "📝 Creating start.bat for Windows..."
cat > "output/${PLATFORM}/start.bat" << 'EOF'
@echo off
REM Pyright LSP WebSocket Bridge
REM Usage: start.bat --port <PORT> --bot-root <BOT_ROOT> --jesse-root <JESSE_ROOT>

set DIR=%~dp0
"%DIR%node\node.exe" "%DIR%bundle.js" %*
EOF
echo "✓ Created start.bat"
echo ""

# Step 8: Create compressed zip archive
echo "📦 Creating zip archive..."
cd output

# Get sizes before compression
DIR_SIZE=$(du -sh "${PLATFORM}" | cut -f1)

# Create zip using standard zip command
if command -v zip &> /dev/null; then
    zip -rq "${PLATFORM}.zip" "${PLATFORM}/"
    echo "✓ Created ${PLATFORM}.zip"
    ARCHIVE_SIZE=$(du -sh "${PLATFORM}.zip" | cut -f1)
else
    # Fallback to tar if zip is not available
    tar -czf "${PLATFORM}.tar.gz" "${PLATFORM}/"
    echo "✓ Created ${PLATFORM}.tar.gz (zip not available)"
    ARCHIVE_SIZE=$(du -sh "${PLATFORM}.tar.gz" | cut -f1)
fi

# Remove extracted folder
rm -rf "${PLATFORM}"
echo "✓ Removed extracted folder"
cd ..
echo ""

# Show summary
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ BUILD COMPLETE                                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -f "output/${PLATFORM}.zip" ]; then
    echo "📦 Compressed archive: output/${PLATFORM}.zip"
elif [ -f "output/${PLATFORM}.tar.gz" ]; then
    echo "📦 Compressed archive: output/${PLATFORM}.tar.gz"
fi

echo "   Original size: ${DIR_SIZE}"
echo "   Compressed: ${ARCHIVE_SIZE}"
echo ""
echo "📁 Archive contains:"
echo "   - bundle.js (all your bridge code bundled)"
echo "   - node/ (Node.js ${NODE_VERSION} runtime for Windows, optimized)"
echo "   - node_modules/ (Pyright + pruned dependencies)"
echo "   - pyrightconfig.json (config template)"
echo "   - start.bat (Windows startup script)"
echo ""
echo "🚀 To deploy on Windows:"
echo "   1. Extract the zip file"
echo "   2. Open Command Prompt or PowerShell"
echo "   3. Run: cd ${PLATFORM} && start.bat --port 9011 --bot-root C:\\path\\to\\bot --jesse-root C:\\path\\to\\jesse"
echo ""

