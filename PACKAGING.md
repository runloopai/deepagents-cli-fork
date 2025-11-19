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

## Archive Comparison

| Package Type | Size | Platform | Build Time | Transfer |
|-------------|------|----------|------------|----------|
| Source | ~259KB | Any | On target | Fast |
| Runtime (macOS) | ~52MB | macOS only | Quick | Slow |
| Runtime (Linux) | ~45MB | Linux only | Quick | Slow |
| Executable (PyInstaller) | ~80MB | Platform-specific | Slow | Medium |

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
2. **For Production**: Use PyInstaller for single executable
3. **For Testing**: Use runtime package on same platform
4. **For CI/CD**: Use Docker builds for each platform
