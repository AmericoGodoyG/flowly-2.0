from __future__ import annotations

import json
import os
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


class AnalyticsRepository:
    """Analytics repository backed by the application MongoDB.

    The Node API reads the same `assistantinsights` collection through its
    Mongoose model. JSONL is kept only as an explicit fallback for development.
    """

    def __init__(self, path: str | None = None) -> None:
        default_path = os.getenv("FLOWLY_ANALYTICS_STORE", "data/analytics_events.jsonl")
        self.path = Path(path or default_path)
        if not self.path.is_absolute():
            self.path = Path(__file__).resolve().parents[3] / self.path

        self.storage_mode = os.getenv("FLOWLY_ANALYTICS_STORAGE", "mongodb").strip().lower()
        self.mongo_uri = os.getenv("FLOWLY_MONGO_URI", os.getenv("MONGO_URI", "mongodb://localhost:27017/Flowly"))
        self.mongo_database = os.getenv("FLOWLY_MONGO_DB", self._database_from_uri(self.mongo_uri) or "Flowly")
        self.collection_name = os.getenv("FLOWLY_ANALYTICS_COLLECTION", "assistantinsights")

    def save_insight(self, event: Dict[str, Any], insight: Dict[str, Any]) -> None:
        if self.storage_mode == "jsonl":
            self._save_to_jsonl(event, insight)
            return
        self._save_to_mongodb(event, insight)

    def list_records(self) -> List[Dict[str, Any]]:
        if self.storage_mode == "jsonl":
            return self._list_jsonl_records()

        collection = self._collection()
        records = []
        for document in collection.find({}).sort("createdAt", -1).limit(1000):
            records.append(
                {
                    "created_at": self._json_date(document.get("createdAt")),
                    "event": {
                        "id": document.get("eventId"),
                        "userId": document.get("userId"),
                        "channelId": document.get("channelId"),
                        "teamId": str(document.get("teamId")) if document.get("teamId") else None,
                        "teamName": document.get("teamName"),
                        "content": document.get("content"),
                        "source": document.get("source"),
                        "createdAt": self._json_date(document.get("eventCreatedAt")),
                    },
                    "insight": {
                        "sentiment": document.get("sentiment"),
                        "topics": document.get("topics") or [],
                        "entities": document.get("entities") or [],
                        "spam_alert": bool(document.get("spamAlert")),
                    },
                }
            )
        return records

    def aggregate(self) -> Dict[str, Any]:
        records = self.list_records()
        sentiments = Counter()
        topics = Counter()
        spam_alerts = 0
        by_team: Dict[str, Dict[str, Any]] = {}

        for record in records:
            event = record.get("event") or {}
            insight = record.get("insight") or {}
            sentiment = insight.get("sentiment") or "neutro"
            team_key = str(event.get("teamId") or event.get("channelId") or "web")
            team_name = event.get("teamName") or ("Canal Web" if team_key == "web" else f"Equipe {team_key[-6:]}")

            sentiments[sentiment] += 1
            if insight.get("spam_alert"):
                spam_alerts += 1

            team = by_team.setdefault(
                team_key,
                {
                    "channelId": team_key,
                    "teamName": team_name,
                    "totalMessages": 0,
                    "spamAlerts": 0,
                    "sentiments": Counter(),
                    "topics": Counter(),
                },
            )
            team["totalMessages"] += 1
            team["sentiments"][sentiment] += 1
            if insight.get("spam_alert"):
                team["spamAlerts"] += 1

            for topic in insight.get("topics") or []:
                topics[str(topic)] += 1
                team["topics"][str(topic)] += 1

        by_team_list = []
        for team in by_team.values():
            top_topics = [{"topic": topic, "count": count} for topic, count in team["topics"].most_common(6)]
            team_payload = {
                "channelId": team["channelId"],
                "teamName": team["teamName"],
                "totalMessages": team["totalMessages"],
                "spamAlerts": team["spamAlerts"],
                "sentiments": dict(team["sentiments"]),
                "topTopics": top_topics,
            }
            team_payload["suggestions"] = self._build_suggestions(team_payload)
            by_team_list.append(team_payload)

        payload = {
            "totalMessages": len(records),
            "sentiments": dict(sentiments),
            "topTopics": [{"topic": topic, "count": count} for topic, count in topics.most_common(10)],
            "spamAlerts": spam_alerts,
            "byTeam": sorted(by_team_list, key=lambda item: item["totalMessages"], reverse=True),
        }
        payload["suggestions"] = self._build_suggestions(payload)
        return payload

    def _save_to_mongodb(self, event: Dict[str, Any], insight: Dict[str, Any]) -> None:
        collection = self._collection()
        now = datetime.now(timezone.utc)
        event_created_at = self._parse_date(event.get("createdAt"))
        team_id = event.get("teamId") or event.get("team_id")
        channel_id = str(event.get("channelId") or "web")

        document = {
            "eventId": str(event["id"]),
            "userId": str(event["userId"]),
            "channelId": channel_id,
            "teamName": event.get("teamName") or event.get("team_name"),
            "content": str(event["content"]),
            "source": event.get("source") or "frontend",
            "eventCreatedAt": event_created_at,
            "sentiment": insight.get("sentiment") or "neutro",
            "topics": list(insight.get("topics") or []),
            "entities": list(insight.get("entities") or []),
            "spamAlert": bool(insight.get("spam_alert") or insight.get("spamAlert")),
            "updatedAt": now,
        }

        object_id = self._object_id(str(team_id or channel_id))
        if object_id is not None:
            document["teamId"] = object_id

        collection.update_one(
            {"eventId": document["eventId"]},
            {
                "$set": document,
                "$setOnInsert": {"createdAt": now},
            },
            upsert=True,
        )

    def _collection(self):
        try:
            from pymongo import MongoClient
        except ModuleNotFoundError as exc:
            raise RuntimeError("Instale pymongo para gravar analytics no MongoDB: pip install pymongo") from exc

        client = MongoClient(self.mongo_uri)
        return client[self.mongo_database][self.collection_name]

    def _save_to_jsonl(self, event: Dict[str, Any], insight: Dict[str, Any]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        record = {
            "created_at": datetime.now(timezone.utc).isoformat(),
            "event": event,
            "insight": insight,
        }
        with self.path.open("a", encoding="utf-8") as file:
            file.write(json.dumps(record, ensure_ascii=False) + "\n")

    def _list_jsonl_records(self) -> List[Dict[str, Any]]:
        if not self.path.exists():
            return []

        records: List[Dict[str, Any]] = []
        with self.path.open("r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if not line:
                    continue
                try:
                    records.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return records

    def _object_id(self, value: str):
        if not value or len(value) != 24:
            return None
        try:
            from bson import ObjectId
            return ObjectId(value)
        except Exception:
            return None

    def _parse_date(self, value: Any) -> Optional[datetime]:
        if isinstance(value, datetime):
            return value
        if not value:
            return None
        try:
            return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        except ValueError:
            return None

    def _json_date(self, value: Any) -> Optional[str]:
        if isinstance(value, datetime):
            return value.isoformat()
        return str(value) if value else None

    def _database_from_uri(self, uri: str) -> Optional[str]:
        tail = uri.rsplit("/", 1)[-1].split("?", 1)[0]
        return tail or None

    def _build_suggestions(self, insight: Dict[str, Any]) -> List[str]:
        suggestions = []
        sentiments = insight.get("sentiments") or {}
        topics = [item.get("topic") for item in insight.get("topTopics") or []]
        total = int(insight.get("totalMessages") or 0)
        negative = int(sentiments.get("negativo") or 0)
        neutral = int(sentiments.get("neutro") or 0)
        spam_alerts = int(insight.get("spamAlerts") or 0)

        if total and negative / total >= 0.35:
            suggestions.append("Priorize uma conversa com a equipe: há volume relevante de mensagens negativas.")
        if total >= 5 and neutral / total >= 0.6:
            suggestions.append("Estimule feedbacks mais objetivos: muitas mensagens estão neutras.")
        if "tarefas" in topics:
            suggestions.append("Revise clareza de tarefas, status e responsabilidades.")
        if "equipes" in topics:
            suggestions.append("Verifique dúvidas sobre papéis, membros ou comunicação da equipe.")
        if "chat" in topics:
            suggestions.append("Acompanhe comentários recorrentes no chat para identificar dúvidas operacionais.")
        if spam_alerts:
            suggestions.append("Investigue alertas de spam ou uso inadequado.")
        if not suggestions:
            suggestions.append("Nenhum ponto crítico detectado. Continue acompanhando os tópicos recorrentes.")
        return suggestions
