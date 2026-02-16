"""
Generate OpenAPI spec from the FastAPI app.

Usage:
    cd backend
    python scripts/generate_openapi.py

Outputs backend/openapi.json
"""

import json
import sys
from pathlib import Path

# Add backend root to path so imports work
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from main import app  # noqa: E402


def main():
    spec = app.openapi()
    output_path = Path(__file__).resolve().parent.parent / "openapi.json"
    output_path.write_text(json.dumps(spec, indent=2))
    print(f"OpenAPI spec written to {output_path}")


if __name__ == "__main__":
    main()
