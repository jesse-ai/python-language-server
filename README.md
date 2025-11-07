# Pyright LSP WebSocket Bridge

A WebSocket bridge for the Pyright language server with a bundled Node.js runtime. This service provides Python language server capabilities (autocomplete, type checking, diagnostics, etc.) through a WebSocket interface, primarily used by the Jesse dashboard to provide IntelliSense features for Jesse strategies.

## Overview

This repository delivers:
- **WebSocket Bridge** - Translates WebSocket messages to Pyright LSP protocol
- **Bundled Runtime** - Includes Node.js, eliminating system dependencies
- **Cross-Platform Support** - Works on Linux, macOS, and Windows
- **Optimized Builds** - ~70% size reduction with production-only dependencies
- **Ruff Formatting** - Built-in Python code formatting (Linux/macOS only)

## Technology Stack

- **TypeScript** - Main language for the bridge implementation
- **Node.js** - Runtime environment
- **Pyright** - Microsoft's static type checker for Python
- **Ruff** - Fast Python linter and formatter (Unix builds only)
- **WebSocket (ws)** - WebSocket communication
- **vscode-ws-jsonrpc** - JSON-RPC over WebSocket
- **esbuild** - Fast JavaScript bundler

## Development

### Setup
```bash
npm install
```

### Running in Development Mode
```bash
npm start -- \
  --port 9011 \
  --bot-root /path/to/jesse-bot \
  --jesse-root /path/to/jesse
```

### Command-Line Arguments
- `--port` - WebSocket server port (required)
- `--bot-root` - Absolute path to the Jesse bot root directory (required)
- `--jesse-root` - Absolute path to the Jesse framework root directory (required)

## Build

### Build with Ruff Support (Recommended)
```bash
./build-with-ruff.sh
```
This builds for all platforms with Ruff formatting support included in Linux/macOS builds:
- `linux-x64.tar.gz` (~46 MB) - **Includes Ruff**
- `darwin-x64.tar.gz` (~44 MB) - **Includes Ruff**
- `darwin-arm64.tar.gz` (~44 MB) - **Includes Ruff**
- `win32-x64.zip` (~34 MB) - Pyright only (no Ruff)

**Note:** Ruff is only bundled for Unix-based systems (Linux/macOS). Windows builds include Pyright only.

### Build without Ruff (Legacy)
```bash
# Single platform (Linux x64 only)
./build.sh

# All platforms (no Ruff bundled)
./build-all.sh
```
Outputs:
- `linux-x64.tar.gz` / `linux-arm64.tar.gz` (~34 MB each)
- `darwin-x64.tar.gz` / `darwin-arm64.tar.gz` (~34 MB each)
- `win32-x64.zip` (~34 MB)

## Deployment & Usage

### Linux/macOS
```bash
# Extract the archive
tar -xzf linux-x64.tar.gz

# Run the server
cd linux-x64
./start.sh \
  --port 9011 \
  --bot-root /path/to/jesse-bot \
  --jesse-root /path/to/jesse
```

### Windows
```cmd
REM Extract win32-x64.zip

REM Run the server
cd win32-x64
start.bat --port 9011 --bot-root C:\path\to\jesse-bot --jesse-root C:\path\to\jesse
```

## Configuration

The Pyright language server is configured via `pyrightconfig.json`. The bridge automatically deploys this configuration file to the bot root directory specified by `--bot-root` on startup. You can customize type checking behavior, Python version, include/exclude patterns, and more.

## Features

- ✅ Bundled Node.js runtime (no system dependencies)
- ✅ Optimized build (~70% size reduction)
- ✅ Cross-platform support (Linux, macOS, Windows)
- ✅ Production-ready dependencies only
- ✅ WebSocket-based communication
- ✅ Full Pyright LSP capabilities
- ✅ Ruff code formatting (Linux/macOS builds)

### Ruff Formatting Support

Ruff is a fast Python linter and formatter written in Rust. When using builds from `build-with-ruff.sh`:

- **Linux/macOS**: Ruff binary is bundled and intercepts LSP formatting requests
- **Windows**: Pyright only (no Ruff bundling)

Formatting is automatically handled when you trigger "Format Document" in your IDE. The bridge intercepts `textDocument/formatting` requests and processes them with Ruff for Unix-based systems.

## Architecture

The bridge acts as a middleware between WebSocket clients (like the Jesse dashboard) and the Pyright language server:

```
Client (Jesse Dashboard) <-> WebSocket <-> Bridge <-> Pyright LSP
```

Messages are translated between WebSocket and the Language Server Protocol, enabling Python IntelliSense features in web-based interfaces.

## File Structure

- `index.ts` - Entry point and CLI argument handling
- `pyright-bridge.ts` - WebSocket bridge implementation
- `formatting.ts` - Ruff formatting handler
- `pyrightconfig.json` - Pyright configuration
- `package.json` - Node.js project configuration
- `build.sh` - Build script for Linux x64 (no Ruff)
- `build-all.sh` - Build script for all platforms (no Ruff)
- `build-with-ruff.sh` - Build script with Ruff support (Linux/macOS/Windows)
- `build-windows.sh` - Build script for Windows only (with Ruff)
- `output/` - Build output directory (generated)

## License

This project is part of the Jesse ecosystem.
