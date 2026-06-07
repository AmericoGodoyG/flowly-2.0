import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { FaMicrophone, FaMicrophoneSlash, FaPaperPlane, FaPowerOff, FaVolumeUp } from 'react-icons/fa';
import Sidebar from '../../components/layout/Sidebar';
import { API_ENDPOINTS } from '../../config/config';
import { authUtils } from '../../config/authUtils';
import '../../styles/pages/common/VoiceAssistantPage.css';

const SpeechRecognition =
  window.SpeechRecognition || window.webkitSpeechRecognition || null;

const initialMessages = [
  {
    id: 'welcome',
    role: 'assistant',
    text: 'Assistente em standby. Toque no microfone e diga um comando.',
  },
];

function VoiceAssistantPage() {
  const [messages, setMessages] = useState(initialMessages);
  const [draft, setDraft] = useState('');
  const [listening, setListening] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [status, setStatus] = useState('standby');
  const recognitionRef = useRef(null);
  const transcriptRef = useRef('');
  const messagesEndRef = useRef(null);
  const conversationIdRef = useRef(`voice-${authUtils.getUserId() || 'guest'}-${Date.now()}`);

  const supported = useMemo(() => Boolean(SpeechRecognition), []);

  const addMessage = useCallback((role, text, meta = {}) => {
    const cleanText = String(text || '').trim();
    if (!cleanText) return;
    setMessages((current) => [
      ...current,
      {
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        role,
        text: cleanText,
        ...meta,
      },
    ]);
  }, []);

  const speak = useCallback((payload) => {
    const text = payload?.tts?.text || payload?.reply_text || '';
    if (!text || !window.speechSynthesis) return;

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = payload?.tts?.language || 'pt-BR';
    utterance.rate = 1;
    window.speechSynthesis.speak(utterance);
  }, []);

  const enterStandby = useCallback(async ({ silent = false } = {}) => {
    setListening(false);
    setProcessing(false);
    setStatus('standby');
    transcriptRef.current = '';

    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (error) {
        // Browser recognition may already be stopped.
      }
    }

    if (window.speechSynthesis) {
      window.speechSynthesis.cancel();
    }

    try {
      await fetch(API_ENDPOINTS.ASSISTANT_STANDBY, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ conversationId: conversationIdRef.current }),
      });
    } catch (error) {
      if (!silent) {
        addMessage('assistant', 'Não consegui avisar o standby, mas parei a escuta local.');
      }
    }
  }, [addMessage]);

  const sendUtterance = useCallback(async (utterance) => {
    const cleanUtterance = String(utterance || '').trim();
    if (!cleanUtterance || processing) return;

    addMessage('user', cleanUtterance);
    setDraft('');
    setProcessing(true);
    setStatus('processing');

    try {
      const response = await fetch(API_ENDPOINTS.ASSISTANT_COMMAND, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authUtils.getToken()}`,
        },
        body: JSON.stringify({
          userId: authUtils.getUserId(),
          channelId: 'voice-assistant',
          conversationId: conversationIdRef.current,
          content: cleanUtterance,
        }),
      });

      const payload = await response.json();
      const reply = payload.reply_text || payload.message || 'Resposta recebida.';
      addMessage('assistant', reply, { error: !payload.ok });
      speak(payload);

      if (payload?.command?.key === 'exit') {
        await enterStandby({ silent: true });
        return;
      }
    } catch (error) {
      addMessage('assistant', 'Não consegui falar com a API do assistente.', { error: true });
    } finally {
      setProcessing(false);
      setStatus('standby');
    }
  }, [addMessage, enterStandby, processing, speak]);

  const startListening = useCallback(() => {
    if (!supported || processing) return;

    const recognition = new SpeechRecognition();
    recognition.lang = 'pt-BR';
    recognition.continuous = false;
    recognition.interimResults = true;
    transcriptRef.current = '';

    recognition.onstart = () => {
      setListening(true);
      setStatus('listening');
    };

    recognition.onresult = (event) => {
      let finalTranscript = '';
      let interimTranscript = '';

      for (let i = event.resultIndex; i < event.results.length; i += 1) {
        const transcript = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          finalTranscript += transcript;
        } else {
          interimTranscript += transcript;
        }
      }

      const current = (finalTranscript || interimTranscript).trim();
      if (current) {
        transcriptRef.current = current;
        setDraft(current);
      }
    };

    recognition.onerror = () => {
      setListening(false);
      setStatus('standby');
      addMessage('assistant', 'Não consegui ouvir agora. Tente novamente ou digite o comando.', { error: true });
    };

    recognition.onend = () => {
      setListening(false);
      const spoken = transcriptRef.current.trim();
      transcriptRef.current = '';
      if (spoken) {
        sendUtterance(spoken);
      } else {
        setStatus('standby');
      }
    };

    recognitionRef.current = recognition;
    recognition.start();
  }, [addMessage, processing, sendUtterance, supported]);

  const toggleListening = () => {
    if (listening) {
      enterStandby();
      return;
    }
    startListening();
  };

  const submitTypedCommand = (event) => {
    event.preventDefault();
    sendUtterance(draft);
  };

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => () => {
    enterStandby({ silent: true });
  }, [enterStandby]);

  return (
    <div className="admin-page voice-assistant-page">
      <Sidebar />

      <main className="voice-assistant-shell">
        <section className="voice-assistant-header">
          <div>
            <p className="voice-assistant-kicker">Flowly Voice</p>
            <h1>Assistente de voz</h1>
          </div>
          <div className={`voice-status ${status}`}>
            <span />
            {status === 'listening' ? 'Ouvindo' : status === 'processing' ? 'Processando' : 'Standby'}
          </div>
        </section>

        <section className="voice-chat-panel" aria-live="polite">
          <div className="voice-chat-messages">
            {messages.map((message) => (
              <article
                key={message.id}
                className={`voice-message ${message.role} ${message.error ? 'error' : ''}`}
              >
                <span className="voice-message-author">
                  {message.role === 'user' ? 'Você' : 'Assistente'}
                </span>
                <p>{message.text}</p>
              </article>
            ))}
            <div ref={messagesEndRef} />
          </div>

          <div className="voice-orb-zone">
            <button
              type="button"
              className={`voice-orb ${listening ? 'listening' : ''}`}
              onClick={toggleListening}
              disabled={!supported || processing}
              aria-label={listening ? 'Parar escuta' : 'Iniciar escuta'}
              title={supported ? 'Falar com o assistente' : 'Reconhecimento de voz indisponível'}
            >
              <span className="voice-wave wave-one" />
              <span className="voice-wave wave-two" />
              <span className="voice-wave wave-three" />
              <span className="voice-orb-icon">
                {listening ? <FaMicrophoneSlash /> : <FaMicrophone />}
              </span>
            </button>
          </div>

          <form className="voice-command-form" onSubmit={submitTypedCommand}>
            <div className="voice-input-wrap">
              <FaVolumeUp />
              <input
                value={draft}
                onChange={(event) => setDraft(event.target.value)}
                placeholder={supported ? 'O texto reconhecido aparece aqui' : 'Digite um comando'}
                disabled={processing}
              />
            </div>
            <button type="submit" disabled={!draft.trim() || processing} title="Enviar comando">
              <FaPaperPlane />
            </button>
            <button type="button" onClick={() => enterStandby()} title="Standby">
              <FaPowerOff />
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}

export default VoiceAssistantPage;
