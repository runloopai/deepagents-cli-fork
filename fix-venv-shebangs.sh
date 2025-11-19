#!/bin/bash
# Fix shebangs in virtual environment to make it relocatable
# Usage: ./fix-venv-shebangs.sh [venv_path]

set -e

VENV_PATH="${1:-.venv}"

if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH"
    exit 1
fi

echo "Fixing shebangs in $VENV_PATH..."

# Fix all Python scripts in bin/ to use env
# This makes them work with whatever Python is in PATH
for file in "$VENV_PATH/bin/"*; do
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        # Check if file has a shebang
        if head -n1 "$file" 2>/dev/null | grep -q "^#!.*python"; then
            # Replace shebang with env-based one
            sed -i '1s|^#!.*python.*$|#!/usr/bin/env python3|' "$file"
            echo "  Fixed: $(basename "$file")"
        fi
    fi
done

# Fix the activate script to use relative paths
# This makes the venv work when moved to different locations
ACTIVATE_SCRIPT="$VENV_PATH/bin/activate"
if [ -f "$ACTIVATE_SCRIPT" ]; then
    # Create a dynamic VIRTUAL_ENV path using the script's location
    sed -i 's|^VIRTUAL_ENV=.*$|VIRTUAL_ENV="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" \&\& pwd)"|' "$ACTIVATE_SCRIPT"
    echo "  Fixed: activate script (now uses relative path)"
fi

echo "✓ Shebangs fixed successfully!"
echo ""
echo "Note: The venv will now use the system's Python 3 from PATH."
echo "Make sure the target system has a compatible Python version installed."
