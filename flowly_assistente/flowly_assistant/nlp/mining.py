from __future__ import annotations

import re
from dataclasses import dataclass, asdict
from typing import Any, Dict, List


@dataclass(frozen=True)
class MiningResult:
    sentiment: str
    topics: List[str]
    entities: List[Dict[str, str]]
    spam_alert: bool

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class NlpMiningService:
    """Initial PLN mining service.

    The methods below are heuristic placeholders. They mark the integration
    points for sentiment, topic modeling and NER models without blocking the
    synchronous request flow.
    """

    POSITIVE = {"bom", "boa", "ótimo", "otimo", "excelente", "resolvido", "concluido", "concluído"}
    NEGATIVE = {"ruim", "erro", "falha", "atrasado", "problema", "travou", "urgente"}
    SPAM = {"spam", "promoção", "promocao", "clique", "oferta"}
    TOPIC_KEYWORDS = {
        "tarefas": {"tarefa", "tarefas", "backlog", "status", "cronometro", "cronômetro"},
        "equipes": {"equipe", "equipes", "membro", "membros", "time"},
        "usuarios": {"usuario", "usuário", "usuarios", "usuários", "perfil"},
        "chat": {"chat", "mensagem", "mensagens", "comentario", "comentário"},
    }

    def mine(self, text: str) -> MiningResult:
        words = set(self._tokenize(text))
        positive_hits = len(words & self.POSITIVE)
        negative_hits = len(words & self.NEGATIVE)

        if positive_hits > negative_hits:
            sentiment = "positivo"
        elif negative_hits > positive_hits:
            sentiment = "negativo"
        else:
            sentiment = "neutro"

        topics = [
            topic
            for topic, keywords in self.TOPIC_KEYWORDS.items()
            if words & keywords
        ] or ["geral"]

        return MiningResult(
            sentiment=sentiment,
            topics=topics,
            entities=self._extract_entities(text),
            spam_alert=bool(words & self.SPAM),
        )

    def _tokenize(self, text: str) -> List[str]:
        return re.findall(r"[\wÀ-ÿ]+", (text or "").lower())

    def _extract_entities(self, text: str) -> List[Dict[str, str]]:
        entities: List[Dict[str, str]] = []
        for object_id in re.findall(r"\b[a-fA-F0-9]{24}\b", text or ""):
            entities.append({"type": "object_id", "value": object_id})
        for mention in re.findall(r"@([\w._-]+)", text or ""):
            entities.append({"type": "mention", "value": mention})
        for capitalized in re.findall(r"\b[A-ZÀ-Ý][a-zà-ÿ]{2,}\b", text or ""):
            entities.append({"type": "proper_name", "value": capitalized})
        return entities[:20]

