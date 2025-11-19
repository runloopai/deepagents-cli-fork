# Dockerfile for building deepagents Linux executable
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Copy project files
COPY . .

# Install dependencies and build
RUN uv pip install --system . && \
    uv pip install --system pyinstaller && \
    pyinstaller --onefile --name deepagents \
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

# The executable will be in /app/dist/deepagents
CMD ["./dist/deepagents", "help"]
