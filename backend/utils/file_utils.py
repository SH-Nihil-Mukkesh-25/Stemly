from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
STATIC_SCANS_DIR = (PROJECT_ROOT / "static" / "scans").resolve()


def resolve_scan_path(image_path: str) -> Path:
    """
    Resolve a user-supplied image path and ensure it resides inside the
    `static/scans` directory. Raises ValueError if the path is invalid.
    """
    if not image_path:
        raise ValueError("image_path is required for scan lookup.")

    path = Path(image_path)
    if not path.is_absolute():
        path = (Path.cwd() / path).resolve()
    else:
        path = path.resolve()

    # Robust check using pathlib
    try:
        path.relative_to(STATIC_SCANS_DIR)
    except ValueError:
        print(f"DEBUG: Path mismatch!")
        print(f"  Input arg:      {image_path}")
        print(f"  Input resolved: {path}")
        print(f"  Expected root:  {STATIC_SCANS_DIR}")
        raise ValueError("image_path must reference a saved scan asset.")

    if not path.is_file():
        raise ValueError("Referenced scan image does not exist.")

    return path


def scan_path_to_relative(path: Path) -> str:
    """Return a path relative to the project root (e.g., static/scans/xyz.png)."""
    return str(path.relative_to(PROJECT_ROOT))