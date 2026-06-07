from __future__ import annotations

import os
import re
from dataclasses import asdict, is_dataclass
from difflib import SequenceMatcher
from typing import Any, Dict, Optional, Tuple

from flowly_assistant.api_client import APIError, FlowlyAPIClient
from flowly_assistant.command_parser import CommandParser, Match


OBJ_ID_RE = re.compile(r"\b[a-fA-F0-9]{24}\b")


def normalize(text: str) -> str:
    return " ".join((text or "").strip().lower().split())


def is_object_id(value: str) -> bool:
    return bool(OBJ_ID_RE.fullmatch((value or "").strip()))


def coerce_jsonable(value: Any) -> Any:
    if is_dataclass(value):
        return asdict(value)
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if isinstance(value, dict):
        return {str(k): coerce_jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [coerce_jsonable(v) for v in value]
    return str(value)


def tts_payload(text: str, *, enabled: bool = True, language: str = "pt-BR") -> Dict[str, Any]:
    clean = " ".join((text or "").split()).strip()
    return {
        "enabled": bool(enabled and clean),
        "language": language,
        "text": clean,
    }


def reply_text(command_key: str, result: Any) -> str:
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


def has_permission(user_type: Optional[str], required: str) -> bool:
    if required == "any":
        return True
    if user_type not in {"admin", "user"}:
        return required != "admin"
    if required == "admin":
        return user_type == "admin"
    if required == "user":
        return user_type == "user"
    return False


class RestAssistant:
    """Stateless assistant use case for HTTP/REST callers."""

    def __init__(
        self,
        *,
        api_base_url: str,
        token: str,
        timeout_sec: float = 20.0,
        debug: bool = False,
        match_threshold: int = 78,
        tts_enabled: bool = True,
        language: str = "pt-BR",
    ) -> None:
        self.api = FlowlyAPIClient(
            base_url=api_base_url,
            token=token,
            timeout_sec=timeout_sec,
            debug=debug,
        )
        self.parser = CommandParser(threshold=match_threshold)
        self.tts_enabled = tts_enabled
        self.language = language
        self.debug = debug

    def handle(self, utterance: str, params: Optional[Dict[str, Any]] = None) -> Tuple[Dict[str, Any], int]:
        utterance = (utterance or "").strip()
        if not utterance:
            return self._error("missing_utterance", "Diga um comando.", 400)

        user_type = self._detect_user_type()
        match = self.parser.match(utterance)
        if match is None:
            return self._error("unrecognized_command", "Não consegui identificar o comando. Pode repetir?", 400)

        if match.command.key == "exit":
            return self._ok(
                {
                    "command": {"key": "exit"},
                    "message": "noop",
                    "reply_text": "Encerrando.",
                    "tts": tts_payload("Encerrando.", enabled=self.tts_enabled, language=self.language),
                }
            )

        if user_type and not has_permission(user_type, match.command.role_required):
            return self._error("forbidden", "Você não tem permissão para esse comando.", 403)

        resolved_params = self._merge_params(match, params or {})
        missing = [p for p in match.command.required_params if not resolved_params.get(p)]
        if missing:
            missing_txt = ", ".join(missing)
            return self._error(
                "missing_params",
                f"Preciso de mais informações: {missing_txt}.",
                400,
                missing=missing,
            )

        try:
            self._resolve_refs(resolved_params, user_type or "user")
            result = self._execute(match, resolved_params)
        except APIError as exc:
            return self._error("api_error", str(exc), 400, message=str(exc))
        except Exception as exc:
            if self.debug:
                print(f"[ASSISTANT] internal_error: {exc}")
            return self._error("internal_error", "Ocorreu um erro inesperado.", 500, message=str(exc))

        text = reply_text(match.command.key, result)
        return self._ok(
            {
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
                "params": resolved_params,
                "result": coerce_jsonable(result),
                "reply_text": text,
                "tts": tts_payload(text, enabled=self.tts_enabled, language=self.language),
            }
        )

    def _detect_user_type(self) -> Optional[str]:
        try:
            me = self.api.me()
            tipo = (me or {}).get("tipo")
            if isinstance(tipo, str) and tipo.strip().lower() in {"admin", "user"}:
                return tipo.strip().lower()
        except Exception as exc:
            if self.debug:
                print(f"[ASSISTANT] user_type lookup failed: {exc}")
        return None

    def _merge_params(self, match: Match, raw_params: Dict[str, Any]) -> Dict[str, str]:
        params = {str(k): str(v) for k, v in raw_params.items() if v is not None}
        params.update(match.params)
        return params

    def _resolve_refs(self, params: Dict[str, str], user_type: str) -> None:
        if params.get("team_id") and not is_object_id(params["team_id"]):
            team_id, label = self._resolve_team_ref(params["team_id"])
            params["team_id"] = team_id
            params.setdefault("_team_label", label)

        if params.get("equipe") and not is_object_id(params["equipe"]):
            team_id, label = self._resolve_team_ref(params["equipe"])
            params["equipe"] = team_id
            params.setdefault("_team_label", label)

        if params.get("task_id") and not is_object_id(params["task_id"]):
            task_id, label = self._resolve_task_ref(user_type, params["task_id"])
            params["task_id"] = task_id
            params.setdefault("_task_label", label)

    def _resolve_team_ref(self, ref: str) -> Tuple[str, str]:
        query = normalize(ref)
        if len(query) < 2:
            raise APIError("Nome da equipe inválido")

        equipes = self.api.list_my_teams()
        if not isinstance(equipes, list) or not equipes:
            raise APIError("Nenhuma equipe encontrada")

        scored = []
        for equipe in equipes:
            if not isinstance(equipe, dict):
                continue
            team_id = str(equipe.get("_id") or "").strip()
            name = str(equipe.get("nome") or "").strip()
            if team_id and name:
                scored.append((self._token_set_ratio(query, name), team_id, name))

        scored.sort(key=lambda item: item[0], reverse=True)
        if not scored or scored[0][0] < 65:
            raise APIError("Não consegui encontrar essa equipe pelo nome")
        return scored[0][1], scored[0][2]

    def _resolve_task_ref(self, user_type: str, ref: str) -> Tuple[str, str]:
        query = normalize(ref)
        if len(query) < 2:
            raise APIError("Descrição da tarefa inválida")

        tasks = []
        if user_type == "admin":
            res = self.api.list_tasks()
            if isinstance(res, list):
                tasks.extend([t for t in res if isinstance(t, dict)])
        else:
            for getter in (self.api.my_tasks, self.api.backlog):
                res = getter()
                if isinstance(res, list):
                    tasks.extend([t for t in res if isinstance(t, dict)])

        if not tasks:
            raise APIError("Nenhuma tarefa disponível para buscar pelo nome")

        seen = set()
        scored = []
        for task in tasks:
            task_id = str(task.get("_id") or "").strip()
            if not task_id or task_id in seen:
                continue
            seen.add(task_id)
            desc = str(task.get("descricao") or "").strip()
            if not desc:
                continue
            equipe = task.get("equipe")
            team_name = str(equipe.get("nome") or "").strip() if isinstance(equipe, dict) else ""
            label = f"{desc} (equipe {team_name})" if team_name else desc
            scored.append((self._token_set_ratio(query, desc), task_id, label))

        scored.sort(key=lambda item: item[0], reverse=True)
        if not scored or scored[0][0] < 62:
            raise APIError("Não consegui encontrar essa tarefa pelo nome/descrição")
        return scored[0][1], scored[0][2]

    def _execute(self, match: Match, params: Dict[str, str]) -> Any:
        key = match.command.key
        if key == "me":
            return self.api.me()
        if key == "list_users":
            return self.api.list_users()
        if key == "search_users":
            return self.api.search_users(params["q"])
        if key == "my_teams":
            return self.api.list_my_teams()
        if key == "list_teams":
            return self.api.list_teams()
        if key == "team_members":
            return self.api.team_members(params["team_id"])
        if key == "team_messages":
            return self.api.team_messages(params["team_id"])
        if key == "create_team":
            return self.api.create_team(params["nome"])
        if key == "task_details":
            return self.api.task_details(params["task_id"])
        if key == "add_comment":
            return self.api.add_comment(params["task_id"], params["texto"])
        if key == "add_subtask":
            return self.api.add_subtask(params["task_id"], params["descricao"])
        if key == "my_tasks":
            return self.api.my_tasks()
        if key == "backlog":
            return self.api.backlog()
        if key == "assign_to_me":
            return self.api.assign_to_me(params["task_id"])
        if key == "update_status":
            return self.api.update_status(params["task_id"], params["status"])
        if key == "timer":
            return self.api.timer(params["task_id"], params["acao"])
        if key == "create_task":
            return self.api.create_task(descricao=params["descricao"], equipe=params["equipe"])
        if key == "list_tasks":
            return self.api.list_tasks()
        if key == "delete_task":
            return self.api.delete_task(params["task_id"])
        raise APIError(f"Comando não implementado: {key}")

    def _ratio(self, a: str, b: str) -> int:
        return int(round(SequenceMatcher(None, a, b).ratio() * 100))

    def _token_set_ratio(self, a: str, b: str) -> int:
        a = normalize(a)
        b = normalize(b)
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
        return max(self._ratio(sect, combo_a), self._ratio(sect, combo_b), self._ratio(combo_a, combo_b))

    def _ok(self, payload: Dict[str, Any]) -> Tuple[Dict[str, Any], int]:
        return {"ok": True, **payload}, 200

    def _error(self, error: str, text: str, status: int, **extra: Any) -> Tuple[Dict[str, Any], int]:
        return {
            "ok": False,
            "error": error,
            **extra,
            "reply_text": text,
            "tts": tts_payload(text, enabled=self.tts_enabled, language=self.language),
        }, status


def assistant_from_http_body(body: Dict[str, Any], token: str, *, debug: bool = False) -> RestAssistant:
    api_base_url = str(
        body.get("api_url")
        or body.get("api_base_url")
        or os.getenv("FLOWLY_API_BASE_URL")
        or os.getenv("FLOWLY_API_URL")
        or "http://localhost:5000/api"
    ).strip()
    return RestAssistant(
        api_base_url=api_base_url,
        token=token,
        timeout_sec=float(body.get("timeout_sec") or os.getenv("FLOWLY_API_TIMEOUT_SEC", "20")),
        debug=debug,
        match_threshold=int(os.getenv("FLOWLY_MATCH_THRESHOLD", "78")),
        tts_enabled=str(body.get("tts_enabled", os.getenv("FLOWLY_TTS_ENABLED", "true"))).lower()
        not in {"0", "false", "no", "off"},
        language=str(body.get("language") or os.getenv("FLOWLY_LANGUAGE", "pt-BR")),
    )
