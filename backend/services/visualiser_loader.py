import os
import json
from typing import Dict, Any, Optional

TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "..", "templates", "visualiser")

TOPIC_TO_TEMPLATE = {
    "projectile motion": "projectile_motion.json",
    "projectile_motion": "projectile_motion.json",
    "projectile": "projectile_motion.json",
    "free fall": "free_fall.json",
    "free_fall": "free_fall.json",
    "shm": "shm.json",
    "simple harmonic motion": "shm.json",
    "harmonic": "shm.json"
}

def _load_template(filename: str) -> Dict[str, Any]:
    path = os.path.join(TEMPLATES_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

async def get_template_by_topic(topic: str) -> Optional[Dict[str, Any]]:
    if not topic:
        return None

    key = topic.strip().lower()
    filename = TOPIC_TO_TEMPLATE.get(key)

    if not filename:
        return None

    try:
        return _load_template(filename)
    except FileNotFoundError:
        return None

def fill_template_defaults(template: Dict[str, Any], variables=None):
    out = dict(template)
    return out