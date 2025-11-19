# Packaging and Distribution Guide

## Common Issues and Solutions

### Error: "Failed to unpack object... failed to untar file: failed to iterate over archive"

This error typically occurs when:

1. **Symbolic links** - The archive contains broken symlinks
   - **Solution**: Use `--dereference` flag (now included by default)

2. **Platform mismatch** - Trying to use a macOS runtime package on Linux
   - **Solution**: Build runtime package on target platform

3. **Corrupted archive** - File was corrupted during transfer
   - **Solution**: Verify with `tar -tzf file.tar.gz`

4. **Incompatible tar version** - Different tar implementations
   - **Solution**: Use POSIX-compatible format

## Debugging Steps

### 1. Verify Archive Integrity

```bash
# Test if archive is readable
tar -tzf deepagents-cli-runtime.tar.gz > /dev/null
echo $?  # Should print 0 if OK

# Count files in archive
tar -tzf deepagents-cli-runtime.tar.gz | wc -l

# Check for broken symlinks (should be none with --dereference)
tar -tzf deepagents-cli-runtime.tar.gz | grep -E "^\s*l"
```

### 2. Check Platform Compatibility

```bash
# Extract and check binary type
tar -xzf deepagents-cli-runtime.tar.gz
file .venv/bin/python3

# macOS: "Mach-O 64-bit executable"
# Linux: "ELF 64-bit LSB executable"
```

### 3. Test Extraction with Verbose Mode

```bash
tar -xzvf deepagents-cli-runtime.tar.gz 2>&1 | tee extract.log
# Check extract.log for errors
```

## Recommended Approach by Platform

### For Cross-Platform Distribution

Use the **source package**:

```bash
# Build on any platform
make package

# Transfer and build on target
tar -xzf deepagents-cli-source.tar.gz
cd deepagents-cli-standalone
make build
```

### For Same-Platform Distribution

Use the **runtime package**:

```bash
# Build on target platform (e.g., Linux server)
ssh user@linux-server
cd /path/to/repo
make package-runtime

# Use on same platform
./run.sh --help
```

### For Linux from macOS

Use **Docker** to build:

```bash
# On macOS
make build-linux

# Or build runtime in Docker
docker run --rm -v $(pwd):/app -w /app python:3.13-slim bash -c "
  apt-get update && apt-get install -y gcc make &&
  pip install uv &&
  uv sync &&
  tar -czf deepagents-cli-runtime-linux.tar.gz \
    --dereference \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    deepagents_cli/ .venv/ pyproject.toml uv.lock README.md Makefile run.sh
"
```

## Relocatable Linux Runtime Package (New!)

For deploying to Linux containers with fast startup and no rebuild:

```bash
# Build on macOS using Podman
make package-runtime-linux

# Use in container
tar -xzf deepagents-cli-runtime-linux.tar.gz
./run.sh --help
```

**What it does:**
1. Uses Podman to build a Python 3.12 Linux x86_64 venv
2. Fixes all shebangs to use `/usr/bin/env python3`
3. Makes the venv relocatable (works with container's Python)
4. Packages everything into a tar

**Benefits:**
- Fast container startup (no rebuild)
- Built from any platform using Podman
- Uses container's Python 3.12 (no binary compatibility issues)
- Smaller than full venv (packages only, no platform-specific binaries)

**Requirements:**
- Container must have Python 3.12 installed
- Built using Podman with `--platform linux/amd64`

## Archive Comparison

| Package Type | Size | Platform | Build Time | Transfer | Relocatable |
|-------------|------|----------|------------|----------|-------------|
| Source | ~259KB | Any | On target | Fast | N/A |
| Runtime (macOS) | ~52MB | macOS only | Quick | Slow | No |
| Runtime (Linux, fixed shebangs) | ~45MB | Linux x86_64 | Medium | Slow | Yes |
| Executable (PyInstaller) | ~80MB | Platform-specific | Slow | Medium | N/A |

## Troubleshooting

### "Cannot execute binary file: Exec format error"

**Cause**: Wrong platform binary

**Solution**:
```bash
file ./dist/deepagents  # Check platform
uname -m               # Check your platform
# Must match!
```

### "Permission denied"

**Cause**: Files not executable

**Solution**:
```bash
chmod +x run.sh
chmod +x .venv/bin/*
```

### "Module not found" errors

**Cause**: Virtual environment not activated or broken

**Solution**:
```bash
# Rebuild venv on target platform
cd deepagents-cli-standalone
rm -rf .venv
uv sync
```

## Best Practices

1. **For Development**: Use source package + build on target
2. **For Production Containers**: Use `make package-runtime-linux` for fast startup
3. **For Production Native**: Use PyInstaller for single executable
4. **For Testing**: Use runtime package on same platform
5. **For CI/CD**: Use Podman/Docker builds for each platform
