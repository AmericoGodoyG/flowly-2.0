#!/usr/bin/env python
"""Exemplos de uso da API Flowly Assistente via HTTP.

Uso:
    python test_api.py

Certifique-se de que:
    1. A API está rodando: functions-framework --target trigger_http --port 8080
    2. Você tem um token JWT válido
    3. Seu backend Flowly está acessível
"""

import requests
import json
import sys
import os


BASE_URL = os.getenv("FLOWLY_FUNCTION_URL", "http://localhost:8080")
TOKEN = os.getenv("FLOWLY_TEST_TOKEN", "seu_jwt_token_aqui")


def print_section(title):
    """Imprime um separador de seção."""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


def print_result(status, response):
    """Imprime o resultado de uma requisição."""
    print(f"Status: {status}")
    try:
        data = response.json()
        print(f"Response:\n{json.dumps(data, indent=2, ensure_ascii=False)}")
    except:
        print(f"Response: {response.text}")


def test_health_check():
    """Testa se a API está rodando."""
    print_section("Health Check (GET /)")
    try:
        response = requests.get(f"{BASE_URL}/")
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_cors_preflight():
    """Testa CORS preflight."""
    print_section("CORS Preflight (OPTIONS /)")
    try:
        response = requests.options(
            f"{BASE_URL}/",
            headers={
                "Origin": "https://seu-frontend.com",
                "Access-Control-Request-Method": "POST"
            }
        )
        print(f"Status: {response.status_code}")
        print("CORS Headers:")
        for key, value in response.headers.items():
            if "Access-Control" in key or "Allow" in key:
                print(f"  {key}: {value}")
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_error_missing_utterance():
    """Testa erro: utterance obrigatório."""
    print_section("Error: Missing Utterance")
    payload = {"token": TOKEN}
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_error_missing_token():
    """Testa erro: token obrigatório."""
    print_section("Error: Missing Token")
    payload = {"utterance": "meu perfil"}
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_error_unknown_command():
    """Testa erro: comando desconhecido."""
    print_section("Error: Unknown Command")
    payload = {
        "utterance": "xyz abc 123 comando que não existe",
        "token": TOKEN
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_command_bearer_header():
    """Testa com token no header Authorization."""
    print_section("Command: My Profile (Bearer Header)")
    payload = {"utterance": "meu perfil"}
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {TOKEN}"
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload, headers=headers)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_command_token_in_body():
    """Testa com token no corpo da requisição."""
    print_section("Command: My Profile (Token in Body)")
    payload = {
        "utterance": "meu perfil",
        "token": TOKEN
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_command_my_tasks():
    """Testa comando: minhas tarefas."""
    print_section("Command: My Tasks")
    payload = {
        "utterance": "minhas tarefas",
        "token": TOKEN
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_command_list_teams():
    """Testa comando: listar equipes."""
    print_section("Command: List Teams")
    payload = {
        "utterance": "listar equipes",
        "token": TOKEN
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def test_command_search_users():
    """Testa comando: buscar usuário."""
    print_section("Command: Search Users")
    payload = {
        "utterance": "buscar usuario joao",
        "token": TOKEN,
        "params": {"q": "joao"}
    }
    try:
        response = requests.post(f"{BASE_URL}/", json=payload)
        print_result(response.status_code, response)
    except Exception as e:
        print(f"❌ Erro: {e}")


def main():
    """Executa testes."""
    print("\n" + "="*60)
    print("FLOWLY ASSISTENTE - API TEST SUITE")
    print("="*60)
    print(f"\nAPI URL: {BASE_URL}")
    print(f"Token: {TOKEN if TOKEN != 'seu_jwt_token_aqui' else '⚠️  Token padrão'}")

    if TOKEN == "seu_jwt_token_aqui":
        print("\n⚠️  Aviso: Use token real para testes!")
        print("   export FLOWLY_TEST_TOKEN='seu_token_aqui'")

    # Testes básicos (sempre)
    test_health_check()
    test_cors_preflight()

    # Testes de erro (sempre)
    print("\n" + "="*60)
    print("ERROR TESTS")
    print("="*60)
    test_error_missing_utterance()
    test_error_missing_token()
    test_error_unknown_command()

    # Testes com sucesso (se tiver token válido)
    if TOKEN != "seu_jwt_token_aqui":
        print("\n" + "="*60)
        print("SUCCESS TESTS (com token válido)")
        print("="*60)
        test_command_bearer_header()
        test_command_token_in_body()
        test_command_my_tasks()
        test_command_list_teams()
        test_command_search_users()
    else:
        print("\n" + "="*60)
        print("⏭️  Pulando testes de sucesso (token não configurado)")
        print("="*60)
        print("\nPara rodar testes com sucesso:")
        print("  export FLOWLY_TEST_TOKEN='seu_token_jwt_aqui'")
        print("  python test_api.py")

    print("\n" + "="*60)
    print("✅ Testes Concluídos")
    print("="*60 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Erro: {e}")
        sys.exit(1)
