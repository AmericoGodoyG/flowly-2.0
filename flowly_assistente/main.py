"""Google Cloud Functions / Functions Framework entrypoint.

O runtime do Cloud Functions (Python) carrega o módulo `main` por padrão.
Aqui nós expomos a função HTTP `trigger_http`.

Para rodar local via Functions Framework:
    functions-framework --target trigger_http --port 8080

Para rodar em modo CLI interativo local:
    python -m assistant
"""

from function import trigger_http  # noqa: F401
from assistant import FlowlyAssistant


def run_cli() -> None:
    """Executa a assistente em modo CLI interativo (local/debug)."""
    assistant = FlowlyAssistant()
    assistant.run()


if __name__ == "__main__":
    import sys
    
    # Se passar --cli, roda em modo interativo
    if "--cli" in sys.argv:
        run_cli()
    else:
        # Modo padrão: avisa que deve usar functions-framework
        print(
            "Para usar a API como Cloud Function:\n"
            "  functions-framework --target trigger_http --port 8080\n\n"
            "Para modo CLI interativo:\n"
            "  python main.py --cli"
        )
