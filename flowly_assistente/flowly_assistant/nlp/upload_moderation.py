from __future__ import annotations

import base64
import re
from typing import Any, Dict, List


BLOCKED_CATEGORIES = [
    "explicit_pornography",
    "suggestive_content",
    "violence",
    "gore",
    "hate_symbols",
    "offensive_content",
]

FILENAME_PATTERNS = [
    r"porn",
    r"porno",
    r"pornografia",
    r"xxx",
    r"nude",
    r"nudes",
    r"sexo",
    r"gore",
    r"sangue",
    r"violencia",
    r"violence",
    r"nazi",
    r"hitler",
    r"swastika",
    r"suastica",
    r"kkk",
    r"odio",
]

TEXT_PATTERNS = [
    r"pornografia\s+explicita",
    r"conte[uú]do\s+sexual",
    r"sexo\s+expl[ií]cito",
    r"gore",
    r"mutila",
    r"decapita",
    r"su[aá]stica",
    r"nazismo",
    r"s[ií]mbolo\s+de\s+[oó]dio",
]


def moderate_upload_payload(body: Dict[str, Any]) -> Dict[str, Any]:
    filename = str(body.get("filename") or "")
    mimetype = str(body.get("mimetype") or "")
    content_base64 = str(body.get("contentBase64") or "")

    categories: List[str] = []
    normalized_name = filename.lower()
    if any(re.search(pattern, normalized_name, re.IGNORECASE) for pattern in FILENAME_PATTERNS):
        categories.append("offensive_content")

    if mimetype == "application/pdf" and content_base64:
        sample = _decode_sample(content_base64)
        if any(re.search(pattern, sample, re.IGNORECASE) for pattern in TEXT_PATTERNS):
            categories.append("offensive_content")

    # Hook para substituir por classificador visual real:
    # OpenAI Vision/Moderation, Google Vision SafeSearch, AWS Rekognition etc.
    allowed = not any(category in BLOCKED_CATEGORIES for category in categories)
    return {
        "allowed": allowed,
        "categories": sorted(set(categories)),
        "reason": "" if allowed else "Arquivo bloqueado pela moderacao de upload.",
        "provider": "flowly_assistant_upload_moderation",
    }


def _decode_sample(content_base64: str) -> str:
    try:
        raw = base64.b64decode(content_base64[:700_000], validate=False)
    except Exception:
        return ""
    return raw[:512_000].decode("latin1", errors="ignore")
