from __future__ import annotations

import json
import os
from typing import Any, Dict, Tuple

import flowly_assistant.settings  # noqa: F401 - loads flowly_assistente/.env for local Functions Framework
from flowly_assistant.assistant_core.message_agent import MessageAgent, get_admin_insights
from flowly_assistant.assistant_core.rest_assistant import assistant_from_http_body
from flowly_assistant.storage.conversation_state import ConversationStateRepository


def _json_response(payload: Dict[str, Any], status: int = 200) -> Tuple[str, int, Dict[str, str]]:
    headers: Dict[str, str] = {"Content-Type": "application/json; charset=utf-8"}
    cors_origin = str(os.getenv("FLOWLY_CORS_ORIGIN", "*") or "*").strip()
    if cors_origin:
        headers["Access-Control-Allow-Origin"] = cors_origin
        headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        headers["Access-Control-Max-Age"] = "3600"
    return json.dumps(payload, ensure_ascii=False), status, headers


def _request_path(request) -> str:
    path = getattr(request, "path", None) or getattr(request, "full_path", None) or "/"
    return str(path).split("?", 1)[0].rstrip("/") or "/"


def _read_body(request) -> Dict[str, Any]:
    try:
        body = request.get_json(silent=True) or {}
    except Exception:
        body = {}
    return body if isinstance(body, dict) else {}


def _read_token(request, body: Dict[str, Any]) -> str:
    token = str(body.get("token") or body.get("authorization") or "").strip()
    if token:
        return token.removeprefix("Bearer ").strip()

    auth_header = request.headers.get("Authorization", "").strip()
    if auth_header.startswith("Bearer "):
        return auth_header[7:].strip()
    return ""


def flowly_http(request):
    """HTTP REST entrypoint for the Flowly assistant.

    Supported routes:
      GET  / or /health
      POST / or /assist
      POST /standby
      POST /api/v1/messages
      GET  /api/v1/admin/insights
    """

    if request.method == "OPTIONS":
        return _json_response({"ok": True}, 204)

    path = _request_path(request)
    if request.method == "GET" and path in {"/", "/health"}:
        return _json_response(
            {
                "ok": True,
                "service": "flowly_assistente",
                "routes": {
                    "health": "GET /health",
                    "assist": "POST /assist",
                    "standby": "POST /standby",
                    "messages": "POST /api/v1/messages",
                    "insights": "GET /api/v1/admin/insights",
                    "legacy_assist": "POST /",
                },
                "example": {"utterance": "meu perfil"},
                "tts_contract": {"reply_text": "string", "tts": {"enabled": True, "language": "pt-BR", "text": "string"}},
            }
        )

    if request.method == "POST" and path == "/standby":
        body = _read_body(request)
        conversation_id = str(body.get("conversationId") or body.get("conversation_id") or "").strip()
        if conversation_id:
            ConversationStateRepository().clear(conversation_id)
        text = "Assistente em standby."
        return _json_response(
            {
                "ok": True,
                "status": "standby",
                "reply_text": text,
                "tts": {"enabled": False, "language": "pt-BR", "text": text},
            }
        )

    if request.method == "GET" and path == "/api/v1/admin/insights":
        body = _read_body(request)
        token = _read_token(request, body)
        if not token:
            return _json_response({"ok": False, "error": "missing_token", "reply_text": "Token obrigatório."}, 401)
        payload, status = get_admin_insights(token, body)
        return _json_response(payload, status)

    if request.method == "POST" and path == "/api/v1/messages":
        body = _read_body(request)
        token = _read_token(request, body)
        if not token:
            return _json_response({"ok": False, "error": "missing_token", "reply_text": "Token obrigatório."}, 401)
        debug = str(body.get("debug") or os.getenv("FLOWLY_DEBUG", "false")).strip().lower() == "true"
        payload, status = MessageAgent(token=token, body=body, debug=debug).handle_message()
        return _json_response(payload, status)

    if request.method != "POST" or path not in {"/", "/assist"}:
        return _json_response({"ok": False, "error": "route_not_found", "reply_text": "Rota não encontrada."}, 404)

    body = _read_body(request)
    token = _read_token(request, body)
    if not token:
        return _json_response(
            {
                "ok": False,
                "error": "missing_token",
                "reply_text": "Token de autenticação obrigatório.",
                "tts": {"enabled": True, "language": "pt-BR", "text": "Token de autenticação obrigatório."},
            },
            401,
        )

    debug = str(body.get("debug") or os.getenv("FLOWLY_DEBUG", "false")).strip().lower() == "true"
    assistant = assistant_from_http_body(body, token, debug=debug)
    utterance = str(body.get("utterance") or body.get("text") or "").strip()
    params = body.get("params") if isinstance(body.get("params"), dict) else {}
    payload, status = assistant.handle(utterance, params)
    return _json_response(payload, status)


def trigger_http(request):
    """Google Cloud Functions HTTP trigger."""

    return flowly_http(request)
