# Python Language Server Repository Guide for AI Agents

## Overview
The python-language-server (pyright-lsp) repository is a WebSocket bridge for the Pyright language server with a bundled Node.js runtime. It provides Python language server capabilities (autocomplete, type checking, diagnostics, etc.) through a WebSocket interface, primarily used by the Jesse dashboard to provide IntelliSense features for Jesse strategies.

## Repository Purpose
- Provide a WebSocket bridge to Pyright language server
- Bundle Node.js runtime for standalone distribution
- Enable cross-platform Python language server capabilities
- Support Jesse dashboard with Python language features
- Deliver optimized, production-ready builds

## Technology Stack
- **TypeScript** - Main language for the bridge implementation
- **Node.js** - Runtime environment
- **Pyright** - Microsoft's static type checker for Python
- **Ruff** - Fast Python linter and formatter (bundled for formatting support)
- **WebSocket (ws)** - WebSocket communication
- **vscode-ws-jsonrpc** - JSON-RPC over WebSocket
- **esbuild** - Fast JavaScript bundler
- **tsx** - TypeScript execution for development

## Development Workflow

### Running in Development
```bash
# Navigate to the project
cd /Users/salehmir/Codes/jesse/dev-jesse/python-language-server

# Install dependencies (if needed)
npm install

# Start the server in development mode
npm start -- --port 9011 --project-root /path/to/project --jesse-relative-path jesse_folder_name --bot-relative-path jesse-bot_folder_name
```

### Building for Production

#### Quick Builds with Ruff Support
```bash
# Build for Linux x64 with Ruff formatting support
npm run build:linux

# Build for macOS (Intel and Apple Silicon) with Ruff
npm run build:mac

# Build for Linux and macOS with Ruff
npm run build:all

# Or use the script directly for specific platforms
./build-with-ruff.sh linux:x64 darwin:arm64
```

#### Legacy Builds (without Ruff)
```bash
# Linux x64 only (Pyright only, no Ruff)
./build.sh

# All platforms (Pyright only, no Ruff)
./build-all.sh
```

### Build Scripts
- `build.sh` - Build for Linux x64 only (no Ruff)
- `build-all.sh` - Build for all supported platforms (no Ruff)
- `build-with-ruff.sh` - Build with Ruff formatting support for Linux & macOS

### Build Outputs
**With Ruff (recommended):**
- `linux-x64.tar.gz` (~46 MB) - Includes Ruff formatter
- `darwin-x64.tar.gz` (~44 MB) - Intel Mac with Ruff
- `darwin-arm64.tar.gz` (~44 MB) - Apple Silicon with Ruff

**Without Ruff:**
- `linux-x64.tar.gz` (~34 MB) - Pyright only

## Important Notes

### Architecture
- **WebSocket Bridge** - Translates WebSocket messages to Pyright LSP protocol
- **Formatting Interception** - Intercepts LSP formatting requests and handles them with Ruff
- **Bundled Runtime** - Includes Node.js (and Ruff if built with `build-with-ruff.sh`)
- **Strategy Module Support** - Automatically handles Jesse's strategy structure (`.py` files that are actually `__init__.py` modules)
- **Production-only Dependencies** - Optimized builds exclude dev dependencies
- **Cross-Platform** - All path handling uses Node.js `path` module for Windows/Linux/macOS compatibility

### Code Style
- Don't write comments for functions unless specifically asked
- Follow TypeScript best practices
- Use async/await for asynchronous operations
- Ensure proper error handling and logging

### Configuration
- `pyrightconfig.json` - Pyright language server configuration
- Command-line arguments:
  - `--port` - WebSocket server port (default: 9011)
  - `--project-root` - Root directory of the Python project
  - `--jesse-relative-path` - Relative path to Jesse framework folder
  - `--bot-relative-path` - Relative path to Jesse bot folder

### Debugging
- Use `console.log()` for debugging in TypeScript/JavaScript code
- Check WebSocket connection status
- Monitor Pyright LSP communication messages
- Verify project-root and path configurations

## Common Tasks

### Modifying the Bridge Logic
1. Edit `pyright-bridge.ts` or `index.ts`
2. Test in development mode with `npm start`
3. Build for your platform with `./build.sh`
4. Test the built package

### Adding New Features
1. Implement the feature in TypeScript
2. Test locally in development mode
3. Build and verify the production bundle works
4. Test cross-platform compatibility if needed

### Updating Dependencies
1. Update `package.json`
2. Run `npm install`
3. Test in development mode
4. Rebuild and verify production builds

### Deployment
After building, the output packages are ready for deployment:

**Linux/macOS:**
```bash
tar -xzf linux-x64.tar.gz
cd linux-x64
./start.sh --port 9011 --project-root /path/to/project --jesse-relative-path jesse_folder_name --bot-relative-path jesse-bot_folder_name
```

**Windows:**
```cmd
REM Extract win32-x64.zip
cd win32-x64
start.bat --port 9011 --project-root C:\path\to\project --jesse-relative-path jesse_folder_name --bot-relative-path jesse-bot_folder_name
```

## File Structure
- `index.ts` - Entry point
- `pyright-bridge.ts` - WebSocket bridge implementation
- `pyrightconfig.json` - Pyright configuration
- `package.json` - Node.js project configuration and dependencies
- `build.sh` - Build script for Linux x64
- `build-all.sh` - Build script for all platforms
- `output/` - Build output directory (generated)


