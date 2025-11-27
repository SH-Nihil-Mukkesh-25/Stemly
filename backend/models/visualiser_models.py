from typing import Any, Dict

from pydantic import BaseModel, Field


class VisualiserSaveRequest(BaseModel):
    template_id: str = Field(..., description="ID of the visualiser template to save")
    parameters: Dict[str, Any] = Field(
        default_factory=dict,
        description="User-customised parameters for the template",
    )
