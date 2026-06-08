# Deploy do reconhecimento facial — nuvem Flowly (equipe FATEC)

Este guia assume a infraestrutura **já usada pelo grupo** no [flowly-2.0](https://github.com/FATEC-Mobile-Group/flowly-2.0):

| Serviço | URL / plataforma |
|---------|------------------|
| API Node | `https://flowly-api-backend-646126851973.southamerica-east1.run.app` (Google Cloud Run) |
| Frontend Web | Azure Static Web Apps + Docker Hub |
| Assistente | Cloud Run (`flowly-assistente-voz-...`) |
| **Face (novo)** | Cloud Run separado — `flowly_iot_face/` |

O frontend e o mobile **não** falam com o Python diretamente. Só a API Node precisa de `FACE_SERVICE_URL`.

---

## Visão geral

```text
Browser / App Flutter
        │
        ▼
  API Node (Cloud Run)  ──HTTP──►  flowly_iot_face (Cloud Run)
        │
        ▼
     MongoDB Atlas
```

---

## Passo 1 — Deploy do microserviço Python no Cloud Run

Pré-requisitos: [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) autenticado no projeto `646126851973` (ou o projeto ativo do grupo).

Na raiz do repositório, pasta `flowly_iot_face/`:

```bash
cd flowly_iot_face

gcloud run deploy flowly-face-iot \
  --source . \
  --region southamerica-east1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 4Gi \
  --cpu 2 \
  --timeout 300 \
  --min-instances 0 \
  --max-instances 3 \
  --set-env-vars "FACE_MODEL=VGG-Face,FACE_DETECTOR=opencv,FACE_MATCH_THRESHOLD=0.4"
```

Anote a URL retornada, por exemplo:

`https://flowly-face-iot-646126851973.southamerica-east1.run.app`

Teste:

```bash
curl https://SUA_URL_CLOUD_RUN/health
```

Resposta esperada: `"status": "ok"`.

**Primeira requisição `/embed` ou `/verify`:** pode demorar 1–3 min (download do modelo VGG-Face ~550 MB). Requests seguintes são mais rápidos.

---

## Passo 2 — Configurar a API Node (Cloud Run existente)

No **Google Cloud Console** → Cloud Run → serviço `flowly-api-backend` → **Editar e implantar nova revisão** → **Variáveis de ambiente**, adicionar:

| Variável | Valor exemplo |
|----------|---------------|
| `FACE_SERVICE_URL` | `https://flowly-face-iot-646126851973.southamerica-east1.run.app` |
| `FACE_MATCH_THRESHOLD` | `0.4` |
| `FACE_SESSION_EXPIRES_IN` | `5m` |
| `FACE_ENROLL_SESSION_EXPIRES_IN` | `10m` |

Salve e aguarde a nova revisão.

Teste pela API pública:

```bash
curl https://flowly-api-backend-646126851973.southamerica-east1.run.app/api/face/health
```

Deve retornar `"api": "ok"` e `"face_service"` com status do Python.

---

## Passo 3 — Frontend e mobile

**Nenhuma alteração de URL do Python** é necessária.

- **Web:** `REACT_APP_API_URL` já aponta para a API Cloud Run (ou localhost em dev).
- **Mobile:** `FLOWLY_API_URL` aponta para a mesma API.

O fluxo facial usa rotas `/api/face/*` na API Node.

---

## Passo 4 — Checklist pós-deploy

- [ ] `GET /api/face/health` na API → `"api": "ok"`
- [ ] Login **admin** → entra direto (sem face)
- [ ] Login **user** verificado → convite ou verificação facial
- [ ] Cadastro facial no perfil (`/perfil` web ou app)
- [ ] Câmera liberada no browser (HTTPS obrigatório — Cloud Run já fornece)

---

## Custos e limites

- Cloud Run cobra por uso; `min-instances=0` evita custo fixo quando ocioso.
- Memória **4 GiB** é recomendada; com 512 MiB o container tende a ser morto pelo OOM.
- Timeout **300 s** na 1ª inferência; depois pode reduzir para 120 s se estável.

---

## Alternativa: Docker Hub (mesmo padrão da API)

```bash
cd flowly_iot_face
docker build -t flowly-face-iot:latest .
docker tag flowly-face-iot:latest SEU_USUARIO/flowly-face-iot:latest
docker push SEU_USUARIO/flowly-face-iot:latest
```

Depois implante a imagem no Cloud Run apontando para `SEU_USUARIO/flowly-face-iot:latest`.

---

## Desenvolvimento local (referência)

```env
# flowly_api/.env
FACE_SERVICE_URL=http://localhost:5001
```

Ver **[SETUP_FACE.md](./SETUP_FACE.md)** para os três terminais locais.

---

## Origem do módulo

Código facial mantido em: [github.com/gabrieldefende/Reconhecimento-Facial](https://github.com/gabrieldefende/Reconhecimento-Facial)

Pasta pronta para PR: **`flowly-2.0-integracao-face/`** (mesclada com o baseline da equipe).
