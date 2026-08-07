"""
utils/json_extract.py — Trích JSON từ output của AI một cách "lì đòn".

Vấn đề thực tế: dù prompt yêu cầu "chỉ trả JSON", các model thỉnh thoảng vẫn
bọc ```json ... ``` hoặc thêm câu dẫn. Module này xử lý mọi trường hợp đó
để pipeline không bao giờ vỡ vì 1 dấu ``` thừa.
"""

from __future__ import annotations

import json
import re
from typing import Any, Optional


def extract_json(text: str) -> Optional[Any]:
    """Cố gắng parse JSON theo nhiều chiến lược, trả None nếu bất khả thi."""
    if not text:
        return None

    # 1) Parse trực tiếp
    try:
        return json.loads(text)
    except (json.JSONDecodeError, ValueError):
        pass

    # 2) Bỏ code fence ```json ... ```
    fence = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    if fence:
        try:
            return json.loads(fence.group(1))
        except (json.JSONDecodeError, ValueError):
            pass

    # 3) Tìm khối {...} hoặc [...] ngoài cùng (cân bằng ngoặc)
    for opener, closer in (("{", "}"), ("[", "]")):
        start = text.find(opener)
        if start == -1:
            continue
        depth = 0
        in_str = False
        escape = False
        for i in range(start, len(text)):
            ch = text[i]
            if in_str:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_str = False
                continue
            if ch == '"':
                in_str = True
            elif ch == opener:
                depth += 1
            elif ch == closer:
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(text[start:i + 1])
                    except (json.JSONDecodeError, ValueError):
                        break
    return None
