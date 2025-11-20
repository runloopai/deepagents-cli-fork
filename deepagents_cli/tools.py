"""Custom tools for the CLI agent."""

import json
import os
import subprocess
from pathlib import Path
from typing import Any, Literal

import requests
from markdownify import markdownify
from tavily import TavilyClient

# Initialize Tavily client only if API key is available
tavily_api_key = os.environ.get("TAVILY_API_KEY")
tavily_client = TavilyClient(api_key=tavily_api_key) if tavily_api_key else None


def http_request(
    url: str,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: str | dict | None = None,
    params: dict[str, str] | None = None,
    timeout: int = 30,
) -> dict[str, Any]:
    """Make HTTP requests to APIs and web services.

    Args:
        url: Target URL
        method: HTTP method (GET, POST, PUT, DELETE, etc.)
        headers: HTTP headers to include
        data: Request body data (string or dict)
        params: URL query parameters
        timeout: Request timeout in seconds

    Returns:
        Dictionary with response data including status, headers, and content
    """
    try:
        kwargs = {"url": url, "method": method.upper(), "timeout": timeout}

        if headers:
            kwargs["headers"] = headers
        if params:
            kwargs["params"] = params
        if data:
            if isinstance(data, dict):
                kwargs["json"] = data
            else:
                kwargs["data"] = data

        response = requests.request(**kwargs)

        try:
            content = response.json()
        except:
            content = response.text

        return {
            "success": response.status_code < 400,
            "status_code": response.status_code,
            "headers": dict(response.headers),
            "content": content,
            "url": response.url,
        }

    except requests.exceptions.Timeout:
        return {
            "success": False,
            "status_code": 0,
            "headers": {},
            "content": f"Request timed out after {timeout} seconds",
            "url": url,
        }
    except requests.exceptions.RequestException as e:
        return {
            "success": False,
            "status_code": 0,
            "headers": {},
            "content": f"Request error: {e!s}",
            "url": url,
        }
    except Exception as e:
        return {
            "success": False,
            "status_code": 0,
            "headers": {},
            "content": f"Error making request: {e!s}",
            "url": url,
        }


def web_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
):
    """Search the web using Tavily for current information and documentation.

    This tool searches the web and returns relevant results. After receiving results,
    you MUST synthesize the information into a natural, helpful response for the user.

    Args:
        query: The search query (be specific and detailed)
        max_results: Number of results to return (default: 5)
        topic: Search topic type - "general" for most queries, "news" for current events
        include_raw_content: Include full page content (warning: uses more tokens)

    Returns:
        Dictionary containing:
        - results: List of search results, each with:
            - title: Page title
            - url: Page URL
            - content: Relevant excerpt from the page
            - score: Relevance score (0-1)
        - query: The original search query

    IMPORTANT: After using this tool:
    1. Read through the 'content' field of each result
    2. Extract relevant information that answers the user's question
    3. Synthesize this into a clear, natural language response
    4. Cite sources by mentioning the page titles or URLs
    5. NEVER show the raw JSON to the user - always provide a formatted response
    """
    if tavily_client is None:
        return {
            "error": "TAVILY_API_KEY environment variable is not set. Web search is unavailable.",
            "query": query,
        }
    try:
        return tavily_client.search(
            query,
            max_results=max_results,
            include_raw_content=include_raw_content,
            topic=topic,
        )
    except Exception as e:
        return {"error": f"Web search error: {e!s}", "query": query}


def fetch_url(url: str, timeout: int = 30) -> dict[str, Any]:
    """Fetch content from a URL and convert HTML to markdown format.

    This tool fetches web page content and converts it to clean markdown text,
    making it easy to read and process HTML content. After receiving the markdown,
    you MUST synthesize the information into a natural, helpful response for the user.

    Args:
        url: The URL to fetch (must be a valid HTTP/HTTPS URL)
        timeout: Request timeout in seconds (default: 30)

    Returns:
        Dictionary containing:
        - success: Whether the request succeeded
        - url: The final URL after redirects
        - markdown_content: The page content converted to markdown
        - status_code: HTTP status code
        - content_length: Length of the markdown content in characters

    IMPORTANT: After using this tool:
    1. Read through the markdown content
    2. Extract relevant information that answers the user's question
    3. Synthesize this into a clear, natural language response
    4. NEVER show the raw markdown to the user unless specifically requested
    """
    try:
        response = requests.get(
            url,
            timeout=timeout,
            headers={"User-Agent": "Mozilla/5.0 (compatible; DeepAgents/1.0)"},
        )
        response.raise_for_status()

        # Convert HTML content to markdown
        markdown_content = markdownify(response.text)

        return {
            "url": str(response.url),
            "markdown_content": markdown_content,
            "status_code": response.status_code,
            "content_length": len(markdown_content),
        }
    except Exception as e:
        return {"error": f"Fetch URL error: {e!s}", "url": url}


def check_python_dependencies(
    requirements_path: str = "requirements.txt",
    check_pyproject: bool = True,
) -> dict[str, Any]:
    """Check Python dependencies and suggest upgrades.

    This tool analyzes Python dependencies from requirements.txt or pyproject.toml
    and suggests available upgrades using pip.

    Args:
        requirements_path: Path to requirements.txt file (default: "requirements.txt")
        check_pyproject: Also check pyproject.toml if it exists (default: True)

    Returns:
        Dictionary containing:
        - dependencies: List of current dependencies with versions
        - outdated: List of packages that have newer versions available
        - upgrades: Suggested upgrade commands
        - source: Which file was analyzed

    Example:
        >>> check_python_dependencies()
        {
            "dependencies": [{"name": "requests", "current": "2.28.0", "latest": "2.31.0"}],
            "outdated": ["requests"],
            "upgrades": ["pip install requests==2.31.0"],
            "source": "requirements.txt"
        }
    """
    try:
        result: dict[str, Any] = {
            "dependencies": [],
            "outdated": [],
            "upgrades": [],
            "source": None,
        }

        # Check which dependency file exists
        req_path = Path(requirements_path)
        pyproject_path = Path("pyproject.toml")

        if check_pyproject and pyproject_path.exists():
            result["source"] = "pyproject.toml"
        elif req_path.exists():
            result["source"] = str(requirements_path)
        else:
            return {
                "error": f"No dependency file found. Checked: {requirements_path}, pyproject.toml"
            }

        # Check for outdated packages
        outdated_result = subprocess.run(
            ["pip", "list", "--outdated", "--format=json"],
            capture_output=True,
            text=True,
            check=True,
            timeout=30,
        )
        outdated = json.loads(outdated_result.stdout)

        # Build response
        for pkg in outdated:
            result["dependencies"].append({
                "name": pkg["name"],
                "current": pkg["version"],
                "latest": pkg["latest_version"],
            })
            result["outdated"].append(pkg["name"])
            result["upgrades"].append(f"pip install {pkg['name']}=={pkg['latest_version']}")

        if not result["outdated"]:
            result["message"] = "All dependencies are up to date!"

        return result

    except subprocess.CalledProcessError as e:
        return {"error": f"Failed to check dependencies: {e.stderr}"}
    except subprocess.TimeoutExpired:
        return {"error": "Command timed out after 30 seconds"}
    except Exception as e:
        return {"error": f"Error checking Python dependencies: {e!s}"}


def check_typescript_dependencies(
    package_json_path: str = "package.json",
) -> dict[str, Any]:
    """Check TypeScript/Node.js dependencies and suggest upgrades.

    This tool analyzes dependencies from package.json and suggests available
    upgrades using npm.

    Args:
        package_json_path: Path to package.json file (default: "package.json")

    Returns:
        Dictionary containing:
        - dependencies: List of current dependencies with versions
        - outdated: List of packages that have newer versions available
        - upgrades: Suggested upgrade commands
        - source: Which file was analyzed

    Example:
        >>> check_typescript_dependencies()
        {
            "dependencies": [{"name": "typescript", "current": "4.9.0", "wanted": "4.9.5", "latest": "5.3.0"}],
            "outdated": ["typescript"],
            "upgrades": ["npm install typescript@5.3.0"],
            "source": "package.json"
        }
    """
    try:
        pkg_path = Path(package_json_path)

        if not pkg_path.exists():
            return {"error": f"No package.json found at: {package_json_path}"}

        result: dict[str, Any] = {
            "dependencies": [],
            "outdated": [],
            "upgrades": [],
            "source": package_json_path,
        }

        # Check for outdated packages using npm outdated
        outdated_result = subprocess.run(
            ["npm", "outdated", "--json"],
            capture_output=True,
            text=True,
            cwd=pkg_path.parent,
            timeout=60,
        )

        # npm outdated returns exit code 1 when there are outdated packages
        if outdated_result.stdout:
            try:
                outdated = json.loads(outdated_result.stdout)

                for pkg_name, pkg_info in outdated.items():
                    result["dependencies"].append({
                        "name": pkg_name,
                        "current": pkg_info.get("current", "N/A"),
                        "wanted": pkg_info.get("wanted", "N/A"),
                        "latest": pkg_info.get("latest", "N/A"),
                    })
                    result["outdated"].append(pkg_name)
                    result["upgrades"].append(
                        f"npm install {pkg_name}@{pkg_info.get('latest', 'latest')}"
                    )
            except json.JSONDecodeError:
                return {"error": "Failed to parse npm outdated output"}

        if not result["outdated"]:
            result["message"] = "All dependencies are up to date!"

        return result

    except FileNotFoundError:
        return {"error": "npm is not installed or not in PATH"}
    except subprocess.TimeoutExpired:
        return {"error": "npm command timed out after 60 seconds"}
    except Exception as e:
        return {"error": f"Error checking TypeScript dependencies: {e!s}"}
