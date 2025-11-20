# deepagents cli

This is the CLI for deepagents

## Installation

This project requires Python >=3.11,<4.0 and uses `uv` for dependency management.

### Install Dependencies

```bash
uv sync
```

To include development dependencies (test, dev, lint groups):

```bash
uv sync --all-groups
```

## Running Locally

After installing dependencies, you can run the CLI in several ways:

### Option 1: Using uv run (Recommended)

```bash
uv run deepagents
```

Or with specific arguments:

```bash
uv run deepagents --agent my-agent --auto-approve
```

### Option 2: Using Python module

```bash
uv run python -m deepagents_cli
```

### Option 3: Install as package (for development)

```bash
uv pip install -e .
```

Then run directly:

```bash
deepagents
# or
deepagents-cli
```

## Development

### Running Tests

To run the test suite:

```bash
uv sync --all-groups
make test
```
