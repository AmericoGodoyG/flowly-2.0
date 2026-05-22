from __future__ import annotations

import json
import os
import re
from dataclasses import asdict, is_dataclass
from difflib import SequenceMatcher
from typing import Any, Dict, Optional, Tuple

from api_client import APIError, FlowlyAPIClient
from command_parser import CommandParser, Match


OBJ_ID_LEN = 24


def _normalize(text: str) -> str:
    text = (text or "").strip().lower()
    return " ".join(text.split())


def _ratio(a: str, b: str) -> int:
    return int(round(SequenceMatcher(None, a, b).ratio() * 100))


def _token_set_ratio(a: str, b: str) -> int:
    a = _normalize(a)
    b = _normalize(b)
    if not a or not b:
        return 0

    tokens_a = set(a.split())
    tokens_b = set(b.split())
    intersection = tokens_a & tokens_b
    diff_a = tokens_a - intersection
    diff_b = tokens_b - intersection

    sect = " ".join(sorted(intersection))
    combo_a = " ".join(sorted(intersection | diff_a))
    combo_b = " ".join(sorted(intersection | diff_b))

    return max(_ratio(sect, combo_a), _ratio(sect, combo_b), _ratio(combo_a, combo_b))


def _is_object_id(value: str) -> bool:
    v = (value or "").strip()
    if len(v) != OBJ_ID_LEN:
        return False
    try:
        int(v, 16)
        return True
    except Exception:
        return False


def _json_response(payload: Dict[str, Any], status: int = 200) -> tuple[str, int, Dict[str, str]]:
    headers: Dict[str, str] = {"Content-Type": "application/json"}
    cors_origin = str(os.getenv("FLOWLY_CORS_ORIGIN", "*") or "*").strip()
    if cors_origin:
        headers["Access-Control-Allow-Origin"] = cors_origin
        headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        headers["Access-Control-Max-Age"] = "3600"
    return (json.dumps(payload, ensure_ascii=False), status, headers)


def _reply_text(command_key: str, result: Any) -> str:
    if command_key in {"my_tasks", "backlog", "list_teams", "my_teams", "list_users"}:
        n = len(result) if isinstance(result, list) else 0
        return f"Ok. Encontrei {n} itens."

    if command_key == "task_details":
        tarefa = (result or {}).get("tarefa") if isinstance(result, dict) else None
        desc = (tarefa or {}).get("descricao") if isinstance(tarefa, dict) else None
        return f"Detalhes carregados. Tarefa: {desc}" if desc else "Detalhes carregados."

    if command_key == "me":
        nome = (result or {}).get("nome") if isinstance(result, dict) else None
        return f"Aqui está o seu perfil, {nome}." if nome else "Aqui está o seu perfil."

    return "Ação concluída com sucesso."


def _has_permission(user_type: Optional[str], required: str) -> bool:
    if required == "any":
        return True
    if user_type not in {"admin", "user"}:
        return required != "admin"
    if required == "admin":
        return user_type == "admin"
    if required == "user":
        return user_type == "user"
    return False


def _coerce_jsonable(value: Any) -> Any:
    if is_dataclass(value):
        return asdict(value)
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if isinstance(value, dict):
        return {str(k): _coerce_jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_coerce_jsonable(v) for v in value]
    return str(value)


def _resolve_team_ref(api: FlowlyAPIClient, ref: str) -> Tuple[str, str]:
    if _is_object_id(ref):
        return ref, ref

    query = _normalize(ref)
    if len(query) < 2:
        raise APIError("Nome da equipe inválido")

    equipes = api.list_my_teams()
    if not isinstance(equipes, list) or not equipes:
        raise APIError("Nenhuma equipe encontrada")

    scored: list[tuple[int, str, str]] = []
    for e in equipes:
        if not isinstance(e, dict):
            continue
        eid = str(e.get("_id") or "").strip()
        nome = str(e.get("nome") or "").strip()
        if not eid or not nome:
            continue
        scored.append((_token_set_ratio(query, nome), eid, nome))

    scored.sort(key=lambda x: x[0], reverse=True)
    if not scored or scored[0][0] < 65:
        raise APIError("Não consegui encontrar essa equipe pelo nome")

    _score, team_id, label = scored[0]
    return team_id, label


def _candidate_tasks(api: FlowlyAPIClient, user_type: str) -> list[dict]:
    tasks: list[dict] = []
    if user_type == "admin":
        res = api.list_tasks()
        if isinstance(res, list):
            tasks.extend([t for t in res if isinstance(t, dict)])
    else:
        for getter in (api.my_tasks, api.backlog):
            res = getter()
            if isinstance(res, list):
                tasks.extend([t for t in res if isinstance(t, dict)])
    return tasks


def _resolve_task_ref(api: FlowlyAPIClient, user_type: str, ref: str) -> Tuple[str, str]:
    if _is_object_id(ref):
        return ref, ref

    query = _normalize(ref)
    if len(query) < 2:
        raise APIError("Descrição da tarefa inválida")

    tasks = _candidate_tasks(api, user_type)
    if not tasks:
        raise APIError("Nenhuma tarefa disponível para buscar pelo nome")

    seen: set[str] = set()
    scored: list[tuple[int, str, str]] = []
    for t in tasks:
        tid = str(t.get("_id") or "").strip()
        if not tid or tid in seen:
            continue
        seen.add(tid)

        desc = str(t.get("descricao") or "").strip()
        if not desc:
            continue

        equipe = t.get("equipe")
        equipe_nome = ""
        if isinstance(equipe, dict):
            equipe_nome = str(equipe.get("nome") or "").strip()

        label = f"{desc} (equipe {equipe_nome})" if equipe_nome else desc
        scored.append((_token_set_ratio(query, desc), tid, label))

    scored.sort(key=lambda x: x[0], reverse=True)
    if not scored or scored[0][0] < 62:
        raise APIError("Não consegui encontrar essa tarefa pelo nome/descrição")

    _score, task_id, label = scored[0]
    return task_id, label


def _execute(match: Match, api: FlowlyAPIClient, params: Dict[str, str]) -> Any:
    key = match.command.key

    if key == "me":
        return api.me()
    if key == "list_users":
        return api.list_users()
    if key == "search_users":
        return api.search_users(params["q"])

    if key == "my_teams":
        return api.list_my_teams()
    if key == "list_teams":
        return api.list_teams()
    if key == "team_members":
        return api.team_members(params["team_id"])
    if key == "team_messages":
        return api.team_messages(params["team_id"])
    if key == "create_team":
        return api.create_team(params["nome"])

    if key == "task_details":
        return api.task_details(params["task_id"])
    if key == "add_comment":
        return api.add_comment(params["task_id"], params["texto"])
    if key == "add_subtask":
        return api.add_subtask(params["task_id"], params["descricao"])

    if key == "my_tasks":
        return api.my_tasks()
    if key == "backlog":
        return api.backlog()
    if key == "assign_to_me":
        return api.assign_to_me(params["task_id"])
    if key == "update_status":
        return api.update_status(params["task_id"], params["status"])
    if key == "timer":
        return api.timer(params["task_id"], params["acao"])

    if key == "create_task":
        return api.create_task(descricao=params["descricao"], equipe=params["equipe"])
    if key == "list_tasks":
        return api.list_tasks()
    if key == "delete_task":
        return api.delete_task(params["task_id"])

    raise APIError(f"Comando não implementado: {key}")


def flowly_http(request):
    """Google Cloud Functions / Cloud Run entrypoint.

    POST JSON:
      {"utterance": "minhas tarefas", "params": {..}, "token": "auth_token"}

    Returns JSON com match + result.
    """

    if request.method == "OPTIONS":
        # CORS preflight
        return _json_response({"ok": True}, 204)

    if request.method == "GET":
        return _json_response(
            {
                "ok": True,
                "service": "flowly_assistente",
                "message": "POST JSON em /",
                "example": {"utterance": "meu perfil", "token": "seu_token_aqui"},
            }
        )

    try:
        body = request.get_json(silent=True) or {}
    except Exception:
        body = {}

    utterance = str(body.get("utterance") or body.get("text") or "").strip()
    if not utterance:
        return _json_response({"ok": False, "error": "missing_utterance", "reply_text": "Diga um comando."}, 400)

    token = str(body.get("token") or body.get("authorization") or "").strip()
    if not token:
        # Tenta pegar do header Authorization
        auth_header = request.headers.get("Authorization", "").strip()
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if not token:
        return _json_response(
            {"ok": False, "error": "missing_token", "reply_text": "Token de autenticação obrigatório."}, 
            401
        )

    # Usar variáveis de ambiente ou valores padrão do request
    base_url = str(body.get("api_url") or os.getenv("FLOWLY_API_URL", "http://localhost:3000/api") or "http://localhost:3000/api").strip()
    debug = str(body.get("debug") or os.getenv("FLOWLY_DEBUG", "false")).strip().lower() == "true"
    timeout_sec = float(body.get("timeout_sec") or os.getenv("FLOWLY_API_TIMEOUT_SEC", "20") or "20")

    api = FlowlyAPIClient(base_url=base_url, token=token, timeout_sec=timeout_sec, debug=debug)

    # Tentar descobrir user_type a partir da API
    user_type = None
    try:
        me = api.me()
        tipo = (me or {}).get("tipo")
        if isinstance(tipo, str) and tipo.strip().lower() in {"admin", "user"}:
            user_type = tipo.strip().lower()
    except Exception as e:
        if debug:
            print(f"[DEBUG] Falha ao buscar user_type: {e}")
        pass

    parser = CommandParser(threshold=int(os.getenv("FLOWLY_MATCH_THRESHOLD", "78")))
    match = parser.match(utterance)
    if match is None:
        return _json_response(
            {
                "ok": False,
                "error": "unrecognized_command",
                "reply_text": "Não consegui identificar o comando. Pode repetir?",
            },
            400,
        )

    if match.command.key == "exit":
        return _json_response(
            {"ok": True, "command": {"key": "exit"}, "message": "noop", "reply_text": "Encerrando."}
        )

    if user_type and not _has_permission(user_type, match.command.role_required):
        return _json_response(
            {"ok": False, "error": "forbidden", "reply_text": "Você não tem permissão para esse comando."}, 403
        )

    params: Dict[str, str] = {}
    raw_params = body.get("params")
    if isinstance(raw_params, dict):
        params.update({str(k): str(v) for k, v in raw_params.items() if v is not None})

    # Parâmetros extraídos da utterance sobrescrevem os fornecidos
    params.update(match.params)

    missing = [p for p in match.command.required_params if not params.get(p)]
    if missing:
        missing_txt = ", ".join(missing)
        return _json_response(
            {
                "ok": False,
                "error": "missing_params",
                "missing": missing,
                "reply_text": f"Preciso de mais informações: {missing_txt}.",
            },
            400,
        )

    # Resolver referências team/task para strings não-ObjectId
    try:
        if params.get("team_id") and not _is_object_id(params["team_id"]):
            tid, label = _resolve_team_ref(api, params["team_id"])
            params["team_id"] = tid
            params.setdefault("_team_label", label)

        if params.get("equipe") and not _is_object_id(params["equipe"]):
            tid, label = _resolve_team_ref(api, params["equipe"])
            params["equipe"] = tid
            params.setdefault("_team_label", label)

        if params.get("task_id") and not _is_object_id(params["task_id"]):
            tid, label = _resolve_task_ref(api, user_type or "user", params["task_id"])
            params["task_id"] = tid
            params.setdefault("_task_label", label)
    except APIError as e:
        return _json_response(
            {
                "ok": False,
                "error": "resolve_failed",
                "message": str(e),
                "reply_text": str(e),
            },
            400,
        )

    try:
        result = _execute(match, api, params)
        reply_text = _reply_text(match.command.key, result)
        return _json_response(
            {
                "ok": True,
                "command": {
                    "key": match.command.key,
                    "title": match.command.title,
                    "method": match.command.method,
                    "route": match.command.route,
                    "controller_method": match.command.controller_method,
                    "role_required": match.command.role_required,
                    "score": match.score,
                },
                "user_type": user_type,
                "params": params,
                "result": _coerce_jsonable(result),
                "reply_text": reply_text,
            }
        )
    except APIError as e:
        return _json_response({"ok": False, "error": "api_error", "message": str(e), "reply_text": str(e)}, 400)
    except Exception as e:
        return _json_response(
            {
                "ok": False,
                "error": "internal_error",
                "message": str(e),
                "reply_text": "Ocorreu um erro inesperado.",
            },
            500,
        )


def trigger_http(request):
    """HTTP Trigger entrypoint (Google Cloud Functions).

    Alias para `flowly_http`.
    """

    return flowly_http(request)
