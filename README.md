# deepagents cli

This is the CLI for deepagents

## Development

### Running Tests

To run the test suite:

```bash
uv sync --all-groups

make test
```

## Building Standalone Executable

To create a standalone executable using PyInstaller:

```bash
make build
```

This creates a single-file executable at `dist/deepagents` that includes all dependencies (including binary extensions) and can be run directly:

```bash
./dist/deepagents --help
./dist/deepagents --auto-approve
./dist/deepagents dev --allow-blocking
```

### Build Options

**Single-file executable** (default, slower startup but more portable):
```bash
make build
```

**Directory-based executable** (faster startup, but a folder instead of single file):
```bash
make build-dir
./dist/deepagents/deepagents --help
```

**Build for Linux** (from macOS/Windows using Docker):
```bash
make build-linux
# Transfer to Linux: scp dist/deepagents-linux user@host:/path/
```

**Clean build artifacts**:
```bash
make clean
```

### Cross-Platform Builds

⚠️ **Important**: PyInstaller creates platform-specific executables. A binary built on macOS won't run on Linux and vice versa.

**Building on Linux:**
```bash
# On Linux machine
git pull
make build
./dist/deepagents help
```

**Building Linux executable from macOS:**
```bash
# Requires Docker
make build-linux
scp dist/deepagents-linux user@linux-host:/usr/local/bin/deepagents
```

**Debugging "Exec format error":**
```bash
# On Linux, check the binary type
file ./dist/deepagents

# If you see "Mach-O" or "arm64", it's a macOS binary
# Rebuild on Linux or use `make build-linux` with Docker
```

### Manual Build

If you prefer to build manually:

```bash
uv pip install pyinstaller
uv run pyinstaller --onefile --name deepagents \
    --collect-all deepagents \
    --collect-all deepagents_cli \
    --collect-all langchain \
    --collect-all langchain_core \
    --hidden-import=deepagents_cli \
    deepagents_cli/__main__.py
```

The executable is portable and can be distributed without requiring a Python environment or virtual environment (though Python itself must be available on the target system).
