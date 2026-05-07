import React, { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import axios from "axios";
import { FaEnvelope, FaPaperPlane, FaKey, FaCheck } from 'react-icons/fa';
import { API_ENDPOINTS } from "../../config/config";
import { authUtils } from "../../config/authUtils";
import "../../styles/pages/auth/Login.css";

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

function Verify() {
  const query = useQuery();
  const tokenFromUrl = query.get("token");
  const emailFromUrl = query.get("email") || "";
  const navigate = useNavigate();

  const [email, setEmail] = useState(emailFromUrl);
  const [userId, setUserId] = useState("");
  const [codigo, setCodigo] = useState("");
  const [statusMsg, setStatusMsg] = useState("");
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState(tokenFromUrl ? "token-verify" : "request");

  useEffect(() => {
    if (emailFromUrl) {
      setEmail(emailFromUrl);
    }
  }, [emailFromUrl]);

  useEffect(() => {
    if (!tokenFromUrl && emailFromUrl && step === "request" && !loading) {
      handleSendCodeFromEmail(emailFromUrl);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tokenFromUrl, emailFromUrl]);

  useEffect(() => {
    if (tokenFromUrl) {
      // Validar token vindo por link
      (async () => {
        setLoading(true);
        setStatusMsg("");
        try {
          const res = await axios.get(`${API_ENDPOINTS.VALIDATE_2FA_TOKEN}?token=${encodeURIComponent(tokenFromUrl)}`);
          const jwt = res.data.token;
          // armazenar token temporariamente e buscar dados do usuário
          localStorage.setItem('token', jwt);
          try {
            const userRes = await axios.get(API_ENDPOINTS.USER_ME, { headers: { Authorization: `Bearer ${jwt}` } });
            authUtils.saveAuthData(jwt, userRes.data);
          } catch (err) {
            // Se não conseguir buscar user/me, apenas salvar token
            console.warn('Não foi possível obter user/me após validação de token.');
          }

          const redirect = res.data.redirect || '/dashboard';
          window.location.href = redirect;
        } catch (err) {
          setStatusMsg(err.response?.data?.message || 'Token inválido ou expirado.');
          setStep('request');
        } finally {
          setLoading(false);
        }
      })();
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tokenFromUrl]);

  const handleSendCode = async (e) => {
    e.preventDefault();
    await handleSendCodeFromEmail(email);
  };

  const handleSendCodeFromEmail = async (emailToSend) => {
    setLoading(true);
    setStatusMsg("");

    try {
      const res = await axios.post(API_ENDPOINTS.SEND_2FA, { email: emailToSend });
      setUserId(res.data.userId || res.data.user_id || "");
      setStatusMsg('Código enviado. Verifique seu email.');
      setStep('enter-code');
    } catch (err) {
      setStatusMsg(err.response?.data?.message || 'Erro ao enviar código.');
    } finally {
      setLoading(false);
    }
  };

  const handleValidateCode = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatusMsg("");

    try {
      const res = await axios.post(API_ENDPOINTS.VALIDATE_2FA_CODE, { userId, codigo });
      const jwt = res.data.token;
      localStorage.setItem('token', jwt);
      try {
        const userRes = await axios.get(API_ENDPOINTS.USER_ME, { headers: { Authorization: `Bearer ${jwt}` } });
        authUtils.saveAuthData(jwt, userRes.data);
      } catch (err) {
        console.warn('Não foi possível obter user/me após validação do código.');
      }

      setStatusMsg('Verificação bem-sucedida! Redirecionando...');
      setTimeout(() => {
        const redirect = res.data.redirect || '/dashboard';
        window.location.href = redirect;
      }, 900);
    } catch (err) {
      setStatusMsg(err.response?.data?.message || 'Código inválido ou expirado.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card glass-panel">
        <div className="auth-header">
          <h2>Verificação de Email</h2>
          <p>Verifique sua conta usando o código enviado ao seu email</p>
        </div>

        {statusMsg && <div className="erro-container" style={{color: '#2b2b2b'}}>{statusMsg}</div>}

        {step === 'request' && (
          <form className="auth-form" onSubmit={handleSendCode}>
            <div className="input-group">
              <div className="input-icon"><FaEnvelope /></div>
              <input
                type="email"
                placeholder="Seu email para receber o código"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <input type="hidden" value={email} readOnly />

            <button type="submit" className="glass-btn primary" disabled={loading}>
              <FaPaperPlane /> {loading ? 'Enviando...' : 'Enviar código'}
            </button>
          </form>
        )}

        {step === 'enter-code' && (
          <form className="auth-form" onSubmit={handleValidateCode}>
            <div className="input-group">
              <div className="input-icon"><FaKey /></div>
              <input
                type="text"
                placeholder="Código de verificação"
                value={codigo}
                onChange={(e) => setCodigo(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <button type="submit" className="glass-btn primary" disabled={loading}>
              <FaCheck /> {loading ? 'Verificando...' : 'Verificar código'}
            </button>
          </form>
        )}

      </div>
    </div>
  );
}

export default Verify;
