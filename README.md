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

To create a standalone executable using `shiv`:

```bash
shiv -c deepagents -o deepagents.pyz deepagents-cli
chmod +x deepagents.pyz
```

This creates a self-contained `deepagents.pyz` file that includes all dependencies and can be run directly:

```bash
./deepagents.pyz --help
```

The executable is portable and can be distributed without requiring a Python environment or virtual environment.
