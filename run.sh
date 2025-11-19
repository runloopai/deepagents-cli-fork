#!/bin/bash
# Convenience script to run deepagents-cli from the extracted runtime package

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Activate the virtual environment
if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
elif [ -f "$SCRIPT_DIR/.venv/Scripts/activate" ]; then
    source "$SCRIPT_DIR/.venv/Scripts/activate"
else
    echo "Error: Virtual environment not found at $SCRIPT_DIR/.venv"
    exit 1
fi

# Run deepagents-cli with all provided arguments
python -m deepagents_cli "$@"
