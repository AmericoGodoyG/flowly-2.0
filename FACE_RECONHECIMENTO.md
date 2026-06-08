# Flowly 2.0 — Reconhecimento Facial (IoT)

Documentação técnica do módulo de verificação facial adicionado ao Flowly 2.0.

---

## 1. Objetivo

Adicionar uma **camada opcional de autenticação biométrica** no login, usando a câmera do PC ou celular como sensor IoT. O fluxo **não substitui** e-mail e senha — complementa após a validação da senha.

---

## 2. Arquitetura

```text
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│ Web React   │     │ App Flutter │     │ flowly_api       │     │ MongoDB     │
│ (câmera)    │────▶│ (câmera)    │────▶│ Node.js :5000    │────▶│ FaceProfile │
└─────────────┘     └─────────────┘     │ /api/face/*      │     │ User        │
                                        └────────┬─────────┘     └─────────────┘
                                                 │
                                                 ▼
                                        ┌──────────────────┐
                                        │ flowly_iot_face  │
                                        │ Python :5001     │
                                        │ DeepFace         │
                                        └──────────────────┘
```

### Princípio de integração

- **Aditivo:** rotas, controllers, telas e microserviço novos.
- **Retrocompatível:** usuários sem rosto cadastrado logam como antes.
- **Admin:** sem verificação facial (por enquanto).
- **Configurável:** URL do serviço facial via `FACE_SERVICE_URL` no `.env`.

---

## 3. Tecnologias utilizadas

| Camada | Tecnologia | Função |
|--------|------------|--------|
| Microserviço IoT | Python 3, Flask, DeepFace | Detectar rosto, gerar embedding, comparar |
| Modelo | VGG-Face (padrão) | Representação numérica do rosto |
| Dependência extra | tf-keras | Obrigatório com TensorFlow 2.16+ |
| Detector | OpenCV (padrão) | Localizar rosto na imagem |
| API | Node.js, Express, JWT | Orquestra login + sessão facial |
| Banco | MongoDB, Mongoose | `FaceProfile` + flags no `User` |
| Web | React, getUserMedia | Captura via webcam |
| Mobile | Flutter, image_picker | Captura via câmera frontal |

---

## 4. O que foi criado

### 4.1 Microserviço `flowly_iot_face/`

| Arquivo | Descrição |
|---------|-----------|
| `main.py` | Servidor Flask com endpoints `/health`, `/embed`, `/verify` |
| `requirements.txt` | Dependências Python (`deepface`, `tensorflow`, **`tf-keras`**, Flask) |
| `.env.example` | HOST, PORT, FACE_MODEL, FACE_DETECTOR, FACE_MATCH_THRESHOLD |

### 4.2 API `flowly_api/`

| Arquivo | Descrição |
|---------|-----------|
| `models/FaceProfile.js` | Coleção com `userId`, `embedding[]`, `model`, `enrolled` |
| `models/User.js` | Campos `faceEnrollmentOffered`, `faceEnrollmentSkipped` |
| `services/faceService.js` | Cliente HTTP para o microserviço Python |
| `controllers/faceController.js` | Lógica de enroll, verify, skip, status |
| `routes/faceRoutes.js` | Rotas `/api/face/*` |
| `utils/faceAuth.js` | Tokens de sessão facial e JWT final |
| `controllers/authController.js` | Condicionais no login (mínimas) |
| `config/config.js` | Config `face.*` |
| `app.js` | Montagem de `/api/face` |

### 4.3 Frontend `flowly_frontend/`

| Arquivo | Descrição |
|---------|-----------|
| `components/face/FaceCapture.jsx` | Webcam + captura |
| `components/face/FaceAuthStep.jsx` | Etapa de login (cadastro ou verificação) |
| `components/face/FaceProfileEnroll.jsx` | Cadastro no perfil |
| `pages/auth/AuthPage.jsx` | Fluxo pós-senha |
| `pages/user/PerfilUser.jsx` | Seção de verificação facial |
| `config/config.js` | Endpoints `/face/*` |

### 4.4 Mobile `flowly_mobal/`

| Arquivo | Descrição |
|---------|-----------|
| `services/face_service.dart` | Chamadas à API facial |
| `screens/auth/face_auth_screen.dart` | Tela de cadastro/verificação no login |
| `screens/profile/face_profile_screen.dart` | Cadastro no perfil |
| `services/auth_service.dart` | Parsing de respostas faciais |
| `screens/auth/login_screen.dart` | Navegação para face após senha |
| `screens/profile/profile_screen.dart` | Menu “Verificação facial” |

---

## 5. Fluxos de uso

### 5.1 Primeiro login (convite opcional)

1. Usuário informa e-mail + senha.
2. API valida credenciais.
3. Se nunca viu o convite (`faceEnrollmentOffered = false` e não pulou):
   - Retorna `requiresFaceEnrollmentOffer: true` + `faceSessionToken`.
4. App exibe tela: **Cadastrar rosto** ou **Pular por agora**.
5. **Pular:** marca `faceEnrollmentSkipped = true`, emite JWT, não pergunta de novo.
6. **Cadastrar:** captura foto → embedding salvo → JWT emitido.

### 5.2 Login com rosto cadastrado

1. E-mail + senha válidos.
2. API retorna `requiresFaceVerification: true` + `faceSessionToken`.
3. Usuário captura rosto.
4. API compara embedding salvo vs. foto atual.
5. **Match:** JWT emitido. **Não match:** `401` — acesso negado.

### 5.3 Cadastro posterior no perfil

- Web: seção em `/perfil` (usuário comum e admin vê admin sem seção facial).
- Mobile: **Perfil → Verificação facial**.

### 5.4 Administrador

- Login retorna JWT direto, sem etapas faciais.

### 5.5 Contas antigas (antes desta feature)

- Próximo login: convite opcional **uma vez**.
- Se pular: comportamento idêntico ao login antigo.

---

## 6. API REST — rotas faciais

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/api/face/health` | Não | Saúde API + serviço Python |
| POST | `/api/face/enroll` | faceSessionToken | Cadastro no 1º login |
| POST | `/api/face/verify` | faceSessionToken | Verificação no login |
| POST | `/api/face/skip-enrollment` | faceSessionToken | Pular cadastro |
| GET | `/api/face/status` | JWT | Status `enrolled/skipped/offered` |
| POST | `/api/face/enroll-profile` | JWT | Cadastro/atualização no perfil |

### Resposta do login (alteração condicional)

**Verificação necessária:**

```json
{
  "requiresFaceVerification": true,
  "faceSessionToken": "...",
  "user": { "id": "...", "nome": "...", "tipo": "user", "fotoPerfil": "" }
}
```

**Convite de cadastro:**

```json
{
  "requiresFaceEnrollmentOffer": true,
  "faceSessionToken": "...",
  "user": { "id": "...", "nome": "...", "tipo": "user", "fotoPerfil": "" }
}
```

**Fluxo normal (sem face ou após skip):**

```json
{
  "token": "...",
  "user": { "id": "...", "nome": "...", "tipo": "user", "fotoPerfil": "" }
}
```

---

## 7. Segurança e privacidade

- **Armazenado:** embedding numérico (vetor), não a foto bruta no MongoDB.
- **Token de sessão facial:** JWT de curta duração (`face_verify` / `face_enroll`), não substitui o JWT de app.
- **Limiar:** `FACE_MATCH_THRESHOLD` (distância cosseno, padrão `0.4`).
- **Limitações acadêmicas:** sem detecção de vivacidade (foto de foto pode enganar em demo). Documentar na apresentação.

---

## 8. Variáveis de ambiente

### `flowly_api/.env`

```env
FACE_SERVICE_URL=http://localhost:5001
FACE_MATCH_THRESHOLD=0.4
FACE_SESSION_EXPIRES_IN=5m
FACE_ENROLL_SESSION_EXPIRES_IN=10m
```

A API aguarda até **120 segundos** por resposta do serviço facial (útil na 1ª captura, quando o modelo ainda está carregando).

### `flowly_iot_face/.env`

```env
HOST=0.0.0.0
PORT=5001
FACE_MODEL=VGG-Face
FACE_DETECTOR=opencv
FACE_MATCH_THRESHOLD=0.4
```

---

## 9. IoT — visão do módulo

No contexto do projeto integrador:

- **Sensor:** câmera USB (PC) ou câmera frontal (smartphone).
- **Atuador lógico:** liberação ou bloqueio do JWT após comparação.
- **Processamento:** microserviço Python isolado, invocado pela API Node.
- **Evolução futura:** ESP32-CAM ou Raspberry Pi pode enviar `image_base64` para os mesmos endpoints, sem alterar o fluxo web/mobile.

---

## 10. Ajuste fino

Se houver **falsos positivos** (aceita rosto errado): diminua `FACE_MATCH_THRESHOLD` (ex.: `0.35`).

Se houver **falsos negativos** (rejeita o dono): aumente levemente (ex.: `0.45`).

Teste sempre com boa iluminação e rosto centralizado.

---

## 11. Primeira execução e erros comuns

| Situação | O que fazer |
|----------|-------------|
| Erro `tf-keras` ou `build_model` | `pip install tf-keras` e **reinicie** `python main.py` |
| Falha ao baixar `vgg_face_weights.h5` | Download manual — ver `SETUP_FACE.md` |
| Cadastro facial lento na 1ª vez | Normal (~550 MB de modelo); aguarde até 2 min |
| E-mail de verificação não chega | SMTP local não configurado — ver `SETUP_FACE.md` |

---

## 12. Referências

- [DeepFace](https://github.com/serengil/deepface)
- [Flask](https://flask.palletsprojects.com/)
- Documentação de setup: [`SETUP_FACE.md`](./SETUP_FACE.md)
- Repositório da feature: [gabrieldefende/Reconhecimento-Facial](https://github.com/gabrieldefende/Reconhecimento-Facial)
- Integração no Flowly: [`INTEGRACAO.md`](./INTEGRACAO.md)
