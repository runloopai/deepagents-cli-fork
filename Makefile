.PHONY: all lint format test help

# Default target executed when no arguments are given to make.
all: help

######################
# TESTING AND COVERAGE
######################

# Define a variable for the test file path.
TEST_FILE ?= tests/unit_tests
INTEGRATION_FILES ?= tests/integration_tests

test:
	uv run pytest --disable-socket --allow-unix-socket $(TEST_FILE)

test_integration:
	uv run pytest $(INTEGRATION_FILES)

test_watch:
	uv run ptw . -- $(TEST_FILE)


######################
# LINTING AND FORMATTING
######################

# Define a variable for Python and notebook files.
lint format: PYTHON_FILES=deepagents_cli/ tests/
lint_diff format_diff: PYTHON_FILES=$(shell git diff --relative=. --name-only --diff-filter=d master | grep -E '\.py$$|\.ipynb$$')

lint lint_diff:
	[ "$(PYTHON_FILES)" = "" ] ||	uv run ruff format $(PYTHON_FILES) --diff
	@if [ "$(LINT)" != "minimal" ]; then \
		if [ "$(PYTHON_FILES)" != "" ]; then \
			uv run ruff check $(PYTHON_FILES) --diff; \
		fi; \
	fi
	# [ "$(PYTHON_FILES)" = "" ] || uv run mypy $(PYTHON_FILES)

format format_diff:
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff format $(PYTHON_FILES)
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff check --fix $(PYTHON_FILES)

format_unsafe:
	[ "$(PYTHON_FILES)" = "" ] || uv run ruff format --unsafe-fixes $(PYTHON_FILES)


######################
# BUILD
######################

build:
	@echo "Building standalone executable with PyInstaller..."
	@echo "Installing PyInstaller..."
	@uv pip install --quiet pyinstaller
	@echo "Building executable..."
	@uv run pyinstaller --onefile --name deepagents \
		--collect-all deepagents \
		--collect-all deepagents_cli \
		--collect-all langchain \
		--collect-all langchain_core \
		--collect-all langchain_anthropic \
		--collect-all langgraph \
		--hidden-import=deepagents_cli \
		--hidden-import=deepagents_cli.main \
		--hidden-import=deepagents_cli.dev_server \
		deepagents_cli/__main__.py
	@echo "✓ Built: dist/deepagents"
	@echo "Run with: ./dist/deepagents --help"

build-dir:
	@echo "Building directory-based executable with PyInstaller..."
	@echo "Installing PyInstaller..."
	@uv pip install --quiet pyinstaller
	@echo "Building executable..."
	@uv run pyinstaller --onedir --name deepagents \
		--collect-all deepagents \
		--collect-all deepagents_cli \
		--collect-all langchain \
		--collect-all langchain_core \
		--collect-all langchain_anthropic \
		--collect-all langgraph \
		--hidden-import=deepagents_cli \
		--hidden-import=deepagents_cli.main \
		--hidden-import=deepagents_cli.dev_server \
		deepagents_cli/__main__.py
	@echo "✓ Built: dist/deepagents/"
	@echo "Run with: ./dist/deepagents/deepagents --help"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build dist *.spec deepagents.pyz
	@echo "✓ Cleaned"

build-linux:
	@echo "Building Linux executable using Docker..."
	@docker build -t deepagents-builder .
	@docker create --name deepagents-tmp deepagents-builder
	@docker cp deepagents-tmp:/app/dist/deepagents ./dist/deepagents-linux
	@docker rm deepagents-tmp
	@echo "✓ Built: dist/deepagents-linux"
	@echo "Transfer to Linux with: scp dist/deepagents-linux user@host:/path/"

package:
	@echo "Packaging application source files..."
	@mkdir -p dist
	@tar --exclude-from=.tarignore -czf dist/deepagents-cli-source.tar.gz \
		deepagents_cli/ \
		pyproject.toml \
		uv.lock \
		README.md \
		Makefile \
		Dockerfile
	@echo "✓ Created: dist/deepagents-cli-source.tar.gz"
	@echo "Extract with: tar -xzf deepagents-cli-source.tar.gz"

package-runtime:
	@echo "Packaging complete runtime (includes venv, platform-specific)..."
	@if [ ! -d .venv ]; then \
		echo "Error: .venv not found. Run 'uv sync' first."; \
		exit 1; \
	fi
	@mkdir -p dist
	@chmod +x run.sh
	@echo "This may take a while (venv is large)..."
	@tar -czf dist/deepagents-cli-runtime.tar.gz \
		--exclude='*.pyc' \
		--exclude='*.pyo' \
		--exclude='__pycache__' \
		--exclude='.DS_Store' \
		--exclude='build' \
		--exclude='dist' \
		--exclude='*.spec' \
		--exclude='.git' \
		--exclude='.github' \
		--exclude='.vscode' \
		--exclude='.idea' \
		--exclude='tests' \
		--exclude='.langgraph_api' \
		deepagents_cli/ \
		.venv/ \
		pyproject.toml \
		uv.lock \
		README.md \
		Makefile \
		Dockerfile \
		run.sh
	@ls -lh dist/deepagents-cli-runtime.tar.gz
	@echo "✓ Created: dist/deepagents-cli-runtime.tar.gz"
	@echo ""
	@echo "⚠️  WARNING: This package is platform-specific!"
	@echo "   Only extract on same OS/architecture as build machine"
	@echo ""
	@echo "To run after extraction:"
	@echo "  tar -xzf deepagents-cli-runtime.tar.gz"
	@echo "  ./run.sh --help              # easiest method"
	@echo ""
	@echo "Or manually:"
	@echo "  source .venv/bin/activate    # or .venv/Scripts/activate on Windows"
	@echo "  python -m deepagents_cli --help"

######################
# HELP
######################

help:
	@echo '===================='
	@echo '-- LINTING --'
	@echo 'format                       - run code formatters'
	@echo 'lint                         - run linters'
	@echo '-- TESTS --'
	@echo 'test                         - run unit tests'
	@echo 'test TEST_FILE=<test_file>   - run all tests in file'
	@echo '-- BUILD --'
	@echo 'build                        - build standalone executable for current platform (single file)'
	@echo 'build-dir                    - build directory-based executable (faster startup)'
	@echo 'build-linux                  - build Linux executable using Docker (from macOS/Windows)'
	@echo '-- PACKAGE --'
	@echo 'package                      - create tar.gz with source only (~259KB, platform-independent)'
	@echo 'package-runtime              - create tar.gz with venv included (~300MB, platform-specific)'
	@echo 'clean                        - remove build artifacts'
	@echo '-- DOCUMENTATION tasks are from the top-level Makefile --'


