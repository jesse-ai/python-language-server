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

#### Single Platform (Linux x64)
```bash
./build.sh
```
Output: `output/linux-x64.tar.gz` (~34 MB)

#### All Platforms
```bash
./build-all.sh
```
Outputs:
- `linux-x64.tar.gz` / `linux-arm64.tar.gz`
- `darwin-x64.tar.gz` / `darwin-arm64.tar.gz`
- `win32-x64.zip`

### Build Scripts
- `build.sh` - Build for Linux x64 only
- `build-all.sh` - Build for all supported platforms

## Important Notes

### Architecture
- **WebSocket Bridge** - Translates WebSocket messages to Pyright LSP protocol
- **Bundled Runtime** - Includes Node.js, eliminating system dependencies
- **Production-only Dependencies** - Optimized builds exclude dev dependencies
- **70% Size Reduction** - Optimized build process significantly reduces package size

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


